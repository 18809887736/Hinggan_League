# 兴安盟仿真器 Windows 原生部署规划（SQLite 版）

> 状态：规划稿，尚未实施。本文只描述方案、步骤与验收，不涉及对仓库的任何改动。 范围：把 ems\_simulate 仿真器部署到同公司同事的 Windows 机器上，不使用 Docker Desktop，数据库由 MySQL 改为 SQLite，并以 SQLite 版作为今后的主线。

## 1. 目标与前提

- 被测端（DUT）仍是那台麒麟 V10 虚拟机（10.0.0.194）里的 qplantagc。仿真器只扮演它的对端（PLC/DCS、NCS、上级主站），不改 DUT 的逻辑。
- 接收方是同公司同事，因此无需顾虑 GPL 的外发限制，随包附带源码与许可文本即可。
- DUT 只有一台，同一时刻只能有一个仿真器在线，所以需要一份割接与回滚手册。
- SQLite 版替代 MySQL 版成为主线，迁移只做一次，不要求做成可反复执行的工具。

## 2. 现状核对结论

| 项目 | 结论 |
| --- | --- |
| SQLite 支持 | 上游默认就是 SQLite：`config.ini` 里 `type = sqlite`，`db_config.py` 已有 SQLite 配置（WAL、`busy_timeout=5000`），建表靠 `create_all`，数据库层无需改代码。 |
| 入口是否便携 | `start_back_end.py` 支持 `--port` 与 `EMS_ROOT_DIR`，首次启动自动准备 `data/log/config` 目录并复制初始 `ems.db`。 |
| 原生依赖难点（2026-11-21 核验，大幅降险） | Windows 原生依赖。`wheels/` 里的 c104 是 `linux_x86_64` 的 cp312 wheel（仅供 Docker 镜像重建用）。但已核实 **PyPI c104 2.2.1 提供全套 win_amd64 wheel（cp310–cp313）**；600888 fork 的 pin 提交（214b88d）内容仅为 "Vendor third-party dependencies"，是打包改动而非协议功能差异；上游 `pyproject.toml` 注释亦明示非 fork 版本可直接满足 pip。首选直接用 PyPI wheel，无需 MSVC 编译。 |
| 构建环境 | 本规划所需的 Windows 构建与验证都要在 Leo 的 Windows 本机（`C:\work\Hinggan_League`）上完成。 |
| 已知缺口（2026-11-21 核验，不成立） | 初稿称 `ems_simulate_backend.spec` 在仓库根目录未找到——实际它就在源码根目录 `发布/old/ems_simulate-src/`（153 行，支持 onefile/onedir 环境变量切换），`build_windows.ps1:180` 直接引用；初稿查错了目录（查成 `C:\work\Hinggan_League` 仓库根）。方案 B 可行性由此确认。 |

## 3. 打包形态选择

| 方案 | 做法 | 优点 | 缺点 |
| --- | --- | --- | --- |
| A（推荐）嵌入式 Python + 离线 wheelhouse | 带上 Windows embeddable Python，依赖在构建机预装进目录，整包拷贝，`.py` 源码原样保留 | 4 处本地补丁都是源码改动，现场可见、可原地热修；没有 PyInstaller 的 hidden-import 问题 | 包体偏大（约 200MB 量级） |
| B 上游 PyInstaller onedir | 使用 `scripts/build_windows.ps1` | 单目录、现成脚本；spec 文件已核实存在 | 补丁要重新打包才生效 |
| C 目标机现场 `uv sync` | 目标机联网自行安装 | 包最小 | 需要 MSVC 编译 c104，对他人机器不现实 |

选择 A 为主，B 为备选。理由是本项目有过补丁在镜像搬运中丢失的教训，源码可见、可原地改的方案在现场更稳。

## 4. 分阶段实施清单

### P0 冻结与基线（约 1 小时）

1. 在 10.0.0.9 的 `mysql84` 上取当前在线库的最终 dump。不要使用 11-20 的 `net.sql`，因为之后映射或点值可能又改过。
2. 同时记录一份基线点值表（机组上下限、调节速度、电气量等），用于重启后回灌，因为设备或进程重启会把模拟点运行值清零。

### P1 Windows 构建与验证（在 Leo 的 Windows 本机）

