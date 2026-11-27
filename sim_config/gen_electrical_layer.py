# -*- coding: utf-8 -*-
"""生成 sim_config/electrical-layer-20261127.sql（阶段三：电气自洽层）。

把 NCS-仿真的电气量之间的关系全部写成 point_mapping 行（数据库数据）：
每台机组的 Q、I、三个线电压由 P、U、cosφ 按物理公式推出，母线量由所挂机组的量合成；
指令反馈 = 派发值限制在 [Pmin, Pmax]（即命令本身）；
机组有功 = 限幅后的派发值 + 一个很小的跟踪偏差（整体仍夹在 [Pmin, Pmax] 内）。
需要补丁⑩（映射公式支持 sqrt/abs/min/max）。

依据（2026-11-27 核对一次图与 DUT 库）：
- 机组铭牌有功按一次图 D-01：1#=6、2#=15、3#=15、4#=6 MW（用户 2026-11-27 裁定以一次图为准，规划 D7）。
  DUT 的 GENERATOR 表是 6/15/6/15，3#、4# 与一次图相反；下限 minPPower=0。
- 每台机组 9 个测量点的点号 P/F/Q/Uab/Ubc/Uca/Ia/Ib/Ic = 501~509 / 601~609 / 901~909 / 1001~1009
  （cosφ 为 515/615/915/1015）。
- 母线归属：BUSBAR_AGC_UP/DOWN_ADJUST_DEV 只把 1#、2# 列在 1# 母线下，据此取
  母线 1 ← 1#、2#，母线 2 ← 3#、4#（2026-11-27 已对照一次图 D-01 核实：Ⅰ 段挂 1G、2G，Ⅱ 段挂 3G、4G）。

跟踪偏差（用户 2026-11-27 要求）：
  机组有功 = min(max(限幅后的派发值 + dev, 0), 铭牌)，dev = min(max(K * (cosφ - 0.8), -DEV), DEV)
  6 MW 机组 DEV = 0.02 MW，15 MW 机组 DEV = 0.045 MW（约 0.3% 额定）；K = DEV / 0.008（0.008 是 cosφ 驱动点的半带宽）。
  偏差借用该机组自己的 cosφ 驱动点作时间基准：每台机组相位、周期各自不同，所以各机组的偏差互不相关；
  不新增测点——60 个 NCS 点都已占用，新增会改变送给 DUT 的总召元素表。
  不按「开始」（或刚启动）时 cosφ = 0.8，dev = 0，实发严格等于命令；按「开始」后小幅起伏。
  派发值在铭牌及以上时（如 DUT 现在的 123/300/700/400）只有负向一半：机组不能超额定，
  所以 6 MW 机组在 5.98~6.00 之间起伏，母线有功随之小幅起伏。

改这里的 UNITS / BUSES 后重新运行：  python gen_electrical_layer.py
产物与 electrical-layer-20261127.sql 同目录；SQL 可重放（UPDATE 幂等、INSERT OR REPLACE）。
在跑的实例上改这 4 条机组有功映射不必重启：用 POST /api/point-mappings/update（写库并立即重载）。
"""
import os

SQ3 = "1.7320508075688772"
PLC, NCS = "PLC-仿真", "NCS-仿真"
PF_CENTRE, PF_HALF = 0.8, 0.008  # cosφ 驱动点的中心与半带宽（来自 band-20261127.sql）

# unit -> 点号、PLC 侧派发遥设与指令反馈、铭牌有功（一次图 D-01：6/15/15/6 MW）、跟踪偏差上限 DEV（MW）
UNITS = {
    1: dict(P="YC501", F="YC502", Q="YC503", Uab="YC504", Ubc="YC505", Uca="YC506", Ia="YC507", Ib="YC508", Ic="YC509", PF="YC515", YS="YS1", FB="YC301", PR=6, DEV=0.02),
    2: dict(P="YC601", F="YC602", Q="YC603", Uab="YC604", Ubc="YC605", Uca="YC606", Ia="YC607", Ib="YC608", Ic="YC609", PF="YC615", YS="YS4", FB="YC303", PR=15, DEV=0.045),
    3: dict(P="YC901", F="YC902", Q="YC903", Uab="YC904", Ubc="YC905", Uca="YC906", Ia="YC907", Ib="YC908", Ic="YC909", PF="YC915", YS="YS6", FB="YC305", PR=15, DEV=0.045),
    4: dict(P="YC1001", F="YC1002", Q="YC1003", Uab="YC1004", Ubc="YC1005", Uca="YC1006", Ia="YC1007", Ib="YC1008", Ic="YC1009", PF="YC1015", YS="YS7", FB="YC307", PR=6, DEV=0.02),
}
BUSES = {
    1: dict(Uab="YC219", Ubc="YC220", Uca="YC221", P="YC222", Q="YC223", COS="YC224", F="YC225", Ia="YC216", Ib="YC217", Ic="YC218", units=(1, 2)),
    2: dict(Uab="YC232", Ubc="YC233", Uca="YC234", P="YC235", Q="YC236", COS="YC237", F="YC238", Ia="YC229", Ib="YC230", Ic="YC231", units=(3, 4)),
}
SYSTEM_F = "YC502"
# 仍然独立起伏的驱动点：系统频率、两段母线电压、四台机组功率因数
DRIVERS = ["YC502", "YC504", "YC904", "YC515", "YC615", "YC915", "YC1015"]

