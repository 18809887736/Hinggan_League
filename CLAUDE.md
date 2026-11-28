# 兴安盟 AGC AVC 子站（qplantagc）工程说明

## 项目概况

- 本仓库整理兴安盟电厂 AVC 子站（qplantagc）的通道配置与点表。
- 权威数据源：`main.sql`（qplantagcrtdb 实时库 SQLite 的 Navicat 导出）。
- 整理文档：`PLC通道点表整理.md`（全部通道总览 + PLC 点表详表 + 疑点清单）。
- 部署环境：银河麒麟 V10 SP1 虚拟机（部署方法见 kylin-qplantagc-deploy skill）。
- 仿真工具：`ems_simulate/`（选型已定，见下文开发任务一节）。
- **10.0.0.9 (myubuntu) 操作准则：任何服务部署一律首选 docker compose，宿主机零污染**——数据 bind mount 持久化、端口绑 `10.0.0.9` 发布；不在宿主机装工具链/venv/ufw 规则（Docker 发布端口走 iptables 绕过 ufw）。原生依赖预编译成 wheel 放构建上下文，PyPI 走清华镜像。参考实现：`ems_simulate/Dockerfile` + `docker-compose.yml`。
- **文本编辑规则：编辑任何含 AVC 字样的文本前，先删除全部"供热"字样**——本项目资料常从热电联产电厂模板拷贝，"供热机组/供热工况"等不适用于兴安盟电厂；新建文本同样不得引入。

## 现行状态（2026-11-28，先读这一节）

下面「开发任务」一节里 10.0.0.9 docker 时代的操作细节只作回退备查，现行状态以本节为准。

- **仿真器现行版本：本机原生包 1.0.4（源码 6.8.3，2026-11-28 12:21 割接）**。目录 `发布\对外统一交付物\ems-sim-win-1.0.4\`；启动 `scripts\start.ps1`、停止 `scripts\stop.ps1`（重启一律整进程，设备级 stop→start 会假活）。Web/REST `http://127.0.0.1:8991`，Modbus `0.0.0.0:502`，104 服务端 `0.0.0.0:2404`；API 助手 `sim_config/ems_local.py`（点号必须大写）。重建打包：`ems_simulate\scripts\rebuild_onedir.ps1` → `sim_config/patch_contact.py`（exe 重建之后跑一遍，两处目标都会打上）→ `发布\对外统一交付物\make-package.ps1 -Version x.y.z`。前端源码有改动时先构建前端：**在 `C:\work` 下新建目录**拷入 `front/`，`npm ci` → `npx vite build`，把产出的 `www` 拷进 `ems_simulate/www`（不要在 `C:\tmp` 下构建，未签名的 esbuild 在那里读不了目录）。**PLC-仿真、NCS-仿真 随程序启动自动开启设备**（TCP 服务端通道，补丁⑪），直接双击 exe 也会监听；主站-仿真（客户端通道）不自动启动，靠 `start.ps1` 启动并开 autoread 与总召唤（换包或重启后主站要最后起，见运维注记 1）。
- **「单位」列与 `config.ini` 开关（2026-11-28 实施，见 [YC单位列规划-20261128.md](YC单位列规划-20261128.md)）**：三个设备测点表的「真实值」后多一列「单位」，只对遥测行显示——有功 MW、无功 Mvar、电压 kV、电流 A、频率 Hz、功率因数 —（无量纲），PLC 的上下限和指令反馈 MW、调节速度 MW/min。单位存在 `point_yc.unit`，只用于显示，不参与计算和报文。是否显示由 `config.ini` 的 `[server] show_unit_column` 决定（默认显示），改完**刷新浏览器**即生效，不用重启；改单位只能用 SQL，改后要整进程重启才显示。
- **DUT 的 PORT_NET 现指本机 10.0.0.7**（ch4→10.0.0.7:502、ch1 主对端→10.0.0.7:2404）。10.0.0.9 上的 docker 版降为回退备选，它的库还是旧取值，回退前先看规划 §9.13。
- **「开始」按钮与电气量（2026-11-27 实施，设计与证据见 [电气量波动规划-20261127.md](电气量波动规划-20261127.md)）**：不按「开始」时，PLC 的 12 个参数点和 NCS 的电压/频率/功率因数启动即为基准值。按「开始」后只有 7 个驱动点（YC502、YC504、YC904、YC515/615/915/1015）各自小幅正弦起伏，NCS 其余电气量由 57 条映射公式实时推出；指令反馈＝派发值限幅在铭牌内（派发 123/300/700/400 → 6/15/15/6），机组有功＝限幅后的派发值＋一个很小的跟踪偏差（6 MW 机组 ±0.02 MW、15 MW 机组 ±0.045 MW，各机组互不相关，仍夹在铭牌内），所以母线有功 YC222/YC235 也会小幅起伏；遥信、遥设不参与。被映射锁定的点手写会被拒，要改就改驱动点或 PLC 遥设。**YC 值一定要遵守电气性**：改动后跑 `python sim_config/yc_electrical_audit.py`（只读，退出码 0 为通过；共 140 条判据，含 78 条单位判据；波动中加 `--seconds 100 --corr`）。
- **机组容量按一次图 D-01：1#＝6、2#＝15、3#＝15、4#＝6 MW**（2026-11-27 用户裁定）。DUT 库 `GENERATOR` 表是 6/15/6/15，与一次图相反；DUT 库未改，待用户或厂商处理。
- **本地补丁共 12 处**：①~④ 见下文「本地补丁」一条；⑤ 启动后自动开浏览器、⑥ 单例模式、⑦ 首页版本号、⑧ 隐藏上游页脚与"联系作者"；⑨「开始」的默认参与规则与启动初值推送、⑩ 映射公式白名单函数 `sqrt/abs/min/max`、锁定点拒写、日志降级；⑪ TCP 服务端通道随程序启动自动开启设备（设备已运行时重复启动为空操作）；⑫ 遥测「单位」列（`point_yc.unit` 透传到表格、`config.ini` 的 `show_unit_column` 开关、`config.ini` 改按 `utf-8-sig` 读取以兼容 BOM）。都在仓库源码里，带「本地补丁」注释；改代码必须拨版本号。
- **运维注记**：
  1. 重启仿真后必须重启 DUT（它的 104 采集通道对不干净断线不自愈）。kill 后静置 ≥80s 再拉起（2026-11-28 两次各静置约 100s 都顺利），nohup 带 `< /dev/null`；启动成功的判据是 **DUT 自己的日志** `~/QCzt2016/build/logfile/<日期>/qplantagcserverlog.txt` 里出现 `rtdbManager start`（标准输出 `~/qserver.log` 里没有这一行）。**换包或重启仿真器时主站-仿真要最后起**：先只起 exe（PLC-仿真、NCS-仿真 自动监听），重启 DUT 并等到 `rtdbManager start`，再 `tools\ems_local.py start master`、`autoread master`、`gi master`。2026-11-28 割接时先用 `start.ps1`（它会立刻起主站并开 autoread）再重启 DUT，仿真器在 DUT 连上来的瞬间崩溃了（`_c104.pyd` 访问违规 0xc0000005，崩溃转储在 `%LOCALAPPDATA%\CrashDumps`）。
  2. `scripts\write-baseline.ps1` 现在只写 4 个机组开关遥信（NCS YX201/211/221/231）；遥测基准由程序启动时自动推送，不必手写。
  3. **1.0.4 起 `config.ini` 真正生效**（带不带 BOM 都能读）：`[server]` 的 `port`、`host`、`open_browser` 改后整进程重启生效，`show_unit_column` 刷新页面即生效——改这个文件就是在改行为。1.0.3 及以前包里那份带 BOM，等于没读（靠与之一致的默认值）。
  4. DUT 会跟随 NCS 每秒的周期上送：改 NCS 的值后，DUT 库在 40~60 秒的落库周期内跟着变。早先"DUT 只认总召"的结论对现行包不成立。
  5. DUT 实时库的写链路会静默冻死（2026-11-27 再次发生，重启 DUT 后恢复）。以 DUT 库读数为准之前先做落库活性预检：模拟停止时写 `YC502=50.123`，90 秒内查 DUT 库 `yc502`；不落库就重启 DUT。
  6. DUT 库只允许改 `PORT_NET` 表，其余表只读。
  7. 仿真器的数据库 `ems.db` 在 git 里（2026-11-27 用户要求：各交付包的 `data/ems.db` 都入库，`-wal`/`-shm`/备份不入库）。在跑的库写操作先进 `-wal`，**改完库里的配置要提交时先做 checkpoint 再 `git add`**：`发布\对外统一交付物\tools\sqlite3.exe ems-sim-win-1.0.4\data\ems.db "PRAGMA wal_checkpoint(TRUNCATE);"`。仿真器运行时不要用 git 还原这个文件。
  8. 不要在虚拟机上整篇扫描 DUT 的通道日志（`Chunnel4.txt` 有十几 MB 且持续追加）：2026-11-28 这样做之后虚拟机卡了约 9 分钟（SSH 登不上、DUT 不收发；原因没有查明，自行恢复）。要看报文就取有限的行（`tail`、`grep -m`），或者看仿真器的报文历史接口 `/api/devices/messages`。
  9. 不要用"重新加载设备配置"（`reload-config` 接口）刷新设备：它会把设备换成未启动的状态，PLC-仿真、NCS-仿真随即停止监听。
  10. 界面上的"复制设备"在 SQLite 包里不可用（返回成功但复制 0 个，日志 `unknown function: now()`，上游缺陷）；"添加设备"很可能同样不可用。需要新设备时手工创建。

## 通道 / 规约关键事实

| 通道号 | 名称 | 规约 | qplantagc 侧角色 | 网络参数 |
|---|---|---|---|---|
| 0 | NCS转发104主 | IEC 60870-5-104 | **服务端**监听 2404 | 上级主站连入 |
| 1 | NCS采集104 | IEC 60870-5-104 | **客户端**外连 | 10.0.0.88:2404、196.5.1.216:2404（双对端） |
| 4 | PLC | Modbus TCP | **客户端**外连 | 192.192.192.31:502，从站地址 1 |
| 5 | NCS转发104备 | IEC 60870-5-104 | **服务端**监听 2404 | 上级主站连入（主备互斥启用） |

- 104 三条通道 rtu_addr（ASDU 公共地址）= 257；遥测为浮点型（iYcFunctionCode=13）。
- PLC 通道 Modbus 映射：遥测 04 功能码 path 0~15、遥信 02 path 0~31、遥控 05 path 51~70、遥设 06 path 51~54。
- 点表明细以 `main.sql` 的 CHUNNEL_YC/YX/YK/YS + YC_DATA/YX_DATA/YK_DATA/YS_DATA 为准，名称看 *_DATA 表。

## 开发任务：多规约仿真工具（协议仿真器）

> 目标：无现场环境下联调 / 回归测试 qplantagc。**一个工具同时仿真 qplantagc 的全部对端角色。**
>
> **⚠ 前提铁律：麒麟 VM 上的 qplantagc 是被测端（DUT）**。本工具只扮演它的对端（PLC/DCS、NCS、上级主站），永远只模拟环境、不替代被测系统；一切功能设计、验收、判据都以「qplantagc 的行为表现」为中心，而不是以仿真工具自身的功能为中心。禁止为了演示方便去改 qplantagc 的逻辑来迁就仿真工具。

### 角色要求（前两项必须同时运行）

1. **Modbus TCP 服务端**（仿 PLC/DCS，即通道 4 对端）
   监听 502、从站地址 1，按 PLC 点表提供遥测（04）/遥信（02），接收并记录遥控（05 写线圈）/遥设（06 写单寄存器）。
2. **IEC 104 服务端**（仿 NCS，即通道 1 对端）
   监听 2404、ASDU 公共地址 257，处理 U 帧（STARTDT/TESTFR）与 S 帧，响应总召唤（C_IC_NA_1），周期上送遥测 M_ME_NC（短浮点）/遥信 M_SP_NA，可接收遥调 C_SE_NC / 遥控 C_SC_NA。
3. **IEC 104 客户端**（仿上级主站，即通道 0/5 对端，可选启停）
   主动连接 qplantagc 的 2404，发起总召唤，接收并记录转发的遥测/遥信；支持下发遥控/遥设以测试 qplantagc 下行链路。

### 数据可变化（核心需求）

- 每点可配驱动方式：定值 / 线性爬坡 / 正弦或随机波动 / 周期翻转（遥信）。
- 场景脚本：按时间轴编排事件（AGC 投退、故障总、通道中断等）。
- 运行时可改：配置文件热加载或 REST/控制台命令，改值立即生效，不重启进程。
- **闭环仿真**（建议）：收到 qplantagc 遥设（Modbus 06，path 51~54）后，对应"指令反馈"遥测（path 3/7/11/15 → yc 301/303/305/307）按机组调节速度爬坡逼近设定值，模拟机组响应。

### 记录与通道故障仿真

- 全量报文日志（104 ASDU / Modbus 事务，带时间戳）。
- 收到的遥控/遥设命令单独记录（来源角色、点号、原始值）。
- 可手动断开/冻结任一角色，配合故障遥信（101 转发主 / 102 采集 / 107 PLC / 108 转发备）验证 qplantagc 的通道故障判别与主备切换。

### 技术方案（已定）：基于 ems_simulate，不自研协议栈

- **选型结论**：采用 [ems_simulate](ems_simulate/)（上游 600888/ems_simulate，GPL-3.0，Python 3.11 + FastAPI + Vue3 + SQLite）。代码已克隆到本仓库 `ems_simulate/` 目录。
- **关键能力（已核实源码）**：
  - Modbus TCP 服务端：从站 ID 列表可配，功能码按测点配（02/04/05/6），客户端写入有回调日志（`src/device/protocol/modbus_handler.py`）；
  - IEC 104 服务端/客户端：ASDU 公共地址取测点 `rtu_addr`（可配 257），支持总召/时钟同步，收到的遥控遥调会更新测点并记日志，客户端支持连接即总召 + 周期总召（`src/device/protocol/iec104_handler.py`）；
  - 数据模拟驱动：不模拟/定值/随机/自增/自减/正弦/斜坡/脉冲，遥信支持随机翻转与脉冲（`src/device/simulator/point_simulator.py`）；
  - 测点映射 + 公式（跨设备跨协议，`src/data/service/point_mapping_service.py`）：**被映射锁定的测点自动退出模拟**（`is_locked_by_mapping`），正好用于「遥设写入 → 指令反馈遥测」闭环。
- **运行方式**（⚠ 现行是本机原生包 1.0.2，见文首「现行状态」；本段是 10.0.0.9 docker 版的操作细节，只作回退备查。2026-11-20 晚已回迁 10.0.0.9 docker ems-simulate；当天上午曾短暂迁本机 Docker Desktop，本机栈已停，全程见 [迁移记录-20261120.md](迁移记录-20261120.md) 含回迁章节）**：运行目录 `~/hinggan/ems_simulate/`（10.0.0.9）。**镜像 `ems-simulate:xam` = ImageID `9fca64e11495`（本地重建版含全部 4 处本地补丁，2026-11-20 从本机 `docker save|load` 搬回；旧镜像 796d077386df 缺补丁④已弃用）**。**数据库：10.0.0.9 容器 `mysql84`（0.0.0.0:3306 发布，root/syth7777，库 net，utf8mb4_0900_ai_ci）**，内容=本机 live dump 回灌（8 条映射/INT16/enable=1/iec_type_id 全带）；config.ini 走 `10.0.0.9:3306`。端口发布：`10.0.0.9:502`、`10.0.0.9:2404`（DUT 连入）、`10.0.0.9:8991`（Web/REST）。API 辅助：Windows 侧 `sim_config/xamapi.py`；或 10.0.0.9 上 `python3 /tmp/xamapi-remote.py`（重启即失，重传=改 `ems-simulate-docker/xamapi-local.py` 的 BASE 再 ssh 管道过去）。⚠ **重大新坑（9fca64e11495 镜像实测）：设备级 stop→start 重启不可靠**——API 报「启动成功」但服务端假活（PLC "Could not start listen" 分裂态、NCS 假监听导致 DUT 102 停 192 半小时不重连），**唯一可靠重启 = `docker compose restart` 整容器**；且设备/容器重启会把模拟点运行值清零，须重启后重新 write。`channels/update` 的 enable 字段不落库，禁用通道直接 SQL 改 `net.channel`（ch3 enable=0 曾导致主站设备 404）。重启恢复链：`docker compose restart` → `/api/devices/start` ×3 → **容器内 `python3 socket` 实测 502/2404**（宿主机 docker-proxy 握手通≠后端活）→ `autoread master` + `gi master` → 重写点值 → 重启 DUT。本机 Docker Desktop：ems-simulate 容器停（config.ini 已改回 `host.docker.internal`，**勿改指 10.0.0.9——双写会污染在线库**）；本机 `dumps/` 留有回迁镜像包与 dump 备查。
- **镜像构建要点（重建时必读）**：容器内 GitHub 不可达、PyPI 直连也不可达——① `wheels/` 内含宿主机预编译的 `c104-2.2.2-cp312` 与 `pydnp3_pure-0.1.0` wheel（源自 uv git 缓存 checkout，**勿删**，删了且 GitHub 断连时无法重建；2026-11-20 已从 10.0.0.9 同步进本仓库，本地重建验证通过）；② 其余依赖经清华镜像（Dockerfile `PIP_INDEX_URL`，本机 Docker Desktop 直连可用）；③ `requirements-docker.txt` 为冻结清单（c104/pydnp3-pure 除外，已同步进仓库）。改依赖后需重新生成该清单。健康检查走容器内 `/api/health`。
- **已建设备（2026-11-12）**：

| 设备 | 角色 | 监听/连接 | 点数 |
|---|---|---|---|
| PLC-仿真 (ch1) | Modbus TCP 服务端，从站1 | 0.0.0.0:502 | 16YC+32YX+20YK+4YS |
| NCS-仿真 (ch2) | IEC104 服务端，CA=257 | 0.0.0.0:2404 | 60YC+11YX |
| 主站-仿真 (ch3) | IEC104 客户端 | 连 10.0.0.194:2404（已连通；点 rtu_addr=1 见下联调节） | 2YC+2YX+1YT(25089) |

冒烟已过：Modbus func4 可读；104 STARTDT/TESTFR/总召正常回 M_ME_NC_1。备通道（ch5）客户端未单独建，需要时用 `/api/channels/copy` 复制 ch3（**2026-11-28 实测：SQLite 包里"复制设备"不可用，要手工建**）。
- **本地补丁 ①~④（4 处；2026-11-20 起已全部固化进本机重建镜像 9fca64e11495，无需再热修；另有 ⑤~⑩ 共 6 处，见文首「现行状态」）**：① `src/device/core/point/point_manager.py` add_point 改 setdefault（原 `range(256)` 预建键导致 104 公共地址 257 KeyError）；② `src/device/core/slave_manager.py` 与 ③ `src/data/service/slave_service.py` 从站上限 255→65534（104 公共地址是 16 位）；④ `src/data/service/yc_service.py` 与 `yt_service.py` 的 **IEC104 分支构造点对象时漏传 `decode`**——运行时 104 遥测/遥调点恒为默认 INT32_ABCD，**一切小数写值被整型化**（123.456→123.0），已补 `decode=item.get("decode_code") or "FLOAT32_ABCD"`（仓库源码已同步；实测教训：save/load 搬旧镜像会把这个"容器内热修"类补丁弄丢——77.7 落库成 77.0，重建镜像后才恢复；另 `net.point_yc/point_yt` 的 104 点需 `iec_type_id`：yc=M_ME_NC_1、主站 yt=C_SE_NC_1，迁移/导入后核验一次，源库已带则免）。补丁均带「本地补丁」注释。
- **点表配置**：Excel 由 `sim_config/gen_excel.py` 从 `sim_config/points.json`（`extract_points.py` 从 main.sql 生成）产出，经 `/api/channels/import-points` 导入。~~Modbus 遥测/遥设解析码暂用 FLOAT32_ABCD~~ → **联调实测：被测端按 1 path = 1 个 INT16 寄存器 × 系数读取，2026-11-13 已全量改为 INT16_AB**（NCS 104 点则须 FLOAT32_ABCD，Excel 类型列留空会默认成 INT32+Random 导致写值被整型化）。API 调试辅助脚本：`sim_config/xamapi.py`（避开 Windows 控制台中文编码坑）。
- **仍需补的缺口**（在其上二次开发或用 REST/映射组合实现）：时间轴场景脚本、通道故障注入（断开/冻结某设备 + 观察被测端 relate_yx 101/102/107/108）、按"被测端表现"自动判分的验收脚本。
- **许可注意**：GPL-3.0，二次开发仅限内部测试使用，不得闭源外发。

### 联调进展（2026-11-13 首轮，全部以被测端表现验证）