1. 确定 Python 版本（上游 CI 用 3.11，现网镜像是 3.12），并与 c104 的构建版本保持一致。
2. 解决 Windows 版 c104：**首选 `pip install c104==2.2.1`**（PyPI 有 cp310–cp313 win_amd64 wheel；需同步把 `pyproject.toml`/requirements 的 `==2.2.2` pin 改为 2.2.1，并按 CLAUDE.md 要求重新生成 `requirements-docker.txt` 冻结清单），装完与第 4 条一起做功能冒烟。MSVC + CMake 自编译 fork 2.2.2 仅作兜底——上游 CI 的短路径缓存坑只在源码构建时出现，走 PyPI wheel 则无关。
3. 确认 `pyiec61850-ng`、`cryptography`、`greenlet`、`psutil` 等原生依赖都有 Windows wheel。
4. 验证 c104 满足 `set_hostname_verification` 等 API 检查，并确认补丁 ①②③④ 对应的源码都在构建树内。
5. 构建嵌入式 Python 便携包（方案 A）；方案 B 的 spec 文件已核实存在，可直接试跑作为对照。

### P2 MySQL → SQLite 一次性迁移（约 1 天）

1. 在构建机用最终 dump 起一个临时 MySQL（构建机使用 Docker 没有问题，目标机不需要）。
2. 写一次性迁移脚本：用项目自己的 SQLAlchemy 模型对 SQLite 执行 `create_all`，再从 MySQL 逐表拷贝，保持主键原值。
3. 重点防坑，见第 5 节。
4. 校验：24 张表行数对账；设备数（3）、点数、映射数（8）逐项比对。
5. 进入仓库的是 SQLite 的文本 `.dump`，由它构建出 `ems.db`，避免二进制文件造成冲突和 diff 不可读。交付时只带 checkpoint 后的单个 `ems.db`，不带 `-wal/-shm`。
6. 并发压力测试：多设备轮询加 REST 写，观察有无 `database is locked`，这是 SQLite 相对 MySQL 唯一实质的风险。

### P3 站点参数与运维脚本（约 1 天）

- `set-site`：输入目标机 IP（以及 DUT IP，默认 10.0.0.194），修改 SQLite 中主站-仿真的对端地址，并输出 DUT 侧 `PORT_NET` 的修改说明。
- 防火墙脚本：放行入站 TCP 502 与 2404，源地址限定 10.0.0.0/24（需管理员）。
- 检查 502 端口占用：别的 Modbus 软件、系统保留端口段。
- 一键启动：启动后端，等健康检查通过，再依次 `devices/start`、主站 `autoread`、`gi`。
- 重启恢复链（替代 `docker compose restart`）：结束进程，启动，设备启动，用 Python socket 实测 502/2404 是否真的在监听，`autoread` 与 `gi`，重写点值。
- 点值重写脚本：从基线值表一键回灌。
- 常驻方式：任务计划程序或 NSSM 服务，二选一。
- Windows 特有注意点：控制台“快速编辑”会在点击窗口时冻结进程，应后台运行或关闭该模式；中文路径和请求体统一走 UTF-8（沿用 Python 脚本，不用 curl）；杀软可能误报 `.pyd`。

### P4 在 Leo 本机原生验证（约 1 天）

用同一台 DUT，对照现有验收标准跑完整一遍，再进入割接，详见第 7 节。同时专项回答一个疑点：Docker 中观察到的“设备级 stop→start 假活”，在原生 Windows 下是否复现。结果决定重启恢复链是否必须整进程重启。

### P5 割接与交付

见第 8 节。

## 5. SQLite 迁移要点

- 大小写敏感：MySQL 使用 `utf8mb4_0900_ai_ci`（不区分大小写），SQLite 默认区分。设备名、通道名等按名称查找的地方要逐一核对，必要时对相关列加 `COLLATE NOCASE`。
- 布尔与时间类型：`tinyint` 转 bool，datetime 格式保持一致。
- 外键：SQLite 连接会开启 `PRAGMA foreign_keys=ON`，插入需按依赖顺序，孤儿行提前清理。
- 字段保真：`iec_type_id`（yc 为 M\_ME\_NC\_1、主站 yt 为 C\_SE\_NC\_1）、`decode_code`（Modbus 为 INT16\_AB，NCS 104 为 FLOAT32\_ABCD）、`enable`、8 条映射的公式，迁完后逐项抽检。
- 已知旧坑：`channels/update` 的 `enable` 字段不落库（曾导致 ch3 enable=0、主站设备 404）。迁完要直接核对 `channel.enable`，并确认 SQLite 下是否复现。
- 字符集：中文名称与描述迁移后要核对无乱码。

## 6. 目录结构建议

