import json
import subprocess
import sys
import time

BASE = "http://10.0.0.9:8991"
HERE = __file__.rsplit("\\", 1)[0]

GROUP = {"code": "XAM_AVC", "name": "兴安盟AVC仿真", "description": "qplantagc 对端仿真（被测端=麒麟VM 10.0.0.194）"}
CHANNELS = [
    {
        "code": "PLC_SVR", "name": "PLC-仿真", "protocol_type": 1, "conn_type": 2,
        "ip": "0.0.0.0", "port": 502,
        "description": "通道4对端：Modbus TCP 服务端, 从站1",
    },
    {
        "code": "NCS_SVR", "name": "NCS-仿真", "protocol_type": 2, "conn_type": 2,
        "ip": "0.0.0.0", "port": 2404,
        "description": "通道1对端：IEC104 服务端, 公共地址257",
    },
    {
        "code": "MASTER_CLI", "name": "主站-仿真", "protocol_type": 2, "conn_type": 1,
        "ip": "10.0.0.194", "port": 2404,
        "description": "通道0/5对端：IEC104 客户端, 连被测端转发口",
    },
]
IMPORTS = [
    ("PLC-仿真", f"{HERE}\\modbus_plc.xlsx"),
    ("NCS-仿真", f"{HERE}\\iec104_ncs_server.xlsx"),
    ("主站-仿真", f"{HERE}\\iec104_master_client.xlsx"),
]


def curl(args, timeout=60):
    r = subprocess.run(
        ["curl", "-s", "-m", str(timeout), "-H", "Content-Type: application/json", *args],
        capture_output=True, text=True, encoding="utf-8",
    )
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError:
        return {"raw": r.stdout, "err": r.stderr}


def post(path, body):
    return curl(["-X", "POST", f"{BASE}{path}", "-d", json.dumps(body, ensure_ascii=False)])


def main():
    for _ in range(60):
        r = curl([f"{BASE}/api/health"], timeout=5)
        if r.get("code") == 200:
            print("backend up")
            break
        time.sleep(3)
    else:
        print("backend not reachable"); sys.exit(1)

    r = post("/api/device-groups/create", GROUP)
    print("group:", r.get("code"), r.get("message"), r.get("data"))
    gid = (r.get("data") or {}).get("group_id")
    if gid is None:
        r = post("/api/device-groups/list", {})
        print("list:", json.dumps(r, ensure_ascii=False)[:300]); sys.exit(1)

    ch_ids = {}
    for ch in CHANNELS:
        body = dict(ch, group_id=gid)
        r = post("/api/channels/create", body)
        print(f"channel {ch['code']}:", r.get("code"), r.get("message"), r.get("data"))
        if r.get("code") != 200:
            sys.exit(1)
        ch_ids[ch["name"]] = r["data"]["channel_id"]

    for name, path in IMPORTS:
        r = curl(["-X", "POST", f"{BASE}/api/channels/import-points",
                  "-F", f"channel_id={ch_ids[name]}", "-F", f"file=@{path}"], timeout=180)
        print(f"import {name}:", r.get("code"), r.get("message"), r.get("data"))

    for _, ch in zip(range(3), CHANNELS):
        r = post("/api/devices/start", {"device_name": ch["name"]})
        print(f"start {ch['name']}:", r.get("code"), r.get("message"))

    r = post("/api/channels/list", {})
    print(json.dumps(r, ensure_ascii=False)[:1500])


if __name__ == "__main__":
    main()
