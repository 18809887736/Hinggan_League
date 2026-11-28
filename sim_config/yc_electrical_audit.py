# -*- coding: utf-8 -*-
"""YC 电气性审计（只读）—— 判定仿真器当前的 YC 值是否"遵守电气性"。

用法（Python 3，无需第三方库）：
  python yc_electrical_audit.py                         # 审计本机 8991，单次采样（静止态，严格判据）
  python yc_electrical_audit.py --base http://10.0.0.9:8991
  python yc_electrical_audit.py --seconds 60            # 连续采样 60 s（波动中，按瞬态容差统计）
  python yc_electrical_audit.py --seconds 100 --corr    # 同上，并检查波形是否错开（各量独立漂移）

只调用 /api/points/batch-values、/api/points/info、/api/devices/slave-id-list 与 /api/devices/table（均为读操作），不写任何值。
退出码：0 = 全部通过；1 = 有不通过项。

判据（每一条不满足都算违规）：
  A 定值   PLC-仿真的 12 个参数点等于机组容量对应的定值（有功上限＝铭牌、下限＝0、调节速度按容量取 3.5/4.0，
           均经 INT16 截断）。铭牌按一次图 D-01：1#=6、2#=15、3#=15、4#=6 MW（2026-11-27 裁定）；
           DUT 的 GENERATOR 表在 3#、4# 上与此相反。
  B 机组   有功 P 在 [0, 铭牌] 内；指令反馈 = 限幅后的派发；实发与指令反馈之差不超过跟踪偏差上限
           （6 MW 机组 0.02 MW、15 MW 机组 0.045 MW）；I·√3·U·cosφ = P；Q = P·tanφ；
           三相电流相等；三个线电压相等。
  C 母线   母线 P、Q = 所挂机组之和；母线 cosφ = P/√(P²+Q²)；母线 I·√3·U = √(P²+Q²)；
           同一母线电压等于所挂机组机端电压；全系统频率一致。
  D 边界   库里设了带宽的点（0 < 上限−下限 ≤ 1000），当前值落在带宽内。
  E 波形   （仅 --corr）按「开始」后 NCS 带宽点的两两相关系数：中位数 <0.6，且 >0.9 的点对不超过四成。
  U 单位   三个设备的每个 YC 点，页面上显示的单位等于期望单位（P=MW、Q=Mvar、U=kV、I=A、F=Hz、cosφ=—；
           PLC 的上下限与指令反馈=MW、调节速度=MW/min）。期望单位取自本脚本里量的分类，显示单位取自表格接口，
           两者是独立来源。有量纲的点是空的、写错了、新增点没配，都在这里查出来。需要仿真器 1.0.4 及以上。

静止态（未按「开始」或已「停止」）要求各恒等式严格成立。波动中派生量由映射逐条更新，采样落在更新窗口内
会看到亚秒级的小偏差（量级 = 源点一拍的漂移量），用 --seconds 采样时按较宽的瞬态容差判定，
并单独报告出现瞬态偏差的采样次数。审计窗口内不要改派发值（PLC 遥设），否则机组有功会有一拍跟不上。

跟踪偏差：按「开始」后机组实发在"限幅后的派发值 ± 跟踪偏差上限"内起伏，派发值在铭牌及以上时只有负向一半
（机组不能超额定，如 6 MW 机组在 5.98~6.00 之间），母线有功随之小幅起伏；指令反馈恒等于命令本身。
不按「开始」（或刚启动）时偏差为 0；按过「开始」再停止后偏差停在当时的值上，不超过上限。
"""
import argparse
import itertools
import json
import math
import sys
import time
import urllib.request

