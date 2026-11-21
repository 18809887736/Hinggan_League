# 站点参数设置：仿真器主站对端指向 DUT；并打印 DUT 侧 PORT_NET 需要的修改 SQL
param([string]$DutIp = '10.0.0.194', [int]$DutPort = 2404)
$pkg = Split-Path $PSScriptRoot -Parent
$sqlite = Join-Path $pkg 'tools\sqlite3.exe'
$db = Join-Path $pkg 'data\ems.db'
if (-not (Test-Path $sqlite)) { throw "缺少 $sqlite（set-site 依赖包内 sqlite3.exe）" }

& $sqlite $db "UPDATE channel SET ip='$DutIp', port=$DutPort WHERE id=3;"
Write-Host "[已改] 主站-仿真 对端 -> ${DutIp}:${DutPort}"
& $sqlite $db "SELECT id, code, ip, port FROM channel;"

# 猜本机在 10.0.0.0/24 的地址，供 DUT 侧 PORT_NET 用
$myIp = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -like '10.0.0.*' } | Select-Object -First 1).IPAddress
if (-not $myIp) { $myIp = '<目标机IP>' }

Write-Host ''
Write-Host '=== DUT 侧需要执行的修改（麒麟 VM，先备份实时库）==='
Write-Host "cp /home/syth/QCzt2016/database/qplantagcrtdb.db /home/syth/QCzt2016/database/qplantagcrtdb.db.bak-cut"
Write-Host "sqlite3 /home/syth/QCzt2016/database/qplantagcrtdb.db `"UPDATE PORT_NET SET remote_address='$myIp' WHERE remote_address='10.0.0.9';`""
Write-Host '（随后重启 DUT，完整步骤见《割接与回滚手册.md》）'
