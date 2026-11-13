import json
from pathlib import Path

import openpyxl

HERE = Path(__file__).resolve().parent
D = json.loads((HERE / "points.json").read_text(encoding="utf-8"))

YC_HEAD = ["测点编码", "测点名称", "从机地址", "寄存器地址", "功能码", "解析码", "乘系数", "加系数", "上限值", "下限值"]
YX_HEAD = ["测点编码", "测点名称", "从机地址", "寄存器地址", "功能码", "解析码", "位偏移", "是否反转"]
YK_HEAD = ["测点编码", "测点名称", "从机地址", "寄存器地址", "功能码", "解析码", "位偏移", "命令类型", "关联遥信编码"]
YT_HEAD = ["测点编码", "测点名称", "从机地址", "寄存器地址", "功能码", "解析码", "乘系数", "加系数", "上限值", "下限值", "关联遥测编码"]
SHEETS = ["遥测", "遥信", "遥控", "遥调"]


def new_wb(rows_by_sheet):
    wb = openpyxl.Workbook()
    wb.remove(wb.active)
    for name in SHEETS:
        ws = wb.create_sheet(name)
        rows = rows_by_sheet.get(name, [])
        head = {"遥测": YC_HEAD, "遥信": YX_HEAD, "遥控": YK_HEAD, "遥调": YT_HEAD}[name]
        ws.append(head)
        for r in rows:
            ws.append(r)
    return wb


def gen_modbus():
    d = D["modbus_server_plc"]
    yc_fb = {1: "YC301", 4: "YC303", 6: "YC305", 7: "YC307"}  # ys path -> 指令反馈 yc
    rows = {
        "遥测": [
            [f"YC{p['yc_num']}", p["name"], 1, str(p["path"]), 4, "FLOAT32_ABCD", 1.0, 0.0, None, None]
            for p in d["yc"]
        ],
        "遥信": [
            [f"YX{p['yx_num']}", p["name"], 1, str(p["path"]), 2, "UINT16_AB", 0, 0]
            for p in d["yx"]
        ],
        "遥控": [
            [f"YK{p['yk_num']}", p["name"], 1, str(p["path"]), 5, "UINT16_AB", 0, 0, ""]
            for p in d["yk"]
        ],
        "遥调": [
            [f"YS{p['ys_num']}", p["name"], 1, str(p["path"]), 6, "FLOAT32_ABCD", 1.0, 0.0, None, None,
             yc_fb.get(p["path"], "")]
            for p in d["ys"]
        ],
    }
    wb = new_wb(rows)
    wb.save(HERE / "modbus_plc.xlsx")
    return {k: len(v) for k, v in rows.items()}


def gen_104_server():
    d = D["iec104_server_ncs"]
    ca = d["common_address"]
    rows = {
        "遥测": [
            [f"YC{p['yc_num']}", p["name"], ca, str(p["ioa"]), 0, "", 1.0, 0.0, None, None, "M_ME_NC_1"]
            for p in d["yc"]
        ],
        "遥信": [
            [f"YX{p['yx_num']}", p["name"], ca, str(p["ioa"]), 0, "", 0, 0, "M_SP_NA_1"]
            for p in d["yx"]
        ],
    }
    wb = new_wb(rows)
    wb.save(HERE / "iec104_ncs_server.xlsx")
    return {k: len(v) for k, v in rows.items()}


def gen_104_client():
    d = D["iec104_client_master_zhu"]
    ca = d["common_address"]
    rows = {
        "遥测": [
            [f"YC{p['yc_num']}", p["name"], ca, str(p["ioa"]), 0, "", 1.0, 0.0, None, None, "M_ME_NC_1"]
            for p in d["yc"]
        ],
        "遥信": [
            [f"YX{p['yx_num']}", p["name"], ca, str(p["ioa"]), 0, "", 0, 0, "M_SP_NA_1"]
            for p in d["yx"]
        ],
        "遥调": [
            [f"YS{p['ys_num']}", p["name"], ca, str(p["ioa"]), 0, "", p.get("coefficient", 1.0), 0.0,
             None, None, "", "C_SE_NC_1"]
            for p in d["ys"]
        ],
    }
    wb = new_wb(rows)
    wb.save(HERE / "iec104_master_client.xlsx")
    return {k: len(v) for k, v in rows.items()}


for name, fn in [("modbus_plc.xlsx", gen_modbus), ("iec104_ncs_server.xlsx", gen_104_server),
                 ("iec104_master_client.xlsx", gen_104_client)]:
    print(name, fn())
