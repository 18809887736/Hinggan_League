/*
 Navicat Premium Data Transfer

 Source Server         : 10.0.0.194
 Source Server Type    : MySQL
 Source Server Version : 80043 (8.0.43-0kylin0.20.04.1+esm1k0.1)
 Source Host           : 10.0.0.194:3306
 Source Schema         : qplantagchisdb

 Target Server Type    : MySQL
 Target Server Version : 80043 (8.0.43-0kylin0.20.04.1+esm1k0.1)
 File Encoding         : 65001

 Date: 14/11/2026 10:02:51
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for ORI_CODE
-- ----------------------------
DROP TABLE IF EXISTS `ORI_CODE`;
CREATE TABLE `ORI_CODE`  (
  `chunnel_num` int NULL DEFAULT NULL,
  `direction` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `save_time` datetime NULL DEFAULT NULL,
  `code` mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL,
  INDEX `idx_ori_code_save_time`(`save_time` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for adjust_info
-- ----------------------------
DROP TABLE IF EXISTS `adjust_info`;
CREATE TABLE `adjust_info`  (
  `adjust_time` datetime NULL DEFAULT NULL,
  `dev_type` int NULL DEFAULT NULL,
  `dev_num` int NULL DEFAULT NULL,
  `channel` int NULL DEFAULT NULL,
  `ysValue` double NULL DEFAULT NULL,
  `curValue` double NULL DEFAULT NULL,
  `controlMode` int NULL DEFAULT NULL,
  INDEX `idx_adjust_info_dev_num`(`dev_num` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for his_curve_bus
-- ----------------------------
DROP TABLE IF EXISTS `his_curve_bus`;
CREATE TABLE `his_curve_bus`  (
  `save_time` datetime NOT NULL,
  `busbar_num` int NOT NULL,
  `high_p` double NULL DEFAULT NULL,
  `low_p` double NULL DEFAULT NULL,
  `average_p` double NULL DEFAULT NULL,
  `cur_p` double NULL DEFAULT NULL,
  `plan_p` double NULL DEFAULT NULL,
  PRIMARY KEY (`save_time`, `busbar_num`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for his_curve_gen
-- ----------------------------
DROP TABLE IF EXISTS `his_curve_gen`;
CREATE TABLE `his_curve_gen`  (
  `save_time` datetime NOT NULL,
  `gen_num` int NOT NULL,
  `high_p` double NULL DEFAULT NULL,
  `low_p` double NULL DEFAULT NULL,
  `avg_p` double NULL DEFAULT NULL,
  `cur_p` double NULL DEFAULT NULL,
  `plan_p` double NULL DEFAULT NULL,
  PRIMARY KEY (`save_time`, `gen_num`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for warn_info
-- ----------------------------
DROP TABLE IF EXISTS `warn_info`;
CREATE TABLE `warn_info`  (
  `warn_time` datetime NULL DEFAULT NULL,
  `millisecond` smallint NULL DEFAULT NULL,
  `warn_type` int NULL DEFAULT NULL,
  `obj_num` int NULL DEFAULT NULL,
  `warn_info` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  INDEX `idx_warn_info_warn_time`(`warn_time` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for yc_curve
-- ----------------------------
DROP TABLE IF EXISTS `yc_curve`;
CREATE TABLE `yc_curve`  (
  `yc_num` int NOT NULL,
  `yc_time` datetime NOT NULL,
  `yc_data` double NOT NULL,
  PRIMARY KEY (`yc_num`, `yc_time`) USING BTREE,
  INDEX `idx_yc_curve_time`(`yc_time` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for yc_history
-- ----------------------------
DROP TABLE IF EXISTS `yc_history`;
CREATE TABLE `yc_history`  (
  `yc_num` int NOT NULL,
  `yc_time` datetime NOT NULL,
  `yc_data` double NOT NULL,
  PRIMARY KEY (`yc_num`, `yc_time`) USING BTREE,
  INDEX `idx_yc_history_time`(`yc_time` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;
