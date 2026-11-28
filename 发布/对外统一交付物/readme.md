# 对外统一交付物（Windows 原生版仿真器）

> 目标：把 ems_simulate（含 4 处本地补丁、SQLite 版）以**解压即用**的形态交付到同事的 Windows 机器，替代 10.0.0.9 的 Docker 部署。对应规划：`发布/兴安盟仿真器 Windows 原生部署规划（SQLite 版）.md`。

## 目录说明

| 条目 | 入库 | 说明 |
|---|---|---|
| `部署说明.md` | ✓ | 目标机 5 步部署 + 已知事项（杀软/大小写/假活等） |
| `割接与回滚手册.md` | ✓ | DUT 切换与回滚完整操作序列 |
| `scripts/` | ✓ | start / start-master / stop / set-site / write-baseline / allow-ports（PowerShell） |
| `assets/ems.dump.sql` | ✓ | 迁移基线库的文本 dump（24 表对账过的快照，make-package 由此重建 ems.db） |
| `make-package.ps1` | ✓ | 一键组装 `ems-sim-win-<版本>/` 与 zip |
| `ems-sim-win-*/`、`*.zip` | ✗ gitignore | 组装产物（约 130MB），走拷贝分发（GitHub 单文件 100MB 上限） |

## 重组交付包（在构建机 Leo 本机）

前置：`ems_simulate/dist` 已有 onedir 产物（没有则先跑 `ems_simulate/scripts/rebuild_onedir.ps1`）。

```powershell
cd C:\work\Hinggan_League\发布\对外统一交付物
.\make-package.ps1 [-Version 1.0.0]
```

产物：`ems-sim-win-1.0.0/`（可直接运行的目录）与 `ems-sim-win-1.0.0.zip`（对外拷贝分发）。

## 注意

- zip 与组装目录已 gitignore；`assets/ems.dump.sql` 是唯一入库的数据基线，改动后重跑 make-package 即可。
- 构建机上联想杀软（火绒引擎）按 exe 位置拦未签名程序写文件——**在本机构建的包目录里直接试跑会被拦**，冒烟请在目标机或杀软加白后进行（见《部署说明.md》已知事项）。
