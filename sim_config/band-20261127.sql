-- 机组容量按一次图 D-01：1#=6、2#=15、3#=15、4#=6 MW（2026-11-27 裁定，D7）；3#、4# 的点按此取值
-- 在跑实例可能正持有写锁（WAL 下读写并行，但同一时刻只能有一个写者）：等 5 s 再报 "database is locked"
.timeout 5000
BEGIN;
UPDATE point_yc SET min_limit=49.97, max_limit=50.03 WHERE code IN ('YC502','YC602','YC902','YC1002','YC225','YC238');
UPDATE point_yc SET min_limit=4.3, max_limit=4.7 WHERE code IN ('YC503','YC1003','YC223');
UPDATE point_yc SET min_limit=10.95, max_limit=11.55 WHERE code IN ('YC603','YC903','YC236');
UPDATE point_yc SET min_limit=10.42, max_limit=10.58 WHERE code IN ('YC504','YC505','YC506','YC604','YC605','YC606','YC904','YC905','YC906','YC1004','YC1005','YC1006','YC219','YC220','YC221','YC232','YC233','YC234');
UPDATE point_yc SET min_limit=409.4, max_limit=415.4 WHERE code IN ('YC507','YC508','YC509','YC1007','YC1008','YC1009','YC216','YC217','YC218');
UPDATE point_yc SET min_limit=1023.1, max_limit=1039.1 WHERE code IN ('YC607','YC608','YC609','YC907','YC908','YC909','YC229','YC230','YC231');
UPDATE point_yc SET min_limit=0.792, max_limit=0.808 WHERE code IN ('YC515','YC615','YC915','YC1015','YC224','YC237');
UPDATE point_yc SET min_limit=77.695, max_limit=77.705 WHERE code='YC222';
UPDATE point_yc SET min_limit=-0.005, max_limit=0.005 WHERE code='YC235';
UPDATE point_yc SET min_limit=6.2, max_limit=6.8 WHERE code IN ('YC512','YC1012');
UPDATE point_yc SET min_limit=15.2, max_limit=15.8 WHERE code IN ('YC612','YC912');
UPDATE point_yc SET min_limit=0.2, max_limit=0.8 WHERE code IN ('YC513','YC613','YC913','YC1013');
UPDATE point_yc SET min_limit=3.2, max_limit=3.8 WHERE code IN ('YC514','YC1014');
UPDATE point_yc SET min_limit=4.2, max_limit=4.8 WHERE code IN ('YC614','YC914');
-- 功率点限值是 11-17 按 DUT 表设的（[0,6]/[0,15]），3#、4# 按一次图对调；阶段三会把功率点改成宽限值，限幅改由映射公式做
UPDATE point_yc SET min_limit=0, max_limit=15 WHERE code='YC901';
UPDATE point_yc SET min_limit=0, max_limit=6 WHERE code='YC1001';
COMMIT;
