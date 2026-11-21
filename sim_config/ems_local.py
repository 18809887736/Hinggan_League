# -*- coding: utf-8 -*-
"""本机 onedir 版仿真器 API 助手（BASE=127.0.0.1:8991，含设备启动）"""
import json
import sys
import urllib.request

BASE = "http://127.0.0.1:8991"
DEV = {"plc": "PLC-仿真", "ncs": "NCS-仿真", "master": "主站-仿真"}


def post(path, obj, timeout=30):
    req = urllib.request.Request(
        BASE + path, data=json.dumps(obj).encode("utf-8"),
        headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req, timeout=timeout).read().decode("utf-8"))


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "start":
        r = post("/api/devices/start", {"device_name": DEV[sys.argv[2]]})
        print(r.get("code"), r.get("message"))
    elif cmd == "autoread":
        r = post("/api/devices/start-auto-read",
                 {"device_name": DEV[sys.argv[2]], "mode": "batch", "cycle_interval_ms": 2000})
        print(json.dumps(r, ensure_ascii=False)[:300])
    elif cmd == "vals":
        codes = sys.argv[3].split(",")
        r = post("/api/points/batch-values", {"device_name": DEV[sys.argv[2]], "point_codes": codes})
        print(json.dumps(r.get("data"), ensure_ascii=False))
    elif cmd == "write":
        code, val = sys.argv[3], float(sys.argv[4])
        body = {"device_name": DEV[sys.argv[2]], "point_code": code, "point_value": val}
        if len(sys.argv) > 5:
            body["slave_id"] = int(sys.argv[5])
        r = post("/api/points/edit-data", body)
        print(r.get("code"), r.get("message"))
    elif cmd == "gi":
        r = post("/api/devices/iec104-interrogation", {"device_name": DEV[sys.argv[2]]})
        print(json.dumps(r, ensure_ascii=False)[:200])
    else:
        print("usage: ems_local.py start|autoread|vals|write|gi plc|ncs|master ...")


if __name__ == "__main__":
    main()
