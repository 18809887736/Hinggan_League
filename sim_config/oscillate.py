# -*- coding: utf-8 -*-
"""仿真器电气量小幅震荡开关（纯 REST 配置工具，不修改仿真器源码）

用法：
  python oscillate.py apply              # 按 oscillation.json 应用（on 点=SineWave+range，off 点=None+基准值）
  python oscillate.py on  [组名|点码]    # 临时全开 / 某点开（并写回 JSON）
  python oscillate.py off [组名|点码]    # 临时全关 / 某点关（恢复基准值，并写回 JSON）
  python oscillate.py report             # 配置期望 vs 运行时实际 对照

说明：
- oscillation.json 为唯一事实来源（每点：device/base/amp/on）；
- SineWave 中心=(max+min)/2、幅值=(max-min)/2，故 range = base±amp；
- 模拟方式为运行态（不落库），容器重启后执行 `apply` 一键恢复期望态；
- 映射锁定点（YC501/601/901/1001 等）与 always_off 点自动跳过。
"""
import json, sys, os, time, urllib.request

BASE = "http://10.0.0.9:8991"
CFG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "oscillation.json")
ALWAYS_OFF = {"YC501", "YC601", "YC901", "YC1001"}  # 映射锁定，永不开震荡


def post(path, obj, timeout=40):
    req = urllib.request.Request(BASE + path, data=json.dumps(obj).encode("utf-8"),
        headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req, timeout=timeout).read().decode("utf-8"))


def load_cfg():
    return json.load(open(CFG, encoding="utf-8"))["points"]


def save_cfg(points):
    json.dump({"points": points}, open(CFG, "w", encoding="utf-8"), ensure_ascii=False, indent=1)


def apply_point(code, p, on=None):
    """按配置应用单点：on=True → SineWave+range；on=False → None+基准值"""
    state = p.get("on", True) if on is None else on
    dev, base, amp = p["device"], p["base"], p.get("amp", 0.0)
    if state:
        r = post("/api/points/set-simulation-range", {"device_name": dev, "point_code": code,
                 "min_value": round(base - amp, 4), "max_value": round(base + amp, 4)})
        if r.get("code") != 200:
            return "range FAIL %s" % r.get("message")
        r = post("/api/points/set-simulate-method", {"device_name": dev, "point_code": code,
                 "simulate_method": "SineWave"})
        if r.get("code") != 200:
            return "sine FAIL %s" % r.get("message")
        return "SINE"
    else:
        r = post("/api/points/set-simulate-method", {"device_name": dev, "point_code": code,
                 "simulate_method": "None"})
        if r.get("code") != 200:
            return "none FAIL %s" % r.get("message")
        r = post("/api/points/edit-data", {"device_name": dev, "point_code": code, "point_value": base})
        if r.get("code") != 200:
            return "base FAIL %s" % r.get("message")
        return "FIXED"


def main():
    argv = sys.argv[1:]
    cmd = argv[0] if argv else "report"
    points = load_cfg()
    sys.stdout.reconfigure(encoding="utf-8")

    target = argv[1] if len(argv) > 1 else None
    def select():
        if not target:
            return list(points.items())
        if target in points:                       # 点码
            return [(target, points[target])]
        return [(c, p) for c, p in points.items() if target in p.get("groups", [target])]  # 组名（预留）

    if cmd == "apply":
        on_cnt = off_cnt = fail = 0
        for code, p in points.items():
            if code in ALWAYS_OFF:
                continue
            r = apply_point(code, p)
            if r in ("SINE",): on_cnt += 1
            elif r == "FIXED": off_cnt += 1
            else: fail += 1; print("apply %s: %s" % (code, r))
        print("apply: %d sine, %d fixed, %d fail (total %d)" % (on_cnt, off_cnt, fail, len(points)))
    elif cmd in ("on", "off"):
        want = cmd == "on"
        sel = select()
        for code, p in sel:
            p["on"] = want
            if code in ALWAYS_OFF and want:
                print("skip %s (always_off)" % code); continue
            print("%s: %s" % (code, apply_point(code, p, want)))
        save_cfg(points)
        print("%s: %d points" % (cmd, len(sel)))
    elif cmd == "report":
        codes = [c for c in points]
        for dev in set(p["device"] for p in points.values()):
            cs = [c for c in codes if points[c]["device"] == dev]
            r = post("/api/points/batch-values", {"device_name": dev, "point_codes": cs})
            vals = r.get("data") or {}
            for c in cs:
                exp = points[c]["base"]
                got = vals.get(c)
                drift = "ok" if (got is not None and abs(got - points[c]["base"]) <= points[c].get("amp", 0)) else "DRIFT"
                print("%s %s base=%s now=%s [%s]" % (dev, c, exp, got, drift))
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
