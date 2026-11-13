# -*- coding: utf-8 -*-
"""兴安盟联调 API 辅助脚本（避免 Windows 控制台中文编码问题）"""
import json
import sys
import urllib.request

BASE = "http://10.0.0.9:8991"
DEV = {"plc": "PLC-仿真", "ncs": "NCS-仿真", "master": "主站-仿真"}


def post(path, obj, timeout=20):
    req = urllib.request.Request(
        BASE + path, data=json.dumps(obj).encode("utf-8"),
        headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req, timeout=timeout).read().decode("utf-8"))


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "autoread":
        dev = DEV[sys.argv[2]]
        r = post("/api/devices/start-auto-read",
                 {"device_name": dev, "mode": "batch", "cycle_interval_ms": 2000})
        print(json.dumps(r, ensure_ascii=False)[:300])
    elif cmd == "vals":
        dev = DEV[sys.argv[2]]
        codes = sys.argv[3].split(",")
        r = post("/api/points/batch-values", {"device_name": dev, "point_codes": codes})
        print(json.dumps(r.get("data"), ensure_ascii=False))
    elif cmd == "write":
        dev = DEV[sys.argv[2]]
        code, val = sys.argv[3], float(sys.argv[4])
        body = {"device_name": dev, "point_code": code, "point_value": val}
        if len(sys.argv) > 5:
            body["slave_id"] = int(sys.argv[5])
        r = post("/api/points/edit-data", body)
        print(r.get("code"), r.get("message"))
    elif cmd == "gi":
        r = post("/api/devices/iec104-interrogation", {"device_name": DEV[sys.argv[2]]})
        print(json.dumps(r, ensure_ascii=False)[:200])
    elif cmd == "restart":
        ch = {"plc": 1, "ncs": 2, "master": 3}[sys.argv[2]]
        r = post("/api/channels/restart", {"channel_id": ch})
        print(json.dumps(r, ensure_ascii=False)[:200])
    else:
        print("usage: xamapi.py autoread|vals|write|gi|restart ...")


if __name__ == "__main__":
    main()