- `python/`：嵌入式 Python 及依赖
- `app/`：源码（含 4 处补丁）与 `www/` 前端产物
- `data/ems.db`
- `config.ini`：`type=sqlite`；监听地址按是否需要远程访问 Web 选择 `0.0.0.0` 或 `127.0.0.1`
- `log/`
- `tools/`：`xamapi-local.py` 等辅助脚本
- `scripts/`：启动、停止、重启恢复、防火墙、站点参数设置

包内不再含 MySQL 配置与明文密码，前端使用现成的 `www/` 构建产物，目标机无需 Node。

## 7. 验收标准（以 DUT 表现为准）

1. 三条 TCP 全通，`relate_yx` 101/102/107 均为 65。
2. NCS 浮点 yc222 写入 77.7 后落库仍为 77.7（验证补丁 ④）；PLC 整型 yc512/513 落库正确。
3. CA=257 的 104 服务端可用（验证补丁 ①②③）。
4. 主站 YS5 下发后，DUT 06 写，仿真 YS1/4/6/7 经 8 条映射回灌到 YC301/303/305/307 与 YC501/601/901/1001，闭环成立。
5. 结束进程后经重启恢复链全部自愈，DUT 重连正常。
6. 连续运行 24 小时，无 `database is locked`，无线程卡死。

## 8. 割接与回滚手册

### 割接

1. 停止 10.0.0.9 上的 `ems-simulate`（`docker compose stop`）。
2. 在 DUT 上修改 `PORT_NET`，使 ch4 指向同事机器 IP 的 502，ch1 主对端指向其 2404。
3. 结束 DUT 进程后静置至少 60 秒再启动（已知坑：紧跟着启动会卡死 installTranslator；kill 需注意进程是否以 root 启动）。
4. 在同事机器上启动仿真器，执行启动脚本与恢复链，回灌点值。
5. 按第 7 节验收。

### 回滚

将 `PORT_NET` 改回 10.0.0.9（已有备份 `qplantagcrtdb.db.bak-20261120-backto9`），再启动 10.0.0.9 的容器，DUT 同样静置 60 秒后重启。

## 9. 主线切换后的连带修改

- 10.0.0.9 的 Docker 版也可改为读取 SQLite 文件（`config.ini` 设 `type=sqlite`，bind mount `data/ems.db`），从此只有一份数据来源。验证通过后停用 `mysql84`，先不删除，留作归档。
- 更新 `CLAUDE.md`、`发布/readme.md`、`发布/目录结构.md` 中的 MySQL 描述，并清除其中的 root 明文密码。
- 调整 `xamapi-local.py` 的 BASE 地址与 `docker-compose.yml` 中对 MySQL 的依赖。

## 10. 风险与缓解

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| PyPI c104 2.2.1 与 fork 2.2.2 存在未察觉的功能差异 | P1 冒烟不通过 | 已核实 PyPI 有 win_amd64 wheel 且 fork pin 提交仅 vendoring；按第 7 节验收冒烟（CA=257、M_ME_NC 浮点、补丁④）；失败则回退 MSVC 自编译 fork 2.2.2（注意短路径缓存） |
| 设备重启假活在原生下仍复现 | 恢复链更重 | 恢复链做成整进程重启并脚本化 |
| SQLite 写锁 | 偶发超时 | 已开 WAL；做压力测试；必要时调大 `busy_timeout` |
| 大小写敏感导致按名查找失败 | 设备或映射找不到 | 迁移后逐项抽检；必要时加 `COLLATE NOCASE` |
| 目标机无管理员权限或杀软拦截 | 无法放行端口、无法运行 | 提前确认；准备免安装说明 |
| 实时库写链路静默冻死 | 改值后不落库 | 沿用既有经验：改值后超过 60 秒不落库即怀疑，必要时重启 DUT |

## 11. 待确认信息

- 同事机器的 Windows 版本与 IP；是否位于 10.0.0.0/24，能否直接访问 10.0.0.194:2404。这决定 `set-site` 的默认值，也决定割接时是否需要处理路由或 VM 网络模式。
- 同事机器是否有管理员权限（影响防火墙脚本与服务注册方式）。

## 12. 交付物

1. 便携包 `ems-sim-win-x.y.z.zip`
2. 部署说明（5 步以内）
3. `set-site` 脚本与 DUT 侧 `PORT_NET` 修改说明
4. 完整源码与 GPL 许可文本
5. 割接与回滚手册（本文第 8 节）
