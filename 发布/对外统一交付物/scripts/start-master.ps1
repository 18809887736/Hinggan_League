# 起主站（后半段）：启动 主站-仿真 → 开自动读取（batch，周期 2000 ms）→ 发总召唤
# 用在 start.ps1 -NoMaster 之后、DUT 重启完成之后。换包或重启仿真器后要重启 DUT 时按这个顺序最稳妥：
#   scripts\start.ps1 -NoMaster → 重启 DUT（等到 DUT 自己的日志出现 rtdbManager start）→ scripts\start-master.ps1
#   2026-11-28 先起主站再重启 DUT，仿真器在 DUT 连上来的瞬间崩溃过一次；因果没有严格证明，先按这个顺序走。
# 起主站之前先探测，下面三种情况不启动、只报错：
#   DUT 的 2404 端口连不上（DUT 没起来或还在初始化）；
#   DUT 的端口接受了连接又马上断开（半死的转发通道）；
#   DUT 的端口通，但 DUT 还没连上仿真器（PLC-仿真 上没有客户端连接）——加 -Force 可跳过这一条。
# 总召唤发出之后还要看 DUT 有没有回报文：端口通着却不应答（半死连接）时接口照样报成功，只看接口会误判成就绪。
param([switch]$Force)
$ErrorActionPreference = 'Stop'
$pkg = Split-Path $PSScriptRoot -Parent
$master = '主站-仿真'

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

function Fail($msg) {
    Write-Host ''
    Write-Host "[失败] $msg" -ForegroundColor Red
    exit 1
}

# Web 地址取自 config.ini 的 [server]（与 start.ps1 相同），读不到按默认值
$webHost = Get-Ini 'server' 'host'
if (-not $webHost -or $webHost -eq '0.0.0.0' -or $webHost -eq '::') { $webHost = '127.0.0.1' }
$webPort = Get-Ini 'server' 'port'
if ($webPort -notmatch '^\d+$') { $webPort = 8991 }
$base = "http://${webHost}:$webPort"

