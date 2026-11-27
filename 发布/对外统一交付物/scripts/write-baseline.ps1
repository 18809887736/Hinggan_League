# 回灌基线点值（清单可编辑；点号必须与库内大小写一致=大写）
# 原理：整进程重启后模拟点运行值清零。窄带宽遥测（PLC 12 个参数点、NCS 的电压/频率/功率因数）
#      由程序在启动时自动推到协议层，不必手写；本清单只补程序不推送的遥信。
# 注意：NCS 由映射派生的点（机组无功/电流、母线量等）被映射锁定，手写会被拒绝；要改就改驱动点
#      （YC502 系统频率、YC504/YC904 电压、YC515/615/915/1015 功率因数）或 PLC 的遥设。
#      浮点保真探针：模拟停止时写 YC502=50.123，核对 DUT 落库后写回 50。
#      负数整型探针：模拟停止时手写 PLC YC513=-555，核对 DUT 落库后写回 0。
$base = 'http://127.0.0.1:8991'
function Post($path, $obj) {
    $json = $obj | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post -Uri "$base/$path" -ContentType 'application/json' `
        -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 30
}

# ---- 基线清单（按需增删）----
$baseline = @(
    @{ dev = 'NCS-仿真'; code = 'YX201'; val = 1 },       # 1#机组开关 合
    @{ dev = 'NCS-仿真'; code = 'YX211'; val = 1 },       # 2#机组开关 合
    @{ dev = 'NCS-仿真'; code = 'YX221'; val = 1 },       # 3#机组开关 合
    @{ dev = 'NCS-仿真'; code = 'YX231'; val = 1 }        # 4#机组开关 合
)
# ------------------------

foreach ($p in $baseline) {
    try {
        Post 'api/points/edit-data' @{ device_name = $p.dev; point_code = $p.code; point_value = $p.val } | Out-Null
        Write-Host ("[OK] {0} {1} = {2}" -f $p.dev, $p.code, $p.val)
    } catch {
        Write-Host ("[失败] {0} {1}: {2}" -f $p.dev, $p.code, $_.Exception.Message)
    }
}