SQ3 = math.sqrt(3)
PLC, NCS = "PLC-仿真", "NCS-仿真"
UNITS = {  # 点号、铭牌有功（MW；按一次图 D-01：1#=6、2#=15、3#=15、4#=6，2026-11-27 裁定以一次图为准。DUT 的 GENERATOR 表在 3#、4# 上相反）、跟踪偏差上限 DEV（MW）、PLC 侧派发遥设与指令反馈
    1: dict(P="YC501", F="YC502", Q="YC503", Uab="YC504", Ubc="YC505", Uca="YC506", Ia="YC507", Ib="YC508", Ic="YC509", PF="YC515", YS="YS1", FB="YC301", PR=6.0, DEV=0.02),
    2: dict(P="YC601", F="YC602", Q="YC603", Uab="YC604", Ubc="YC605", Uca="YC606", Ia="YC607", Ib="YC608", Ic="YC609", PF="YC615", YS="YS4", FB="YC303", PR=15.0, DEV=0.045),
    3: dict(P="YC901", F="YC902", Q="YC903", Uab="YC904", Ubc="YC905", Uca="YC906", Ia="YC907", Ib="YC908", Ic="YC909", PF="YC915", YS="YS6", FB="YC305", PR=15.0, DEV=0.045),
    4: dict(P="YC1001", F="YC1002", Q="YC1003", Uab="YC1004", Ubc="YC1005", Uca="YC1006", Ia="YC1007", Ib="YC1008", Ic="YC1009", PF="YC1015", YS="YS7", FB="YC307", PR=6.0, DEV=0.02),
}
BUSES = {  # 母线归属按 DUT 的 AGC 调节设备表：1# 母线 ← 1#、2# 机组；2# 母线 ← 3#、4# 机组（一次图 D-01 已核实）
    1: dict(Uab="YC219", Ubc="YC220", Uca="YC221", P="YC222", Q="YC223", COS="YC224", F="YC225", Ia="YC216", Ib="YC217", Ic="YC218", units=(1, 2)),
    2: dict(Uab="YC232", Ubc="YC233", Uca="YC234", P="YC235", Q="YC236", COS="YC237", F="YC238", Ia="YC229", Ib="YC230", Ic="YC231", units=(3, 4)),
}
# 12 个参数点的定值：上限=铭牌（6/15/15/6）、下限=0、调节速度按容量取 3.5（6 MW）/ 4.0（15 MW），均为 INT16 截断后的读数
PLC_FIXED = {"YC512": 6, "YC1012": 6, "YC612": 15, "YC912": 15, "YC513": 0, "YC613": 0, "YC913": 0, "YC1013": 0,
             "YC514": 3, "YC1014": 3, "YC614": 4, "YC914": 4}
MASTER = "主站-仿真"
DASH = "—"  # 无量纲量（功率因数）在页面上显示的单位
UNIT_SYMBOL = {"P": "MW", "F": "Hz", "Q": "Mvar", "Uab": "kV", "Ubc": "kV", "Uca": "kV",
               "Ia": "A", "Ib": "A", "Ic": "A", "PF": DASH, "COS": DASH}
SPEED = {"YC514", "YC614", "YC914", "YC1014"}  # 调节速度：图纸称"机组响应速率"，单位按惯例取 MW/min（数值借自 singleMaxDeltaP，待 DCS 量程确认）
EXPECT_UNIT = {PLC: {}, NCS: {}, MASTER: {"YC101": "MW", "YC103": "MW"}}
for _u in UNITS.values():
    EXPECT_UNIT[PLC][_u["FB"]] = "MW"
    for _k in ("P", "F", "Q", "Uab", "Ubc", "Uca", "Ia", "Ib", "Ic", "PF"):
        EXPECT_UNIT[NCS][_u[_k]] = UNIT_SYMBOL[_k]
for _b in BUSES.values():
    for _k in ("Uab", "Ubc", "Uca", "P", "Q", "COS", "F", "Ia", "Ib", "Ic"):
        EXPECT_UNIT[NCS][_b[_k]] = UNIT_SYMBOL[_k]
for _c in PLC_FIXED:
    EXPECT_UNIT[PLC][_c] = "MW/min" if _c in SPEED else "MW"
# 容差：第一列静止态（严格），第二列波动中的瞬态。
# 波动时派生量由映射逐条更新，采样若落在更新窗口内会看到"一半新一半旧"，偏差量级 = 源点一拍的漂移量
#（隔离实测：电流 ≤2 A、无功 ≤0.06 Mvar、频率 ≤0.01 Hz），持续不到 0.1 s；停止波动后恢复严格一致。
TOL = {"P": (0.01, 0.01), "S": (0.01, 0.05), "Q": (0.01, 0.05), "I": (0.05, 3.0), "U": (0.005, 0.02), "F": (0.005, 0.012), "SUM": (0.005, 0.08),
       "DEV": (0.0005, 0.02),  # DEV：实发与指令反馈之差超出跟踪偏差上限的量
       "UNIT": (0, 0)}  # UNIT：单位不符的条数（0 为通过）。注意 U 是电压的容差键，不要混用


