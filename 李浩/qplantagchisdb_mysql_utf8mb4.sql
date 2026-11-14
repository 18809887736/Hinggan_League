-- ============================================================
-- qplantagchisdb 建库脚本 (MySQL) —— utf8mb4 修正版 (2026-11-14)
-- 基于李浩 2026-11-04 gbk 版修正。改字符集的依据（2026-11-14 上午实测）：
--   程序（Qt4 + MySQL ODBC 8.0）写入的中文是 UTF-8 字节，不是 gbk；
--   DSN 已配 Charset=utf8mb4（/etc/odbc.ini [QPlantAgcHisdb]）。
--   gbk 版在 DSN 缺 Charset 时 Connector/ODBC 会协商成 latin1，
--   中文告警插入全部失败（Incorrect string value）——已踩坑并修复。
-- 表名/字段名与程序保持一致；his_curve_gen 为裁剪后终态：
--   仅 时间+机组+5个有功功率列（thermal/coal 列已随煤/热功能裁撤）
-- 类型映射: INTEGER->INT, FLOAT->DOUBLE, timestamp->DATETIME(避开2038限制),
--          VARCHAR(4096)->TEXT
-- 执行: mysql -uroot -p --default-character-set=utf8mb4 < qplantagchisdb_mysql_utf8mb4.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS qplantagchisdb DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE qplantagchisdb;

CREATE TABLE adjust_info (
    adjust_time DATETIME,
    dev_type    INT,
    dev_num     INT,
    channel     INT,
    ysValue     DOUBLE,
    curValue    DOUBLE,
    controlMode INT,
    KEY idx_adjust_info_dev_num (dev_num)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ORI_CODE (
    chunnel_num INT,
    direction   VARCHAR(1),
    save_time   DATETIME,
    code        TEXT,
    KEY idx_ori_code_save_time (save_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE warn_info (
    warn_time    DATETIME,
    millisecond  SMALLINT,
    warn_type    INT,
    obj_num      INT,
    warn_info    VARCHAR(100),
    KEY idx_warn_info_warn_time (warn_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE yc_curve (
    yc_num  INT NOT NULL,
    yc_time DATETIME NOT NULL,
    yc_data DOUBLE NOT NULL,
    PRIMARY KEY (yc_num, yc_time),
    KEY idx_yc_curve_time (yc_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE yc_history (
    yc_num  INT NOT NULL,
    yc_time DATETIME NOT NULL,
    yc_data DOUBLE NOT NULL,
    PRIMARY KEY (yc_num, yc_time),
    KEY idx_yc_history_time (yc_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE his_curve_bus (
    save_time  DATETIME NOT NULL,
    busbar_num INT NOT NULL,
    high_p     DOUBLE,
    low_p      DOUBLE,
    average_p  DOUBLE,
    cur_p      DOUBLE,
    plan_p     DOUBLE,
    PRIMARY KEY (save_time, busbar_num)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE his_curve_gen (
    save_time DATETIME NOT NULL,
    gen_num   INT NOT NULL,
    high_p    DOUBLE,
    low_p     DOUBLE,
    avg_p     DOUBLE,
    cur_p     DOUBLE,
    plan_p    DOUBLE,
    PRIMARY KEY (save_time, gen_num)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
