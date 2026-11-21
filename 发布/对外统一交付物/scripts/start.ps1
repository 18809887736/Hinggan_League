# 启动仿真器：起后端 → 等健康检查 → 启动三台设备 → 主站 autoread + 总召唤
$ErrorActionPreference = 'Stop'
$pkg = Split-Path $PSScriptRoot -Parent
$env:EMS_ROOT_DIR = $pkg
$base = 'http://127.0.0.1:8991'

if (Get-Process ems_simulate_backend -ErrorAction SilentlyContinue) {
    Write-Host '[跳过] 后端已在运行（先跑 stop.ps1 可整进程重启）'
} else {
    Start-Process -FilePath (Join-Path $pkg 'ems_simulate_backend.exe') -WorkingDirectory $pkg -WindowStyle Minimized
    $ok = $false
    for ($i = 0; $i -lt 30; $i++) {
        try { Invoke-RestMethod "$base/api/health" -TimeoutSec 2 | Out-Null; $ok = $true; break } catch { Start-Sleep 2 }
    }
    if (-not $ok) { throw '健康检查 60s 未通过，查看 log\ 下日志（杀软拦截会出现 PermissionError）' }
    Write-Host '[1/3] 后端已就绪'
}

function Post($path, $obj) {
    $json = $obj | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post -Uri "$base/$path" -ContentType 'application/json' `
        -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 30
}

foreach ($dev in @('PLC-仿真', 'NCS-仿真', '主站-仿真')) {
    Post 'api/devices/start' @{ device_name = $dev } | Out-Null
}
Write-Host '[2/3] 三台设备已启动'

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
Write-Host '启动完成。Web 界面: http://127.0.0.1:8991'
Write-Host '提醒: 若 DUT 已在运行，此刻需重启 DUT 让其重连总召（见割接手册）；改点值跑 write-baseline.ps1'
