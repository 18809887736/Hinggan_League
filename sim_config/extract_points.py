import json
import re
import sys
from pathlib import Path

SQL = Path(__file__).resolve().parent.parent / "main.sql"


def split_values(s):
    out, cur, in_str = [], [], False
    i = 0
    while i < len(s):
        c = s[i]
        if in_str:
            if c == "'":
                if i + 1 < len(s) and s[i + 1] == "'":
                    cur.append("'")
                    i += 2
                    continue
                in_str = False
            else:
                cur.append(c)
        else:
            if c == "'":
                in_str = True
            elif c == ",":
                out.append("".join(cur).strip())
                cur = []
            else:
                cur.append(c)
        i += 1
    out.append("".join(cur).strip())
    return out


def parse_inserts(text):
    rows = {}
    for m in re.finditer(r'INSERT INTO "(\w+)" VALUES \((.*?)\);', text):
        rows.setdefault(m.group(1), []).append(split_values(m.group(2)))
    return rows


def to_int(v):
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return None


def main():
    text = SQL.read_text(encoding="utf-8", errors="replace")
    rows = parse_inserts(text)

    yc_names = {to_int(r[0]): r[1] for r in rows.get("yc_data", [])}
    yx_names = {to_int(r[0]): r[1] for r in rows.get("YX_DATA", [])}
    yk_names = {to_int(r[0]): r[1] for r in rows.get("YK_DATA", [])}
    ys_names = {to_int(r[0]): r[1] for r in rows.get("YS_DATA", [])}

    def modbus_points(ch):
        yc = [
            {"path": to_int(r[4]), "yc_num": to_int(r[5]), "name": yc_names.get(to_int(r[5]), "?")}
            for r in rows.get("CHUNNEL_YC", []) if to_int(r[1]) == ch
        ]
        yx = [
            {"path": to_int(r[4]), "yx_num": to_int(r[5]), "name": yx_names.get(to_int(r[5]), "?")}
            for r in rows.get("CHUNNEL_YX", []) if to_int(r[1]) == ch
        ]
        yk = [
            {"path": to_int(r[4]), "yk_num": to_int(r[8]), "name": yk_names.get(to_int(r[8]), "?")}
            for r in rows.get("CHUNNEL_YK", []) if to_int(r[1]) == ch
        ]
        ys = [
            {"path": to_int(r[4]), "ys_num": to_int(r[5]), "name": ys_names.get(to_int(r[5]), "?"),
             "coefficient": float(r[6]) if r[6] else 1.0}
            for r in rows.get("CHUNNEL_YS", []) if to_int(r[1]) == ch
        ]
        for lst in (yc, yx, yk, ys):
            lst.sort(key=lambda p: (p.get("path") is None, p.get("path")))
        return {"yc": yc, "yx": yx, "yk": yk, "ys": ys}

    def iec104_points(ch):
        yc = [
            {"ioa": to_int(r[4]), "yc_num": to_int(r[5]), "name": yc_names.get(to_int(r[5]), "?")}
            for r in rows.get("CHUNNEL_YC", []) if to_int(r[1]) == ch
        ]
        yx = [
            {"ioa": to_int(r[4]), "yx_num": to_int(r[5]), "name": yx_names.get(to_int(r[5]), "?")}
            for r in rows.get("CHUNNEL_YX", []) if to_int(r[1]) == ch
        ]
        ys = [
            {"ioa": to_int(r[4]), "ys_num": to_int(r[5]), "name": ys_names.get(to_int(r[5]), "?"),
             "coefficient": float(r[6]) if r[6] else 1.0}
            for r in rows.get("CHUNNEL_YS", []) if to_int(r[1]) == ch
        ]
        for lst in (yc, yx, ys):
            lst.sort(key=lambda p: (p.get("ioa") is None, p.get("ioa")))
        return {"yc": yc, "yx": yx, "yk": [], "ys": ys}

    result = {
        "modbus_server_plc": {"chunnel": 4, "slave_id": 1, "port": 502, **modbus_points(4)},
        "iec104_server_ncs": {"chunnel": 1, "common_address": 257, "port": 2404, **iec104_points(1)},
        "iec104_client_master_zhu": {"chunnel": 0, "common_address": 257, "remote_port": 2404, **iec104_points(0)},
        "iec104_client_master_bei": {"chunnel": 5, "common_address": 257, "remote_port": 2404, **iec104_points(5)},
    }

    out = Path(__file__).resolve().parent / "points.json"
    out.write_text(json.dumps(result, ensure_ascii=False, indent=1), encoding="utf-8")
    for dev, d in result.items():
        print(f"{dev}: yc={len(d['yc'])} yx={len(d['yx'])} yk={len(d['yk'])} ys={len(d['ys'])}")
        missing = [p for lst in (d["yc"], d["yx"], d["yk"], d["ys"]) for p in lst if p.get("name") == "?"]
        if missing:
            print(f"  !! {len(missing)} 点无名称: {missing[:5]}")
    print(f"written: {out}")


if __name__ == "__main__":
    sys.exit(main())
