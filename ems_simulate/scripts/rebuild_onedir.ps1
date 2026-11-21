# 一键重打包：方案 B onedir（绕过 build_windows.ps1 的 c104==2.2.2 硬门槛，直接调 PyInstaller）
# 用法：在 ems_simulate/ 下执行  powershell -File scripts\rebuild_onedir.ps1
# 产物：dist\ems_simulate_backend\（exe + _internal；config.ini 需自行放 exe 旁）
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$py = Join-Path $root ".venv-win\Scripts\python.exe"
if (-not (Test-Path $py)) { throw "未找到 .venv-win（$py）——先按规划文档 P1 准备构建环境" }
$pyi = Join-Path $root ".venv-win\Scripts\pyinstaller.exe"
if (-not (Test-Path $pyi)) {
    & $py -m pip install pyinstaller==6.18.0 altgraph==0.17.5 Pillow -i https://pypi.tuna.tsinghua.edu.cn/simple -q
}

$env:EMS_PYINSTALLER_MODE = "onedir"
$env:EMS_PYINSTALLER_CONSOLE = "1"   # 保留控制台便于看日志；交付版可改 0
& $pyi ems_simulate_backend.spec --noconfirm --distpath dist --workpath build
if ($LASTEXITCODE -ne 0) { throw "PyInstaller 构建失败 (exit $LASTEXITCODE)" }

Write-Host ""
Write-Host "构建完成: $root\dist\ems_simulate_backend\"
Write-Host "部署提醒: config.ini 与 data\ems.db 需放在 exe 同级目录（onedir 不打包二者）"