def post(base, path, obj, timeout=20):
    req = urllib.request.Request(base + path, data=json.dumps(obj, ensure_ascii=False).encode("utf-8"),
                                 headers={"Content-Type": "application/json"})
    try:
        return json.loads(urllib.request.urlopen(req, timeout=timeout).read().decode("utf-8"))
    except urllib.error.HTTPError as exc:  # 测点不存在等情形接口返回 4xx/5xx
        return {"code": exc.code, "data": None}


def values(base, dev, codes):
    return post(base, "/api/points/batch-values", {"device_name": dev, "point_codes": codes}).get("data") or {}


def limits(base, dev, codes):
    out = {}
    for c in codes:
        d = post(base, "/api/points/info", {"device_name": dev, "point_code": c}).get("data") or {}
        out[c] = (d.get("min_value"), d.get("max_value"))
    return out


def shown_units(base, dev):
    """页面表格里每个遥测点显示的单位：({测点编码: 单位}, 表格接口是否带单位列)。行内第 9 位（从 0 数）是单位。"""
    out, has = {}, None
    slaves = post(base, "/api/devices/slave-id-list", {"device_name": dev}).get("data") or []
    for sid in slaves:
        data = post(base, "/api/devices/table", {"device_name": dev, "slave_id": sid, "point_name": None, "page_index": 1,
                                                   "page_size": 500, "point_types": [0, 1, 2, 3]}).get("data") or {}
        for row in data.get("table_data") or []:
            has = (len(row) >= 16) if has is None else has  # 加列后每行 16 项；1.0.3 及以前是 15 项
            if len(row) > 12 and row[12] == "遥测":
                out[row[6]] = (row[9] or "") if len(row) > 9 else None
    return out, bool(has)


def unit_residuals(shown):
    """返回 {判据名: (不符的条数, "UNIT", 说明)}；说明为空表示通过。"""
    r = {}

    def put(label, note=""):
        r[label] = (1 if note else 0, "UNIT", note)

    for dev, expect in EXPECT_UNIT.items():
        got, has = shown[dev]
        for code in sorted(expect):
            want = expect[code]
            actual = got.get(code, "未找到") if has else "无法读取"
            label = "U 单位 %s %s = %s" % (dev, code, want)
            if actual == want:
                put(label)
            else:
                put(label, "显示为 %s%s" % ("空" if actual == "" else actual,
                                          "" if has else "（表格接口没有单位列：仿真器版本低于 1.0.4？）"))
        for code in sorted(set(got) - set(expect)):
            label = "U 单位 %s %s（未分类的遥测点）不为空" % (dev, code)
            put(label, "" if got[code] else "显示为空：新增的遥测点没有配单位")
    return r


