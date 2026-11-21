# 一次性迁移：mysql84(net) -> SQLite ems.db
# 用法：在有 SQLAlchemy+pymysql 的环境跑（实配为 10.0.0.9 的 ems-simulate 容器内），
#       产物 /tmp/ems.db 拷回。表结构用反射从 MySQL 现库取，行按 sorted_tables 拓扑序拷入。
import os
from sqlalchemy import create_engine, MetaData, insert, text
from sqlalchemy.types import Boolean, SmallInteger, Integer, Float, String, Text

MYSQL_URL = "mysql+pymysql://root:syth7777@10.0.0.9:3306/net?charset=utf8mb4"
SQLITE_PATH = "/tmp/ems.db"

if os.path.exists(SQLITE_PATH):
    os.remove(SQLITE_PATH)

src = create_engine(MYSQL_URL)
dst = create_engine(f"sqlite:///{SQLITE_PATH}")

md = MetaData()
md.reflect(bind=src)

# MySQL 方言类型转通用类型，否则 create_all 到 SQLite 报 can't render TINYINT 等
def to_generic(t):
    try:
        g = t.as_generic()
        if not type(g).__module__.startswith("sqlalchemy.dialects"):
            return g
    except Exception:
        pass
    n = type(t).__name__.upper()
    if n == "TINYINT":
        return Boolean() if (getattr(t, "display_width", None) or 1) == 1 else SmallInteger()
    if n == "MEDIUMINT":
        return Integer()
    if n in ("MEDIUMTEXT", "LONGTEXT", "TINYTEXT"):
        return Text()
    if n in ("DOUBLE", "FLOAT"):
        return Float()
    if n in ("ENUM", "SET"):
        return String(255)
    if n == "BIT":
        return Boolean()
    return Text()

for table in md.tables.values():
    for col in table.columns:
        if type(col.type).__module__.startswith("sqlalchemy.dialects"):
            col.type = to_generic(col.type)

# MySQL utf8mb4_0900_ai_ci 不区分大小写，SQLite 默认区分——按名/按码查找列加 NOCASE 对齐行为
# （Text 是 String 子类，collation 直接设即可，不换类型避免长度截断）
NOCASE_COLS = {"code", "name", "device_name", "target_point_code", "source_point_codes"}
for table in md.tables.values():
    for col in table.columns:
        if col.name in NOCASE_COLS and isinstance(col.type, String):
            col.type.collation = "NOCASE"

# connection_session 是运行态数据：表结构保留（应用要写），行不拷
SKIP_COPY = {"connection_session"}

md.create_all(bind=dst)

copied = {}
with dst.begin() as conn:
    for table in md.sorted_tables:
        if table.name in SKIP_COPY:
            copied[table.name] = 0
            continue
        with src.connect() as cs:
            rows = [dict(r._mapping) for r in cs.execute(table.select())]
        if rows:
            conn.execute(insert(table), rows)
        copied[table.name] = len(rows)

print("=== 逐表对账（mysql / sqlite）===")
ok = True
with dst.connect() as cd, src.connect() as cs:
    for t in md.sorted_tables:
        m = 0 if t.name in SKIP_COPY else cs.execute(text(f"SELECT COUNT(*) FROM `{t.name}`")).scalar()
        s = cd.execute(text(f"SELECT COUNT(*) FROM `{t.name}`")).scalar()
        status = "OK" if m == s else "!! MISMATCH"
        if m != s:
            ok = False
        print(f"{t.name:28s} {m:6d} {s:6d} {status}")

fk_violations = []
with dst.connect() as cd:
    fk_violations = cd.execute(text("PRAGMA foreign_key_check")).fetchall()
print("外键检查:", "OK" if not fk_violations else fk_violations[:10])
with dst.connect() as cd:
    cd.execute(text("PRAGMA wal_checkpoint(TRUNCATE)"))
print("关键计数: device=%d point_mapping=%d point_yc=%d" % (
    copied.get("device", 0), copied.get("point_mapping", 0), copied.get("point_yc", 0)))
print("RESULT:", "ALL OK" if ok and not fk_violations else "FAILED")