EPS_UV = "max(%s, 0.001)"  # 电压/功率因数做分母时的保护：映射链首轮流算时上游可能还是 0
EPS_S = "max(sqrt(P * P + Q * Q), 0.000001)"


def _src(*pairs):
    items = ", ".join('{"device_name": "%s", "point_code": "%s", "alias": "%s"}' % (d, c, a) for d, c, a in pairs)
    return "'[%s]'" % items


def _q(s):
    return "'" + s.replace("'", "''") + "'"


def _n(x):
    return repr(float(x))


def build():
    fb_upd, p_upd, new = [], [], []  # 指令反馈 (目标点, 公式)；机组有功 (目标点, 源点 JSON, 公式)；派生映射
    for u in UNITS.values():
        clamp = "min(max(%s, 0), %d)" % (u["YS"], u["PR"])
        k = u["DEV"] / PF_HALF
        track = "min(max(%s + min(max(%s * (PF - %s), -%s), %s), 0), %d)" % (
            clamp, _n(k), _n(PF_CENTRE), _n(u["DEV"]), _n(u["DEV"]), u["PR"])   # 公式里用源点的别名 PF，不是点号
        fb_upd.append((PLC, u["FB"], clamp))   # 既有映射 #1~#4，只改公式：指令反馈 = 命令本身
        p_upd.append((NCS, u["P"], _src((PLC, u["YS"], u["YS"]), (NCS, u["PF"], "PF")), track))  # 既有映射 #5~#8：加源点与跟踪偏差
        new.append((NCS, u["Ubc"], _src((NCS, u["Uab"], "Uab")), "Uab"))
        new.append((NCS, u["Uca"], _src((NCS, u["Uab"], "Uab")), "Uab"))
        new.append((NCS, u["Q"], _src((NCS, u["P"], "P"), (NCS, u["PF"], "PF")),
                    "P * sqrt(1 / (%s * %s) - 1)" % (EPS_UV % "PF", EPS_UV % "PF")))
        current = "1000 * P / (%s * %s * %s)" % (SQ3, EPS_UV % "Uab", EPS_UV % "PF")
        for c in (u["Ia"], u["Ib"], u["Ic"]):
            new.append((NCS, c, _src((NCS, u["P"], "P"), (NCS, u["Uab"], "Uab"), (NCS, u["PF"], "PF")), current))
    for b in BUSES.values():
        ua, ub = (UNITS[k] for k in b["units"])
        # 同一段母线上的机组机端电压、母线电压是同一个电气节点：都取第一台机组的线电压
        new.append((NCS, ub["Uab"], _src((NCS, ua["Uab"], "Uab")), "Uab"))
        for c in (b["Uab"], b["Ubc"], b["Uca"]):
            new.append((NCS, c, _src((NCS, ua["Uab"], "Uab")), "Uab"))
        # 系统频率全局一致
        for u in (ua, ub):
            if u["F"] != SYSTEM_F:
                new.append((NCS, u["F"], _src((NCS, SYSTEM_F, "F")), "F"))
        new.append((NCS, b["F"], _src((NCS, SYSTEM_F, "F")), "F"))
        # 母线量 = 所挂机组量之和；母线电流、功率因数由母线 P、Q、U 推出
        new.append((NCS, b["P"], _src((NCS, ua["P"], "Pa"), (NCS, ub["P"], "Pb")), "Pa + Pb"))
        new.append((NCS, b["Q"], _src((NCS, ua["Q"], "Qa"), (NCS, ub["Q"], "Qb")), "Qa + Qb"))
        new.append((NCS, b["COS"], _src((NCS, b["P"], "P"), (NCS, b["Q"], "Q")), "P / %s" % EPS_S))
        bus_i = "1000 * sqrt(P * P + Q * Q) / (%s * %s)" % (SQ3, EPS_UV % "U")
        for c in (b["Ia"], b["Ib"], b["Ic"]):
            new.append((NCS, c, _src((NCS, b["P"], "P"), (NCS, b["Q"], "Q"), (NCS, b["Uab"], "U")), bus_i))
    return fb_upd, p_upd, new


