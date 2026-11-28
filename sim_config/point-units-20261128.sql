UPDATE point_yc SET unit='MW'   WHERE code IN ('YC222','YC235','YC501','YC601','YC901','YC1001',   -- NCS：母线、机组有功
                                             'YC301','YC303','YC305','YC307',                     -- PLC：指令反馈
                                             'YC512','YC612','YC912','YC1012',                     -- PLC：上限
                                             'YC513','YC613','YC913','YC1013',                     -- PLC：下限
                                             'YC101','YC103');                                     -- 主站
UPDATE point_yc SET unit='Mvar' WHERE code IN ('YC223','YC236','YC503','YC603','YC903','YC1003');
UPDATE point_yc SET unit='kV'   WHERE code IN ('YC219','YC220','YC221','YC232','YC233','YC234',
                                             'YC504','YC505','YC506','YC604','YC605','YC606',
                                             'YC904','YC905','YC906','YC1004','YC1005','YC1006');
UPDATE point_yc SET unit='A'    WHERE code IN ('YC216','YC217','YC218','YC229','YC230','YC231',
                                             'YC507','YC508','YC509','YC607','YC608','YC609',
                                             'YC907','YC908','YC909','YC1007','YC1008','YC1009');
UPDATE point_yc SET unit='Hz'   WHERE code IN ('YC225','YC238','YC502','YC602','YC902','YC1002');
UPDATE point_yc SET unit='—'    WHERE code IN ('YC224','YC237','YC515','YC615','YC915','YC1015');   -- 功率因数：无量纲（U4）
-- 调节速度（U1，r5 裁定 MW/min）：单位按图纸"机组响应速率"（端子排点表 51 行、接线图）；
-- 注意：数值 3.5/4.0（INT16 后 3/4）借自 DUT generator_agc.singleMaxDeltaP（单步上限，量纲 MW），
-- 与本单位的物理含义不一致，待 DCS 侧 4-20mA 量程确认后再定是否重设数值
UPDATE point_yc SET unit='MW/min' WHERE code IN ('YC514','YC614','YC914','YC1014');

-- 校验：期望 MW=20、Mvar=6、kV=18、A=18、Hz=6、—=6、MW/min=4、空=0（合计 78）
SELECT unit, COUNT(*) FROM point_yc GROUP BY unit;