def residuals(v, lim):
    """返回 {判据名: (残差, 量纲键, 说明)}；残差 = 越界量或恒等式偏差，单位见量纲键。"""
    g = lambda c: v.get(c)
    r = {}

    def put(name, res, unit, note=""):
        r[name] = (abs(res) if res is not None else float("inf"), unit, note)

    for c, want in PLC_FIXED.items():
        put("A PLC 定值 %s = %s" % (c, want), (g(c) - want) if g(c) is not None else None, "P")
    for k, u in UNITS.items():
        P, Q, I, PF, U = g(u["P"]), g(u["Q"]), g(u["Ia"]), g(u["PF"]), g(u["Uab"])
        put("B 机组%d 有功在 [0, %g] 内" % (k, u["PR"]), max(-P, P - u["PR"], 0) if P is not None else None, "P")
        put("B 机组%d 指令反馈 = 限幅后的派发" % k, g(u["FB"]) - min(max(g(u["YS"]) or 0, 0), u["PR"]) if None not in (g(u["FB"]), g(u["YS"])) else None, "S")
        put("B 机组%d 实发与指令反馈之差 ≤ %g" % (k, u["DEV"]), max(abs(P - g(u["FB"])) - u["DEV"], 0) if None not in (P, g(u["FB"])) else None, "DEV")
        if None in (Q, I, PF, U):
            continue
        put("B 机组%d I·√3·U·cosφ = P" % k, I * SQ3 * U * PF / 1000 - P if U and PF else None, "S")
        put("B 机组%d Q = P·tanφ" % k, Q - P * math.sqrt(1 / (PF * PF) - 1) if PF else None, "Q")
        put("B 机组%d 三相电流相等" % k, max(abs(g(u["Ia"]) - g(u["Ib"])), abs(g(u["Ia"]) - g(u["Ic"]))), "I")
        put("B 机组%d 线电压相等" % k, max(abs(U - g(u["Ubc"])), abs(U - g(u["Uca"]))), "U")
    for k, b in BUSES.items():
        ua, ub = (UNITS[x] for x in b["units"])
        P, Q, I, COS, U = g(b["P"]), g(b["Q"]), g(b["Ia"]), g(b["COS"]), g(b["Uab"])
        put("C 母线%d P = 所挂机组之和" % k, P - g(ua["P"]) - g(ub["P"]), "SUM")
        put("C 母线%d Q = 所挂机组之和" % k, Q - g(ua["Q"]) - g(ub["Q"]), "SUM")
        if P or Q:
            put("C 母线%d cosφ = P/√(P²+Q²)" % k, COS - P / math.hypot(P, Q), "Q")
            put("C 母线%d I·√3·U = √(P²+Q²)" % k, I * SQ3 * U / 1000 - math.hypot(P, Q) if U else None, "I")
        put("C 母线%d 三相电流相等" % k, max(abs(I - g(b["Ib"])), abs(I - g(b["Ic"]))), "I")
        put("C 母线%d 线电压相等" % k, max(abs(U - g(b["Ubc"])), abs(U - g(b["Uca"]))), "U")
        put("C 母线%d 电压 = 所挂机组机端电压" % k, max(abs(U - g(ua["Uab"])), abs(U - g(ub["Uab"]))), "U")
    put("C 全系统频率一致", max(abs(g(u["F"]) - g("YC502")) for u in UNITS.values()) + max(abs(g(b["F"]) - g("YC502")) for b in BUSES.values()), "F")
    for c, (lo, hi) in lim.items():
        if lo is not None and hi is not None and lo < hi <= lo + 1000 and g(c) is not None:
            put("D 带内 %s [%g, %g]" % (c, lo, hi), max(lo - g(c), g(c) - hi, 0), "S")
    return r


def pearson(a, b):
    ma, mb = sum(a) / len(a), sum(b) / len(b)
    num = sum((x - ma) * (y - mb) for x, y in zip(a, b))
    den = math.sqrt(sum((x - ma) ** 2 for x in a) * sum((y - mb) ** 2 for y in b))
    return num / den if den else 0.0


