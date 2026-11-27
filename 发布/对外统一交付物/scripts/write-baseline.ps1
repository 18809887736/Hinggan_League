# 回灌基线点值（清单可编辑；点号必须与库内大小写一致=大写）
# 原理：整进程重启后模拟点运行值清零，须在 DUT 重连总召之前写回
$base = 'http://127.0.0.1:8991'
function Post($path, $obj) {
    $json = $obj | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post -Uri "$base/$path" -ContentType 'application/json' `
        -Body ([Text.Encoding]::UTF8.GetBytes($json)) -TimeoutSec 30
}

# ---- 基线清单（按需增删）----
$baseline = @(
    @{ dev = 'PLC-仿真'; code = 'YC512'; val = 200 },     # 1#机有功上限
    @{ dev = 'PLC-仿真'; code = 'YC513'; val = -555 },    # 1#机有功下限
    @{ dev = 'NCS-仿真'; code = 'YC222'; val = 77.7 },    # 1#二次P（浮点保真探针）
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
