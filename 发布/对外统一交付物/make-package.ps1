# 一键组装对外交付包：ems-sim-win-<版本>/ + 同名 zip
# 前置：ems_simulate/dist 已有 onedir 产物（没有先跑 ems_simulate\scripts\rebuild_onedir.ps1）
param([string]$Version = '1.0.0')
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$repo = Split-Path (Split-Path $here -Parent) -Parent   # ...\Hinggan_League
$dist = Join-Path $repo 'ems_simulate\dist\ems_simulate_backend'
$src  = Join-Path $repo 'ems_simulate'
$out  = Join-Path $here "ems-sim-win-$Version"
$zip  = Join-Path $here "ems-sim-win-$Version.zip"
$sqlite = Join-Path $here 'tools\sqlite3.exe'

if (-not (Test-Path (Join-Path $dist 'ems_simulate_backend.exe'))) { throw "未找到 onedir 产物：$dist" }
if (-not (Test-Path $sqlite)) { throw "未找到 $sqlite" }

if (Test-Path $out)  { Remove-Item $out  -Recurse -Force }
if (Test-Path $zip)  { Remove-Item $zip  -Force }
New-Item -ItemType Directory $out | Out-Null

# 1) onedir 运行体（剔除 dist 里残留的运行态目录与旁置 config）
robocopy $dist $out /E /NFL /NDL /NJH /NJS /NP `
    /XD data log config plan upload /XF config.ini | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy dist 失败 ($LASTEXITCODE)" }
Write-Host '[1/6] onedir 运行体已拷入'

# 2) config.ini（sqlite 模板）
@"
[database]
type = sqlite
sqlite_path = data/ems.db

[mysql]
host = 127.0.0.1
port = 3306
username = -
password = -
database = net

[data_source]
type = db

[server]
host = 127.0.0.1
port = 8991
"@ | Set-Content (Join-Path $out 'config.ini') -Encoding UTF8
Write-Host '[2/6] config.ini 已生成（type=sqlite）'

# 3) 基线库：由文本 dump 重建
New-Item -ItemType Directory -Force (Join-Path $out 'data') | Out-Null
$db = Join-Path $out 'data\ems.db'
if (Test-Path $db) { Remove-Item $db -Force }
& $sqlite $db ".read $(Join-Path $here 'assets\ems.dump.sql')"
Write-Host '[3/6] data\ems.db 已由基线 dump 重建'

# 4) 源码（GPL 合规，含 4 处本地补丁与构建脚本）
robocopy $src (Join-Path $out 'source') /E /NFL /NDL /NJH /NJS /NP `
    /XD .venv .venv-win dist build .git .pytest_cache .ruff_cache __pycache__ node_modules | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy source 失败 ($LASTEXITCODE)" }
Write-Host '[4/6] source\ 已拷入（GPL 全源码）'

# 5) tools + scripts + 文档
New-Item -ItemType Directory (Join-Path $out 'tools') | Out-Null
Copy-Item (Join-Path $repo 'sim_config\ems_local.py') (Join-Path $out 'tools\')
Copy-Item $sqlite (Join-Path $out 'tools\')
robocopy (Join-Path $here 'scripts') (Join-Path $out 'scripts') /E /NFL /NDL /NJH /NJS /NP | Out-Null
Copy-Item (Join-Path $here '部署说明.md') $out
Copy-Item (Join-Path $here '割接与回滚手册.md') $out
Write-Host '[5/6] tools / scripts / 文档已拷入'

# 6) 压缩（Compress-Archive 会被运行中仿真器持有的文件锁卡住，走 python 共享读打包）
python -c "import shutil,sys; shutil.make_archive(sys.argv[1], 'zip', root_dir=sys.argv[1])" $out
$sz = '{0:N1} MB' -f ((Get-Item $zip).Length / 1MB)
Write-Host "[6/6] zip 已生成：$zip（$sz）"
Write-Host ''
Write-Host '组装完成。目标机部署见《部署说明.md》；本机构建机上杀软会拦新位置 exe 试跑，冒烟请在目标机做'