> 全过程逐步记录（含每个坑的定位与证据帧）见 [联调记录-20261113.md](联调记录-20261113.md)。2026-11-14 实时库落库冻结排查（yc512=456 不落库 → 实时库写线程冻死 → 重启解冻）+ hisdb 字符集修复（DSN `Charset=utf8mb4` + 七表及库默认转 utf8mb4，中文告警恢复落库；重建库一律用 `李浩/qplantagchisdb_mysql_utf8mb4.sql`，gbk 旧版勿用）见 [联调记录-20261114.md](联调记录-20261114.md)。2026-11-16 VM 库重置为李浩基线+仿真指向后**仿真端同步与重新联调**（基线考古：DUT 采集按总召元素序对应、转发 IOA 是 DUT 内部生成、转发总召间歇为空/STARTDT 激活间歇失败两项 DUT 缺陷）见 [联调记录-20261116.md](联调记录-20261116.md)。2026-11-17 **CHUNNEL_YC/YX 全量清扫通过**（yc 76/76、ch1 yx 11/11、ch4 yx 32/32）+ **功率反馈闭环映射**（YS1/4/6/7 跨设备映射到 YC501/601/901/1001，AGC 功率输入跟随派发指令，共 8 条映射）见 [联调记录-20261117.md](联调记录-20261117.md)。2026-11-20 **仿真器整体迁移 10.0.0.9 → 本机 Docker Desktop，当晚又回迁 10.0.0.9**（含旧镜像④补丁缺失的发现与修复、镜像 save/load 搬运、net 库 live dump 回灌；推值须知修正：DUT 只认总召响应，但**设备级 stop→start 在新镜像上服务端假活不可用，推新值 = `docker compose restart` 整容器**诱发 DUT 重连总召）见 [迁移记录-20261120.md](迁移记录-20261120.md)。⚠ 实时库写链路会静默冻死（改值后 >60s 不落库即疑）；⚠ 被测端 kill 后必须静置 ≥60s 再启动（紧跟 kill 启动会卡死 installTranslator），nohup 必须带 `< /dev/null`，详见记录与 memory kylin-qplantagc-runtime。2026-11-27 **「开始」按钮电气量波动与电气自洽层**（补丁⑨⑩、包 1.0.2 割接、机组容量按一次图；三个阶段全部实施并通过验收，DUT 库停更随重启恢复）见 [电气量波动规划-20261127.md](电气量波动规划-20261127.md)。

**链路状态（2026-11-20 晚回迁后终验全绿）**：**【2026-11-27 现状以文首「现行状态」为准：仿真器＝本机包 1.0.2，PORT_NET 指 10.0.0.7，relate_yx 101/102/107=65；下面这段是 11-20 的历史状态。】**qplantagc 已在麒麟 VM 运行（`/home/syth/QCzt2016/build/qplantagcserver`，VM 重启后需手动拉起，见 kylin skill §8；⚠ 2026-11-20 实测进程曾被以 **root** 启动，syth kill 会 EPERM，需 `sudo -S kill`）；PORT_NET 已改指 **10.0.0.9** 仿真器（回迁改前备份 `qplantagcrtdb.db.bak-20261120-backto9`；指 10.0.0.7 的旧备份 `bak-20261120-portnet` 仍在）：ch4→10.0.0.9:502、ch1 主对端→10.0.0.9:2404（ch1 备对端 196.5.1.216 留为不可达）。三条 TCP 全通（104采集/Modbus/主站→2404），relate_yx 101/102/107=65。**2026-11-20 应用户要求删除 PORT_NET ch3 行**（远方/就地源通道，备份 `qplantagcrtdb.db.bak-20261120-delch3`；回迁后维持删除，yx30=192 就地）：AGC 远方测试前恢复方法 `INSERT INTO PORT_NET VALUES(3,'0.0.0.0',0,'10.0.0.9',2404);` + 重启 DUT（见 联调记录-20261114.md §七 配方）。

**验收结果**（11-13 首轮的历史结果。**2026-11-27 起的现行基线**：PLC 上限 6/15/15/6、调节速度 3/4/4/3；映射 57 条，指令反馈＝派发值限幅在铭牌内（DUT 派发 123/300/700/400 → 回读 6/15/15/6），机组有功在此基础上带跟踪偏差（按「开始」后 6 MW 机组在 5.98~6.00 起伏）；浮点探针改用 `YC502=50.123`；本轮验收结果见规划 §8.4、§8.5）：
1. 通道连通：relate_yx **101/102/107=65（正常）**；108=0（备通道 ch5 未建对端，仿真侧复制 ch3 即可补——2026-11-28 实测 SQLite 包里复制设备不可用，ch5 要手工建）。被测端「正常」编码=65（bit0=值1 + bit6 标志位）；开关遥信合上也是 65。
2. 遥测联动：PLC 整型（YC512=200、YC513=-555）、NCS 浮点（yc222=77.7）均精确落入 qplantagcrtdb。**被测端约 40~60s 周期批量落库，update_time 列不写**（判断联调结果勿依赖 update_time）。
3. 遥设闭环六环全通：主站 YS5 C_SE_NC(25089)→被测端 ACTCON→AGC 计算（yc101=160、yc103=688.7）→Modbus 06 写 path51~54（100/300/700/400）→仿真侧 YS1→YC301 等映射回灌→被测端回读（yc301/303/305/307=100/300/700/400）→转发上行（主站-仿真 YC101=160）。映射已建 8 条：回显 4 条（PLC-仿真 内 YS1→YC301、YS4→YC303、YS6→YC305、YS7→YC307）+ **功率反馈 4 条**（NCS-仿真 名下跨设备 YS1/4/6/7→YC501/601/901/1001，2026-11-17，公式=源点名；跨设备映射实测可用，注意目标点被锁定后不可手动设值）。

**被测端（DUT）联调实测行为**（仿它、别改它）：
- qplantagc Modbus 遥测按 **INT16/path** 读（系数 1.0）；遥设 06 单寄存器写，**写出的只能是整数**：库里的分配指令值 4.5，写到寄存器 51 的是 4（2026-11-28 实测，小数被丢）。
- qplantagc ch0（转发）**上送 ASDU CA=1**（rtu_addr 257 只取高字节的味道），但对**收到的命令 CA 完全不校验**（CA 0/1/256/257 的总召与遥设都应答）。主站-仿真 5 个点的 rtu_addr 已改成 **1**（原 257 收不到上行）。
- NCS-仿真（服务端）CA=257 正常，被测端采集无碍。
- YS_DATA.YsValue 不落库（一直 0），遥设收到与否看 ACTCON 报文与 06 写。
- AGC 输出（06 写的值）**不跟随 ys5 设定值**：投入条件未满足（AGC_PARA.AGCStatusYxNum=3，yx3「AGC允许投入远方调节」=0；机组开关已合上仍不跟随）。每个 C_SE 会触发一轮 06 写（约 100s 延迟），值恒为 100/300/700/400（疑似默认/计划值）。

**仿真侧联调必做配置**（都持久化在仿真器库里，重建设备后要重做）：① 主站-仿真开 auto-read（`xamapi.py autoread master`，batch 模式）否则收不到上行值；② 主站收到值靠总召唤（`xamapi.py gi master` 或把通道 general_interrogation_interval_s 设周期）；③ C_SE 数值有 ~0.07% 系数往返误差（300→299.93，系数 0.171 双向换算所致）。

**下一步联调项（2026-11-27 更新）**：① **AGC 派发验证——本期未做**（本期只做链路回归）。重启它之前有两道前提：(a) 远方/就地信号（yx30）要有不改 DUT 配置的来源——`PORT_NET` 的 ch3 行已删、`chunnel` 未注册 ch3，现行配置下派发链第 1 道门 `IsRemoteLocalLock` 过不去；(b) DUT 参数表 `GENERATOR` 的 3#、4# 容量与一次图相反，要先由用户或厂商处理（DUT 库只许动 `PORT_NET`）。详见规划 §9.10、§9.12；派发逻辑的逆向结论见 联调记录-20261114.md §八/§九。② 建 ch5 备通道客户端验证 108 与主备互斥切换（未做）。③ 反馈映射改斜坡——未做，现行映射是"派发值限幅在铭牌内"的直通，不做爬坡。④ 故障注入（断开 PLC-仿真 看 107 变 0，未做）。⑤ 可选的小修：包里 `config.ini` 的 BOM 问题（规划 §9.14）——已随 1.0.4 了结。

**11-14 时的记录（备查）**：AGC 投入路径已打通到最后一环（通道3模拟上线=远方/就地源 ✓、HMI 投入序列 ✓、yx30=远方稳态 ✓、范围内 ys5=100 → yc101 跟随=99.864 ✓；卡点：06 写派发仍恒 100/300/700/400，目标→派发最后一道门未破）。

### 验收标准（全部以被测端 qplantagc 的表现判分，不以仿真工具自身判分）

1. 麒麟 VM 上的 qplantagc 改指本工具后，四条通道全部连通（relate_yx 101/102/107/108 均为通信正常）。
2. 修改任一仿真遥测值，qplantagc 实时库对应 yc 记录随之变化。
3. 从 104 客户端角色下发遥设 → qplantagc 计算转发 → Modbus 服务端收到对应 06 写寄存器 → 指令反馈遥测爬坡回传（全链路闭环）。
