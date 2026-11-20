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

数据库快照（在 `ems-simulate-docker/dumps/`）：
- `net_dump-20261120-release.sql` — 发布时点全量快照（含 `CREATE DATABASE net`）
- `net_dump-final-20261120.sql` — 迁移完成时的快照
- `build.log` — 本机镜像构建日志（重建时可对照）

## 架构与角色

| 容器 | 作用 | 端口 |
|---|---|---|
| `ems-simulate`（镜像 `ems-simulate:xam`） | 协议仿真器后端（Python 3.12 + FastAPI），扮演 qplantagc 的三个对端 | `10.0.0.7:502`（Modbus）、`10.0.0.7:2404`（IEC104，DUT 连入）、`127.0.0.1:8991`（REST/Web，仅本机） |
| `mysql84`（官方 `mysql:8.4.11`） | 仿真器数据库（库名 `net`） | `127.0.0.1:3306`，root/syth7777 |

已建设的三台仿真设备（配置持久化在 `net` 库中，随 dump 恢复）：

| 设备 | 角色 | 点数 |
|---|---|---|
| PLC-仿真 | Modbus TCP 服务端，从站 1，监听 0.0.0.0:502 | 16YC+32YX+20YK+4YS |
| NCS-仿真 | IEC104 服务端，ASDU 公共地址 257，监听 0.0.0.0:2404 | 60YC+11YX |
| 主站-仿真 | IEC104 客户端，主动连 DUT 的 2404（点 rtu_addr=1） | 2YC+2YX+1YT(25089) |

## 前置条件

- Windows 本机装有 Docker Desktop（容器自启即随其恢复）。
- 官方镜像 `mysql:8.4.11`（`docker pull mysql:8.4.11`，需外网；内网环境请提前导入）。
- 本机需有 `10.0.0.7` IP（与麒麟 DUT 同网段；DUT 侧 PORT_NET 已改指 10.0.0.7:502 / 10.0.0.7:2404）。
- Windows 防火墙 2 条入站规则：放行 502 / 2404，远程地址限 10.0.0.0/24。

## 部署步骤

```powershell
# 1. 启动 MySQL 容器（本机无 mysql84 时；名字/密码/端口见上表）
docker run -d --name mysql84 --restart unless-stopped -p 127.0.0.1:3306:3306 -e MYSQL_ROOT_PASSWORD=syth7777 mysql:8.4.11
```

```powershell
# 2. 导入仿真器镜像
docker load -i ems-simulate-xam-image.tar
```

```powershell
# 3. 恢复 net 库（dump 自带 CREATE DATABASE；容器需先跑起来）
Get-Content ems-simulate-docker\dumps\net_dump-20261120-release.sql -Raw | docker exec -i mysql84 mysql -uroot -psyth7777 --default-character-set=utf8mb4
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
docker exec ems-simulate curl -s http://127.0.0.1:8991/api/health
```

- Web/REST：浏览器开 `http://127.0.0.1:8991`。
- API 辅助：`python xamapi-local.py vals master yc101` 之类读值；全部子命令见脚本 usage。
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

## 与 DUT 的对接（麒麟 VM 侧，非本包内容）

- DUT 程序：`/home/syth/QCzt2016/build/qplantagcserver`（VM 重启后手动拉起）。
- PORT_NET 已改指本机：ch4→10.0.0.7:502、ch1 主对端→10.0.0.7:2404（改前备份 `qplantagcrtdb.db.bak-20261120-portnet`）。
- 备通道（ch5）如需验证 relate_yx 108 与主备切换，用 `/api/channels/copy` 复制主站-仿真即可补齐。

## 许可

ems_simulate 上游为 GPL-3.0；本包仅限内部测试使用，不得闭源外发。