function Post($path, $obj, $timeoutSec = 30) {
    $json = $obj | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post -Uri "$base/$path" -ContentType 'application/json' `
        -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec $timeoutSec
}

function Test-Tcp($ip, $port) {
    # 探测 DUT 的端口：连得上、而且对端不马上断开，返回 $null；否则返回原因
    $client = New-Object Net.Sockets.TcpClient
    try {
        $ar = $client.BeginConnect($ip, $port, $null, $null)
        if (-not $ar.AsyncWaitHandle.WaitOne(3000)) { return '3 秒内没有响应（超时）' }
        $client.EndConnect($ar)
        # 端口接受了连接又马上断开的（半死的转发通道）也算不通：在它上面起主站，仿真器崩溃过
        Start-Sleep -Milliseconds 1500
        $sock = $client.Client
        if ($sock.Poll(0, [Net.Sockets.SelectMode]::SelectRead) -and $sock.Available -eq 0) { return '端口接受了连接又马上断开' }
        return $null
    } catch {
        $e = $_.Exception
        if ($e.InnerException) { $e = $e.InnerException }
        return $e.SocketErrorCode
    } finally {
        $client.Close()
    }
}

function Test-BackendAlive {
    try { Invoke-RestMethod "$base/api/health" -TimeoutSec 3 | Out-Null; return $true } catch { return $false }
}

function Get-DownNote($action) {
    # 接口调用失败之后，后端进程已经不在了（崩溃）时返回说明，否则返回 $null
    if (Test-BackendAlive) { return $null }
    return "仿真器后端在$action 时退出了（多半是崩溃，出错模块通常是 _c104.pyd）。补救：scripts\stop.ps1 → scripts\start.ps1 -NoMaster → 重启 DUT → 等到 rtdbManager start → 再跑本脚本；线索看 log\iec104.log 和 %LOCALAPPDATA%\CrashDumps。"
}

function Get-ApiMessage($err) {
    # 取接口错误响应里的 message（PS 5.1 和 7 都放在 ErrorDetails.Message），取不到就用异常文本
    if ($err.ErrorDetails.Message) {
        try { return ($err.ErrorDetails.Message | ConvertFrom-Json).message } catch { }
    }
    return $err.Exception.Message
}

function Get-AutoReadState {
    (Post 'api/devices/auto-read-status' @{ device_name = $master }).data.state
}

function Get-FrameStat {
    # 主站报文缓存里最近一次收到（rx）和发出（tx）报文的时间戳（epoch 秒），没有就是 0
    $rx = 0; $tx = 0
    $msgs = @((Post 'api/devices/messages' @{ device_name = $master; limit = 200 }).data.messages)
    foreach ($m in $msgs) {
        if ($m.direction -eq 'RX') { $rx = $m.timestamp } elseif ($m.direction -eq 'TX') { $tx = $m.timestamp }
    }
    return @{ rx = $rx; tx = $tx }
}

$alive = $false
for ($i = 0; $i -lt 3; $i++) {
    try { Invoke-RestMethod "$base/api/health" -TimeoutSec 3 | Out-Null; $alive = $true; break } catch { Start-Sleep 2 }
}
if (-not $alive) {
    Fail "仿真器后端没有在运行（$base 无响应）。补救：先跑 scripts\start.ps1 -NoMaster 起后端（不起主站），重启 DUT，等 DUT 自己的日志出现 rtdbManager start 后再跑本脚本。"
}
Write-Host '[1/4] 后端在运行'

$info = (Post 'api/devices/info' @{ device_name = $master }).data
$peer = "$($info.ip):$($info.port)"
if ($info.server_status) {
    Write-Host "[2/4] 主站-仿真 已在运行（对端 $peer）"
} else {
    $why = Test-Tcp $info.ip $info.port
    if ($why -eq '端口接受了连接又马上断开') {
        Fail "DUT $peer 的端口接受了连接又马上断开：DUT 的 IEC 104 转发通道没有在正常工作（多半是没走完初始化，或留着半死连接）。这种情况不去起主站——在这种对端上启动主站，仿真器在 _c104.pyd 里崩溃过。补救：等 DUT 走完初始化（日志出现 rtdbManager start）后重跑本脚本；仍是这样就重启 DUT 再重跑。"
    }
    if ($why) {
        Fail "连不上 DUT $peer（$why）。DUT 没起来，或还在初始化。补救：等 DUT 自己的日志 ~/QCzt2016/build/logfile/<日期>/qplantagcserverlog.txt 出现 rtdbManager start 再重跑本脚本；仍不通时在 DUT 上确认转发通道在监听 2404（ss -tn | grep 2404），并核对本机到 DUT 的网络。"
    }
    $plc = (Post 'api/devices/info' @{ device_name = 'PLC-仿真' }).data
    if (-not $Force -and $plc.server_status -and $plc.connection_monitoring_supported -and $plc.current_connection_count -lt 1) {
        Fail "DUT 的端口已通，但 DUT 还没连上仿真器（PLC-仿真 上没有客户端连接）。主站等 DUT 连上之后再起才稳妥。补救：等 DUT 走完初始化（日志出现 rtdbManager start，PLC-仿真 上出现 DUT 的连接）再重跑本脚本；确认 DUT 已就绪、仍要现在起主站，加 -Force。"
    }
    try {
        Post 'api/devices/start' @{ device_name = $master } | Out-Null
    } catch {
        $err = $_
        $down = Get-DownNote '启动主站'
        if ($down) { Fail $down }
        Fail "主站-仿真 启动失败（$(Get-ApiMessage $err)）。补救：确认 DUT $peer 在运行、2404 端口通，然后重跑本脚本。"
    }
    Write-Host "[2/4] 主站-仿真 已启动（对端 $peer）"
}

if ((Get-AutoReadState) -eq 'running') {
    Write-Host '[3/4] 自动读取已在运行'
} else {
    $started = $false
    $why = ''
    for ($i = 1; $i -le 5; $i++) {
        try {
            Post 'api/devices/start-auto-read' @{ device_name = $master; mode = 'batch'; cycle_interval_ms = 2000 } | Out-Null
            $started = $true
            break
        } catch { $err = $_; $why = Get-ApiMessage $err; Start-Sleep 5 }
    }
    if (-not $started) {
        $down = Get-DownNote '开自动读取'
        if ($down) { Fail $down }
        Fail "主站-仿真的自动读取开不起来（重试 5 次都失败：$why）。主站多半没连上 DUT $peer。补救：确认 DUT 在运行后重跑本脚本。"
    }
    Start-Sleep -Seconds 3
    if ((Get-AutoReadState) -ne 'running') {
        Fail "自动读取开起来后第一轮就失败了，主站没有和 DUT $peer 正常通信。补救：确认 DUT 在运行后重跑本脚本。"
    }
    Write-Host '[3/4] 自动读取已开启（batch，周期 2000 ms）'
}

$before = Get-FrameStat
try {
    # DUT 不应答时这个接口会等满每个站约 10 秒才返回，超时放宽
    Post 'api/devices/iec104-interrogation' @{ device_name = $master } 90 | Out-Null
} catch {
    $err = $_
    $down = Get-DownNote '发总召唤'
    if ($down) { Fail $down }
    Fail "总召唤发送失败（$(Get-ApiMessage $err)）。主站多半已和 DUT $peer 断开。补救：确认 DUT 在运行后重跑本脚本。"
}
if ($before.tx -eq 0) {
    Write-Host '[4/4] 总召唤已发送（报文捕获没有开，无法核对 DUT 是否应答）'
} else {
    # DUT 不回话时总召唤接口照样返回成功（帧发出去了），所以再看总召唤之后 DUT 有没有回报文
    $answered = $false
    for ($i = 0; $i -lt 5; $i++) {
        if ((Get-FrameStat).rx -gt $before.rx) { $answered = $true; break }
        Start-Sleep 1
    }
    if (-not $answered) {
        Fail "总召唤发出去了，但 DUT $peer 没有回报文：TCP 连得上，DUT 的 IEC 104 转发通道却没有在应答（多半是没走完初始化，或留着半死连接）。补救：等 DUT 走完初始化（日志出现 rtdbManager start）后重跑本脚本；仍不行就重启 DUT 再重跑。"
    }
    Write-Host '[4/4] 总召唤已发送，DUT 有应答'
}

Write-Host ''
Write-Host "主站已就绪：主站-仿真 → $peer，自动读取（batch，2000 ms）+ 总召唤完成。"
Write-Host '核对（《割接与回滚手册.md》第一节第 5 步）：DUT 上 101/102/107 三个通道信号为 65，本机有一条到 DUT:2404 的连接，改一个仿真值后 DUT 库跟着变。'
