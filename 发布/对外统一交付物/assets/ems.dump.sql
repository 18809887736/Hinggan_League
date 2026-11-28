PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE device_group (
	id INTEGER NOT NULL, 
	code VARCHAR(32) COLLATE "NOCASE" NOT NULL, 
	name VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	parent_id INTEGER, 
	description VARCHAR(256), 
	status INTEGER DEFAULT '0' NOT NULL, 
	enable INTEGER DEFAULT '1' NOT NULL, 
	created_at DATETIME DEFAULT (now()) NOT NULL, 
	updated_at DATETIME DEFAULT (now()) NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT device_group_ibfk_1 FOREIGN KEY(parent_id) REFERENCES device_group (id)
);
INSERT INTO device_group VALUES(1,'XAM_AVC','兴安盟AVC仿真',NULL,'qplantagc 对端仿真（被测端=麒麟VM 10.0.0.194）',0,1,'2026-11-12 08:17:49.000000','2026-11-12 08:17:49.000000');
CREATE TABLE iec61850_model_project (
	id VARCHAR(36) NOT NULL, 
	name VARCHAR(128) COLLATE "NOCASE" NOT NULL, 
	code VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	description VARCHAR(512) NOT NULL, 
	file_type VARCHAR(16) NOT NULL, 
	standard_version VARCHAR(32) NOT NULL, 
	namespace VARCHAR(256) NOT NULL, 
	modeling_mode VARCHAR(32) NOT NULL, 
	status VARCHAR(16) NOT NULL, 
	revision INTEGER NOT NULL, 
	validation_errors INTEGER NOT NULL, 
	validation_warnings INTEGER NOT NULL, 
	model_json VARCHAR NOT NULL, 
	model_format_version INTEGER NOT NULL, 
	model_node_count INTEGER NOT NULL, 
	model_checksum VARCHAR(64) NOT NULL, 
	created_at DATETIME DEFAULT (now()) NOT NULL, 
	updated_at DATETIME DEFAULT (now()) NOT NULL, 
	PRIMARY KEY (id)
);
CREATE TABLE point_mapping (
	id INTEGER NOT NULL, 
	device_name VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	target_point_code VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	source_point_codes TEXT COLLATE "NOCASE" NOT NULL, 
	formula TEXT NOT NULL, 
	enable INTEGER DEFAULT '1' NOT NULL, 
	PRIMARY KEY (id)
);
INSERT INTO point_mapping VALUES(1,'PLC-仿真','YC301','[{"device_name": "PLC-\u4eff\u771f", "point_code": "YS1", "alias": "YS1"}]','min(max(YS1, 0), 6)',1);
INSERT INTO point_mapping VALUES(2,'PLC-仿真','YC303','[{"device_name": "PLC-\u4eff\u771f", "point_code": "YS4", "alias": "YS4"}]','min(max(YS4, 0), 15)',1);
INSERT INTO point_mapping VALUES(3,'PLC-仿真','YC305','[{"device_name": "PLC-\u4eff\u771f", "point_code": "YS6", "alias": "YS6"}]','min(max(YS6, 0), 15)',1);
INSERT INTO point_mapping VALUES(4,'PLC-仿真','YC307','[{"device_name": "PLC-\u4eff\u771f", "point_code": "YS7", "alias": "YS7"}]','min(max(YS7, 0), 6)',1);
INSERT INTO point_mapping VALUES(5,'NCS-仿真','YC501','[{"device_name": "PLC-仿真", "point_code": "YS1", "alias": "YS1"}, {"device_name": "NCS-仿真", "point_code": "YC515", "alias": "PF"}]','min(max(min(max(YS1, 0), 6) + min(max(2.5 * (PF - 0.8), -0.02), 0.02), 0), 6)',1);
INSERT INTO point_mapping VALUES(6,'NCS-仿真','YC601','[{"device_name": "PLC-仿真", "point_code": "YS4", "alias": "YS4"}, {"device_name": "NCS-仿真", "point_code": "YC615", "alias": "PF"}]','min(max(min(max(YS4, 0), 15) + min(max(5.625 * (PF - 0.8), -0.045), 0.045), 0), 15)',1);
INSERT INTO point_mapping VALUES(7,'NCS-仿真','YC901','[{"device_name": "PLC-仿真", "point_code": "YS6", "alias": "YS6"}, {"device_name": "NCS-仿真", "point_code": "YC915", "alias": "PF"}]','min(max(min(max(YS6, 0), 15) + min(max(5.625 * (PF - 0.8), -0.045), 0.045), 0), 15)',1);
INSERT INTO point_mapping VALUES(8,'NCS-仿真','YC1001','[{"device_name": "PLC-仿真", "point_code": "YS7", "alias": "YS7"}, {"device_name": "NCS-仿真", "point_code": "YC1015", "alias": "PF"}]','min(max(min(max(YS7, 0), 6) + min(max(2.5 * (PF - 0.8), -0.02), 0.02), 0), 6)',1);
INSERT INTO point_mapping VALUES(58,'NCS-仿真','YC505','[{"device_name": "NCS-仿真", "point_code": "YC504", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(59,'NCS-仿真','YC506','[{"device_name": "NCS-仿真", "point_code": "YC504", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(60,'NCS-仿真','YC503','[{"device_name": "NCS-仿真", "point_code": "YC501", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC515", "alias": "PF"}]','P * sqrt(1 / (max(PF, 0.001) * max(PF, 0.001)) - 1)',1);
INSERT INTO point_mapping VALUES(61,'NCS-仿真','YC507','[{"device_name": "NCS-仿真", "point_code": "YC501", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC504", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC515", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(62,'NCS-仿真','YC508','[{"device_name": "NCS-仿真", "point_code": "YC501", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC504", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC515", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(63,'NCS-仿真','YC509','[{"device_name": "NCS-仿真", "point_code": "YC501", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC504", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC515", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(64,'NCS-仿真','YC605','[{"device_name": "NCS-仿真", "point_code": "YC604", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(65,'NCS-仿真','YC606','[{"device_name": "NCS-仿真", "point_code": "YC604", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(66,'NCS-仿真','YC603','[{"device_name": "NCS-仿真", "point_code": "YC601", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC615", "alias": "PF"}]','P * sqrt(1 / (max(PF, 0.001) * max(PF, 0.001)) - 1)',1);
INSERT INTO point_mapping VALUES(67,'NCS-仿真','YC607','[{"device_name": "NCS-仿真", "point_code": "YC601", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC604", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC615", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(68,'NCS-仿真','YC608','[{"device_name": "NCS-仿真", "point_code": "YC601", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC604", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC615", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(69,'NCS-仿真','YC609','[{"device_name": "NCS-仿真", "point_code": "YC601", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC604", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC615", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(70,'NCS-仿真','YC905','[{"device_name": "NCS-仿真", "point_code": "YC904", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(71,'NCS-仿真','YC906','[{"device_name": "NCS-仿真", "point_code": "YC904", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(72,'NCS-仿真','YC903','[{"device_name": "NCS-仿真", "point_code": "YC901", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC915", "alias": "PF"}]','P * sqrt(1 / (max(PF, 0.001) * max(PF, 0.001)) - 1)',1);
INSERT INTO point_mapping VALUES(73,'NCS-仿真','YC907','[{"device_name": "NCS-仿真", "point_code": "YC901", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC904", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC915", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(74,'NCS-仿真','YC908','[{"device_name": "NCS-仿真", "point_code": "YC901", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC904", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC915", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(75,'NCS-仿真','YC909','[{"device_name": "NCS-仿真", "point_code": "YC901", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC904", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC915", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(76,'NCS-仿真','YC1005','[{"device_name": "NCS-仿真", "point_code": "YC1004", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(77,'NCS-仿真','YC1006','[{"device_name": "NCS-仿真", "point_code": "YC1004", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(78,'NCS-仿真','YC1003','[{"device_name": "NCS-仿真", "point_code": "YC1001", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC1015", "alias": "PF"}]','P * sqrt(1 / (max(PF, 0.001) * max(PF, 0.001)) - 1)',1);
INSERT INTO point_mapping VALUES(79,'NCS-仿真','YC1007','[{"device_name": "NCS-仿真", "point_code": "YC1001", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC1004", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC1015", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(80,'NCS-仿真','YC1008','[{"device_name": "NCS-仿真", "point_code": "YC1001", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC1004", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC1015", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(81,'NCS-仿真','YC1009','[{"device_name": "NCS-仿真", "point_code": "YC1001", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC1004", "alias": "Uab"}, {"device_name": "NCS-仿真", "point_code": "YC1015", "alias": "PF"}]','1000 * P / (1.7320508075688772 * max(Uab, 0.001) * max(PF, 0.001))',1);
INSERT INTO point_mapping VALUES(82,'NCS-仿真','YC604','[{"device_name": "NCS-仿真", "point_code": "YC504", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(83,'NCS-仿真','YC219','[{"device_name": "NCS-仿真", "point_code": "YC504", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(84,'NCS-仿真','YC220','[{"device_name": "NCS-仿真", "point_code": "YC504", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(85,'NCS-仿真','YC221','[{"device_name": "NCS-仿真", "point_code": "YC504", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(86,'NCS-仿真','YC602','[{"device_name": "NCS-仿真", "point_code": "YC502", "alias": "F"}]','F',1);
INSERT INTO point_mapping VALUES(87,'NCS-仿真','YC225','[{"device_name": "NCS-仿真", "point_code": "YC502", "alias": "F"}]','F',1);
INSERT INTO point_mapping VALUES(88,'NCS-仿真','YC222','[{"device_name": "NCS-仿真", "point_code": "YC501", "alias": "Pa"}, {"device_name": "NCS-仿真", "point_code": "YC601", "alias": "Pb"}]','Pa + Pb',1);
INSERT INTO point_mapping VALUES(89,'NCS-仿真','YC223','[{"device_name": "NCS-仿真", "point_code": "YC503", "alias": "Qa"}, {"device_name": "NCS-仿真", "point_code": "YC603", "alias": "Qb"}]','Qa + Qb',1);
INSERT INTO point_mapping VALUES(90,'NCS-仿真','YC224','[{"device_name": "NCS-仿真", "point_code": "YC222", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC223", "alias": "Q"}]','P / max(sqrt(P * P + Q * Q), 0.000001)',1);
INSERT INTO point_mapping VALUES(91,'NCS-仿真','YC216','[{"device_name": "NCS-仿真", "point_code": "YC222", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC223", "alias": "Q"}, {"device_name": "NCS-仿真", "point_code": "YC219", "alias": "U"}]','1000 * sqrt(P * P + Q * Q) / (1.7320508075688772 * max(U, 0.001))',1);
INSERT INTO point_mapping VALUES(92,'NCS-仿真','YC217','[{"device_name": "NCS-仿真", "point_code": "YC222", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC223", "alias": "Q"}, {"device_name": "NCS-仿真", "point_code": "YC219", "alias": "U"}]','1000 * sqrt(P * P + Q * Q) / (1.7320508075688772 * max(U, 0.001))',1);
INSERT INTO point_mapping VALUES(93,'NCS-仿真','YC218','[{"device_name": "NCS-仿真", "point_code": "YC222", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC223", "alias": "Q"}, {"device_name": "NCS-仿真", "point_code": "YC219", "alias": "U"}]','1000 * sqrt(P * P + Q * Q) / (1.7320508075688772 * max(U, 0.001))',1);
INSERT INTO point_mapping VALUES(94,'NCS-仿真','YC1004','[{"device_name": "NCS-仿真", "point_code": "YC904", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(95,'NCS-仿真','YC232','[{"device_name": "NCS-仿真", "point_code": "YC904", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(96,'NCS-仿真','YC233','[{"device_name": "NCS-仿真", "point_code": "YC904", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(97,'NCS-仿真','YC234','[{"device_name": "NCS-仿真", "point_code": "YC904", "alias": "Uab"}]','Uab',1);
INSERT INTO point_mapping VALUES(98,'NCS-仿真','YC902','[{"device_name": "NCS-仿真", "point_code": "YC502", "alias": "F"}]','F',1);
INSERT INTO point_mapping VALUES(99,'NCS-仿真','YC1002','[{"device_name": "NCS-仿真", "point_code": "YC502", "alias": "F"}]','F',1);
INSERT INTO point_mapping VALUES(100,'NCS-仿真','YC238','[{"device_name": "NCS-仿真", "point_code": "YC502", "alias": "F"}]','F',1);
INSERT INTO point_mapping VALUES(101,'NCS-仿真','YC235','[{"device_name": "NCS-仿真", "point_code": "YC901", "alias": "Pa"}, {"device_name": "NCS-仿真", "point_code": "YC1001", "alias": "Pb"}]','Pa + Pb',1);
INSERT INTO point_mapping VALUES(102,'NCS-仿真','YC236','[{"device_name": "NCS-仿真", "point_code": "YC903", "alias": "Qa"}, {"device_name": "NCS-仿真", "point_code": "YC1003", "alias": "Qb"}]','Qa + Qb',1);
INSERT INTO point_mapping VALUES(103,'NCS-仿真','YC237','[{"device_name": "NCS-仿真", "point_code": "YC235", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC236", "alias": "Q"}]','P / max(sqrt(P * P + Q * Q), 0.000001)',1);
INSERT INTO point_mapping VALUES(104,'NCS-仿真','YC229','[{"device_name": "NCS-仿真", "point_code": "YC235", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC236", "alias": "Q"}, {"device_name": "NCS-仿真", "point_code": "YC232", "alias": "U"}]','1000 * sqrt(P * P + Q * Q) / (1.7320508075688772 * max(U, 0.001))',1);
INSERT INTO point_mapping VALUES(105,'NCS-仿真','YC230','[{"device_name": "NCS-仿真", "point_code": "YC235", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC236", "alias": "Q"}, {"device_name": "NCS-仿真", "point_code": "YC232", "alias": "U"}]','1000 * sqrt(P * P + Q * Q) / (1.7320508075688772 * max(U, 0.001))',1);
INSERT INTO point_mapping VALUES(106,'NCS-仿真','YC231','[{"device_name": "NCS-仿真", "point_code": "YC235", "alias": "P"}, {"device_name": "NCS-仿真", "point_code": "YC236", "alias": "Q"}, {"device_name": "NCS-仿真", "point_code": "YC232", "alias": "U"}]','1000 * sqrt(P * P + Q * Q) / (1.7320508075688772 * max(U, 0.001))',1);
CREATE TABLE device (
	id INTEGER NOT NULL, 
	code VARCHAR(32) COLLATE "NOCASE" NOT NULL, 
	name VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	device_type INTEGER DEFAULT '0' NOT NULL, 
	group_id INTEGER, 
	enable INTEGER DEFAULT '1' NOT NULL, 
	created_at DATETIME DEFAULT (now()) NOT NULL, 
	updated_at DATETIME DEFAULT (now()) NOT NULL, 
	icd_path VARCHAR(512), 
	icd_file_hash VARCHAR(64), 
	PRIMARY KEY (id), 
	CONSTRAINT device_ibfk_1 FOREIGN KEY(group_id) REFERENCES device_group (id)
);
INSERT INTO device VALUES(1,'PLC_SVR','PLC-仿真',0,1,1,'2026-11-12 08:17:49.000000','2026-11-12 08:17:49.000000',NULL,NULL);
INSERT INTO device VALUES(2,'NCS_SVR','NCS-仿真',0,1,1,'2026-11-12 08:17:50.000000','2026-11-12 08:17:50.000000',NULL,NULL);
INSERT INTO device VALUES(3,'MASTER_CLI','主站-仿真',0,1,1,'2026-11-12 08:17:50.000000','2026-11-12 08:17:50.000000',NULL,NULL);
CREATE TABLE iec61850_model_version (
	id VARCHAR(36) NOT NULL, 
	project_id VARCHAR(36) NOT NULL, 
	version_number INTEGER NOT NULL, 
	label VARCHAR(128) NOT NULL, 
	description VARCHAR(512) NOT NULL, 
	status VARCHAR(16) NOT NULL, 
	source_revision INTEGER NOT NULL, 
	snapshot_json VARCHAR NOT NULL, 
	created_at DATETIME DEFAULT (now()) NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT iec61850_model_version_ibfk_1 FOREIGN KEY(project_id) REFERENCES iec61850_model_project (id) ON DELETE CASCADE
);
CREATE TABLE channel (
	id INTEGER NOT NULL, 
	code VARCHAR(32) COLLATE "NOCASE" NOT NULL, 
	name VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	device_id INTEGER, 
	protocol_type INTEGER DEFAULT '1' NOT NULL, 
	conn_type INTEGER DEFAULT '1' NOT NULL, 
	ip VARCHAR(32), 
	port INTEGER, 
	com_port VARCHAR(16), 
	baud_rate INTEGER DEFAULT '9600', 
	data_bits INTEGER DEFAULT '8', 
	stop_bits INTEGER DEFAULT '1', 
	parity VARCHAR(1) DEFAULT 'N', 
	rtu_addr VARCHAR(16) DEFAULT '1' NOT NULL, 
	timeout INTEGER DEFAULT '5' NOT NULL, 
	enable INTEGER DEFAULT '1' NOT NULL, 
	change_tracking_enabled INTEGER DEFAULT '0' NOT NULL, 
	dlt645_point_mode VARCHAR(16) DEFAULT 'import' NOT NULL, 
	dlt698_point_mode VARCHAR(16) DEFAULT 'import' NOT NULL, 
	model_name VARCHAR(128), 
	icd_path VARCHAR(512), 
	icd_file_hash VARCHAR(64), 
	PRIMARY KEY (id), 
	CONSTRAINT channel_ibfk_1 FOREIGN KEY(device_id) REFERENCES device (id)
);
INSERT INTO channel VALUES(1,'PLC_SVR','PLC-仿真',1,1,2,'0.0.0.0',502,NULL,9600,8,1,'N','1',5,1,0,'import','import',NULL,NULL,NULL);
INSERT INTO channel VALUES(2,'NCS_SVR','NCS-仿真',2,2,2,'0.0.0.0',2404,NULL,9600,8,1,'N','1',5,1,0,'import','import',NULL,NULL,NULL);
INSERT INTO channel VALUES(3,'MASTER_CLI','主站-仿真',3,2,1,'10.0.0.194',2404,NULL,9600,8,1,'N','1',5,1,0,'import','import',NULL,NULL,NULL);
CREATE TABLE channel_protocol_params (
	channel_id INTEGER NOT NULL, 
	protocol_type INTEGER NOT NULL, 
	conn_type INTEGER NOT NULL, 
	schema_version INTEGER DEFAULT '1' NOT NULL, 
	params_json JSON NOT NULL, 
	created_at DATETIME DEFAULT (now()) NOT NULL, 
	updated_at DATETIME DEFAULT (now()) NOT NULL, 
	PRIMARY KEY (channel_id), 
	CONSTRAINT channel_protocol_params_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id)
);
INSERT INTO channel_protocol_params VALUES(1,1,2,1,'{"max_connections": 0, "client_idle_timeout_ms": 0}','2026-11-12 08:17:49.000000','2026-11-12 08:17:49.000000');
INSERT INTO channel_protocol_params VALUES(2,2,2,1,'{"t0_timeout_s": 10, "t1_timeout_s": 15, "t2_timeout_s": 10, "t3_interval_s": 20, "max_connections": 0, "send_window_size": 12, "receive_window_size": 8}','2026-11-12 08:17:50.000000','2026-11-12 08:17:50.000000');
INSERT INTO channel_protocol_params VALUES(3,2,1,1,'{"t0_timeout_s": 10, "t1_timeout_s": 15, "t2_timeout_s": 10, "t3_interval_s": 20, "send_window_size": 12, "originator_address": 0, "receive_window_size": 8, "clock_sync_interval_s": 0, "reconnect_max_attempts": 0, "reconnect_max_interval_ms": 30000, "reconnect_initial_interval_ms": 2000, "counter_interrogation_interval_s": 0, "counter_interrogation_on_connect": false, "general_interrogation_interval_s": 0, "general_interrogation_on_connect": true}','2026-11-12 08:17:50.000000','2026-11-12 08:17:50.000000');
CREATE TABLE channel_security_config (
	channel_id INTEGER NOT NULL, 
	tls_enabled INTEGER DEFAULT '0' NOT NULL, 
	tls_mode VARCHAR(16) DEFAULT 'one_way' NOT NULL, 
	tls_version VARCHAR(16) DEFAULT '1.2' NOT NULL, 
	certificate_path VARCHAR(512), 
	certificate_filename VARCHAR(255), 
	private_key_path VARCHAR(512), 
	private_key_filename VARCHAR(255), 
	ca_certificate_path VARCHAR(512), 
	ca_certificate_filename VARCHAR(255), 
	created_at DATETIME DEFAULT (now()) NOT NULL, 
	updated_at DATETIME DEFAULT (now()) NOT NULL, 
	PRIMARY KEY (channel_id), 
	CONSTRAINT channel_security_config_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id)
);
CREATE TABLE connection_session (
	id INTEGER NOT NULL, 
	session_id VARCHAR(36) NOT NULL, 
	channel_id INTEGER NOT NULL, 
	protocol_type VARCHAR(32) NOT NULL, 
	server_instance_id VARCHAR(36) NOT NULL, 
	remote_ip VARCHAR(45), 
	remote_port INTEGER, 
	local_ip VARCHAR(45), 
	local_port INTEGER, 
	state VARCHAR(16) NOT NULL, 
	transport_connected_at DATETIME NOT NULL, 
	established_at DATETIME, 
	last_activity_at DATETIME NOT NULL, 
	disconnected_at DATETIME, 
	duration_ms BIGINT NOT NULL, 
	disconnect_reason VARCHAR(40), 
	disconnect_initiator VARCHAR(16), 
	close_detail VARCHAR(512), 
	client_identity_json TEXT NOT NULL, 
	security_json TEXT NOT NULL, 
	rx_bytes BIGINT NOT NULL, 
	tx_bytes BIGINT NOT NULL, 
	rx_messages BIGINT NOT NULL, 
	tx_messages BIGINT NOT NULL, 
	error_count BIGINT NOT NULL, 
	end_time_accuracy VARCHAR(16) NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT connection_session_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id) ON DELETE CASCADE
);
CREATE TABLE dlt698_point (
	id INTEGER NOT NULL, 
	channel_id INTEGER NOT NULL, 
	code VARCHAR(128) COLLATE "NOCASE" NOT NULL, 
	definition JSON NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT dlt698_point_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id) ON DELETE CASCADE
);
CREATE TABLE goose_publisher (
	id INTEGER NOT NULL, 
	channel_id INTEGER, 
	interface VARCHAR(64) DEFAULT 'eth0' NOT NULL, 
	go_cb_ref VARCHAR(256) NOT NULL, 
	go_id VARCHAR(128) DEFAULT '' NOT NULL, 
	data_set_ref VARCHAR(256) DEFAULT '' NOT NULL, 
	app_id INTEGER DEFAULT '1' NOT NULL, 
	conf_rev INTEGER DEFAULT '1' NOT NULL, 
	time_allowed_to_live INTEGER DEFAULT '10000' NOT NULL, 
	dst_mac_json TEXT, 
	vlan_id INTEGER DEFAULT '0' NOT NULL, 
	vlan_prio INTEGER DEFAULT '4' NOT NULL, 
	simulation INTEGER DEFAULT '1' NOT NULL, 
	retransmit_initial_ms INTEGER DEFAULT '2' NOT NULL, 
	retransmit_multiplier FLOAT DEFAULT '2' NOT NULL, 
	retransmit_final_ms INTEGER DEFAULT '5000' NOT NULL, 
	needs_commissioning INTEGER DEFAULT '0' NOT NULL, 
	name VARCHAR(128) COLLATE "NOCASE" DEFAULT '' NOT NULL, 
	description VARCHAR(512) DEFAULT '' NOT NULL, 
	auto_start INTEGER DEFAULT '0' NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT goose_publisher_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id)
);
CREATE TABLE goose_receiver (
	id INTEGER NOT NULL, 
	channel_id INTEGER NOT NULL, 
	name VARCHAR(128) COLLATE "NOCASE" DEFAULT 'default' NOT NULL, 
	description VARCHAR(512) DEFAULT '' NOT NULL, 
	interface VARCHAR(256) NOT NULL, 
	auto_start INTEGER DEFAULT '0' NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT goose_receiver_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id) ON DELETE CASCADE
);
CREATE TABLE opcua_config (
	channel_id INTEGER NOT NULL, 
	schema_version INTEGER NOT NULL, 
	endpoint_url VARCHAR(1024), 
	endpoint_path VARCHAR(255) NOT NULL, 
	namespace_uri VARCHAR(255), 
	PRIMARY KEY (channel_id), 
	CONSTRAINT opcua_config_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id)
);
CREATE TABLE opcua_feature (
	channel_id INTEGER NOT NULL, 
	name VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	schema_version INTEGER NOT NULL, 
	config JSON NOT NULL, 
	PRIMARY KEY (channel_id, name), 
	CONSTRAINT opcua_feature_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id)
);
CREATE TABLE opcua_node (
	id INTEGER NOT NULL, 
	channel_id INTEGER NOT NULL, 
	schema_version INTEGER NOT NULL, 
	namespace_uri VARCHAR(255) NOT NULL, 
	node_id VARCHAR(512) NOT NULL, 
	browse_name VARCHAR(128) NOT NULL, 
	data_type VARCHAR(32) NOT NULL, 
	initial_value JSON NOT NULL, 
	writable INTEGER NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT opcua_node_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id)
);
CREATE TABLE opcua_point (
	id INTEGER NOT NULL, 
	channel_id INTEGER NOT NULL, 
	schema_version INTEGER NOT NULL, 
	point_type INTEGER NOT NULL, 
	point_code VARCHAR(128) NOT NULL, 
	point_name VARCHAR(255) NOT NULL, 
	attribute_code VARCHAR(255) NOT NULL, 
	node_id VARCHAR(512) NOT NULL, 
	namespace_uri VARCHAR(255) NOT NULL, 
	data_type VARCHAR(32) NOT NULL, 
	sampling_interval_ms INTEGER NOT NULL, 
	unit VARCHAR(64), 
	scale_mul FLOAT, 
	scale_add FLOAT, 
	upper_limit FLOAT, 
	lower_limit FLOAT, 
	initial_value JSON NOT NULL, 
	reverse INTEGER NOT NULL, 
	command_type VARCHAR(64), 
	related_code VARCHAR(128), 
	PRIMARY KEY (id), 
	CONSTRAINT opcua_point_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id)
);
CREATE TABLE opcua_secret (
	channel_id INTEGER NOT NULL, 
	name VARCHAR(128) COLLATE "NOCASE" NOT NULL, 
	ciphertext TEXT NOT NULL, 
	PRIMARY KEY (channel_id, name), 
	CONSTRAINT opcua_secret_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id)
);
CREATE TABLE point_yc (
	id INTEGER NOT NULL, 
	code VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	name VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	channel_id INTEGER, 
	rtu_addr INTEGER DEFAULT '1' NOT NULL, 
	reg_addr VARCHAR(128) NOT NULL, 
	func_code INTEGER DEFAULT '3' NOT NULL, 
	decode_code VARCHAR(32) DEFAULT 'INT32_ABCD' NOT NULL, 
	mul_coe FLOAT DEFAULT '1' NOT NULL, 
	add_coe FLOAT DEFAULT '0' NOT NULL, 
	max_limit FLOAT NOT NULL, 
	min_limit FLOAT NOT NULL, 
	iec_common_address INTEGER, 
	iec_cot INTEGER DEFAULT '3', 
	iec_quality INTEGER DEFAULT '0', 
	iec_type_id VARCHAR(16), 
	fc VARCHAR(8), 
	dnp3_config TEXT, 
	enable INTEGER DEFAULT '1' NOT NULL, 
	unit VARCHAR(64), 
	PRIMARY KEY (id), 
	CONSTRAINT point_yc_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id)
);
INSERT INTO point_yc VALUES(77,'YC512','#1机组_有功功率上限',1,1,'0',4,'INT16_AB',1,0,6.8,6.2,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(78,'YC513','#1机组_有功功率下限',1,1,'1',4,'INT16_AB',1,0,0.8,0.2,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(79,'YC514','#1机组_有功调节速度',1,1,'2',4,'INT16_AB',1,0,3.8,3.2,NULL,3,0,NULL,NULL,NULL,1,'MW/min');
INSERT INTO point_yc VALUES(80,'YC301','#1机组有功功率指令反馈',1,1,'3',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(81,'YC612','#2机组_有功功率上限',1,1,'4',4,'INT16_AB',1,0,15.8,15.2,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(82,'YC613','#2机组_有功功率下限',1,1,'5',4,'INT16_AB',1,0,0.8,0.2,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(83,'YC614','#2机组_有功调节速度',1,1,'6',4,'INT16_AB',1,0,4.8,4.2,NULL,3,0,NULL,NULL,NULL,1,'MW/min');
INSERT INTO point_yc VALUES(84,'YC303','#2机组有功功率指令反馈',1,1,'7',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(85,'YC912','#3机组_有功功率上限',1,1,'8',4,'INT16_AB',1,0,15.8,15.2,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(86,'YC913','#3机组_有功功率下限',1,1,'9',4,'INT16_AB',1,0,0.8,0.2,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(87,'YC914','#3机组_有功调节速度',1,1,'10',4,'INT16_AB',1,0,4.8,4.2,NULL,3,0,NULL,NULL,NULL,1,'MW/min');
INSERT INTO point_yc VALUES(88,'YC305','#3机组有功功率指令反馈',1,1,'11',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(89,'YC1012','#4机组_有功功率上限',1,1,'12',4,'INT16_AB',1,0,6.8,6.2,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(90,'YC1013','#4机组_有功功率下限',1,1,'13',4,'INT16_AB',1,0,0.8,0.2,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(91,'YC1014','#4机组_有功调节速度',1,1,'14',4,'INT16_AB',1,0,3.8,3.2,NULL,3,0,NULL,NULL,NULL,1,'MW/min');
INSERT INTO point_yc VALUES(92,'YC307','#4机组有功功率指令反馈',1,1,'15',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(93,'YC222','1#二次P_1#母线',2,257,'16385',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(94,'YC225','1#二次F_1#母线',2,257,'16386',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Hz');
INSERT INTO point_yc VALUES(95,'YC223','1#二次Q_1#母线',2,257,'16387',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Mvar');
INSERT INTO point_yc VALUES(96,'YC219','1#二次Uab_1#母线',2,257,'16388',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(97,'YC220','1#二次Ubc_1#母线',2,257,'16389',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(98,'YC221','1#二次Uca_1#母线',2,257,'16390',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(99,'YC216','1#二次Ia_1#母线',2,257,'16391',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(100,'YC217','1#二次Ib_1#母线',2,257,'16392',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(101,'YC218','1#二次Ic_1#母线',2,257,'16393',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(102,'YC224','1#二次COS_1#母线',2,257,'16394',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'—');
INSERT INTO point_yc VALUES(103,'YC235','2#二次P_2#母线',2,257,'16395',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(104,'YC238','2#二次F_2#母线',2,257,'16396',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Hz');
INSERT INTO point_yc VALUES(105,'YC236','2#二次Q_2#母线',2,257,'16397',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Mvar');
INSERT INTO point_yc VALUES(106,'YC232','2#二次Uab_2#母线',2,257,'16398',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(107,'YC233','2#二次Ubc_2#母线',2,257,'16399',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(108,'YC234','2#二次Uca_2#母线',2,257,'16400',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(109,'YC229','2#二次Ia_2#母线',2,257,'16401',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(110,'YC230','2#二次Ib_2#母线',2,257,'16402',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(111,'YC231','2#二次Ic_2#母线',2,257,'16403',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(112,'YC237','2#二次COS_2#母线',2,257,'16404',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'—');
INSERT INTO point_yc VALUES(113,'YC501','#1机组_有功功率',2,257,'16405',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(114,'YC502','#1机组_频率',2,257,'16406',3,'FLOAT32_ABCD',1,0,50.03,49.97,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Hz');
INSERT INTO point_yc VALUES(115,'YC503','#1机组_无功功率',2,257,'16407',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Mvar');
INSERT INTO point_yc VALUES(116,'YC504','#1机组_线电压uab',2,257,'16408',3,'FLOAT32_ABCD',1,0,10.58,10.42,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(117,'YC505','#1机组_线电压ubc',2,257,'16409',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(118,'YC506','#1机组_线电压uca',2,257,'16410',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(119,'YC507','#1机组_A相电流',2,257,'16412',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(120,'YC508','#1机组_B相电流',2,257,'16414',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(121,'YC509','#1机组_C相电流',2,257,'16415',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(122,'YC515','#1机组_功率因数',2,257,'16416',3,'FLOAT32_ABCD',1,0,0.8080000000000001,0.792,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'—');
INSERT INTO point_yc VALUES(123,'YC601','#2机组_有功功率',2,257,'16417',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(124,'YC602','#2机组_频率',2,257,'16418',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Hz');
INSERT INTO point_yc VALUES(125,'YC603','#2机组_无功功率',2,257,'16419',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Mvar');
INSERT INTO point_yc VALUES(126,'YC604','#2机组_线电压uab',2,257,'16420',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(127,'YC605','#2机组_线电压ubc',2,257,'16421',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(128,'YC606','#2机组_线电压uca',2,257,'16422',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(129,'YC607','#2机组_A相电流',2,257,'16423',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(130,'YC608','#2机组_B相电流',2,257,'16424',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(131,'YC609','#2机组_C相电流',2,257,'16425',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(132,'YC615','#2机组_功率因数',2,257,'16426',3,'FLOAT32_ABCD',1,0,0.8080000000000001,0.792,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'—');
INSERT INTO point_yc VALUES(133,'YC901','#3机组_有功功率',2,257,'16427',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(134,'YC902','#3机组_频率',2,257,'16428',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Hz');
INSERT INTO point_yc VALUES(135,'YC903','#3机组_无功功率',2,257,'16429',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Mvar');
INSERT INTO point_yc VALUES(136,'YC904','#3机组_线电压uab',2,257,'16430',3,'FLOAT32_ABCD',1,0,10.58,10.42,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(137,'YC905','#3机组_线电压ubc',2,257,'16431',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(138,'YC906','#3机组_线电压uca',2,257,'16432',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(139,'YC907','#3机组_A相电流',2,257,'16433',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(140,'YC908','#3机组_B相电流',2,257,'16434',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(141,'YC909','#3机组_C相电流',2,257,'16435',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(142,'YC915','#3机组_功率因数',2,257,'16436',3,'FLOAT32_ABCD',1,0,0.8080000000000001,0.792,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'—');
INSERT INTO point_yc VALUES(143,'YC1001','#4机组_有功功率',2,257,'16437',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(144,'YC1002','#4机组_频率',2,257,'16438',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Hz');
INSERT INTO point_yc VALUES(145,'YC1003','#4机组_无功功率',2,257,'16439',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'Mvar');
INSERT INTO point_yc VALUES(146,'YC1004','#4机组_线电压uab',2,257,'16440',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(147,'YC1005','#4机组_线电压ubc',2,257,'16441',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(148,'YC1006','#4机组_线电压uca',2,257,'16442',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'kV');
INSERT INTO point_yc VALUES(149,'YC1007','#4机组_A相电流',2,257,'16443',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(150,'YC1008','#4机组_B相电流',2,257,'16444',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(151,'YC1009','#4机组_C相电流',2,257,'16445',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'A');
INSERT INTO point_yc VALUES(152,'YC1015','#4机组_功率因数',2,257,'16446',3,'FLOAT32_ABCD',1,0,0.8080000000000001,0.792,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'—');
INSERT INTO point_yc VALUES(153,'YC101','1#母线有功指令执行值',3,1,'16385',3,'INT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'MW');
INSERT INTO point_yc VALUES(154,'YC103','1#母线有功功率计算值',3,1,'16390',3,'INT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1,'MW');
CREATE TABLE point_yx (
	id INTEGER NOT NULL, 
	code VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	name VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	channel_id INTEGER, 
	rtu_addr INTEGER DEFAULT '1' NOT NULL, 
	reg_addr VARCHAR(128) NOT NULL, 
	func_code INTEGER DEFAULT '1' NOT NULL, 
	decode_code VARCHAR(32) DEFAULT 'UINT16_AB' NOT NULL, 
	bit INTEGER, 
	reverse INTEGER DEFAULT '0' NOT NULL, 
	iec_common_address INTEGER, 
	iec_cot INTEGER DEFAULT '3', 
	iec_quality INTEGER DEFAULT '0', 
	iec_type_id VARCHAR(16), 
	fc VARCHAR(8), 
	dnp3_config TEXT, 
	enable INTEGER DEFAULT '1' NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT point_yx_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id)
);
INSERT INTO point_yx VALUES(44,'YX302','#1机组AGC开关锁',1,1,'0',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(45,'YX305','#1机组负荷禁增状态',1,1,'1',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(46,'YX306','#1机组负荷禁减状态',1,1,'2',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(47,'YX301','#1机组DCS侧AGC投入/退出',1,1,'3',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(48,'YX414','#1机组一次调频状态',1,1,'4',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(49,'YX304','#1机组并网状态',1,1,'5',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(50,'YX303','#1机组RB状态',1,1,'6',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(51,'YX351','#1机组故障总',1,1,'7',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(52,'YX309','#2机组AGC开关锁',1,1,'8',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(53,'YX312','#2机组负荷禁增',1,1,'9',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(54,'YX313','#2机组负荷禁减',1,1,'10',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(55,'YX308','#2机组DCS侧AGC投入/退出',1,1,'11',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(56,'YX514','#2机组一次调频状态',1,1,'12',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(57,'YX311','#2机组并网状态',1,1,'13',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(58,'YX310','#2机组RB状态',1,1,'14',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(59,'YX353','#2机组故障总',1,1,'15',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(60,'YX602','#3机组AGC开关锁',1,1,'16',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(61,'YX605','#3机组负荷禁增状态',1,1,'17',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(62,'YX606','#3机组负荷禁减状态',1,1,'18',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(63,'YX601','#3机组DCS侧AGC投入/退出',1,1,'19',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(64,'YX714','#3机组一次调频状态',1,1,'20',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(65,'YX604','#3机组并网状态',1,1,'21',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(66,'YX603','#3机组RB状态',1,1,'22',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(67,'YX651','#3机组故障总',1,1,'23',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(68,'YX609','#4机组AGC开关锁',1,1,'24',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(69,'YX612','#4机组负荷禁增',1,1,'25',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(70,'YX613','#4机组负荷禁减',1,1,'26',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(71,'YX608','#4机组DCS侧AGC投入/退出',1,1,'27',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(72,'YX814','#4机组一次调频状态',1,1,'28',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(73,'YX611','#4机组并网状态',1,1,'29',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(74,'YX610','#4机组RB状态',1,1,'30',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(75,'YX653','#4机组故障总',1,1,'31',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yx VALUES(76,'YX201','#1机组开关',2,257,'1',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(77,'YX211','#2机组开关',2,257,'2',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(78,'YX221','#3机组开关',2,257,'3',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(79,'YX231','#4机组开关',2,257,'4',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(80,'YX241','10kVI母开关1',2,257,'5',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(81,'YX242','10kVI母开关2',2,257,'6',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(82,'YX243','10kVI母开关3',2,257,'7',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(83,'YX251','10kVII母开关1',2,257,'8',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(84,'YX252','10kVII母开关1',2,257,'9',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(85,'YX253','10kVII母开关1',2,257,'10',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(86,'YX261','10kV母联开关',2,257,'11',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(87,'YX3','AGC允许投入远方调节',3,1,'0x0001',3,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
INSERT INTO point_yx VALUES(88,'YX4','1#母线AGC投入/退出',3,1,'0x0002',3,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
CREATE TABLE slave (
	id INTEGER NOT NULL, 
	channel_id INTEGER NOT NULL, 
	slave_id INTEGER NOT NULL, 
	name VARCHAR(64) COLLATE "NOCASE", 
	enable INTEGER DEFAULT '1' NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT slave_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id)
);
INSERT INTO slave VALUES(1,2,257,'NCS公共地址',1);
INSERT INTO slave VALUES(2,3,257,'主站公共地址',1);
INSERT INTO slave VALUES(3,1,1,'PLC从站',1);
CREATE TABLE goose_entry (
	id INTEGER NOT NULL, 
	publisher_id INTEGER NOT NULL, 
	name VARCHAR(256) COLLATE "NOCASE" NOT NULL, 
	value TEXT, 
	iec_type VARCHAR(32) DEFAULT 'boolean' NOT NULL, 
	sort_order INTEGER DEFAULT '0' NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT goose_entry_ibfk_1 FOREIGN KEY(publisher_id) REFERENCES goose_publisher (id) ON DELETE CASCADE
);
CREATE TABLE goose_subscription (
	id INTEGER NOT NULL, 
	receiver_id INTEGER NOT NULL, 
	go_cb_ref VARCHAR(256) NOT NULL, 
	app_id INTEGER, 
	dst_mac_json TEXT, 
	description VARCHAR(512) DEFAULT '' NOT NULL, 
	data_set_ref VARCHAR(256) DEFAULT '' NOT NULL, 
	conf_rev INTEGER DEFAULT '0' NOT NULL, 
	enabled INTEGER DEFAULT '0' NOT NULL, 
	ied_name VARCHAR(128) DEFAULT '' NOT NULL, 
	ld_inst VARCHAR(128) DEFAULT '' NOT NULL, 
	ln_name VARCHAR(128) DEFAULT 'LLN0' NOT NULL, 
	dataset_entries_json TEXT, 
	go_id VARCHAR(256) DEFAULT '' NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT goose_subscription_ibfk_1 FOREIGN KEY(receiver_id) REFERENCES goose_receiver (id) ON DELETE CASCADE
);
CREATE TABLE point_yk (
	id INTEGER NOT NULL, 
	code VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	name VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	channel_id INTEGER, 
	rtu_addr INTEGER DEFAULT '1' NOT NULL, 
	reg_addr VARCHAR(128) NOT NULL, 
	func_code INTEGER DEFAULT '5' NOT NULL, 
	decode_code VARCHAR(32) DEFAULT 'UINT16_AB' NOT NULL, 
	bit INTEGER, 
	command_type INTEGER DEFAULT '0' NOT NULL, 
	related_yx_id INTEGER, 
	iec_common_address INTEGER, 
	iec_cot INTEGER DEFAULT '3', 
	iec_quality INTEGER DEFAULT '0', 
	iec_type_id VARCHAR(16), 
	fc VARCHAR(8), 
	dnp3_config TEXT, 
	enable INTEGER DEFAULT '1' NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT point_yk_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id), 
	CONSTRAINT point_yk_ibfk_2 FOREIGN KEY(related_yx_id) REFERENCES point_yx (id)
);
INSERT INTO point_yk VALUES(1,'YK0','#1机组投入/退出',1,1,'51',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(2,'YK1','#1机组故障总',1,1,'52',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(3,'YK2','#1机组增闭锁',1,1,'53',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(4,'YK3','#1机组减闭锁',1,1,'54',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(5,'YK4','#1机组超出调节能力',1,1,'55',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(6,'YK5','#2机组投入/退出',1,1,'56',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(7,'YK6','#2机组故障总',1,1,'57',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(8,'YK7','#2机组增闭锁',1,1,'58',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(9,'YK8','#2机组减闭锁',1,1,'59',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(10,'YK9','#2机组超出调节能力',1,1,'60',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(11,'YK10','#3机组投入/退出',1,1,'61',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(12,'YK11','#3机组故障总',1,1,'62',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(13,'YK12','#3机组增闭锁',1,1,'63',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(14,'YK13','#3机组减闭锁',1,1,'64',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(15,'YK14','#3机组超出调节能力',1,1,'65',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(16,'YK15','#4机组投入/退出',1,1,'66',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(17,'YK16','#4机组故障总',1,1,'67',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(18,'YK17','#4机组增闭锁',1,1,'68',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(19,'YK18','#4机组减闭锁',1,1,'69',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yk VALUES(20,'YK19','#4机组超出调节能力',1,1,'70',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
CREATE TABLE point_yt (
	id INTEGER NOT NULL, 
	code VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	name VARCHAR(64) COLLATE "NOCASE" NOT NULL, 
	channel_id INTEGER, 
	rtu_addr INTEGER DEFAULT '1' NOT NULL, 
	reg_addr VARCHAR(128) NOT NULL, 
	func_code INTEGER DEFAULT '3' NOT NULL, 
	decode_code VARCHAR(32) DEFAULT 'UINT16_AB' NOT NULL, 
	mul_coe FLOAT DEFAULT '1' NOT NULL, 
	add_coe FLOAT DEFAULT '0' NOT NULL, 
	max_limit FLOAT NOT NULL, 
	min_limit FLOAT NOT NULL, 
	related_yc_id INTEGER, 
	iec_common_address INTEGER, 
	iec_cot INTEGER DEFAULT '3', 
	iec_quality INTEGER DEFAULT '0', 
	iec_type_id VARCHAR(16), 
	fc VARCHAR(8), 
	dnp3_config TEXT, 
	enable INTEGER DEFAULT '1' NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT point_yt_ibfk_1 FOREIGN KEY(channel_id) REFERENCES channel (id), 
	CONSTRAINT point_yt_ibfk_2 FOREIGN KEY(related_yc_id) REFERENCES point_yc (id)
);
INSERT INTO point_yt VALUES(1,'YS1','1#机组数字遥设指令',1,1,'51',6,'INT16_AB',1,0,1000000000,-1000000000,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yt VALUES(2,'YS4','2#机组数字遥设指令',1,1,'52',6,'INT16_AB',1,0,1000000000,-1000000000,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yt VALUES(3,'YS6','3#机组数字遥设指令',1,1,'53',6,'INT16_AB',1,0,1000000000,-1000000000,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yt VALUES(4,'YS7','4#机组数字遥设指令',1,1,'54',6,'INT16_AB',1,0,1000000000,-1000000000,NULL,NULL,3,0,NULL,NULL,NULL,1);
INSERT INTO point_yt VALUES(5,'YS5','有功功率AGC设定值',3,1,'25089',6,'INT32_ABCD',0.171,0,367220000,-367220000,NULL,NULL,3,0,'C_SE_NC_1',NULL,NULL,1);
CREATE INDEX ix_device_group_parent_id ON device_group (parent_id);
CREATE UNIQUE INDEX ix_device_group_code ON device_group (code);
CREATE INDEX ix_iec61850_model_project_status ON iec61850_model_project (status);
CREATE INDEX ix_iec61850_model_project_name ON iec61850_model_project (name);
CREATE UNIQUE INDEX ix_iec61850_model_project_code ON iec61850_model_project (code);
CREATE UNIQUE INDEX uix_device_target_point ON point_mapping (device_name, target_point_code);
CREATE INDEX ix_device_group_id ON device (group_id);
CREATE UNIQUE INDEX ix_device_code ON device (code);
CREATE UNIQUE INDEX uq_iec61850_model_version_number ON iec61850_model_version (project_id, version_number);
CREATE INDEX ix_iec61850_model_version_project_id ON iec61850_model_version (project_id);
CREATE INDEX ix_iec61850_model_version_status ON iec61850_model_version (status);
CREATE INDEX device_id ON channel (device_id);
CREATE UNIQUE INDEX ix_channel_code ON channel (code);
CREATE UNIQUE INDEX ix_connection_session_session_id ON connection_session (session_id);
CREATE INDEX ix_connection_session_channel_end ON connection_session (channel_id, disconnected_at);
CREATE INDEX ix_connection_session_channel_reason ON connection_session (channel_id, disconnect_reason, disconnected_at);
CREATE UNIQUE INDEX uq_dlt698_channel_code ON dlt698_point (channel_id, code);
CREATE INDEX ix_dlt698_point_channel_id ON dlt698_point (channel_id);
CREATE INDEX ix_goose_publisher_go_cb_ref ON goose_publisher (go_cb_ref);
CREATE UNIQUE INDEX uq_goose_publisher_channel_gocb ON goose_publisher (channel_id, go_cb_ref);
CREATE INDEX ix_goose_publisher_channel_id ON goose_publisher (channel_id);
CREATE INDEX ix_goose_receiver_channel_id ON goose_receiver (channel_id);
CREATE UNIQUE INDEX uq_goose_receiver_channel_interface_name ON goose_receiver (channel_id, interface, name);
CREATE INDEX ix_opcua_node_channel_id ON opcua_node (channel_id);
CREATE UNIQUE INDEX uq_opcua_node_channel_node_id ON opcua_node (channel_id, node_id);
CREATE INDEX ix_opcua_point_channel_id ON opcua_point (channel_id);
CREATE UNIQUE INDEX uq_opcua_point_code ON opcua_point (channel_id, point_code);
CREATE UNIQUE INDEX uq_opcua_point_node_id ON opcua_point (channel_id, node_id);
CREATE INDEX ix_point_yc_code ON point_yc (code);
CREATE UNIQUE INDEX uq_point_yc_code_channel_rtu ON point_yc (code, channel_id, rtu_addr);
CREATE INDEX ix_point_yc_channel_id ON point_yc (channel_id);
CREATE UNIQUE INDEX uq_point_yx_code_channel_rtu ON point_yx (code, channel_id, rtu_addr);
CREATE INDEX ix_point_yx_channel_id ON point_yx (channel_id);
CREATE INDEX ix_point_yx_code ON point_yx (code);
CREATE UNIQUE INDEX uq_slave_channel_slave ON slave (channel_id, slave_id);
CREATE INDEX ix_slave_channel_id ON slave (channel_id);
CREATE INDEX ix_goose_entry_publisher_id ON goose_entry (publisher_id);
CREATE UNIQUE INDEX uq_goose_subscription_filter ON goose_subscription (receiver_id, go_cb_ref, app_id);
CREATE INDEX ix_goose_subscription_receiver_id ON goose_subscription (receiver_id);
CREATE INDEX ix_point_yk_channel_id ON point_yk (channel_id);
CREATE UNIQUE INDEX uq_point_yk_code_channel_rtu ON point_yk (code, channel_id, rtu_addr);
CREATE INDEX related_yx_id ON point_yk (related_yx_id);
CREATE INDEX ix_point_yk_code ON point_yk (code);
CREATE UNIQUE INDEX uq_point_yt_code_channel_rtu ON point_yt (code, channel_id, rtu_addr);
CREATE INDEX related_yc_id ON point_yt (related_yc_id);
CREATE INDEX ix_point_yt_code ON point_yt (code);
CREATE INDEX ix_point_yt_channel_id ON point_yt (channel_id);
COMMIT;
