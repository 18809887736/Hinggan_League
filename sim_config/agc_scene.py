# -*- coding: utf-8 -*-
"""AGC 派发验证 —— 仿真侧助手（本机 onedir 版，BASE=127.0.0.1:8991）。只动仿真器，不改 DUT 端。

放到 sim_config/ 下运行（Python 3，UTF-8 请求体，避开 Windows 控制台中文坑）。

子命令：
  maps                        列出全部测点映射（id / 目标 / 公式 / enable）
  map-off | map-on            停用 / 启用 YS1→YC501、YS4→YC601 两条功率映射（按目标点号定位）
  plc-cond                    写 PLC-仿真 机组条件遥信（IsAgcLocked 放行组合，见手册 §4）
  power P1 P2                 写 NCS-仿真 YC501=P1、YC601=P2（功率映射停用后才有效）
  keeper [ys5] [interval_s]   主站-仿真 周期重发 YS5（默认 81、200s；Ctrl+C 停止）
  vals                        读回关键点
"""
import json
import sys
import time
import urllib.request

BASE = "http://127.0.0.1:8991"
POWER_TARGETS = ("YC501", "YC601")  # 只动 1#/2# 机组功率映射；YC901/YC1001 与 YC301~307 回显映射保留

# IsAgcLocked 放行组合（联调记录-20261114 §9.4，修正版）：
#   AGC 投退(agcPermit)=1、RB=1（须合）、并网=0（须分！）、禁增/禁减=0、检修(一次调频位)=0、锁/故障总=0
PLC_COND = {
    # 1# 机组
    "YX301": 1, "YX303": 1, "YX304": 0, "YX305": 0, "YX306": 0, "YX414": 0, "YX302": 0, "YX351": 0,
    # 2# 机组
    "YX308": 1, "YX310": 1, "YX311": 0, "YX312": 0, "YX313": 0, "YX514": 0, "YX309": 0, "YX353": 0,
}


def post(path, obj, timeout=30):
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(obj, ensure_ascii=False).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    return json.loads(urllib.request.urlopen(req, timeout=timeout).read().decode("utf-8"))


def show(tag, r):
    print(tag, r.get("code"), r.get("message"), json.dumps(r.get("data"), ensure_ascii=False)[:300])
    return r


def write(dev, code, val):
    return show(f"write {dev} {code}={val}:", post("/api/points/edit-data",
                {"device_name": dev, "point_code": code, "point_value": val}))


def maps_list():
    r = post("/api/point-mappings/list", {})
    data = r.get("data")
    items = data if isinstance(data, list) else (data or {}).get("items") or (data or {}).get("list") or []
    if not items:
        print(json.dumps(r, ensure_ascii=False)[:1500])
    for m in items:
        print(m.get("id"), m.get("device_name"), m.get("target_point_code"), m.get("formula"), m.get("enable"))
    return items


def maps_toggle(enable: bool):
    for m in maps_list():
        if m.get("target_point_code") in POWER_TARGETS:
            show(f"mapping {m['id']} {m['target_point_code']} enable={enable}:",
                 post("/api/point-mappings/update", {"id": m["id"], "enable": enable,
                                                      "device_name": m.get("device_name")}))


def keeper(ys5: float, interval: float):
    print(f"ys5 keeper: YS5={ys5} 每 {interval}s（maxCommandInterval=300s 窗口）；Ctrl+C 停止")
    while True:
        try:
            write("主站-仿真", "YS5", ys5)
        except Exception as exc:  # 主站未连上 DUT 时会失败，下一轮重试
            print(time.strftime("%H:%M:%S"), "keeper 写入失败（DUT 未连上？）:", exc)
            time.sleep(10)
            continue
        time.sleep(interval)


def vals():
    for dev, codes in (("NCS-仿真", ["YC501", "YC601", "YC222"]),
                       ("PLC-仿真", ["YS1", "YS4", "YC301", "YC303", "YC512", "YC612"]),
                       ("主站-仿真", ["YC101", "YS5"])):
        try:
            r = post("/api/points/batch-values", {"device_name": dev, "point_codes": codes})
            print(dev, json.dumps(r.get("data"), ensure_ascii=False))
        except Exception as exc:
            print(dev, "读失败:", exc)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    a = sys.argv[1:]
    cmd = a[0] if a else ""
    if cmd == "maps":
        maps_list()
    elif cmd == "map-off":
        maps_toggle(False)
    elif cmd == "map-on":
        maps_toggle(True)
    elif cmd == "plc-cond":
        for code, v in PLC_COND.items():
            write("PLC-仿真", code, v)
    elif cmd == "power":
        write("NCS-仿真", "YC501", float(a[1]))
        write("NCS-仿真", "YC601", float(a[2]))
    elif cmd == "keeper":
        keeper(float(a[1]) if len(a) > 1 else 81.0, float(a[2]) if len(a) > 2 else 200.0)
    elif cmd == "vals":
        vals()
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
