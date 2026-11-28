# 启动仿真器：起后端 → 等健康检查 → 启动三台设备 → 主站 autoread + 总召唤
# -NoMaster：只起后端并确认 PLC-仿真、NCS-仿真 已监听，不起 主站-仿真。
#   换包或重启仿真器之后要重启 DUT 时用它（主站最后起，按这个顺序最稳妥）：
#   scripts\start.ps1 -NoMaster → 重启 DUT，等 DUT 自己的日志出现 rtdbManager start → scripts\start-master.ps1
param([switch]$NoMaster)
$ErrorActionPreference = 'Stop'
$pkg = Split-Path $PSScriptRoot -Parent
$env:EMS_ROOT_DIR = $pkg
$exe = Join-Path $pkg 'ems_simulate_backend.exe'

function Get-Ini($section, $key) {
    # 读运行根 config.ini 的一个键，没有这个键返回 $null
    $ini = Join-Path $pkg 'config.ini'
    if (Test-Path $ini) {
        $cur = ''
        foreach ($line in [IO.File]::ReadAllLines($ini, [Text.Encoding]::UTF8)) {
            $t = $line.Trim()
            if ($t -match '^\[(.+)\]$') { $cur = $Matches[1]; continue }
            if ($cur -eq $section -and $t -match "^$key\s*=\s*([^;#]*)") { return $Matches[1].Trim() }
        }
    }
    return $null
}

# Web 地址取自 config.ini 的 [server]（1.0.4 起这个文件真正生效），读不到按默认值
$webHost = Get-Ini 'server' 'host'
if (-not $webHost -or $webHost -eq '0.0.0.0' -or $webHost -eq '::') { $webHost = '127.0.0.1' }
$webPort = Get-Ini 'server' 'port'
if ($webPort -notmatch '^\d+$') { $webPort = 8991 }
$base = "http://${webHost}:$webPort"

function Post($path, $obj) {
    $json = $obj | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post -Uri "$base/$path" -ContentType 'application/json' `
        -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 30
}

function Get-ServerStatus($dev) {
    (Post 'api/devices/info' @{ device_name = $dev }).data.server_status
}

function Test-BackendRunning {
    # 只认本运行根的 exe，别的目录（别的运行根）的并行实例不算
    foreach ($p in @(Get-Process ems_simulate_backend -ErrorAction SilentlyContinue)) {
        if ($p.Path -eq $exe) { return $true }
    }
    return $false
}

if (Test-BackendRunning) {
    Write-Host '[跳过] 后端已在运行（先跑 stop.ps1 可整进程重启）'
} else {
    Start-Process -FilePath $exe -WorkingDirectory $pkg -WindowStyle Minimized
    $ok = $false
    for ($i = 0; $i -lt 30; $i++) {
        try { Invoke-RestMethod "$base/api/health" -TimeoutSec 2 | Out-Null; $ok = $true; break } catch { Start-Sleep 2 }
    }
    if (-not $ok) { throw '健康检查 60s 未通过，查看 log\ 下日志（杀软拦截会出现 PermissionError）' }
    # 端口上应答的必须是刚起的这个进程：它若已退出（端口被别的实例占用等），上面连通的是别的实例，不能再往下发命令
    if (-not (Test-BackendRunning)) { throw '后端启动后又退出了，Web 端口上应答的是别的实例。查看 log\ 下日志，并确认 config.ini 的 port 没有被占用' }
    Write-Host '[1/3] 后端已就绪'
}

if ($NoMaster) {
    foreach ($dev in @('PLC-仿真', 'NCS-仿真')) {
        if (-not (Get-ServerStatus $dev)) { Post 'api/devices/start' @{ device_name = $dev } | Out-Null }
        if (-not (Get-ServerStatus $dev)) { throw "$dev 没有启动，查看 log\ 下日志（端口被占用时起不来）" }
    }
    $master = (Post 'api/devices/info' @{ device_name = '主站-仿真' }).data
    $peer = "$($master.ip):$($master.port)"
    if ($master.server_status) {
        Write-Warning "主站-仿真 已经在运行（$peer）：-NoMaster 只对这次新起的进程有效。要按稳妥顺序重来，先跑 stop.ps1 再跑 start.ps1 -NoMaster"
        Write-Host '[3/3] 两台服务端设备在监听，但主站-仿真 没有被挡住（见上面的警告）'
    } else {
        Write-Host "[2/3] PLC-仿真、NCS-仿真 已监听；主站-仿真 没有启动（对端 $peer）"
        Write-Host '[3/3] 主站先不起，等 DUT 重启之后再说'
    }
    Write-Host ''
    Write-Host "Web 界面: $base"
    Write-Host '下一步（按这个顺序最稳妥）：'
    Write-Host '  1) 重启 DUT：kill → 静置 ≥80 秒 → 拉起，等 DUT 自己的日志出现 rtdbManager start'
    Write-Host '     （~/QCzt2016/build/logfile/<日期>/qplantagcserverlog.txt，命令见《割接与回滚手册.md》第一节第 4 步）'
    Write-Host '  2) 再跑本目录的 start-master.ps1：起主站-仿真、开自动读取、发总召唤'
    Write-Host '  这期间不要在 Web 界面上手动启动 主站-仿真；改点值跑 write-baseline.ps1'
    return
}

foreach ($dev in @('PLC-仿真', 'NCS-仿真', '主站-仿真')) {
    Post 'api/devices/start' @{ device_name = $dev } | Out-Null
}
Write-Host '[2/3] 设备已就绪（PLC-仿真、NCS-仿真 随程序自动开启，这里的启动调用是空操作；主站-仿真已启动）'

# 主站客户端需先连上 DUT 才能开自动读取，最多重试 5 次
for ($i = 1; $i -le 5; $i++) {
    try {
        Post 'api/devices/start-auto-read' @{ device_name = '主站-仿真'; mode = 'batch'; cycle_interval_ms = 2000 } | Out-Null
        break
    } catch { Start-Sleep 5 }
}
Post 'api/devices/iec104-interrogation' @{ device_name = '主站-仿真' } | Out-Null
Write-Host '[3/3] 主站 autoread + 总召唤完成'

Write-Host ''
Write-Host "启动完成。Web 界面: $base"
Write-Host '提醒: 仿真器重启后 DUT 要重启一次才会重连（见割接手册）；改点值跑 write-baseline.ps1'
Write-Host '      换包或重启后要重启 DUT 的，按更稳妥的顺序: stop.ps1 → start.ps1 -NoMaster → 重启 DUT → start-master.ps1'
