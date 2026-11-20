# 兴安盟 AGC 子站联调仿真器 — Docker Desktop 部署包

> 无现场环境下联调 / 回归测试 qplantagc（AGC 子站）的多规约仿真工具部署物料与源码。
> 本包只扮演 qplantagc 的对端（PLC/DCS、NCS、上级主站），qplantagc 是被测端（DUT），
> 一切验收以被测端的行为表现为准。
> 基于 [ems_simulate](https://github.com/600888/ems_simulate)（GPL-3.0）二次开发，内部测试使用，不得闭源外发。

## 包内容清单

| 条目 | 说明 |
|---|---|
| `ems-simulate-xam-image.tar` | 镜像 `ems-simulate:xam` 的导出包（OCI 格式，109MB，解压视图 525MB，ImageID `9fca64e11495`），含全部 4 处本地补丁 |
| `ems-simulate-docker/` | 运行目录：`docker-compose.yml` + `config.ini`（LF 行尾）+ `xamapi-local.py`（本机 API 辅助脚本）+ `dumps/`（net 库备份）+ `data/`（运行时落盘兜底目录） |
| `ems_simulate-src/` | 完整源码树（84MB），含 `wheels/`（离线构建关键物料）、`Dockerfile`、`requirements-docker.txt`（冻结依赖清单），可用于重建镜像或二次开发 |

数据库快照（`net.sql` 为权威快照，另在 `ems-simulate-docker/dumps/` 留有历史版本）：
- `net.sql`（包根目录）— 发布时点全量快照（含 `CREATE DATABASE net`），恢复部署用这一份
- `ems-simulate-docker/dumps/net_dump-20261120-release.sql` — 与 `net.sql` 同源
- `ems-simulate-docker/dumps/net_dump-final-20261120.sql` — 迁移完成时的快照
- `ems-simulate-docker/dumps/build.log` — 本机镜像构建日志（重建时可对照）

## 架构与角色

| 容器 | 作用 | 端口 |
|---|---|---|
| `ems-simulate`（镜像 `ems-simulate:xam`） | 协议仿真器后端（Python 3.12 + FastAPI），扮演 qplantagc 的三个对端 | `10.0.0.7:502`（Modbus）、`10.0.0.7:2404`（IEC104，DUT 连入）、`127.0.0.1:8991`（REST/Web，仅本机） |
| `mysql84`（**10.0.0.9 上的容器**，官方 `mysql:8.4`） | 仿真器数据库（库名 `net`），跑在远端主机 myubuntu | `10.0.0.9:3306`，root/syth7777，root 允许远程（root@'%') |

已建设的三台仿真设备（配置持久化在 `net` 库中，随 dump 恢复）：

| 设备 | 角色 | 点数 |
|---|---|---|
| PLC-仿真 | Modbus TCP 服务端，从站 1，监听 0.0.0.0:502 | 16YC+32YX+20YK+4YS |
| NCS-仿真 | IEC104 服务端，ASDU 公共地址 257，监听 0.0.0.0:2404 | 60YC+11YX |
| 主站-仿真 | IEC104 客户端，主动连 DUT 的 2404（点 rtu_addr=1） | 2YC+2YX+1YT(25089) |

## 前置条件

- Windows 本机装有 Docker Desktop（跑 `ems-simulate` 容器，容器自启即随其恢复）；**本机不需要装 MySQL**。
- 数据库在远端：10.0.0.9（myubuntu，Ubuntu 22.04）上的 `mysql84` 容器（官方 `mysql:8.4`，3306 绑 0.0.0.0 发布）。`config.ini` 里 `host = 10.0.0.9` 直接走容器→宿主机网卡 IP 的路由（前提正是 3306 在 10.0.0.9 上监听）。
- 本机需有 `10.0.0.7` IP（与麒麟 DUT 及 10.0.0.9 同网段；DUT 侧 PORT_NET 已改指 10.0.0.7:502 / 10.0.0.7:2404）。
- Windows 防火墙 2 条入站规则：放行 502 / 2404，远程地址限 10.0.0.0/24。

## 部署步骤

```bash
# 1. 在 10.0.0.9 (myubuntu) 上确保 mysql84 运行（ssh 到远端执行；已存在则 docker start 即可）
docker start mysql84
# 无 mysql84 时才需要新建（绑 0.0.0.0:3306，密码见架构表）：
# docker run -d --name mysql84 --restart unless-stopped -p 3306:3306 -e MYSQL_ROOT_PASSWORD=syth7777 mysql:8.4
```

