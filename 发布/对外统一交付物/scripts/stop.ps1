# 停止仿真器（整进程，唯一可靠方式；设备级 stop→start 会假活）
$procs = Get-Process ems_simulate_backend -ErrorAction SilentlyContinue
if ($procs) {
    $procs | Stop-Process -Force
    Write-Host '已停止 ems_simulate_backend'
} else {
    Write-Host '未在运行'
}
Write-Host '提醒: DUT 的 104 采集通道对不干净断线不自愈——下次 start.ps1 后需按割接手册重启 DUT'