def render():
    fb_upd, p_upd, new = build()
    targets = [t for _, t, _, _ in new]
    assert len(targets) == len(set(targets)) == 49, len(targets)
    existing = [t for _, t, _ in fb_upd] + [t for _, t, _, _ in p_upd]
    assert len(existing) == len(set(existing)) == 8, existing
    assert not set(targets) & set(existing)
    drivers = [d for d in DRIVERS if d not in targets and d not in existing]
    assert len(drivers) == len(DRIVERS), drivers

    out = []
    a = out.append
    a("-- electrical-layer-20261127.sql —— 阶段三：电气自洽层（由 gen_electrical_layer.py 生成，勿手改；请改脚本后重新生成）")
    a("-- 在 band-20261127.sql 之后执行；需要补丁⑩（映射公式支持 sqrt/abs/min/max）。")
    a("-- 内容全部是 point_yc / point_mapping 的数据：NCS 的电气量由 7 个驱动点 + 4 路派发按物理公式推出。")
    a("-- 重放安全：UPDATE 幂等，INSERT OR REPLACE 按唯一键 (device_name, target_point_code) 覆盖。回滚办法见文末。")
    a(".timeout 5000")
    a("BEGIN;")
    a("-- 1) 派生点取消带宽（不再各自独立起伏）。NCS 只保留 7 个驱动点的带宽：频率 50±0.03、")
    a("--    两段母线电压 10.5±0.08、四台机组功率因数 0.8±0.008（带宽仍来自 band-20261127.sql）")
    a("UPDATE point_yc SET min_limit=-2147480000, max_limit=2147480000")
    a(" WHERE channel_id=2 AND code NOT IN (%s);" % ", ".join(_q(c) for c in drivers))
    a("-- 2) 既有 8 条映射改公式（铭牌按一次图 D-01：6/15/15/6 MW）：")
    a("--    指令反馈（PLC YC301~307）= 派发值限制在 [Pmin=0, Pmax=铭牌]，即命令本身；")
    a("--    机组有功（NCS YC501/601/901/1001）= 限幅后的派发值 + 跟踪偏差，整体再夹在铭牌内。")
    a("--    跟踪偏差 = 机组 cosφ 驱动点偏离 0.8 的量 × K，夹在 ±DEV 内：6 MW 机组 ±0.02 MW，15 MW 机组 ±0.045 MW。")
    for dev, t, f in fb_upd:
        a("UPDATE point_mapping SET formula=%s WHERE device_name=%s AND target_point_code=%s;" % (_q(f), _q(dev), _q(t)))
    for dev, t, s, f in p_upd:
        a("UPDATE point_mapping SET source_point_codes=%s, formula=%s WHERE device_name=%s AND target_point_code=%s;" % (s, _q(f), _q(dev), _q(t)))
    a("-- 3) 新增 49 条派生映射。目标点被映射锁定：不再参与模拟，也不接受人工写值（补丁⑩）")
    for dev, t, s, f in new:
        a("INSERT OR REPLACE INTO point_mapping(device_name, target_point_code, source_point_codes, formula, enable) VALUES (%s, %s, %s, %s, 1);" % (_q(dev), _q(t), s, _q(f)))
    a("COMMIT;")
    a("-- 校验（预期 57 / 7）：")
    a("--   SELECT count(*) FROM point_mapping;")
    a("--   SELECT count(*) FROM point_yc WHERE channel_id=2 AND min_limit<max_limit AND max_limit-min_limit<=1000;")
    a("-- 回滚：")
    a("--   DELETE FROM point_mapping WHERE target_point_code NOT IN ('YC301','YC303','YC305','YC307','YC501','YC601','YC901','YC1001');")
    for u in UNITS.values():
        a("--   UPDATE point_mapping SET source_point_codes=%s, formula=%s WHERE target_point_code IN (%s, %s);"
          % (_src((PLC, u["YS"], u["YS"])), _q(u["YS"]), _q(u["FB"]), _q(u["P"])))
    a("--   然后重跑 band-20261127.sql 恢复 54 点带宽；或直接用执行前的备份覆盖 ems.db。")
    a("--   只想去掉跟踪偏差、保留其余：把 4 条机组有功映射的公式改回 min(max(YS, 0), 铭牌) 即可（源点留着不影响）。")
    return "\n".join(out) + "\n", fb_upd, p_upd, new


if __name__ == "__main__":
    text, fb_upd, p_upd, new = render()
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "electrical-layer-20261127.sql")
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    print("wrote %s | feedback mappings: %d | unit power mappings: %d | new mappings: %d" % (path, len(fb_upd), len(p_upd), len(new)))
