#Requires -RunAsAdministrator
# 放行仿真器入站端口（DUT 连入用）：TCP 502 / 2404，源限 10.0.0.0/24
netsh advfirewall firewall add rule name="ems-sim 502"  dir=in action=allow protocol=TCP localport=502  remoteip=10.0.0.0/24
netsh advfirewall firewall add rule name="ems-sim 2404" dir=in action=allow protocol=TCP localport=2404 remoteip=10.0.0.0/24
Write-Host '已放行 502/2404（源 10.0.0.0/24）。若两条规则已存在会重复添加，可用 delete rule name=... 清理'
