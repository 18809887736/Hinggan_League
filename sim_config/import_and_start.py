import json
import subprocess
import sys
import time

BASE = "http://10.0.0.9:8991"
HERE = __file__.rsplit("\\", 1)[0]

IMPORTS = [
    (1, "PLC-仿真", f"{HERE}\\modbus_plc.xlsx"),
    (2, "NCS-仿真", f"{HERE}\\iec104_ncs_server.xlsx"),
    (3, "主站-仿真", f"{HERE}\\iec104_master_client.xlsx"),
]


def curl(args, timeout=180):
    r = subprocess.run(["curl", "-s", "-m", str(timeout), *args],
                       capture_output=True, text=True, encoding="utf-8")
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError:
        return {"raw": r.stdout[:300], "err": r.stderr}


def post(path, body):
    return curl(["-X", "POST", "-H", "Content-Type: application/json",
                 f"{BASE}{path}", "-d", json.dumps(body, ensure_ascii=False)])


def main():
    for cid, name, path in IMPORTS:
        r = curl(["-X", "POST", f"{BASE}/api/channels/import-points",
                  "-F", f"channel_id={cid}", "-F", f"file=@{path}"])
        print(f"import {name} (ch{cid}):", r.get("code"), r.get("message"), r.get("data"))
        if r.get("code") != 200:
            sys.exit(1)

    for cid, name in [(c, n) for c, n, _ in IMPORTS]:
        r = post("/api/channels/restart", {"channel_id": cid})
        print(f"restart {name}:", r.get("code"), r.get("message"))

    time.sleep(3)
    for _, name in [(c, n) for c, n, _ in IMPORTS]:
        r = post("/api/devices/info", {"device_name": name})
        d = r.get("data") or {}
        print(f"info {name}:", r.get("code"), json.dumps(
            {k: d.get(k) for k in ("is_running", "is_start", "protocol_running", "point_count",
                                    "yc_count", "yx_count", "yk_count", "yt_count") if k in d},
            ensure_ascii=False))


if __name__ == "__main__":
    main()