def main():
    sys.stdout.reconfigure(encoding="utf-8")  # 先于 argparse：否则 Windows 控制台下 --help 的中文是乱码
    ap = argparse.ArgumentParser(description="YC 电气性审计（只读）")
    ap.add_argument("--base", default="http://127.0.0.1:8991")
    ap.add_argument("--seconds", type=float, default=0, help="连续采样时长；0 = 单次（静止态严格判据）")
    ap.add_argument("--interval", type=float, default=0.5)
    ap.add_argument("--corr", action="store_true",
                    help="同时检查波形是否错开（各量独立漂移）：NCS 带宽点两两相关系数。波动中采样才有意义，需 --seconds ≥ 90")
    args = ap.parse_args()
    base = args.base.rstrip("/")

    unit_keys = ("P", "F", "Q", "Uab", "Ubc", "Uca", "Ia", "Ib", "Ic", "PF")
    ncs = sorted({u[k] for u in UNITS.values() for k in unit_keys} | {b[k] for b in BUSES.values() for k in ("Uab", "Ubc", "Uca", "P", "Q", "COS", "F", "Ia", "Ib", "Ic")})
    pl = sorted(set(PLC_FIXED) | {u["FB"] for u in UNITS.values()})
    # 带内判据只针对 NCS 的浮点遥测。PLC 的 12 个参数点是 INT16 整数寄存器，库里的区间是"整数中间区间"
    # （如上限 6 的区间为 6.2~6.8），寄存器截断后的值本就不落在该区间内，由判据 A 按定值核对。
    lim = limits(base, NCS, ncs)
    band_pts = [c for c, (lo, hi) in sorted(lim.items()) if lo is not None and hi is not None and lo < hi <= lo + 1000]
    # 波形错开检查取 NCS 带宽点里均匀分布的至多 10 个。观察窗要够长：同周期或周期相近的正弦在短窗口里
    # 也会表现出高相关，离线计算表明 60 s 窗口下中位数可在 0.4~0.9 间波动，100 s 窗口下稳定在 0.5 以下。
    corr_pts = band_pts[:: max(1, len(band_pts) // 10)][:10]
    series = {c: [] for c in corr_pts}
    worst, over, n = {}, 0, 0
    end = time.time() + args.seconds
    while True:
        v = dict(values(base, NCS, ncs))
        v.update(values(base, PLC, pl + [u["YS"] for u in UNITS.values()]))
        for c in corr_pts:
            series[c].append(v.get(c))
        r = residuals(v, lim)
        n += 1
        bad = False
        for name, (res, unit, _) in r.items():
            tol = TOL[unit][1 if args.seconds else 0]
            prev = worst.get(name)
            if prev is None or res > prev[0]:
                worst[name] = (res, tol)
            if res > tol:
                bad = True
        over += bad
        if time.time() >= end:
            break
        time.sleep(args.interval)

    # 单位判据与采样无关，只算一次
    ures = unit_residuals({dev: shown_units(base, dev) for dev in EXPECT_UNIT})
    for name, (res, unit_key, _) in ures.items():
        worst[name] = (res, TOL[unit_key][0])

    failed = {k: t for k, t in worst.items() if t[0] > t[1]}
    print("YC 电气性审计  目标=%s  采样=%d 次  判据=%d 条（含单位判据 %d 条）" % (base, n, len(worst), len(ures)))
    for name, (res, tol) in worst.items():
        if name not in failed or name in ures:
            continue
        detail = "无法计算（电压或功率因数为 0）" if math.isinf(res) else "最大偏差 %.4f（容差 %g）" % (res, tol)
        print("  [不通过] %-44s %s" % (name, detail))
    for name, (_, _, note) in ures.items():
        if name in failed:
            print("  [不通过] %-44s %s" % (name, note))
    sfailed = list(failed)
    print("通过 %d 条，不通过 %d 条" % (len(worst) - len(failed), len(failed)))
    if args.seconds:
        print("波动中超出瞬态容差的采样：%d / %d（派生量逐点异步更新，偶发的亚秒级小偏差属预期）" % (over, n))
    if args.corr:
        pairs = list(itertools.combinations(corr_pts, 2))
        usable = [p for p in pairs if None not in series[p[0]] and None not in series[p[1]]]
        judged = bool(pairs) and args.seconds >= 90 and len(usable) == len(pairs) and len(series[corr_pts[0]]) >= 30
        if not judged:
            print("波形错开：未判定（需要波动中采样，--seconds ≥ 90，且带宽点读数完整）  [不通过]")
            sfailed.append("波形错开")
        else:
            cors = sorted(abs(pearson(series[a], series[b])) for a, b in usable)
            median = cors[len(cors) // 2]
            share = 100.0 * sum(1 for x in cors if x > 0.9) / len(cors)
            bad_corr = median >= 0.6 or share > 40
            if bad_corr:
                sfailed.append("波形错开")
            print("波形错开：%d 个带宽点、%d 对，|corr| 中位数 %.2f，>0.9 的点对占 %.0f%%"
                  "（判据：中位数 <0.6 且占比 ≤40%%）%s" % (len(corr_pts), len(cors), median, share, "  [不通过]" if bad_corr else ""))
    sys.exit(1 if sfailed else 0)


if __name__ == "__main__":
    main()