```powershell
# 2. 导入仿真器镜像（本机 Docker Desktop）
docker load -i ems-simulate-xam-image.tar
```

```powershell
# 3. 恢复 net 库到 10.0.0.9 的 mysql84（dump 自带 CREATE DATABASE；在包根目录执行）
Get-Content net.sql -Raw | ssh syth@10.0.0.9 "docker exec -i mysql84 mysql -uroot -psyth7777 --default-character-set=utf8mb4"
```

```powershell
# 4. 启动仿真器（必须在 ems-simulate-docker 目录内执行，相对挂载才有效）
cd ems-simulate-docker
docker compose up -d
```

```powershell
# 5. 重启恢复链（容器自启后设备不会自动拉起，手动三连）
python xamapi-local.py start        # /api/devices/start ×3（PLC-仿真 / NCS-仿真 / 主站-仿真）
python xamapi-local.py autoread master   # 主站-仿真开 auto-read（batch 模式），否则收不到上行值
python xamapi-local.py gi master         # 主站发起总召唤，收到转发值
```

## 验证

```powershell
# 容器健康（Docker Desktop 冒烟怪癖：宿主机自连 10.0.0.7:502/2404 会超时，属端口代理怪癖，冒烟走容器内或 DUT 侧）
docker ps                              # ems-simulate 应为 Up (healthy)
docker exec ems-simulate python -c "import urllib.request;print(urllib.request.urlopen('http://127.0.0.1:8991/api/health',timeout=5).read().decode())"
# 容器里没有 curl；health 返回 database":"mysql" 即已连上 10.0.0.9 的库
```

- Web/REST：浏览器开 `http://127.0.0.1:8991`。
- API 辅助：`python xamapi-local.py vals master YC101` 之类读值；全部子命令见脚本 usage。**点码是大写格式**（库 `net.point_yc.code` 存 `YC512`），传小写 `yc512` 会返回空。
- **连本容器主机一律写 `127.0.0.1`，勿写 `localhost`**（::1 被 Docker 端口代理黑洞，连接卡约 10 秒）。
- **API 中文请求体必须走 Python UTF-8**（用 `xamapi-local.py`，curl -d 中文会被 Windows 控制台编码弄坏）。
- DUT 侧核验：麒麟 VM 的 qplantagc relate_yx 应为 101/102/107=65（通信正常）。

## 注意事项（联调实测坑）

1. `channels/update` 接口的 enable 字段不落库；禁用通道直接 SQL 改 `net.channel` 表。
2. 实时库写链路（DUT 侧）会静默冻死：改值后 >60s 不落库即疑，重启 DUT 解冻；DUT 落库约 40~60s 周期批量，勿依赖 update_time 列。
3. DUT（麒麟 VM）kill 后必须静置 ≥60s 再启动；nohup 拉起必须带 `< /dev/null`。
4. DUT 采集推值须知：只认总召响应；给 DUT 推新值 = NCS 设备 stop → start 两步式重启，诱发 DUT 重连总召。
5. C_SE 数值存在约 0.07% 系数往返误差（系数 0.171 双向换算所致，如 300→299.93），属正常。
6. `net.point_yc/point_yt` 的 104 点需带 `iec_type_id`（yc=M_ME_NC_1、主站 yt=C_SE_NC_1）；迁移/导入后核验一次（本包 dump 已带）。
7. 镜像标签 `ems-simulate:xam` 若被旧版占用，`docker load` 会跳过重名——先 `docker rmi` 清掉或改 tag 后再 load。
8. 数据库指向原理：`config.ini` 的 `host` 必须写「宿主机上确实监听着的地址」。10.0.0.9 的 mysql84 绑 0.0.0.0 → 写 `10.0.0.9`；若哪天改回本机 Docker Desktop 的 mysql（绑 127.0.0.1 发布）→ 必须写 `host.docker.internal`，而本机网卡 IP `10.0.0.7` 反而不通（127.0.0.1 上才有监听）。容器内永远不能写 `127.0.0.1`（那是容器自己）。

## 镜像重建（源码改过之后）

构建上下文只依赖源码树根的 `Dockerfile`、`wheels/`、`requirements-docker.txt` 与源码本体：

