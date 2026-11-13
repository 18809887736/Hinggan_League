# 兴安盟 AGC AVC 子站（qplantagc）工程说明

## 项目概况

- 本仓库整理兴安盟电厂 AVC 子站（qplantagc）的通道配置与点表。
- 权威数据源：`main.sql`（qplantagcrtdb 实时库 SQLite 的 Navicat 导出）。
- 整理文档：`PLC通道点表整理.md`（全部通道总览 + PLC 点表详表 + 疑点清单）。
- 部署环境：银河麒麟 V10 SP1 虚拟机（部署方法见 kylin-qplantagc-deploy skill）。
- 仿真工具：`ems_simulate/`（选型已定，见下文开发任务一节）。
- **10.0.0.9 (myubuntu) 操作准则：任何服务部署一律首选 docker compose，宿主机零污染**——数据 bind mount 持久化、端口绑 `10.0.0.9` 发布；不在宿主机装工具链/venv/ufw 规则（Docker 发布端口走 iptables 绕过 ufw）。原生依赖预编译成 wheel 放构建上下文，PyPI 走清华镜像。参考实现：`ems_simulate/Dockerfile` + `docker-compose.yml`。
- **文本编辑规则：编辑任何含 AVC 字样的文本前，先删除全部"供热"字样**——本项目资料常从热电联产电厂模板拷贝，"供热机组/供热工况"等不适用于兴安盟电厂；新建文本同样不得引入。

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
- **运行方式（2026-11-13 起为 Docker Compose，宿主机零污染）**：部署在 **10.0.0.9 (myubuntu)** 的 `~/hinggan/ems_simulate`（镜像 `ems-simulate:xam`，495MB）。启动/重启：`cd ~/hinggan/ems_simulate && docker compose up -d`（重建：`docker compose build && docker compose up -d`）；日志：`docker logs ems-simulate`；REST/Web UI：`http://10.0.0.9:8991`。端口经 compose 绑定到 `10.0.0.9`（8991/502/2404），容器内 root 直接绑 502，无需宿主机 setcap。宿主机原有部署残留（uv/venv/setcap/apt 编译工具/ufw 放行）已全部清除，仅剩 docker 与项目目录。
- **镜像构建要点（重建时必读）**：容器内 GitHub 不可达、PyPI 直连也不可达——① `wheels/` 内含宿主机预编译的 `c104-2.2.2-cp312` 与 `pydnp3_pure-0.1.0` wheel（源自 uv git 缓存 checkout，**勿删**，删了且 GitHub 断连时无法重建）；② 其余依赖经清华镜像（Dockerfile `PIP_INDEX_URL`）；③ `requirements-docker.txt` 为冻结清单（c104/pydnp3-pure 除外）。改依赖后需重新生成该清单。健康检查走容器内 `/api/health`。
- **已建设备（2026-11-12）**：

| 设备 | 角色 | 监听/连接 | 点数 |
|---|---|---|---|
| PLC-仿真 (ch1) | Modbus TCP 服务端，从站1 | 0.0.0.0:502 | 16YC+32YX+20YK+4YS |
| NCS-仿真 (ch2) | IEC104 服务端，CA=257 | 0.0.0.0:2404 | 60YC+11YX |
| 主站-仿真 (ch3) | IEC104 客户端 | 连 10.0.0.194:2404（已连通；点 rtu_addr=1 见下联调节） | 2YC+2YX+1YT(25089) |

冒烟已过：Modbus func4 可读；104 STARTDT/TESTFR/总召正常回 M_ME_NC_1。备通道（ch5）客户端未单独建，需要时用 `/api/channels/copy` 复制 ch3。
- **本地补丁（3 处，重装/升级 ems_simulate 时需重打）**：① `src/device/core/point/point_manager.py` add_point 改 setdefault（原 `range(256)` 预建键导致 104 公共地址 257 KeyError）；② `src/device/core/slave_manager.py` 与 ③ `src/data/service/slave_service.py` 从站上限 255→65534（104 公共地址是 16 位）。补丁均带「本地补丁」注释。
- **点表配置**：Excel 由 `sim_config/gen_excel.py` 从 `sim_config/points.json`（`extract_points.py` 从 main.sql 生成）产出，经 `/api/channels/import-points` 导入。~~Modbus 遥测/遥设解析码暂用 FLOAT32_ABCD~~ → **联调实测：被测端按 1 path = 1 个 INT16 寄存器 × 系数读取，2026-11-13 已全量改为 INT16_AB**（NCS 104 点则须 FLOAT32_ABCD，Excel 类型列留空会默认成 INT32+Random 导致写值被整型化）。API 调试辅助脚本：`sim_config/xamapi.py`（避开 Windows 控制台中文编码坑）。
- **仍需补的缺口**（在其上二次开发或用 REST/映射组合实现）：时间轴场景脚本、通道故障注入（断开/冻结某设备 + 观察被测端 relate_yx 101/102/107/108）、按"被测端表现"自动判分的验收脚本。
- **许可注意**：GPL-3.0，二次开发仅限内部测试使用，不得闭源外发。

### 联调进展（2026-11-13 首轮，全部以被测端表现验证）

> 全过程逐步记录（含每个坑的定位与证据帧）见 [联调记录-20261113.md](联调记录-20261113.md)。

**链路状态**：qplantagc 已在麒麟 VM 运行（`/home/syth/QCzt2016/build/qplantagcserver`，VM 重启后需手动拉起，见 kylin skill §8）；PORT_NET 已改指仿真器（改前备份 `qplantagcrtdb.db.bak-20261113`）：ch4→10.0.0.9:502、ch1 主对端→10.0.0.9:2404（ch1 备对端 196.5.1.216 留为不可达）。三条 TCP 全通（104采集/Modbus/主站→2404）。

**验收结果**：
1. 通道连通：relate_yx **101/102/107=65（正常）**；108=0（备通道 ch5 未建对端，仿真侧复制 ch3 即可补）。被测端「正常」编码=65（bit0=值1 + bit6 标志位）；开关遥信合上也是 65。
2. 遥测联动：PLC 整型（YC512=200、YC513=-555）、NCS 浮点（yc222=77.7）均精确落入 qplantagcrtdb。**被测端约 40~60s 周期批量落库，update_time 列不写**（判断联调结果勿依赖 update_time）。
3. 遥设闭环六环全通：主站 YS5 C_SE_NC(25089)→被测端 ACTCON→AGC 计算（yc101=160、yc103=688.7）→Modbus 06 写 path51~54（100/300/700/400）→仿真侧 YS1→YC301 等映射回灌→被测端回读（yc301/303/305/307=100/300/700/400）→转发上行（主站-仿真 YC101=160）。映射已建 4 条（PLC-仿真 内 YS1→YC301、YS4→YC303、YS6→YC305、YS7→YC307，公式=源点名）。

**被测端（DUT）联调实测行为**（仿它、别改它）：
- qplantagc Modbus 遥测按 **INT16/path** 读（系数 1.0）；遥设 06 单寄存器写。
- qplantagc ch0（转发）**上送 ASDU CA=1**（rtu_addr 257 只取高字节的味道），但对**收到的命令 CA 完全不校验**（CA 0/1/256/257 的总召与遥设都应答）。主站-仿真 5 个点的 rtu_addr 已改成 **1**（原 257 收不到上行）。
- NCS-仿真（服务端）CA=257 正常，被测端采集无碍。
- YS_DATA.YsValue 不落库（一直 0），遥设收到与否看 ACTCON 报文与 06 写。
- AGC 输出（06 写的值）**不跟随 ys5 设定值**：投入条件未满足（AGC_PARA.AGCStatusYxNum=3，yx3「AGC允许投入远方调节」=0；机组开关已合上仍不跟随）。每个 C_SE 会触发一轮 06 写（约 100s 延迟），值恒为 100/300/700/400（疑似默认/计划值）。

**仿真侧联调必做配置**（都持久化在仿真器库里，重建设备后要重做）：① 主站-仿真开 auto-read（`xamapi.py autoread master`，batch 模式）否则收不到上行值；② 主站收到值靠总召唤（`xamapi.py gi master` 或把通道 general_interrogation_interval_s 设周期）；③ C_SE 数值有 ~0.07% 系数往返误差（300→299.93，系数 0.171 双向换算所致）。

**下一步联调项**：① AGC 投入路径（yx3 怎么变 1：HMI？遥控？查 GENERATOR_AGC_LOCK* 表）→ 验证 06 写值跟随 ys5；② 建 ch5 备通道客户端验证 108 与主备互斥切换；③ 反馈映射改斜坡（机组调节速度爬坡）替代直通；④ 故障注入（断开 PLC-仿真 看 107 变 0）。

### 验收标准（全部以被测端 qplantagc 的表现判分，不以仿真工具自身判分）

1. 麒麟 VM 上的 qplantagc 改指本工具后，四条通道全部连通（relate_yx 101/102/107/108 均为通信正常）。
2. 修改任一仿真遥测值，qplantagc 实时库对应 yc 记录随之变化。
3. 从 104 客户端角色下发遥设 → qplantagc 计算转发 → Modbus 服务端收到对应 06 写寄存器 → 指令反馈遥测爬坡回传（全链路闭环）。
