# 兴安盟 AGC AVC 子站（qplantagc）工程说明

## 项目概况

- 本仓库整理兴安盟电厂 AVC 子站（qplantagc）的通道配置与点表。
- 权威数据源：`main.sql`（qplantagcrtdb 实时库 SQLite 的 Navicat 导出）。
- 整理文档：`PLC通道点表整理.md`（全部通道总览 + PLC 点表详表 + 疑点清单）。
- 部署环境：银河麒麟 V10 SP1 虚拟机（部署方法见 kylin-qplantagc-deploy skill）。
- 仿真工具：`ems_simulate/`（选型已定，见下文开发任务一节）。

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
- **运行方式**：Windows 本机运行（qplantagc 在麒麟 VM 上走 TCP 直连它）：`uv sync --extra dev && uv run python start_back_end.py` 起后端；`cd front && npm install && npm run dev` 起前端（Vue Web UI 管设备/测点/模拟）。
- **点表配置**：用其 Excel 导入功能（模板见 `ems_simulate/data/point_csv/point_sample_modbus.xlsx`、`point_sample_iec104.xlsx`），点表内容从 `main.sql` 的 CHUNNEL_* + *_DATA 表生成。
- **仍需补的缺口**（在其上二次开发或用 REST/映射组合实现）：时间轴场景脚本、通道故障注入（断开/冻结某设备 + 观察被测端 relate_yx 101/102/107/108）、按"被测端表现"自动判分的验收脚本。
- **许可注意**：GPL-3.0，二次开发仅限内部测试使用，不得闭源外发。

### 验收标准（全部以被测端 qplantagc 的表现判分，不以仿真工具自身判分）

1. 麒麟 VM 上的 qplantagc 改指本工具后，四条通道全部连通（relate_yx 101/102/107/108 均为通信正常）。
2. 修改任一仿真遥测值，qplantagc 实时库对应 yc 记录随之变化。
3. 从 104 客户端角色下发遥设 → qplantagc 计算转发 → Modbus 服务端收到对应 06 写寄存器 → 指令反馈遥测爬坡回传（全链路闭环）。