- **`wheels/` 内两个 wheel 勿删**（`c104-2.2.2-cp312` 与 `pydnp3_pure-0.1.0`，源自 git 依赖的预编译产物；容器内 GitHub 与 PyPI 直连均不可达，删了且断网时无法重建）。
- 其余依赖走清华 PyPI 镜像（Dockerfile 内 `PIP_INDEX_URL`）。
- 改依赖后需重新生成 `requirements-docker.txt` 冻结清单。

```powershell
cd ems_simulate-src
docker build -t ems-simulate:xam .
docker compose -f ..\ems-simulate-docker\docker-compose.yml up -d
```

## 本地补丁（4 处，均已固化进本镜像；源码内带「本地补丁」注释）

| # | 位置 | 内容 |
|---|---|---|
| ① | `src/device/core/point/point_manager.py` | add_point 改 setdefault（原 `range(256)` 预建键导致 104 公共地址 257 KeyError） |
| ② | `src/device/core/slave_manager.py` | 从站上限 255→65534（104 公共地址是 16 位） |
| ③ | `src/data/service/slave_service.py` | 同上上限修正 |
| ④ | `src/data/service/yc_service.py` 与 `yt_service.py` | IEC104 分支构造点对象时漏传 `decode`，104 遥测/遥调点恒为默认 INT32_ABCD，小数写值被整型化（123.456→123.0）；已补 `decode=item.get("decode_code") or "FLOAT32_ABCD"` |

> 实测教训：save/load 搬旧镜像会把容器内热修类补丁弄丢（77.7 落库成 77.0），补丁必须固化进镜像重建，不能只热修容器。

## 与 DUT 的对接（麒麟 VM 侧）

### DUT 实时库（qplantagcrtdb.db）需要的修改

DUT 实时库是 SQLite（`qplantagcrtdb.db`），网络参数在 **PORT_NET** 表（列：`chunnel_num, local_address, local_port, remote_address, remote_port`）。铁律：**程序停止后改库、改前备份、改完重启 DUT 生效**。2026-11-20 迁移时已按此做过（备份 `qplantagcrtdb.db.bak-20261120-portnet`），全新环境或换回现场地址时用同样的两条 UPDATE：

```sql
-- 备份：cp qplantagcrtdb.db qplantagcrtdb.db.bak-<日期>

-- ① ch4 PLC 通道 → 仿真器 Modbus（原现场地址 192.192.192.31:502）
UPDATE PORT_NET SET remote_address='10.0.0.7', remote_port=502 WHERE chunnel_num=4;

-- ② ch1 NCS采集主对端 → 仿真器 IEC104 服务端（原 10.0.0.88:2404；备对端 196.5.1.216 故意留为不可达）
UPDATE PORT_NET SET remote_address='10.0.0.7' WHERE chunnel_num=1 AND remote_address='10.0.0.88';
```

- ch0/ch5（转发服务端，监听 2404）由主站-仿真主动连入，**DUT 侧无需修改**。
- **ch3（远方/就地源通道）**：2026-11-20 应要求已删除其 PORT_NET 行（备份 `qplantagcrtdb.db.bak-20261120-delch3`），删后 yx30 由 65（远方）→192（就地），**AGC 远方调节断源**。需要 AGC 远方路径时重建并重启 DUT：`INSERT INTO PORT_NET VALUES(3,'0.0.0.0',0,'10.0.0.7',2404);`，并按联调记录-20261114.md §七 补齐 chunnel 注册行与 CHUNNEL_YX IOA 映射（仿真器侧需有 YX50 点、模拟方式=不模拟）。

### DUT 重启规程（每次改库/重启后）

- kill 后**必须静置 ≥60s** 再启动（紧跟 kill 启动会卡死 installTranslator）；进程可能曾被以 root 启动，syth 用户 kill 会 EPERM，需 `sudo -S kill`。
- 启动用 nohup 必须带 `< /dev/null`：`nohup /home/syth/QCzt2016/build/qplantagcserver < /dev/null &`。
- 重启后 HMI 登录态丢失（账号 fzy/777777）；AGC 投入序列见联调记录-20261114.md（关键扳机：总控参数「MEGC 允许调节」退出→投入翻一遍）。
- 核验：DUT relate_yx 101/102/107=65（通信正常）；「改仿真遥测值 → ≤60s 落库」是链路体检口诀。
- 备通道（ch5）如需验证 relate_yx 108 与主备切换，用 `/api/channels/copy` 复制主站-仿真即可补齐。

## 许可

ems_simulate 上游为 GPL-3.0；本包仅限内部测试使用，不得闭源外发。
