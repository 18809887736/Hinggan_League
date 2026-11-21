-- MySQL dump 10.13  Distrib 8.4.11, for Linux (x86_64)
--
-- Host: localhost    Database: net
-- ------------------------------------------------------
-- Server version	8.4.11

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `net`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `net` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `net`;

--
-- Table structure for table `channel`
--

DROP TABLE IF EXISTS `channel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `channel` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '通道ID',
  `code` varchar(32) NOT NULL COMMENT '通道编码',
  `name` varchar(64) NOT NULL COMMENT '通道名称',
  `device_id` int DEFAULT NULL COMMENT '所属设备ID',
  `protocol_type` int NOT NULL DEFAULT '1' COMMENT '协议类型: 0:ModbusRtu, 1:ModbusTcp, 2:IEC104, 3:DLT645',
  `conn_type` int NOT NULL DEFAULT '1' COMMENT '连接类型: 0:串口, 1:TCP客户端, 2:TCP服务端',
  `ip` varchar(32) DEFAULT NULL COMMENT 'IP地址(TCP模式)',
  `port` int DEFAULT NULL COMMENT '端口号(TCP模式)',
  `com_port` varchar(16) DEFAULT NULL COMMENT '串口号(如COM1)',
  `baud_rate` int DEFAULT '9600' COMMENT '波特率',
  `data_bits` int DEFAULT '8' COMMENT '数据位',
  `stop_bits` int DEFAULT '1' COMMENT '停止位',
  `parity` varchar(1) DEFAULT 'N' COMMENT '校验位: N/E/O',
  `rtu_addr` varchar(16) NOT NULL DEFAULT '1' COMMENT '电表地址(DLT645)',
  `timeout` int NOT NULL DEFAULT '5' COMMENT '超时时间(秒)',
  `enable` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  `change_tracking_enabled` tinyint(1) NOT NULL DEFAULT '0' COMMENT '全部测点变化回溯开关',
  `dlt645_point_mode` varchar(16) NOT NULL DEFAULT 'import' COMMENT 'DLT645点表来源: standard/import',
  `dlt698_point_mode` varchar(16) NOT NULL DEFAULT 'import' COMMENT 'DLT698点表来源: standard/import',
  `model_name` varchar(128) DEFAULT NULL COMMENT 'IED 模型名称 (IEC61850)',
  `icd_path` varchar(512) DEFAULT NULL COMMENT 'ICD文件存储路径 (IEC61850)',
  `icd_file_hash` varchar(64) DEFAULT NULL COMMENT 'ICD文件内容Hash (用于缓存校验)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_channel_code` (`code`),
  KEY `device_id` (`device_id`),
  CONSTRAINT `channel_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `device` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='通道表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `channel`
--

LOCK TABLES `channel` WRITE;
/*!40000 ALTER TABLE `channel` DISABLE KEYS */;
INSERT INTO `channel` VALUES (1,'PLC_SVR','PLC-仿真',1,1,2,'0.0.0.0',502,NULL,9600,8,1,'N','1',5,1,0,'import','import',NULL,NULL,NULL),(2,'NCS_SVR','NCS-仿真',2,2,2,'0.0.0.0',2404,NULL,9600,8,1,'N','1',5,1,0,'import','import',NULL,NULL,NULL),(3,'MASTER_CLI','主站-仿真',3,2,1,'10.0.0.194',2404,NULL,9600,8,1,'N','1',5,0,0,'import','import',NULL,NULL,NULL);
/*!40000 ALTER TABLE `channel` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `channel_protocol_params`
--

DROP TABLE IF EXISTS `channel_protocol_params`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `channel_protocol_params` (
  `channel_id` int NOT NULL,
  `protocol_type` int NOT NULL,
  `conn_type` int NOT NULL,
  `schema_version` int NOT NULL DEFAULT '1',
  `params_json` json NOT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  `updated_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`channel_id`),
  CONSTRAINT `channel_protocol_params_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `channel_protocol_params`
--

LOCK TABLES `channel_protocol_params` WRITE;
/*!40000 ALTER TABLE `channel_protocol_params` DISABLE KEYS */;
INSERT INTO `channel_protocol_params` VALUES (1,1,2,1,'{\"max_connections\": 0, \"client_idle_timeout_ms\": 0}','2026-11-12 08:17:49','2026-11-12 08:17:49'),(2,2,2,1,'{\"t0_timeout_s\": 10, \"t1_timeout_s\": 15, \"t2_timeout_s\": 10, \"t3_interval_s\": 20, \"max_connections\": 0, \"send_window_size\": 12, \"receive_window_size\": 8}','2026-11-12 08:17:50','2026-11-12 08:17:50'),(3,2,1,1,'{\"t0_timeout_s\": 10, \"t1_timeout_s\": 15, \"t2_timeout_s\": 10, \"t3_interval_s\": 20, \"send_window_size\": 12, \"originator_address\": 0, \"receive_window_size\": 8, \"clock_sync_interval_s\": 0, \"reconnect_max_attempts\": 0, \"reconnect_max_interval_ms\": 30000, \"reconnect_initial_interval_ms\": 2000, \"counter_interrogation_interval_s\": 0, \"counter_interrogation_on_connect\": false, \"general_interrogation_interval_s\": 0, \"general_interrogation_on_connect\": true}','2026-11-12 08:17:50','2026-11-12 08:17:50');
/*!40000 ALTER TABLE `channel_protocol_params` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `channel_security_config`
--

DROP TABLE IF EXISTS `channel_security_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `channel_security_config` (
  `channel_id` int NOT NULL,
  `tls_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `tls_mode` varchar(16) NOT NULL DEFAULT 'one_way',
  `tls_version` varchar(16) NOT NULL DEFAULT '1.2',
  `certificate_path` varchar(512) DEFAULT NULL,
  `certificate_filename` varchar(255) DEFAULT NULL,
  `private_key_path` varchar(512) DEFAULT NULL,
  `private_key_filename` varchar(255) DEFAULT NULL,
  `ca_certificate_path` varchar(512) DEFAULT NULL,
  `ca_certificate_filename` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  `updated_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`channel_id`),
  CONSTRAINT `channel_security_config_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `channel_security_config`
--

LOCK TABLES `channel_security_config` WRITE;
/*!40000 ALTER TABLE `channel_security_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `channel_security_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `connection_session`
--

DROP TABLE IF EXISTS `connection_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `connection_session` (
  `id` int NOT NULL AUTO_INCREMENT,
  `session_id` varchar(36) NOT NULL,
  `channel_id` int NOT NULL,
  `protocol_type` varchar(32) NOT NULL,
  `server_instance_id` varchar(36) NOT NULL,
  `remote_ip` varchar(45) DEFAULT NULL,
  `remote_port` int DEFAULT NULL,
  `local_ip` varchar(45) DEFAULT NULL,
  `local_port` int DEFAULT NULL,
  `state` varchar(16) NOT NULL,
  `transport_connected_at` datetime NOT NULL,
  `established_at` datetime DEFAULT NULL,
  `last_activity_at` datetime NOT NULL,
  `disconnected_at` datetime DEFAULT NULL,
  `duration_ms` bigint NOT NULL,
  `disconnect_reason` varchar(40) DEFAULT NULL,
  `disconnect_initiator` varchar(16) DEFAULT NULL,
  `close_detail` varchar(512) DEFAULT NULL,
  `client_identity_json` text NOT NULL,
  `security_json` text NOT NULL,
  `rx_bytes` bigint NOT NULL,
  `tx_bytes` bigint NOT NULL,
  `rx_messages` bigint NOT NULL,
  `tx_messages` bigint NOT NULL,
  `error_count` bigint NOT NULL,
  `end_time_accuracy` varchar(16) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_connection_session_session_id` (`session_id`),
  KEY `ix_connection_session_channel_end` (`channel_id`,`disconnected_at`),
  KEY `ix_connection_session_channel_reason` (`channel_id`,`disconnect_reason`,`disconnected_at`),
  CONSTRAINT `connection_session_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='服务端客户端连接会话';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `connection_session`
--

LOCK TABLES `connection_session` WRITE;
/*!40000 ALTER TABLE `connection_session` DISABLE KEYS */;
INSERT INTO `connection_session` VALUES (1,'d55a182c-00a3-4e92-a174-4685b806e9fa',1,'ModbusTcpServer','f5251f59-e49e-4f51-ae43-470b4d57c64d','10.0.0.194',49620,'172.21.0.2',502,'closed','2026-11-16 05:26:49','2026-11-16 05:26:49','2026-11-16 05:35:27','2026-11-16 05:35:27',518391,'remote_closed','remote',NULL,'{}','{\"tls\":false}',21768,39318,1814,1814,0,'exact'),(2,'938126fe-af7b-4349-ab53-ea803e3f018a',2,'Iec104Server','5adf6663-cfd0-4be3-8c70-d08ed92787b3','10.0.0.194',45576,'172.21.0.2',2404,'closed','2026-11-16 05:28:17','2026-11-16 05:28:17','2026-11-16 05:35:27','2026-11-16 05:35:27',429920,'remote_closed','remote','remote closed connection or transport I/O failed','{}','{\"tls\":false,\"observed_remote_ip\":\"10.0.0.194\",\"observed_remote_port\":45576}',4304,228162,704,1307,1,'exact'),(3,'b71dbcdc-8928-41b8-b70a-a72f32f211c6',1,'ModbusTcpServer','f5251f59-e49e-4f51-ae43-470b4d57c64d','10.0.0.194',47134,'172.21.0.2',502,'closed','2026-11-16 05:36:49','2026-11-16 05:36:49','2026-11-16 06:03:33','2026-11-16 06:03:33',1604656,'server_stopped','server',NULL,'{}','{\"tls\":false}',66000,118817,5499,5499,0,'exact'),(4,'50536a59-2f66-4aa1-afcb-3455903dde79',2,'Iec104Server','5adf6663-cfd0-4be3-8c70-d08ed92787b3','10.0.0.194',41796,'172.21.0.2',2404,'closed','2026-11-16 05:36:49','2026-11-16 05:36:49','2026-11-16 06:03:33','2026-11-16 06:03:33',1604598,'server_stopped','server',NULL,'{}','{\"tls\":false,\"observed_remote_ip\":\"10.0.0.194\",\"observed_remote_port\":41796}',10220,848832,1660,4852,0,'exact'),(5,'5aae658d-2de5-4e08-a3b7-587799a928f9',1,'ModbusTcpServer','942df807-92f4-43a3-b546-a38295bc5c2a','10.0.0.194',35024,'172.21.0.2',502,'closed','2026-11-16 06:06:43','2026-11-16 06:06:43','2026-11-16 07:11:16','2026-11-16 07:11:16',3873347,'remote_closed','remote',NULL,'{}','{\"tls\":false}',162360,293370,13530,13530,0,'exact'),(6,'c69f6070-a866-4671-8cb0-640531945df9',2,'Iec104Server','b7873f7c-dae7-4b0b-ba5b-d40d185dcc36','10.0.0.194',41108,'172.21.0.2',2404,'closed','2026-11-16 06:09:04','2026-11-16 06:09:04','2026-11-16 07:11:16','2026-11-16 07:11:16',3731609,'remote_closed','remote','remote closed connection or transport I/O failed','{}','{\"tls\":false,\"observed_remote_ip\":\"10.0.0.194\",\"observed_remote_port\":41108}',23882,1977300,3877,11306,1,'exact'),(7,'a7198618-a3e8-4749-a68a-b855d6fb3762',2,'Iec104Server','b7873f7c-dae7-4b0b-ba5b-d40d185dcc36','10.0.0.194',49616,'172.21.0.2',2404,'closed','2026-11-16 07:12:38','2026-11-16 07:12:38','2026-11-16 07:22:44','2026-11-16 07:22:45',607460,'remote_closed','remote','remote closed connection or transport I/O failed','{}','{\"tls\":false,\"observed_remote_ip\":\"10.0.0.194\",\"observed_remote_port\":49616}',3892,322036,632,1842,1,'exact'),(8,'95213638-49f8-416d-98c2-8b2cc2d826ec',1,'ModbusTcpServer','942df807-92f4-43a3-b546-a38295bc5c2a','10.0.0.194',38508,'172.21.0.2',502,'abnormal','2026-11-16 07:12:38','2026-11-16 07:12:38','2026-11-16 07:29:16','2026-11-16 07:29:16',998262,'network_reset','network','[Errno 104] Connection reset by peer','{}','{\"tls\":false}',41160,74100,3430,3430,0,'exact'),(9,'3ee588b5-da27-4fd4-a9ba-d98b6b531dac',2,'Iec104Server','b7873f7c-dae7-4b0b-ba5b-d40d185dcc36','10.0.0.194',52484,'172.21.0.2',2404,'closed','2026-11-16 07:27:25','2026-11-16 07:27:25','2026-11-16 07:29:16','2026-11-16 07:29:16',111470,'remote_closed','remote','remote closed connection or transport I/O failed','{}','{\"tls\":false,\"observed_remote_ip\":\"10.0.0.194\",\"observed_remote_port\":52484}',722,59430,117,341,1,'exact'),(10,'75fe1d23-e3c6-47ef-bc4f-ea5a45098f7b',2,'Iec104Server','b7873f7c-dae7-4b0b-ba5b-d40d185dcc36','10.0.0.194',52190,'172.21.0.2',2404,'abnormal','2026-11-16 07:30:46','2026-11-16 07:30:46','2026-11-16 07:38:48',NULL,482000,'process_terminated','process',NULL,'{}','{\"tls\":false,\"observed_remote_ip\":\"10.0.0.194\",\"observed_remote_port\":52190}',3070,254094,500,1451,0,'estimated'),(11,'760f8a2f-af2b-47cb-975a-10e24d78c7a6',1,'ModbusTcpServer','942df807-92f4-43a3-b546-a38295bc5c2a','10.0.0.194',37004,'172.21.0.2',502,'closed','2026-11-16 07:30:46','2026-11-16 07:30:46','2026-11-16 07:39:16','2026-11-16 07:39:17',510353,'server_stopped','server',NULL,'{}','{\"tls\":false}',21024,37884,1752,1752,0,'exact'),(12,'2e4703b2-1433-4668-bd1d-fe85304f954e',1,'ModbusTcpServer','a700853d-fdba-430e-8eb4-8ab33a6ffdf5','10.0.0.194',55866,'172.21.0.2',502,'closed','2026-11-16 07:39:37','2026-11-16 07:39:37','2026-11-16 08:23:08','2026-11-16 08:23:09',2611298,'server_stopped','server',NULL,'{}','{\"tls\":false}',107664,193764,8972,8972,0,'exact'),(13,'f0d958d8-cbe1-40e2-8742-148c9eefa725',2,'Iec104Server','ebf568ce-0cb7-4942-af50-bdbe27829454','10.0.0.194',34924,'172.21.0.2',2404,'closed','2026-11-16 07:39:47','2026-11-16 07:39:47','2026-11-16 08:23:08','2026-11-16 08:23:09',2601730,'server_stopped','server',NULL,'{}','{\"tls\":false,\"observed_remote_ip\":\"10.0.0.194\",\"observed_remote_port\":34924}',16614,1376694,2699,7869,0,'exact'),(14,'24e5ed05-9424-4af0-b9ee-fddca8d101c4',1,'ModbusTcpServer','0c0a6c8d-a538-4754-bead-f5a7e2cf8d85','10.0.0.194',52842,'172.21.0.2',502,'closed','2026-11-16 08:23:30','2026-11-16 08:23:30','2026-11-20 01:34:41','2026-11-20 01:34:41',321071891,'server_stopped','server',NULL,'{}','{\"tls\":false}',12784464,22944203,1065372,1065372,0,'exact'),(15,'3917d0c2-0b3f-4735-abf9-861d5965de10',2,'Iec104Server','eb8e60f2-3323-4e7a-9bc9-9548d11c33e8','10.0.0.194',48874,'172.21.0.2',2404,'closed','2026-11-16 08:28:06','2026-11-16 08:28:06','2026-11-20 01:34:41','2026-11-20 01:34:41',320795563,'server_stopped','server',NULL,'{}','{\"tls\":false,\"observed_remote_ip\":\"10.0.0.194\",\"observed_remote_port\":48874}',2609384,164683144,426134,1156743,0,'exact');
/*!40000 ALTER TABLE `connection_session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `device`
--

DROP TABLE IF EXISTS `device`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '设备ID',
  `code` varchar(32) NOT NULL COMMENT '设备编码',
  `name` varchar(64) NOT NULL COMMENT '设备名称',
  `device_type` int NOT NULL DEFAULT '0' COMMENT '设备类型: 0:其他, 1:PCS, 2:BMS, 3:空调, 4:电表, 5:消防',
  `group_id` int DEFAULT NULL COMMENT '所属设备组ID（NULL表示未分组）',
  `enable` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  `created_at` datetime NOT NULL DEFAULT (now()) COMMENT '创建时间',
  `updated_at` datetime NOT NULL DEFAULT (now()) COMMENT '更新时间',
  `icd_path` varchar(512) DEFAULT NULL COMMENT 'ICD文件存储路径 (IEC61850)',
  `icd_file_hash` varchar(64) DEFAULT NULL COMMENT 'ICD文件内容Hash (IEC61850)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_device_code` (`code`),
  KEY `ix_device_group_id` (`group_id`),
  CONSTRAINT `device_ibfk_1` FOREIGN KEY (`group_id`) REFERENCES `device_group` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='设备表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `device`
--

LOCK TABLES `device` WRITE;
/*!40000 ALTER TABLE `device` DISABLE KEYS */;
INSERT INTO `device` VALUES (1,'PLC_SVR','PLC-仿真',0,1,1,'2026-11-12 08:17:49','2026-11-12 08:17:49',NULL,NULL),(2,'NCS_SVR','NCS-仿真',0,1,1,'2026-11-12 08:17:50','2026-11-12 08:17:50',NULL,NULL),(3,'MASTER_CLI','主站-仿真',0,1,1,'2026-11-12 08:17:50','2026-11-12 08:17:50',NULL,NULL);
/*!40000 ALTER TABLE `device` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `device_group`
--

DROP TABLE IF EXISTS `device_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_group` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '设备组ID',
  `code` varchar(32) NOT NULL COMMENT '设备组编码',
  `name` varchar(64) NOT NULL COMMENT '设备组名称',
  `parent_id` int DEFAULT NULL COMMENT '父设备组ID（用于多层嵌套）',
  `description` varchar(256) DEFAULT NULL COMMENT '设备组描述',
  `status` int NOT NULL DEFAULT '0' COMMENT '设备组状态: 0:正常, 1:告警, 2:故障, 3:离线',
  `enable` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  `created_at` datetime NOT NULL DEFAULT (now()) COMMENT '创建时间',
  `updated_at` datetime NOT NULL DEFAULT (now()) COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_device_group_code` (`code`),
  KEY `ix_device_group_parent_id` (`parent_id`),
  CONSTRAINT `device_group_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `device_group` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='设备组表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `device_group`
--

LOCK TABLES `device_group` WRITE;
/*!40000 ALTER TABLE `device_group` DISABLE KEYS */;
INSERT INTO `device_group` VALUES (1,'XAM_AVC','兴安盟AVC仿真',NULL,'qplantagc 对端仿真（被测端=麒麟VM 10.0.0.194）',0,1,'2026-11-12 08:17:49','2026-11-12 08:17:49');
/*!40000 ALTER TABLE `device_group` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dlt698_point`
--

DROP TABLE IF EXISTS `dlt698_point`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dlt698_point` (
  `id` int NOT NULL AUTO_INCREMENT,
  `channel_id` int NOT NULL,
  `code` varchar(128) NOT NULL,
  `definition` json NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dlt698_channel_code` (`channel_id`,`code`),
  KEY `ix_dlt698_point_channel_id` (`channel_id`),
  CONSTRAINT `dlt698_point_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dlt698_point`
--

LOCK TABLES `dlt698_point` WRITE;
/*!40000 ALTER TABLE `dlt698_point` DISABLE KEYS */;
/*!40000 ALTER TABLE `dlt698_point` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `goose_entry`
--

DROP TABLE IF EXISTS `goose_entry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `goose_entry` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '条目ID',
  `publisher_id` int NOT NULL COMMENT '所属 Publisher ID',
  `name` varchar(256) NOT NULL COMMENT '条目名称 (FCDA 引用路径)',
  `value` text COMMENT '默认值 (JSON 序列化)',
  `iec_type` varchar(32) NOT NULL DEFAULT 'boolean' COMMENT 'IEC 数据类型',
  `sort_order` int NOT NULL DEFAULT '0' COMMENT '排序序号',
  PRIMARY KEY (`id`),
  KEY `ix_goose_entry_publisher_id` (`publisher_id`),
  CONSTRAINT `goose_entry_ibfk_1` FOREIGN KEY (`publisher_id`) REFERENCES `goose_publisher` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `goose_entry`
--

LOCK TABLES `goose_entry` WRITE;
/*!40000 ALTER TABLE `goose_entry` DISABLE KEYS */;
/*!40000 ALTER TABLE `goose_entry` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `goose_publisher`
--

DROP TABLE IF EXISTS `goose_publisher`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `goose_publisher` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT 'Publisher ID',
  `channel_id` int DEFAULT NULL COMMENT '所属通道ID',
  `interface` varchar(64) NOT NULL DEFAULT 'eth0' COMMENT '网络接口',
  `go_cb_ref` varchar(256) NOT NULL COMMENT 'GOOSE 控制块引用',
  `go_id` varchar(128) NOT NULL DEFAULT '' COMMENT 'GOOSE 标识符',
  `data_set_ref` varchar(256) NOT NULL DEFAULT '' COMMENT '数据集引用',
  `app_id` int NOT NULL DEFAULT '1' COMMENT 'APPID',
  `conf_rev` int NOT NULL DEFAULT '1' COMMENT '配置修订号',
  `time_allowed_to_live` int NOT NULL DEFAULT '10000' COMMENT '存活时间 (ms)',
  `dst_mac_json` text COMMENT '目标 MAC 地址 (JSON 数组)',
  `vlan_id` int NOT NULL DEFAULT '0' COMMENT 'VLAN ID',
  `vlan_prio` int NOT NULL DEFAULT '4' COMMENT 'VLAN 优先级',
  `simulation` tinyint(1) NOT NULL DEFAULT '1' COMMENT '仿真模式',
  `retransmit_initial_ms` int NOT NULL DEFAULT '2',
  `retransmit_multiplier` float NOT NULL DEFAULT '2',
  `retransmit_final_ms` int NOT NULL DEFAULT '5000',
  `needs_commissioning` tinyint(1) NOT NULL DEFAULT '0',
  `name` varchar(128) NOT NULL DEFAULT '' COMMENT '显示名称',
  `description` varchar(512) NOT NULL DEFAULT '' COMMENT '描述',
  `auto_start` tinyint(1) NOT NULL DEFAULT '0' COMMENT '自动启动',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_goose_publisher_channel_gocb` (`channel_id`,`go_cb_ref`),
  KEY `ix_goose_publisher_go_cb_ref` (`go_cb_ref`),
  KEY `ix_goose_publisher_channel_id` (`channel_id`),
  CONSTRAINT `goose_publisher_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='GOOSE 发布配置';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `goose_publisher`
--

LOCK TABLES `goose_publisher` WRITE;
/*!40000 ALTER TABLE `goose_publisher` DISABLE KEYS */;
/*!40000 ALTER TABLE `goose_publisher` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `goose_receiver`
--

DROP TABLE IF EXISTS `goose_receiver`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `goose_receiver` (
  `id` int NOT NULL AUTO_INCREMENT,
  `channel_id` int NOT NULL,
  `name` varchar(128) NOT NULL DEFAULT 'default',
  `description` varchar(512) NOT NULL DEFAULT '',
  `interface` varchar(256) NOT NULL,
  `auto_start` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_goose_receiver_channel_interface_name` (`channel_id`,`interface`,`name`),
  KEY `ix_goose_receiver_channel_id` (`channel_id`),
  CONSTRAINT `goose_receiver_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='GOOSE 接收器配置';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `goose_receiver`
--

LOCK TABLES `goose_receiver` WRITE;
/*!40000 ALTER TABLE `goose_receiver` DISABLE KEYS */;
/*!40000 ALTER TABLE `goose_receiver` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `goose_subscription`
--

DROP TABLE IF EXISTS `goose_subscription`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `goose_subscription` (
  `id` int NOT NULL AUTO_INCREMENT,
  `receiver_id` int NOT NULL,
  `go_cb_ref` varchar(256) NOT NULL,
  `app_id` int DEFAULT NULL,
  `dst_mac_json` text,
  `description` varchar(512) NOT NULL DEFAULT '',
  `data_set_ref` varchar(256) NOT NULL DEFAULT '',
  `conf_rev` int NOT NULL DEFAULT '0',
  `enabled` tinyint(1) NOT NULL DEFAULT '0',
  `ied_name` varchar(128) NOT NULL DEFAULT '',
  `ld_inst` varchar(128) NOT NULL DEFAULT '',
  `ln_name` varchar(128) NOT NULL DEFAULT 'LLN0',
  `dataset_entries_json` text,
  `go_id` varchar(256) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_goose_subscription_filter` (`receiver_id`,`go_cb_ref`,`app_id`),
  KEY `ix_goose_subscription_receiver_id` (`receiver_id`),
  CONSTRAINT `goose_subscription_ibfk_1` FOREIGN KEY (`receiver_id`) REFERENCES `goose_receiver` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='GOOSE 订阅配置';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `goose_subscription`
--

LOCK TABLES `goose_subscription` WRITE;
/*!40000 ALTER TABLE `goose_subscription` DISABLE KEYS */;
/*!40000 ALTER TABLE `goose_subscription` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `iec61850_model_project`
--

DROP TABLE IF EXISTS `iec61850_model_project`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `iec61850_model_project` (
  `id` varchar(36) NOT NULL,
  `name` varchar(128) NOT NULL,
  `code` varchar(64) NOT NULL,
  `description` varchar(512) NOT NULL,
  `file_type` varchar(16) NOT NULL,
  `standard_version` varchar(32) NOT NULL,
  `namespace` varchar(256) NOT NULL,
  `modeling_mode` varchar(32) NOT NULL,
  `status` varchar(16) NOT NULL,
  `revision` int NOT NULL,
  `validation_errors` int NOT NULL,
  `validation_warnings` int NOT NULL,
  `model_json` longtext NOT NULL,
  `model_format_version` int NOT NULL,
  `model_node_count` int NOT NULL,
  `model_checksum` varchar(64) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  `updated_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_iec61850_model_project_code` (`code`),
  KEY `ix_iec61850_model_project_status` (`status`),
  KEY `ix_iec61850_model_project_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `iec61850_model_project`
--

LOCK TABLES `iec61850_model_project` WRITE;
/*!40000 ALTER TABLE `iec61850_model_project` DISABLE KEYS */;
/*!40000 ALTER TABLE `iec61850_model_project` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `iec61850_model_version`
--

DROP TABLE IF EXISTS `iec61850_model_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `iec61850_model_version` (
  `id` varchar(36) NOT NULL,
  `project_id` varchar(36) NOT NULL,
  `version_number` int NOT NULL,
  `label` varchar(128) NOT NULL,
  `description` varchar(512) NOT NULL,
  `status` varchar(16) NOT NULL,
  `source_revision` int NOT NULL,
  `snapshot_json` longtext NOT NULL,
  `created_at` datetime NOT NULL DEFAULT (now()),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_iec61850_model_version_number` (`project_id`,`version_number`),
  KEY `ix_iec61850_model_version_project_id` (`project_id`),
  KEY `ix_iec61850_model_version_status` (`status`),
  CONSTRAINT `iec61850_model_version_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `iec61850_model_project` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `iec61850_model_version`
--

LOCK TABLES `iec61850_model_version` WRITE;
/*!40000 ALTER TABLE `iec61850_model_version` DISABLE KEYS */;
/*!40000 ALTER TABLE `iec61850_model_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `opcua_config`
--

DROP TABLE IF EXISTS `opcua_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `opcua_config` (
  `channel_id` int NOT NULL,
  `schema_version` int NOT NULL,
  `endpoint_url` varchar(1024) DEFAULT NULL,
  `endpoint_path` varchar(255) NOT NULL,
  `namespace_uri` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`channel_id`),
  CONSTRAINT `opcua_config_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `opcua_config`
--

LOCK TABLES `opcua_config` WRITE;
/*!40000 ALTER TABLE `opcua_config` DISABLE KEYS */;
/*!40000 ALTER TABLE `opcua_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `opcua_feature`
--

DROP TABLE IF EXISTS `opcua_feature`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `opcua_feature` (
  `channel_id` int NOT NULL,
  `name` varchar(64) NOT NULL,
  `schema_version` int NOT NULL,
  `config` json NOT NULL,
  PRIMARY KEY (`channel_id`,`name`),
  CONSTRAINT `opcua_feature_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `opcua_feature`
--

LOCK TABLES `opcua_feature` WRITE;
/*!40000 ALTER TABLE `opcua_feature` DISABLE KEYS */;
/*!40000 ALTER TABLE `opcua_feature` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `opcua_node`
--

DROP TABLE IF EXISTS `opcua_node`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `opcua_node` (
  `id` int NOT NULL AUTO_INCREMENT,
  `channel_id` int NOT NULL,
  `schema_version` int NOT NULL,
  `namespace_uri` varchar(255) NOT NULL,
  `node_id` varchar(512) NOT NULL,
  `browse_name` varchar(128) NOT NULL,
  `data_type` varchar(32) NOT NULL,
  `initial_value` json NOT NULL,
  `writable` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_opcua_node_channel_node_id` (`channel_id`,`node_id`),
  KEY `ix_opcua_node_channel_id` (`channel_id`),
  CONSTRAINT `opcua_node_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `opcua_node`
--

LOCK TABLES `opcua_node` WRITE;
/*!40000 ALTER TABLE `opcua_node` DISABLE KEYS */;
/*!40000 ALTER TABLE `opcua_node` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `opcua_point`
--

DROP TABLE IF EXISTS `opcua_point`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `opcua_point` (
  `id` int NOT NULL AUTO_INCREMENT,
  `channel_id` int NOT NULL,
  `schema_version` int NOT NULL,
  `point_type` int NOT NULL,
  `point_code` varchar(128) NOT NULL,
  `point_name` varchar(255) NOT NULL,
  `attribute_code` varchar(255) NOT NULL,
  `node_id` varchar(512) NOT NULL,
  `namespace_uri` varchar(255) NOT NULL,
  `data_type` varchar(32) NOT NULL,
  `sampling_interval_ms` int NOT NULL,
  `unit` varchar(64) DEFAULT NULL,
  `scale_mul` float DEFAULT NULL,
  `scale_add` float DEFAULT NULL,
  `upper_limit` float DEFAULT NULL,
  `lower_limit` float DEFAULT NULL,
  `initial_value` json NOT NULL,
  `reverse` tinyint(1) NOT NULL,
  `command_type` varchar(64) DEFAULT NULL,
  `related_code` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_opcua_point_code` (`channel_id`,`point_code`),
  UNIQUE KEY `uq_opcua_point_node_id` (`channel_id`,`node_id`),
  KEY `ix_opcua_point_channel_id` (`channel_id`),
  CONSTRAINT `opcua_point_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `opcua_point`
--

LOCK TABLES `opcua_point` WRITE;
/*!40000 ALTER TABLE `opcua_point` DISABLE KEYS */;
/*!40000 ALTER TABLE `opcua_point` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `opcua_secret`
--

DROP TABLE IF EXISTS `opcua_secret`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `opcua_secret` (
  `channel_id` int NOT NULL,
  `name` varchar(128) NOT NULL,
  `ciphertext` text NOT NULL,
  PRIMARY KEY (`channel_id`,`name`),
  CONSTRAINT `opcua_secret_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `opcua_secret`
--

LOCK TABLES `opcua_secret` WRITE;
/*!40000 ALTER TABLE `opcua_secret` DISABLE KEYS */;
/*!40000 ALTER TABLE `opcua_secret` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `point_mapping`
--

DROP TABLE IF EXISTS `point_mapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `point_mapping` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '映射ID',
  `device_name` varchar(64) NOT NULL COMMENT '设备名称',
  `target_point_code` varchar(64) NOT NULL COMMENT '目标测点编码',
  `source_point_codes` text NOT NULL COMMENT '源测点编码列表(JSON)',
  `formula` text NOT NULL COMMENT '计算公式',
  `enable` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uix_device_target_point` (`device_name`,`target_point_code`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='测点映射表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `point_mapping`
--

LOCK TABLES `point_mapping` WRITE;
/*!40000 ALTER TABLE `point_mapping` DISABLE KEYS */;
INSERT INTO `point_mapping` VALUES (1,'PLC-仿真','YC301','[{\"device_name\": \"PLC-\\u4eff\\u771f\", \"point_code\": \"YS1\", \"alias\": \"YS1\"}]','YS1',1),(2,'PLC-仿真','YC303','[{\"device_name\": \"PLC-\\u4eff\\u771f\", \"point_code\": \"YS4\", \"alias\": \"YS4\"}]','YS4',1),(3,'PLC-仿真','YC305','[{\"device_name\": \"PLC-\\u4eff\\u771f\", \"point_code\": \"YS6\", \"alias\": \"YS6\"}]','YS6',1),(4,'PLC-仿真','YC307','[{\"device_name\": \"PLC-\\u4eff\\u771f\", \"point_code\": \"YS7\", \"alias\": \"YS7\"}]','YS7',1),(5,'NCS-仿真','YC501','[{\"device_name\": \"PLC-\\u4eff\\u771f\", \"point_code\": \"YS1\", \"alias\": \"YS1\"}]','YS1',1),(6,'NCS-仿真','YC601','[{\"device_name\": \"PLC-\\u4eff\\u771f\", \"point_code\": \"YS4\", \"alias\": \"YS4\"}]','YS4',1),(7,'NCS-仿真','YC901','[{\"device_name\": \"PLC-\\u4eff\\u771f\", \"point_code\": \"YS6\", \"alias\": \"YS6\"}]','YS6',1),(8,'NCS-仿真','YC1001','[{\"device_name\": \"PLC-\\u4eff\\u771f\", \"point_code\": \"YS7\", \"alias\": \"YS7\"}]','YS7',1);
/*!40000 ALTER TABLE `point_mapping` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `point_yc`
--

DROP TABLE IF EXISTS `point_yc`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `point_yc` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '测点ID',
  `code` varchar(64) NOT NULL COMMENT '测点编码',
  `name` varchar(64) NOT NULL COMMENT '测点名称',
  `channel_id` int DEFAULT NULL COMMENT '所属通道ID',
  `rtu_addr` int NOT NULL DEFAULT '1' COMMENT '从机地址/IEC104信息对象地址',
  `reg_addr` varchar(128) NOT NULL COMMENT '寄存器地址',
  `func_code` int NOT NULL DEFAULT '3' COMMENT '功能码',
  `decode_code` varchar(32) NOT NULL DEFAULT 'INT32_ABCD' COMMENT '解析码(Modbus专用)',
  `mul_coe` float NOT NULL DEFAULT '1' COMMENT '乘系数',
  `add_coe` float NOT NULL DEFAULT '0' COMMENT '加系数',
  `max_limit` float NOT NULL COMMENT '上限值',
  `min_limit` float NOT NULL COMMENT '下限值',
  `iec_common_address` int DEFAULT NULL COMMENT 'IEC104公共地址',
  `iec_cot` int DEFAULT '3' COMMENT 'IEC104传送原因(COT)',
  `iec_quality` int DEFAULT '0' COMMENT 'IEC104品质描述符(位标志: OV BL SB NT IV)',
  `iec_type_id` varchar(16) DEFAULT NULL COMMENT 'IEC104类型标识(如M_ME_NC_1)',
  `fc` varchar(8) DEFAULT NULL COMMENT 'IEC61850功能约束(FC), 如MX/ST/CO/DC/CF/SF等',
  `dnp3_config` text COMMENT 'DNP3点级配置(JSON)',
  `enable` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_point_yc_code_channel_rtu` (`code`,`channel_id`,`rtu_addr`),
  KEY `ix_point_yc_code` (`code`),
  KEY `ix_point_yc_channel_id` (`channel_id`),
  CONSTRAINT `point_yc_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=156 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='遥测测点表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `point_yc`
--

LOCK TABLES `point_yc` WRITE;
/*!40000 ALTER TABLE `point_yc` DISABLE KEYS */;
INSERT INTO `point_yc` VALUES (77,'YC512','#1机组_有功功率上限',1,1,'0',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(78,'YC513','#1机组_有功功率下限',1,1,'1',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(79,'YC514','#1机组_有功调节速度',1,1,'2',4,'INT16_AB',1,0,3.5,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(80,'YC301','#1机组有功功率指令反馈',1,1,'3',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(81,'YC612','#2机组_有功功率上限',1,1,'4',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(82,'YC613','#2机组_有功功率下限',1,1,'5',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(83,'YC614','#2机组_有功调节速度',1,1,'6',4,'INT16_AB',1,0,4,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(84,'YC303','#2机组有功功率指令反馈',1,1,'7',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(85,'YC912','#3机组_有功功率上限',1,1,'8',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(86,'YC913','#3机组_有功功率下限',1,1,'9',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(87,'YC914','#3机组_有功调节速度',1,1,'10',4,'INT16_AB',1,0,3.5,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(88,'YC305','#3机组有功功率指令反馈',1,1,'11',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(89,'YC1012','#4机组_有功功率上限',1,1,'12',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(90,'YC1013','#4机组_有功功率下限',1,1,'13',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(91,'YC1014','#4机组_有功调节速度',1,1,'14',4,'INT16_AB',1,0,4,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(92,'YC307','#4机组有功功率指令反馈',1,1,'15',4,'INT16_AB',1,0,1000000000,-1000000000,NULL,3,0,NULL,NULL,NULL,1),(93,'YC222','1#二次P_1#母线',2,257,'16385',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(94,'YC225','1#二次F_1#母线',2,257,'16386',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(95,'YC223','1#二次Q_1#母线',2,257,'16387',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(96,'YC219','1#二次Uab_1#母线',2,257,'16388',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(97,'YC220','1#二次Ubc_1#母线',2,257,'16389',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(98,'YC221','1#二次Uca_1#母线',2,257,'16390',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(99,'YC216','1#二次Ia_1#母线',2,257,'16391',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(100,'YC217','1#二次Ib_1#母线',2,257,'16392',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(101,'YC218','1#二次Ic_1#母线',2,257,'16393',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(102,'YC224','1#二次COS_1#母线',2,257,'16394',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(103,'YC235','2#二次P_2#母线',2,257,'16395',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(104,'YC238','2#二次F_2#母线',2,257,'16396',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(105,'YC236','2#二次Q_2#母线',2,257,'16397',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(106,'YC232','2#二次Uab_2#母线',2,257,'16398',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(107,'YC233','2#二次Ubc_2#母线',2,257,'16399',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(108,'YC234','2#二次Uca_2#母线',2,257,'16400',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(109,'YC229','2#二次Ia_2#母线',2,257,'16401',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(110,'YC230','2#二次Ib_2#母线',2,257,'16402',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(111,'YC231','2#二次Ic_2#母线',2,257,'16403',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(112,'YC237','2#二次COS_2#母线',2,257,'16404',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(113,'YC501','#1机组_有功功率',2,257,'16405',3,'FLOAT32_ABCD',1,0,6,0,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(114,'YC502','#1机组_频率',2,257,'16406',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(115,'YC503','#1机组_无功功率',2,257,'16407',3,'FLOAT32_ABCD',1,0,4.5,0,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(116,'YC504','#1机组_线电压uab',2,257,'16408',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(117,'YC505','#1机组_线电压ubc',2,257,'16409',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(118,'YC506','#1机组_线电压uca',2,257,'16410',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(119,'YC507','#1机组_A相电流',2,257,'16412',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(120,'YC508','#1机组_B相电流',2,257,'16414',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(121,'YC509','#1机组_C相电流',2,257,'16415',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(122,'YC515','#1机组_功率因数',2,257,'16416',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(123,'YC601','#2机组_有功功率',2,257,'16417',3,'FLOAT32_ABCD',1,0,15,0,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(124,'YC602','#2机组_频率',2,257,'16418',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(125,'YC603','#2机组_无功功率',2,257,'16419',3,'FLOAT32_ABCD',1,0,11.25,0,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(126,'YC604','#2机组_线电压uab',2,257,'16420',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(127,'YC605','#2机组_线电压ubc',2,257,'16421',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(128,'YC606','#2机组_线电压uca',2,257,'16422',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(129,'YC607','#2机组_A相电流',2,257,'16423',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(130,'YC608','#2机组_B相电流',2,257,'16424',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(131,'YC609','#2机组_C相电流',2,257,'16425',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(132,'YC615','#2机组_功率因数',2,257,'16426',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(133,'YC901','#3机组_有功功率',2,257,'16427',3,'FLOAT32_ABCD',1,0,6,0,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(134,'YC902','#3机组_频率',2,257,'16428',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(135,'YC903','#3机组_无功功率',2,257,'16429',3,'FLOAT32_ABCD',1,0,4.5,0,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(136,'YC904','#3机组_线电压uab',2,257,'16430',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(137,'YC905','#3机组_线电压ubc',2,257,'16431',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(138,'YC906','#3机组_线电压uca',2,257,'16432',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(139,'YC907','#3机组_A相电流',2,257,'16433',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(140,'YC908','#3机组_B相电流',2,257,'16434',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(141,'YC909','#3机组_C相电流',2,257,'16435',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(142,'YC915','#3机组_功率因数',2,257,'16436',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(143,'YC1001','#4机组_有功功率',2,257,'16437',3,'FLOAT32_ABCD',1,0,15,0,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(144,'YC1002','#4机组_频率',2,257,'16438',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(145,'YC1003','#4机组_无功功率',2,257,'16439',3,'FLOAT32_ABCD',1,0,11.25,0,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(146,'YC1004','#4机组_线电压uab',2,257,'16440',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(147,'YC1005','#4机组_线电压ubc',2,257,'16441',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(148,'YC1006','#4机组_线电压uca',2,257,'16442',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(149,'YC1007','#4机组_A相电流',2,257,'16443',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(150,'YC1008','#4机组_B相电流',2,257,'16444',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(151,'YC1009','#4机组_C相电流',2,257,'16445',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(152,'YC1015','#4机组_功率因数',2,257,'16446',3,'FLOAT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(153,'YC101','1#母线有功指令执行值',3,1,'16385',3,'INT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1),(154,'YC103','1#母线有功功率计算值',3,1,'16390',3,'INT32_ABCD',1,0,2147480000,-2147480000,NULL,3,0,'M_ME_NC_1',NULL,NULL,1);
/*!40000 ALTER TABLE `point_yc` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `point_yk`
--

DROP TABLE IF EXISTS `point_yk`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `point_yk` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '测点ID',
  `code` varchar(64) NOT NULL COMMENT '测点编码',
  `name` varchar(64) NOT NULL COMMENT '测点名称',
  `channel_id` int DEFAULT NULL COMMENT '所属通道ID',
  `rtu_addr` int NOT NULL DEFAULT '1' COMMENT '从机地址/IEC104信息对象地址',
  `reg_addr` varchar(128) NOT NULL COMMENT '寄存器地址',
  `func_code` int NOT NULL DEFAULT '5' COMMENT '功能码',
  `decode_code` varchar(32) NOT NULL DEFAULT 'UINT16_AB' COMMENT '解析码(Modbus专用)',
  `bit` int DEFAULT NULL COMMENT '位偏移',
  `command_type` int NOT NULL DEFAULT '0' COMMENT '命令类型: 0:单点, 1:双点',
  `related_yx_id` int DEFAULT NULL COMMENT '关联遥信点ID',
  `iec_common_address` int DEFAULT NULL COMMENT 'IEC104公共地址',
  `iec_cot` int DEFAULT '3' COMMENT 'IEC104传送原因(COT)',
  `iec_quality` int DEFAULT '0' COMMENT 'IEC104品质描述符(遥控方向通常不带品质)',
  `iec_type_id` varchar(16) DEFAULT NULL COMMENT 'IEC104类型标识(如C_SC_NA_1)',
  `fc` varchar(8) DEFAULT NULL COMMENT 'IEC61850功能约束(FC), 如MX/ST/CO/DC/CF/SF等',
  `dnp3_config` text COMMENT 'DNP3点级配置(JSON)',
  `enable` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_point_yk_code_channel_rtu` (`code`,`channel_id`,`rtu_addr`),
  KEY `related_yx_id` (`related_yx_id`),
  KEY `ix_point_yk_channel_id` (`channel_id`),
  KEY `ix_point_yk_code` (`code`),
  CONSTRAINT `point_yk_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`),
  CONSTRAINT `point_yk_ibfk_2` FOREIGN KEY (`related_yx_id`) REFERENCES `point_yx` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='遥控测点表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `point_yk`
--

LOCK TABLES `point_yk` WRITE;
/*!40000 ALTER TABLE `point_yk` DISABLE KEYS */;
INSERT INTO `point_yk` VALUES (1,'YK0','#1机组投入/退出',1,1,'51',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(2,'YK1','#1机组故障总',1,1,'52',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(3,'YK2','#1机组增闭锁',1,1,'53',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(4,'YK3','#1机组减闭锁',1,1,'54',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(5,'YK4','#1机组超出调节能力',1,1,'55',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(6,'YK5','#2机组投入/退出',1,1,'56',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(7,'YK6','#2机组故障总',1,1,'57',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(8,'YK7','#2机组增闭锁',1,1,'58',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(9,'YK8','#2机组减闭锁',1,1,'59',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(10,'YK9','#2机组超出调节能力',1,1,'60',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(11,'YK10','#3机组投入/退出',1,1,'61',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(12,'YK11','#3机组故障总',1,1,'62',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(13,'YK12','#3机组增闭锁',1,1,'63',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(14,'YK13','#3机组减闭锁',1,1,'64',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(15,'YK14','#3机组超出调节能力',1,1,'65',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(16,'YK15','#4机组投入/退出',1,1,'66',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(17,'YK16','#4机组故障总',1,1,'67',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(18,'YK17','#4机组增闭锁',1,1,'68',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(19,'YK18','#4机组减闭锁',1,1,'69',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1),(20,'YK19','#4机组超出调节能力',1,1,'70',5,'UINT16_AB',NULL,0,NULL,NULL,3,0,NULL,NULL,NULL,1);
/*!40000 ALTER TABLE `point_yk` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `point_yt`
--

DROP TABLE IF EXISTS `point_yt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `point_yt` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '测点ID',
  `code` varchar(64) NOT NULL COMMENT '测点编码',
  `name` varchar(64) NOT NULL COMMENT '测点名称',
  `channel_id` int DEFAULT NULL COMMENT '所属通道ID',
  `rtu_addr` int NOT NULL DEFAULT '1' COMMENT '从机地址/IEC104信息对象地址',
  `reg_addr` varchar(128) NOT NULL COMMENT '寄存器地址',
  `func_code` int NOT NULL DEFAULT '3' COMMENT '功能码',
  `decode_code` varchar(32) NOT NULL DEFAULT 'UINT16_AB' COMMENT '解析码(Modbus专用)',
  `mul_coe` float NOT NULL DEFAULT '1' COMMENT '乘系数',
  `add_coe` float NOT NULL DEFAULT '0' COMMENT '加系数',
  `max_limit` float NOT NULL COMMENT '上限值',
  `min_limit` float NOT NULL COMMENT '下限值',
  `related_yc_id` int DEFAULT NULL COMMENT '关联遥测点ID',
  `iec_common_address` int DEFAULT NULL COMMENT 'IEC104公共地址',
  `iec_cot` int DEFAULT '3' COMMENT 'IEC104传送原因(COT)',
  `iec_quality` int DEFAULT '0' COMMENT 'IEC104品质描述符(位标志: OV BL SB NT IV)',
  `iec_type_id` varchar(16) DEFAULT NULL COMMENT 'IEC104类型标识(如C_SE_NC_1)',
  `fc` varchar(8) DEFAULT NULL COMMENT 'IEC61850功能约束(FC), 如MX/ST/CO/DC/CF/SF等',
  `dnp3_config` text COMMENT 'DNP3点级配置(JSON)',
  `enable` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_point_yt_code_channel_rtu` (`code`,`channel_id`,`rtu_addr`),
  KEY `related_yc_id` (`related_yc_id`),
  KEY `ix_point_yt_code` (`code`),
  KEY `ix_point_yt_channel_id` (`channel_id`),
  CONSTRAINT `point_yt_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`),
  CONSTRAINT `point_yt_ibfk_2` FOREIGN KEY (`related_yc_id`) REFERENCES `point_yc` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='遥调测点表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `point_yt`
--

LOCK TABLES `point_yt` WRITE;
/*!40000 ALTER TABLE `point_yt` DISABLE KEYS */;
INSERT INTO `point_yt` VALUES (1,'YS1','1#机组数字遥设指令',1,1,'51',6,'INT16_AB',1,0,1000000000,-1000000000,NULL,NULL,3,0,NULL,NULL,NULL,1),(2,'YS4','2#机组数字遥设指令',1,1,'52',6,'INT16_AB',1,0,1000000000,-1000000000,NULL,NULL,3,0,NULL,NULL,NULL,1),(3,'YS6','3#机组数字遥设指令',1,1,'53',6,'INT16_AB',1,0,1000000000,-1000000000,NULL,NULL,3,0,NULL,NULL,NULL,1),(4,'YS7','4#机组数字遥设指令',1,1,'54',6,'INT16_AB',1,0,1000000000,-1000000000,NULL,NULL,3,0,NULL,NULL,NULL,1),(5,'YS5','有功功率AGC设定值',3,1,'25089',6,'INT32_ABCD',0.171,0,367220000,-367220000,NULL,NULL,3,0,'C_SE_NC_1',NULL,NULL,1);
/*!40000 ALTER TABLE `point_yt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `point_yx`
--

DROP TABLE IF EXISTS `point_yx`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `point_yx` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '测点ID',
  `code` varchar(64) NOT NULL COMMENT '测点编码',
  `name` varchar(64) NOT NULL COMMENT '测点名称',
  `channel_id` int DEFAULT NULL COMMENT '所属通道ID',
  `rtu_addr` int NOT NULL DEFAULT '1' COMMENT '从机地址/IEC104信息对象地址',
  `reg_addr` varchar(128) NOT NULL COMMENT '寄存器地址',
  `func_code` int NOT NULL DEFAULT '1' COMMENT '功能码',
  `decode_code` varchar(32) NOT NULL DEFAULT 'UINT16_AB' COMMENT '解析码(Modbus专用)',
  `bit` int DEFAULT NULL COMMENT '位偏移',
  `reverse` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否反转',
  `iec_common_address` int DEFAULT NULL COMMENT 'IEC104公共地址',
  `iec_cot` int DEFAULT '3' COMMENT 'IEC104传送原因(COT)',
  `iec_quality` int DEFAULT '0' COMMENT 'IEC104品质描述符(位标志: BL=0x02 SB=0x04 NT=0x08 IV=0x10)',
  `iec_type_id` varchar(16) DEFAULT NULL COMMENT 'IEC104类型标识(如M_SP_NA_1)',
  `fc` varchar(8) DEFAULT NULL COMMENT 'IEC61850功能约束(FC), 如MX/ST/CO/DC/CF/SF等',
  `dnp3_config` text COMMENT 'DNP3点级配置(JSON)',
  `enable` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_point_yx_code_channel_rtu` (`code`,`channel_id`,`rtu_addr`),
  KEY `ix_point_yx_code` (`code`),
  KEY `ix_point_yx_channel_id` (`channel_id`),
  CONSTRAINT `point_yx_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='遥信测点表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `point_yx`
--

LOCK TABLES `point_yx` WRITE;
/*!40000 ALTER TABLE `point_yx` DISABLE KEYS */;
INSERT INTO `point_yx` VALUES (44,'YX302','#1机组AGC开关锁',1,1,'0',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(45,'YX305','#1机组负荷禁增状态',1,1,'1',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(46,'YX306','#1机组负荷禁减状态',1,1,'2',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(47,'YX301','#1机组DCS侧AGC投入/退出',1,1,'3',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(48,'YX414','#1机组一次调频状态',1,1,'4',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(49,'YX304','#1机组并网状态',1,1,'5',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(50,'YX303','#1机组RB状态',1,1,'6',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(51,'YX351','#1机组故障总',1,1,'7',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(52,'YX309','#2机组AGC开关锁',1,1,'8',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(53,'YX312','#2机组负荷禁增',1,1,'9',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(54,'YX313','#2机组负荷禁减',1,1,'10',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(55,'YX308','#2机组DCS侧AGC投入/退出',1,1,'11',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(56,'YX514','#2机组一次调频状态',1,1,'12',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(57,'YX311','#2机组并网状态',1,1,'13',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(58,'YX310','#2机组RB状态',1,1,'14',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(59,'YX353','#2机组故障总',1,1,'15',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(60,'YX602','#3机组AGC开关锁',1,1,'16',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(61,'YX605','#3机组负荷禁增状态',1,1,'17',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(62,'YX606','#3机组负荷禁减状态',1,1,'18',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(63,'YX601','#3机组DCS侧AGC投入/退出',1,1,'19',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(64,'YX714','#3机组一次调频状态',1,1,'20',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(65,'YX604','#3机组并网状态',1,1,'21',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(66,'YX603','#3机组RB状态',1,1,'22',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(67,'YX651','#3机组故障总',1,1,'23',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(68,'YX609','#4机组AGC开关锁',1,1,'24',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(69,'YX612','#4机组负荷禁增',1,1,'25',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(70,'YX613','#4机组负荷禁减',1,1,'26',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(71,'YX608','#4机组DCS侧AGC投入/退出',1,1,'27',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(72,'YX814','#4机组一次调频状态',1,1,'28',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(73,'YX611','#4机组并网状态',1,1,'29',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(74,'YX610','#4机组RB状态',1,1,'30',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(75,'YX653','#4机组故障总',1,1,'31',2,'UINT16_AB',NULL,0,NULL,3,0,NULL,NULL,NULL,1),(76,'YX201','#1机组开关',2,257,'1',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(77,'YX211','#2机组开关',2,257,'2',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(78,'YX221','#3机组开关',2,257,'3',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(79,'YX231','#4机组开关',2,257,'4',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(80,'YX241','10kVI母开关1',2,257,'5',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(81,'YX242','10kVI母开关2',2,257,'6',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(82,'YX243','10kVI母开关3',2,257,'7',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(83,'YX251','10kVII母开关1',2,257,'8',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(84,'YX252','10kVII母开关1',2,257,'9',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(85,'YX253','10kVII母开关1',2,257,'10',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(86,'YX261','10kV母联开关',2,257,'11',1,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(87,'YX3','AGC允许投入远方调节',3,1,'0x0001',3,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1),(88,'YX4','1#母线AGC投入/退出',3,1,'0x0002',3,'UINT16_AB',NULL,0,NULL,3,0,'M_SP_NA_1',NULL,NULL,1);
/*!40000 ALTER TABLE `point_yx` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `slave`
--

DROP TABLE IF EXISTS `slave`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `slave` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `channel_id` int NOT NULL COMMENT '所属通道ID',
  `slave_id` int NOT NULL COMMENT '从机地址(0-247)',
  `name` varchar(64) DEFAULT NULL COMMENT '从机名称',
  `enable` tinyint(1) NOT NULL DEFAULT '1' COMMENT '是否启用',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_slave_channel_slave` (`channel_id`,`slave_id`),
  KEY `ix_slave_channel_id` (`channel_id`),
  CONSTRAINT `slave_ibfk_1` FOREIGN KEY (`channel_id`) REFERENCES `channel` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='从机表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `slave`
--

LOCK TABLES `slave` WRITE;
/*!40000 ALTER TABLE `slave` DISABLE KEYS */;
INSERT INTO `slave` VALUES (1,2,257,'NCS公共地址',1),(2,3,257,'主站公共地址',1),(3,1,1,'PLC从站',1);
/*!40000 ALTER TABLE `slave` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'net'
--

--
-- Dumping routines for database 'net'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed
