# 兴安盟仿真器 Windows 原生部署规划（SQLite 版）

> 状态：规划稿。P1（方案 B 构建验证）与 P0–P4 全链路已于 2026-11-21 在 Leo 本机对 DUT 实施并通过验收（见第 13、14 节），P5 割接交付与 24h 稳定性观察待做。 范围：把 ems\_simulate 仿真器部署到同公司同事的 Windows 机器上，不使用 Docker Desktop，数据库由 MySQL 改为 SQLite，并以 SQLite 版作为今后的主线。

## 1. 目标与前提

- 被测端（DUT）仍是那台麒麟 V10 虚拟机（10.0.0.194）里的 qplantagc。仿真器只扮演它的对端（PLC/DCS、NCS、上级主站），不改 DUT 的逻辑。
- 接收方是同公司同事，因此无需顾虑 GPL 的外发限制，随包附带源码与许可文本即可。
- DUT 只有一台，同一时刻只能有一个仿真器在线，所以需要一份割接与回滚手册。
- SQLite 版替代 MySQL 版成为主线，迁移只做一次，不要求做成可反复执行的工具。

## 2. 现状核对结论

| 项目 | 结论 |
| --- | --- |
| SQLite 支持 | 上游默认就是 SQLite：`config.ini` 里 `type = sqlite`，`db_config.py` 已有 SQLite 配置（WAL、`busy_timeout=5000`），建表靠 `create_all`，数据库层无需改代码。 |
| 入口是否便携 | `start_back_end.py` 支持 `--port` 与 `EMS_ROOT_DIR`，首次启动自动准备 `data/log/config` 目录；若包内有初始 `data/ems.db` 则自动复制。注意：仓库源码树里**没有** `data/ems.db`（只有 `ems_schema.sql`），冷启动实际靠 `create_all` 建空库；交付包放迁移后的 `ems.db` 即走复制路径。 |
| 原生依赖难点（2026-11-21 二次核验修正） | Windows 原生依赖。`wheels/` 里的 c104 是 `linux_x86_64` cp312（仅供 Docker 镜像重建）。PyPI c104 2.2.1 有全套 win_amd64 wheel（cp310–cp313），可直接装、能跑；**但 fork 2.2.2 在 2.2.1 之后有功能提交**（c7ea398 稳定连接 ID/本地端点/TLS 握手事件，及 fe436e6/f9ded6f/8ec90de 的 TLS/hostname verification 修复；pin 214b88d 只是压在最上面的 vendoring，不能代表 fork 全部差异）。ems 代码用 `c104.ServerConnection` 做连接监控（iec104server.py:18-24 有 getattr 降级——2.2.1 能跑但**丢连接监控**）；`c104.TransportSecurity` 直接使用（tls.py:196，无降级）。`pyproject.toml` 注释本意是"本地编译的 2.2.2 可满足 pip"，不等于 PyPI 2.2.1 等效。另 `build_windows.ps1:152-155` 有硬门槛（`c104=="2.2.2"` 且 `TransportSecurity` 有 `set_hostname_verification`，该 API 在全部 Python 代码中零引用、只在这道门槛里）——**PyPI 2.2.1 过不了此脚本**，须绕开（见 P1）。 |
| 构建环境 | 本规划所需的 Windows 构建与验证都要在 Leo 的 Windows 本机（`C:\work\Hinggan_League`）上完成。 |
| spec 可用性（2026-11-21 已闭环） | 初稿"spec 未找到"的判断来自 **GitHub 克隆**——当时根 `.gitignore` 模板规则 `*.spec` 把两份 `ems_simulate_backend.spec` 挡在库外，远端确实看不到，不是查错目录。已修（PR #1，已合并）：gitignore 加 `!` 例外，两份 spec 与 Docker 重建 wheels 入库。spec 本体 153 行，onefile/onedir 环境变量切换；c104 仅作为 hiddenimport 收集，**spec 自身不检查 c104 版本与 TLS API**。2026-11-21 已在 Windows 实际构建+冒烟通过，见第 13 节。 |

## 3. 打包形态选择

| 方案 | 做法 | 优点 | 缺点 |
| --- | --- | --- | --- |
| A 嵌入式 Python + 离线 wheelhouse | 带上 Windows embeddable Python，依赖在构建机预装进目录，整包拷贝，`.py` 源码原样保留 | 4 处本地补丁现场可见、可原地热修；没有 PyInstaller 的 hidden-import 问题 | 打包工序最重（原 P1 主要工作量所在）；包体约 200MB 量级 |
| B（推荐）上游 PyInstaller onedir | `scripts/build_windows.ps1`，或绕开脚本直接调 PyInstaller（见 P1 第 4 条） | 单目录；**目标机零安装环境**——解压即用、无需 Python/依赖，自动建 SQLite（已实证）；2026-11-21 构建+冒烟通过（第 13 节）；产物 109MB | 脚本内含 c104==2.2.2 硬门槛，用 PyPI 2.2.1 须绕开；补丁冻结在 exe 内，改动需构建机重打包（约 4 分钟）再拷贝覆盖 |
| C 目标机现场 `uv sync` | 目标机联网自行安装 | 包最小 | 需要 MSVC 编译 c104，对他人机器不现实 |

选择 B 为主（2026-11-21 定）：目标机零安装环境是硬需求且已实证；现场热修用"构建机重打包 + 拷贝覆盖"满足，全套源码仍随包交付（GPL 本身要求），源码可见性不丢，丢的只是"原地改立即生效"。A 降为备选，仅在 PyInstaller 出现无法绕过的打包问题时启用。

## 4. 分阶段实施清单

**P0 前置（最优先，两项待确认不解决则全流程阻塞）**：原第 11 节两项——① 同事机器的 Windows 版本与 IP、是否位于 10.0.0.0/24、能否直接访问 10.0.0.194:2404（不在同网段则割接不可行，需先处理路由或 VM 网络模式）；② 同事机器是否有管理员权限（影响防火墙脚本与服务注册方式）。

### P0 冻结与基线（约 1 小时）

1. 在 10.0.0.9 的 `mysql84` 上取当前在线库的最终 dump。不要使用 11-20 的 `net.sql`，因为之后映射或点值可能又改过。
2. 同时记录一份基线点值表（机组上下限、调节速度、电气量等），用于重启后回灌，因为设备或进程重启会把模拟点运行值清零。

### P1 Windows 构建与验证（在 Leo 的 Windows 本机）

1. Python 版本定 **3.12**（与现网镜像一致；PyPI c104 / pyiec61850-ng 均有 cp312 win_amd64 wheel）。构建环境已就绪：`ems_simulate/.venv-win` 即 py3.12.15 + PyPI c104 2.2.1 + 全部运行依赖，2026-11-21 又补装了 pyinstaller 6.18.0 / altgraph / Pillow。
2. c104 选型（2026-11-21 核验后的定版）：**PyPI 2.2.1 可直接装、能跑**（有 getattr 降级），代价是丢连接监控（`ServerConnection`）与 TLS 新 API；**fork 2.2.2 功能完整但需 MSVC 自编译**（上游 CI 的短路径缓存坑只在此场景出现）。交付包（方案 B）先用 2.2.1 起步、P4 对 DUT 验收后定夺是否换自编译 2.2.2；若定 2.2.1，需同步改 `pyproject.toml`/requirements 的 `==2.2.2` pin 并按 CLAUDE.md 重新生成 `requirements-docker.txt` 冻结清单。
3. 确认 `pyiec61850-ng`、`cryptography`、`greenlet`、`psutil` 等原生依赖都有 Windows wheel（已核：pyiec61850-ng 1.6.1.10 有 cp310–cp314 win_amd64，其余在 `.venv-win` 实装可用）。
4. ~~验证 c104 满足 `set_hostname_verification` 等 API 检查~~（2026-11-21 修正：该 API 只存在于 `build_windows.ps1:152-155` 的硬门槛里，Python 代码零引用，PyPI 2.2.1 没有此 API）。**用 2.2.1 时不得按原脚本走**：直接用环境变量调 PyInstaller 绕开脚本（已验证可行，见第 13 节），或删掉脚本里那处断言。补丁 ①②③④ 源码已在构建树内核实（5 个文件"本地补丁"注释齐全）。
5. ~~构建嵌入式 Python 便携包（方案 A）~~——方案 B 已升为主交付（§3，2026-11-21 定），本条简化为：把第 13 节的构建流程固化成一键重打包脚本，并做一次完整交付态打包（exe + 旁置 config.ini + 装载迁移后 `ems.db`）作为交付基线；方案 A 仅在 PyInstaller 出现无法绕过的打包问题时启用。

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

- 大小写敏感：MySQL 使用 `utf8mb4_0900_ai_ci`（不区分大小写），SQLite 默认区分。~~必要时对相关列加 `COLLATE NOCASE`~~ **（2026-11-21 实测修正：无效）**——测点查找走运行时内存字典精确匹配（`point_manager.get_point_by_code`），SQL 层 collation 不参与；**正确做法是 API 调用一律用库内大小写（点号全大写，如 `YC512` 而非 `yc512`）**。迁移脚本仍给 code/name 列加了 NOCASE（对直接 SQL 查询友好，无害）。
- 布尔与时间类型：`tinyint` 转 bool，datetime 格式保持一致。
- 外键：SQLite 连接会开启 `PRAGMA foreign_keys=ON`，插入需按依赖顺序，孤儿行提前清理。
- 字段保真：`iec_type_id`（yc 为 M\_ME\_NC\_1、主站 yt 为 C\_SE\_NC\_1）、`decode_code`（Modbus 为 INT16\_AB，NCS 104 为 FLOAT32\_ABCD）、`enable`、8 条映射的公式，迁完后逐项抽检。
- 已知旧坑：`channels/update` 的 `enable` 字段不落库（曾导致 ch3 enable=0、主站设备 404）。迁完要直接核对 `channel.enable`，并确认 SQLite 下是否复现。
- 字符集：中文名称与描述迁移后要核对无乱码。

## 6. 目录结构建议

- `ems_simulate_backend.exe` + `_internal/`：onedir 产物放包根（`www/` 前端与 point_csv 已打进 `_internal`；以下 config/data/log 均生成在 exe 同级，实测如此）
- `data/ems.db`：迁移后的库（exe 旁，启动自动使用）
- `config.ini`：`type=sqlite`；放 exe 旁（onedir 按设计不打包 config，旁置的可编辑配置优先，已实证）；监听地址按是否需要远程访问 Web 选择 `0.0.0.0` 或 `127.0.0.1`
- `src/`：全套源码（含 4 处补丁）与 GPL 许可文本——合规交付与备查用，现场不从源码跑
- `log/`
- `tools/`：`xamapi-local.py` 等辅助脚本
- `scripts/`：启动、停止、重启恢复、防火墙、站点参数设置

包内不含 Python 运行时与任何安装环境（已冻结进 exe），不含 MySQL 配置与明文密码；目标机无需 Python / Node，解压即用。

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
| PyPI c104 2.2.1 与 fork 2.2.2 的功能差异（连接监控 `ServerConnection`、TLS API）影响超出预期 | P4 对 DUT 验收不达标 | 差异已定位（fork 2.2.1 后有功能提交，非"仅 vendoring"）；2.2.1 有 getattr 降级能跑、构建实证已过（第 13 节）；P4 按第 7 节验收判分，不达标则 MSVC 自编译 fork 2.2.2（注意短路径缓存） |
| 设备重启假活在原生下仍复现 | 恢复链更重 | 恢复链做成整进程重启并脚本化 |
| SQLite 写锁 | 偶发超时 | 已开 WAL；做压力测试；必要时调大 `busy_timeout` |
| 大小写敏感导致按名查找失败 | 设备或映射找不到 | 迁移后逐项抽检；必要时加 `COLLATE NOCASE` |
| 目标机无管理员权限或杀软拦截 | 无法放行端口、无法运行 | 提前确认；准备免安装说明 |
| 实时库写链路静默冻死 | 改值后不落库 | 沿用既有经验：改值后超过 60 秒不落库即怀疑，必要时重启 DUT |

## 11. 待确认信息（已前置到 P0 之前解决，见第 4 节开头）

两项：目标机 Windows 版本 / IP / 是否在 10.0.0.0/24 及对 10.0.0.194:2404 的可达性；目标机管理员权限。

## 12. 交付物

1. 便携包 `ems-sim-win-x.y.z.zip`
2. 部署说明（5 步以内）
3. `set-site` 脚本与 DUT 侧 `PORT_NET` 修改说明
4. 完整源码与 GPL 许可文本
5. 割接与回滚手册（本文第 8 节）

## 13. 方案 B 构建实证（2026-11-21，Leo 本机）

spec 首次在 Windows 上真实构建并冒烟通过，"spec 是否可用"疑点关闭。

- 环境：`ems_simulate/.venv-win`（Python 3.12.15 + PyPI c104 2.2.1 + 全部运行依赖；当日补装 pyinstaller 6.18.0 / altgraph / Pillow）。对照 `requirements-docker.txt` 冻结清单仅缺 uvloop——Linux 专属，Windows 上 uvicorn 自动走 asyncio，无碍。
- 构建命令（绕开 `build_windows.ps1` 的 c104==2.2.2 硬门槛，直接调 PyInstaller）：

  ```
  cd ems_simulate
  EMS_PYINSTALLER_MODE=onedir EMS_PYINSTALLER_CONSOLE=1 .venv-win/Scripts/pyinstaller.exe ems_simulate_backend.spec --noconfirm --distpath dist --workpath build
  ```

  约 3.6 分钟，产物 `dist/ems_simulate_backend/`（onedir，109MB）。
- 冒烟：`ems_simulate_backend.exe --port 8992` 启动正常，`/api/health` 返回 200 且 `database: sqlite`（自动建空库）；`_internal/` 内确认 c104、pyiec61850 原生模块均已打入。
- 过程发现（3 条）：
  1. onedir 模式按设计**不打包 config.ini**（spec 的 `BUNDLE_CONFIG` 默认 off），需在 exe 旁放可编辑配置（复制后正常读取，已验证）；
  2. health 报 `version 0.0.0`——冻结环境丢包元数据，纯外观问题；
  3. `/docs` 与裸 `/api/devices` 前缀 404 属正常（子路径路由 + 未开 docs），非缺陷。
- 产物在 `ems_simulate/dist`（gitignored，未入库，不需要可直接删）。一键重打包脚本：`ems_simulate/scripts/rebuild_onedir.ps1`；迁移脚本：`sim_config/migrate_to_sqlite.py`（在 10.0.0.9 容器内跑，读 mysql84 写 SQLite，逐表对账）。

## 14. P0–P4 实测记录（2026-11-21，Leo 本机 10.0.0.7 对 DUT 10.0.0.194）

方案 B onedir 从构建到对 DUT 验收全链路一次跑通，运行目录 `C:\tmp\ems-win-run`（exe + 旁置 config.ini/sqlite + data/ems.db）。

- **P0**：10.0.0.9 mysql84 最终 dump 72KB（`发布/old/ems-simulate-docker/dumps/net_dump_final_20261121.sql`），计数 device=3 / point_mapping=8 / point_yc=78。
- **P2**：迁移脚本在 10.0.0.9 ems-simulate 容器内实跑，24 表逐表对账全 OK、外键检查 OK（connection_session 为运行态数据，表结构保留、行清空）。踩坑两处：MySQL 方言类型（TINYINT 等）需转通用类型再 create_all；SA 2.0 无 `Table.count()`。
- **P3**：主站-仿真对端地址发现库里是 `127.0.0.1:2406`（与运行态不符——**API 改 channel ip/port 疑似不落库**，`channels/update` 坑的变体），set-site 直接 SQL 改为 `10.0.0.194:2404`。本机 10.0.0.7 网卡走公用配置档且防火墙公用=关，502/2404 入站免配置。
- **P4 验收（§7 对照）**：
  1. ✓ 三条 TCP 全通（DUT→本机 502/2404、本机→DUT 2404），`YX_DATA` 101/102/107=65、108=0（同 10.0.0.9 基线）；
  2. ✓ yc512=200.0、yc513=-555.0、yc222=77.7 精确落库（补丁④小数保真）；
  3. ✓ CA=257 服务端正常（由 102=65 与浮点数据隐含证明）；
  4. ✓ 闭环六环：主站 YS5=100 → DUT AGC 计算（yc101=99.864，与 2026-11-14 联调记录同值复现）→ 06 写 YS1/4/6/7=123/300/700/400 → 8 条映射回灌 → DUT 回读 yc301/303/305/307 与 yc501/601/901/1001 全对 → 转发上行（主站总召收到 YC101=100.0）。功率反馈 4 条跨设备映射在 SQLite 上工作正常。
- **专项疑点已答**：设备级 stop→start 假活在**原生 Windows 同样复现**，且比 Docker 版更完整地看清了机理——`channels/restart` 后 API 报成功、iec104.log 只有"已停止"无"已启动"；此后仿真整进程重启能重建 2404 监听（新进程持有 socket），**但 DUT 侧 ch1 卡 CLOSE-WAIT 极久不重连**（与 Docker 时代"102 停 192 半小时"同款；主站/Modbus 通道不受影响、自动恢复）。**完整恢复配方 = 仿真整进程重启 + DUT 重启**（实测：DUT 重启后 ch1 即刻重连）。
- **恢复链定版（原生版，13 秒完成实测）**：taskkill exe → 重启 → start×3 → **立刻写点值（抢在 DUT 重连总召之前，窗口约 30s）** → autoread + gi。竞态教训：DUT 只认总召响应、运行值不自发上送、也不主动周期总召——写值晚于 DUT 重连总召则值停在 0；反之预写值会被 DUT 重启后的总召正确拾取（实测 88.8 于 DUT 重启重连后 19 秒落库）。
- 待办：24h 稳定性观察（§7 第 6 条）与 P5 正式割接交付。
