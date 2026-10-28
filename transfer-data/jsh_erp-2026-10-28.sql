-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: jsh_erp
-- ------------------------------------------------------
-- Server version	8.0.44

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
-- Current Database: `jsh_erp`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `jsh_erp` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `jsh_erp`;

--
-- Table structure for table `jsh_account`
--

DROP TABLE IF EXISTS `jsh_account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_account` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '名称',
  `serial_no` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '编号',
  `initial_amount` decimal(24,6) DEFAULT NULL COMMENT '期初金额',
  `current_amount` decimal(24,6) DEFAULT NULL COMMENT '当前余额',
  `remark` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `enabled` bit(1) DEFAULT NULL COMMENT '启用',
  `sort` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '排序',
  `is_default` bit(1) DEFAULT NULL COMMENT '是否默认',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='账户信息';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_account`
--

LOCK TABLES `jsh_account` WRITE;
/*!40000 ALTER TABLE `jsh_account` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_account` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_account_head`
--

DROP TABLE IF EXISTS `jsh_account_head`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_account_head` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型(支出/收入/收款/付款/转账)',
  `organ_id` bigint DEFAULT NULL COMMENT '单位Id(收款/付款单位)',
  `hands_person_id` bigint DEFAULT NULL COMMENT '经手人id',
  `creator` bigint DEFAULT NULL COMMENT '操作员',
  `change_amount` decimal(24,6) DEFAULT NULL COMMENT '变动金额(优惠/收款/付款/实付)',
  `discount_money` decimal(24,6) DEFAULT NULL COMMENT '优惠金额',
  `total_price` decimal(24,6) DEFAULT NULL COMMENT '合计金额',
  `account_id` bigint DEFAULT NULL COMMENT '账户(收款/付款)',
  `bill_no` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '单据编号',
  `bill_time` datetime DEFAULT NULL COMMENT '单据日期',
  `remark` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `file_name` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '附件名称',
  `status` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '状态，0未审核、1已审核、9审核中',
  `source` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '单据来源，0-pc，1-手机',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `FK9F4C0D8DB610FC06` (`organ_id`) USING BTREE,
  KEY `FK9F4C0D8DAAE50527` (`account_id`) USING BTREE,
  KEY `FK9F4C0D8DC4170B37` (`hands_person_id`) USING BTREE,
  KEY `bill_no` (`bill_no`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=127 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='财务主表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_account_head`
--

LOCK TABLES `jsh_account_head` WRITE;
/*!40000 ALTER TABLE `jsh_account_head` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_account_head` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_account_item`
--

DROP TABLE IF EXISTS `jsh_account_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_account_item` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `header_id` bigint NOT NULL COMMENT '表头Id',
  `account_id` bigint DEFAULT NULL COMMENT '账户Id',
  `in_out_item_id` bigint DEFAULT NULL COMMENT '收支项目Id',
  `bill_id` bigint DEFAULT NULL COMMENT '单据id',
  `need_debt` decimal(24,6) DEFAULT NULL COMMENT '应收欠款',
  `finish_debt` decimal(24,6) DEFAULT NULL COMMENT '已收欠款',
  `each_amount` decimal(24,6) DEFAULT NULL COMMENT '单项金额',
  `remark` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '单据备注',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `FK9F4CBAC0AAE50527` (`account_id`) USING BTREE,
  KEY `FK9F4CBAC0C5FE6007` (`header_id`) USING BTREE,
  KEY `FK9F4CBAC0D203EDC5` (`in_out_item_id`) USING BTREE,
  KEY `bill_id` (`bill_id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=152 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='财务子表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_account_item`
--

LOCK TABLES `jsh_account_item` WRITE;
/*!40000 ALTER TABLE `jsh_account_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_account_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_depot`
--

DROP TABLE IF EXISTS `jsh_depot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_depot` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '仓库名称',
  `address` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '仓库地址',
  `warehousing` decimal(24,6) DEFAULT NULL COMMENT '仓储费',
  `truckage` decimal(24,6) DEFAULT NULL COMMENT '搬运费',
  `type` int DEFAULT NULL COMMENT '类型',
  `sort` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '排序',
  `remark` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `principal` bigint DEFAULT NULL COMMENT '负责人',
  `enabled` bit(1) DEFAULT NULL COMMENT '启用',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_Flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  `is_default` bit(1) DEFAULT NULL COMMENT '是否默认',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='仓库表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_depot`
--

LOCK TABLES `jsh_depot` WRITE;
/*!40000 ALTER TABLE `jsh_depot` DISABLE KEYS */;
INSERT INTO `jsh_depot` VALUES (19,'模拟原料仓',NULL,NULL,NULL,0,NULL,NULL,NULL,0x01,327,'0',0x00),(20,'模拟成品仓',NULL,NULL,NULL,0,NULL,NULL,NULL,0x01,327,'0',0x01);
/*!40000 ALTER TABLE `jsh_depot` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_depot_head`
--

DROP TABLE IF EXISTS `jsh_depot_head`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_depot_head` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型(出库/入库)',
  `sub_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '出入库分类',
  `default_number` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '初始票据号',
  `number` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '票据号',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `oper_time` datetime DEFAULT NULL COMMENT '出入库时间',
  `organ_id` bigint DEFAULT NULL COMMENT '供应商id',
  `creator` bigint DEFAULT NULL COMMENT '操作员',
  `account_id` bigint DEFAULT NULL COMMENT '账户id',
  `change_amount` decimal(24,6) DEFAULT NULL COMMENT '变动金额(收款/付款)',
  `back_amount` decimal(24,6) DEFAULT NULL COMMENT '找零金额',
  `total_price` decimal(24,6) DEFAULT NULL COMMENT '合计金额',
  `pay_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '付款类型(现金、记账等)',
  `bill_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '单据类型',
  `remark` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `file_name` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '附件名称',
  `sales_man` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '销售员（可以多个）',
  `account_id_list` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多账户ID列表',
  `account_money_list` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多账户金额列表',
  `discount` decimal(24,6) DEFAULT NULL COMMENT '优惠率',
  `discount_money` decimal(24,6) DEFAULT NULL COMMENT '优惠金额',
  `discount_last_money` decimal(24,6) DEFAULT NULL COMMENT '优惠后金额',
  `other_money` decimal(24,6) DEFAULT NULL COMMENT '销售或采购费用合计',
  `deposit` decimal(24,6) DEFAULT NULL COMMENT '订金',
  `last_deposit` decimal(24,6) DEFAULT NULL COMMENT '剩余订金',
  `debt` decimal(24,6) DEFAULT NULL COMMENT '本次欠款',
  `last_debt` decimal(24,6) DEFAULT NULL COMMENT '最终欠款',
  `status` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '状态，0未审核、1已审核、2完成采购|销售、3部分采购|销售、9审核中',
  `purchase_status` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '采购状态，0未采购、2完成采购、3部分采购',
  `source` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '单据来源，0-pc，1-手机',
  `link_number` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关联订单号',
  `link_apply` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关联请购单',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `FK2A80F214B610FC06` (`organ_id`) USING BTREE,
  KEY `FK2A80F214AAE50527` (`account_id`) USING BTREE,
  KEY `number` (`number`) USING BTREE,
  KEY `link_number` (`link_number`) USING BTREE,
  KEY `creator` (`creator`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=675 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='单据主表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_depot_head`
--

LOCK TABLES `jsh_depot_head` WRITE;
/*!40000 ALTER TABLE `jsh_depot_head` DISABLE KEYS */;
INSERT INTO `jsh_depot_head` VALUES (666,'入库','其它','SIM-RK-20261026-RAW-A','SIM-RK-20261026-RAW-A','2026-10-26 16:05:29','2026-10-26 16:05:27',NULL,338,NULL,0.000000,NULL,0.000000,'现付',NULL,'【模拟测试】原料A准备库存2吨；非真实配方、采购或生产耗用。',NULL,NULL,NULL,NULL,0.000000,0.000000,0.000000,0.000000,NULL,0.000000,0.000000,0.000000,'1','0','0',NULL,NULL,327,'0'),(667,'其它','销售订单',NULL,'XSDD20261027947FA92B-1FD','2026-10-27 08:25:51','2026-10-27 08:25:51',91,329,NULL,0.000000,NULL,207500.000000,'现付',NULL,'',NULL,NULL,NULL,NULL,0.000000,0.000000,207500.000000,0.000000,NULL,0.000000,0.000000,0.000000,'1','0','0',NULL,NULL,327,'0'),(668,'其它','销售订单',NULL,'XSDD20261027A572FFB5-B21','2026-10-27 08:27:17','2026-10-27 08:27:16',91,330,NULL,0.000000,NULL,3600.000000,'现付',NULL,'',NULL,NULL,NULL,NULL,0.000000,0.000000,3600.000000,0.000000,NULL,0.000000,0.000000,0.000000,'1','0','0',NULL,NULL,327,'0'),(669,'其它','销售订单',NULL,'XSDD2026102707563DAD-DFF','2026-10-27 08:32:37','2026-10-27 08:32:36',92,330,NULL,0.000000,NULL,1000.000000,'现付',NULL,'SELF-REVIEW-fdaee0d1',NULL,NULL,NULL,NULL,0.000000,0.000000,1000.000000,0.000000,NULL,0.000000,0.000000,0.000000,'0','0','0',NULL,NULL,327,'1'),(670,'其它','销售订单',NULL,'XSDD20261027B7697AAB-465','2026-10-27 08:32:54','2026-10-27 08:32:53',92,329,NULL,0.000000,NULL,1000.000000,'现付',NULL,'SELF-REVIEW-fdaee0d1',NULL,NULL,NULL,NULL,0.000000,0.000000,1000.000000,0.000000,NULL,0.000000,0.000000,0.000000,'0','0','0',NULL,NULL,327,'1'),(671,'其它','销售订单',NULL,'XSDD20261027264D53A0-7AA','2026-10-27 08:54:39','2026-10-27 08:54:38',93,330,NULL,0.000000,NULL,1000.000000,'现付',NULL,'PROD-REVERSE-c02a42ae',NULL,NULL,NULL,NULL,0.000000,0.000000,1000.000000,0.000000,NULL,0.000000,0.000000,0.000000,'0','0','0',NULL,NULL,327,'1'),(672,'出库','其它',NULL,'CL20261027C63B03CA6DDC-OUT','2026-10-27 09:27:53','2026-10-27 09:27:52',NULL,338,NULL,0.000000,NULL,0.000000,'现付',NULL,'车间CL20261027C63B03CA6DDC / 生产任务#667',NULL,NULL,NULL,NULL,0.000000,0.000000,0.000000,0.000000,NULL,0.000000,0.000000,0.000000,'1','0','0',NULL,NULL,327,'0'),(673,'入库','其它',NULL,'CPRK26','2026-10-27 10:36:23','2026-10-27 10:36:22',NULL,338,NULL,0.000000,NULL,0.000000,'现付',NULL,'成品整批入库 / 生产任务#667',NULL,NULL,NULL,NULL,0.000000,0.000000,0.000000,0.000000,NULL,0.000000,0.000000,0.000000,'1','0','0',NULL,NULL,327,'0'),(674,'入库','其它',NULL,'SIM-RK-SHIP-667-20261027','2026-10-27 10:40:50','2026-10-27 10:40:47',NULL,338,NULL,0.000000,NULL,0.000000,'现付',NULL,'【模拟发货测试】按用户要求为订单667补入成品24.9吨；非实际生产、非真实质检及放行；仅用于系统发货流程演练。',NULL,NULL,NULL,NULL,0.000000,0.000000,0.000000,0.000000,NULL,0.000000,0.000000,0.000000,'1','0','0',NULL,NULL,327,'0');
/*!40000 ALTER TABLE `jsh_depot_head` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_depot_item`
--

DROP TABLE IF EXISTS `jsh_depot_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_depot_item` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `header_id` bigint NOT NULL COMMENT '表头Id',
  `material_id` bigint NOT NULL COMMENT '商品Id',
  `material_extend_id` bigint DEFAULT NULL COMMENT '商品扩展id',
  `material_unit` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '商品单位',
  `sku` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多属性',
  `oper_number` decimal(24,6) DEFAULT NULL COMMENT '数量',
  `basic_number` decimal(24,6) DEFAULT NULL COMMENT '基础数量，如kg、瓶',
  `unit_price` decimal(24,6) DEFAULT NULL COMMENT '单价',
  `purchase_unit_price` decimal(24,6) DEFAULT NULL COMMENT '采购单价',
  `tax_unit_price` decimal(24,6) DEFAULT NULL COMMENT '含税单价',
  `all_price` decimal(24,6) DEFAULT NULL COMMENT '金额',
  `remark` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `depot_id` bigint DEFAULT NULL COMMENT '仓库ID',
  `another_depot_id` bigint DEFAULT NULL COMMENT '调拨时，对方仓库Id',
  `tax_rate` decimal(24,6) DEFAULT NULL COMMENT '税率',
  `tax_money` decimal(24,6) DEFAULT NULL COMMENT '税额',
  `tax_last_money` decimal(24,6) DEFAULT NULL COMMENT '价税合计',
  `material_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '商品类型',
  `sn_list` varchar(2000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '序列号列表',
  `batch_number` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '批号',
  `expiration_date` datetime DEFAULT NULL COMMENT '有效日期',
  `link_id` bigint DEFAULT NULL COMMENT '关联明细id',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `FK2A819F475D61CCF7` (`material_id`) USING BTREE,
  KEY `FK2A819F474BB6190E` (`header_id`) USING BTREE,
  KEY `FK2A819F479485B3F5` (`depot_id`) USING BTREE,
  KEY `FK2A819F47729F5392` (`another_depot_id`) USING BTREE,
  KEY `material_extend_id` (`material_extend_id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=777 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='单据子表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_depot_item`
--

LOCK TABLES `jsh_depot_item` WRITE;
/*!40000 ALTER TABLE `jsh_depot_item` DISABLE KEYS */;
INSERT INTO `jsh_depot_item` VALUES (768,666,671,92,'吨',NULL,2.000000,2.000000,0.000000,NULL,NULL,0.000000,NULL,19,NULL,0.000000,0.000000,0.000000,NULL,NULL,'SIM-RAW-20261026-A',NULL,NULL,327,'0'),(769,667,670,91,'吨',NULL,25.000000,25.000000,8300.000000,NULL,NULL,207500.000000,NULL,NULL,NULL,NULL,0.000000,207500.000000,NULL,NULL,NULL,NULL,NULL,327,'0'),(770,668,670,91,'吨',NULL,30.000000,30.000000,120.000000,NULL,NULL,3600.000000,NULL,NULL,NULL,NULL,0.000000,3600.000000,NULL,NULL,NULL,NULL,NULL,327,'0'),(771,669,677,98,'吨',NULL,1.000000,1.000000,1000.000000,NULL,NULL,1000.000000,NULL,NULL,NULL,NULL,0.000000,1000.000000,NULL,NULL,NULL,NULL,NULL,327,'1'),(772,670,677,98,'吨',NULL,1.000000,1.000000,1000.000000,NULL,NULL,1000.000000,NULL,NULL,NULL,NULL,0.000000,1000.000000,NULL,NULL,NULL,NULL,NULL,327,'1'),(773,671,678,99,'吨',NULL,1.000000,1.000000,1000.000000,NULL,NULL,1000.000000,NULL,NULL,NULL,NULL,0.000000,1000.000000,NULL,NULL,NULL,NULL,NULL,327,'1'),(774,672,671,92,'吨',NULL,2.000000,2.000000,0.000000,NULL,NULL,0.000000,'CL20261027C63B03CA6DDC',19,NULL,0.000000,0.000000,0.000000,NULL,NULL,'SIM-RAW-20261026-A',NULL,NULL,327,'0'),(775,673,670,91,'吨',NULL,0.100000,0.100000,0.000000,NULL,NULL,0.000000,'成品最终抽样送检#68',20,NULL,0.000000,0.000000,0.000000,NULL,NULL,'SIM-SC-20261027-01',NULL,NULL,327,'0'),(776,674,670,91,'吨',NULL,24.900000,24.900000,0.000000,NULL,NULL,0.000000,'【模拟发货测试】按用户要求为订单667补入成品24.9吨；非实际生产、非真实质检及放行；仅用于系统发货流程演练。',20,NULL,0.000000,0.000000,0.000000,NULL,NULL,'SIM-SHIP-667-20261027',NULL,NULL,327,'0');
/*!40000 ALTER TABLE `jsh_depot_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_batch_quality`
--

DROP TABLE IF EXISTS `jsh_factory_batch_quality`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_batch_quality` (
  `item_id` bigint NOT NULL,
  `tenant_id` bigint NOT NULL,
  `qc_status` varchar(20) NOT NULL,
  `qualified_quantity` decimal(24,6) NOT NULL,
  `release_state` varchar(20) NOT NULL DEFAULT 'pending',
  `return_released` tinyint NOT NULL DEFAULT '0',
  `report_number` varchar(100) NOT NULL,
  `report_text` mediumtext NOT NULL,
  PRIMARY KEY (`item_id`),
  KEY `tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_batch_quality`
--

LOCK TABLES `jsh_factory_batch_quality` WRITE;
/*!40000 ALTER TABLE `jsh_factory_batch_quality` DISABLE KEYS */;
INSERT INTO `jsh_factory_batch_quality` VALUES (775,327,'passed',0.100000,'released',0,'CPZJ68','成品最终抽样质检汇总\n批号：SIM-SC-20261027-01\n整批数量（吨）：0.100000\n确认人账号：337\n确认时间：2026-10-27T10:27:36\n判定说明：\n\n成品技术指标（产品介绍摘录，供模拟验证） / 录入人：模拟质检员\n堆密度：1 g/cm³；标准：0.68～不限\n比表面积：400 m²/g；标准：350～不限\n孔容积：1 cm³/g；标准：0.40～不限\n磨耗：0.2 %；标准：不限～0.30\n检测说明：'),(776,327,'passed',24.900000,'released',0,'SIM-QC-SHIP-667-20261027','【模拟发货测试】按用户要求为订单667补入成品24.9吨；非实际生产、非真实质检及放行；仅用于系统发货流程演练。');
/*!40000 ALTER TABLE `jsh_factory_batch_quality` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_change_config`
--

DROP TABLE IF EXISTS `jsh_factory_change_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_change_config` (
  `tenant_id` bigint NOT NULL,
  `leader_ids` text NOT NULL,
  PRIMARY KEY (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_change_config`
--

LOCK TABLES `jsh_factory_change_config` WRITE;
/*!40000 ALTER TABLE `jsh_factory_change_config` DISABLE KEYS */;
INSERT INTO `jsh_factory_change_config` VALUES (327,'[331]');
/*!40000 ALTER TABLE `jsh_factory_change_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_customer_return`
--

DROP TABLE IF EXISTS `jsh_factory_customer_return`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_customer_return` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `source_head_id` bigint NOT NULL,
  `workflow_status` varchar(20) NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `reason` varchar(2000) NOT NULL,
  `created_by` bigint NOT NULL,
  `created_at` datetime NOT NULL,
  `approved_by` bigint DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `received_by` bigint DEFAULT NULL,
  `received_at` datetime DEFAULT NULL,
  `ledger_head_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`,`source_head_id`,`workflow_status`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_customer_return`
--

LOCK TABLES `jsh_factory_customer_return` WRITE;
/*!40000 ALTER TABLE `jsh_factory_customer_return` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_factory_customer_return` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_customer_return_history`
--

DROP TABLE IF EXISTS `jsh_factory_customer_return_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_customer_return_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `return_id` bigint NOT NULL,
  `action` varchar(30) NOT NULL,
  `actor_id` bigint NOT NULL,
  `actor_name` varchar(100) NOT NULL,
  `comment` varchar(2000) NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`,`return_id`)
) ENGINE=InnoDB AUTO_INCREMENT=64 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_customer_return_history`
--

LOCK TABLES `jsh_factory_customer_return_history` WRITE;
/*!40000 ALTER TABLE `jsh_factory_customer_return_history` DISABLE KEYS */;
INSERT INTO `jsh_factory_customer_return_history` VALUES (63,327,0,'configure',327,'jingjing','审批领导账号：[331]','2026-10-26 15:27:06');
/*!40000 ALTER TABLE `jsh_factory_customer_return_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_customer_return_line`
--

DROP TABLE IF EXISTS `jsh_factory_customer_return_line`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_customer_return_line` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `return_id` bigint NOT NULL,
  `tenant_id` bigint NOT NULL,
  `source_item_id` bigint NOT NULL,
  `quantity` decimal(24,6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`,`return_id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_customer_return_line`
--

LOCK TABLES `jsh_factory_customer_return_line` WRITE;
/*!40000 ALTER TABLE `jsh_factory_customer_return_line` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_factory_customer_return_line` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_finished_batch`
--

DROP TABLE IF EXISTS `jsh_factory_finished_batch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_finished_batch` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `line_no` int NOT NULL,
  `stage_no` int NOT NULL,
  `material_id` bigint NOT NULL,
  `bar_code` varchar(100) NOT NULL,
  `batch_number` varchar(100) NOT NULL,
  `quantity` decimal(18,6) NOT NULL,
  `root_inspection_id` bigint NOT NULL,
  `inspection_id` bigint NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `depot_id` bigint DEFAULT NULL,
  `ledger_head_id` bigint DEFAULT NULL,
  `received_by` bigint DEFAULT NULL,
  `received_at` datetime DEFAULT NULL,
  `release_state` varchar(20) NOT NULL DEFAULT 'pending',
  `released_by` bigint DEFAULT NULL,
  `released_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `finished_lot` (`tenant_id`,`material_id`,`batch_number`),
  UNIQUE KEY `task_batch` (`tenant_id`,`head_id`,`line_no`,`batch_number`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_finished_batch`
--

LOCK TABLES `jsh_factory_finished_batch` WRITE;
/*!40000 ALTER TABLE `jsh_factory_finished_batch` DISABLE KEYS */;
INSERT INTO `jsh_factory_finished_batch` VALUES (26,327,667,0,2,670,'ALD-MOCK-052-10G','SIM-SC-20261027-01',0.100000,68,68,3,20,673,338,'2026-10-27 10:36:23','released',331,'2026-10-27 10:37:19');
/*!40000 ALTER TABLE `jsh_factory_finished_batch` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_inspection`
--

DROP TABLE IF EXISTS `jsh_factory_inspection`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_inspection` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `line_no` int NOT NULL,
  `stage_no` int NOT NULL,
  `workshop_no` int NOT NULL,
  `batch_number` varchar(100) NOT NULL,
  `quantity` decimal(18,6) NOT NULL,
  `parent_id` bigint DEFAULT NULL,
  `standard_version` int NOT NULL,
  `forms_json` mediumtext NOT NULL,
  `workflow_status` varchar(20) NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `qualified_quantity` decimal(18,6) DEFAULT NULL,
  `comment` varchar(2000) NOT NULL,
  `created_by` bigint NOT NULL,
  `created_at` datetime NOT NULL,
  `confirmed_by` bigint DEFAULT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  `inspection_kind` varchar(10) NOT NULL DEFAULT 'semi',
  PRIMARY KEY (`id`),
  KEY `task_batch` (`tenant_id`,`head_id`,`line_no`,`stage_no`,`workshop_no`,`batch_number`),
  KEY `parent` (`tenant_id`,`parent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=69 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_inspection`
--

LOCK TABLES `jsh_factory_inspection` WRITE;
/*!40000 ALTER TABLE `jsh_factory_inspection` DISABLE KEYS */;
INSERT INTO `jsh_factory_inspection` VALUES (63,327,667,0,1,1,'SIM-SC-20261027-01',0.100000,NULL,1,'[{\"recordedAt\":\"2026-10-27T10:03:13.624\",\"name\":\"成品技术指标（产品介绍摘录，供模拟验证）\",\"comment\":\"\",\"actorName\":\"模拟质检员\",\"items\":[{\"unit\":\"g/cm³\",\"min\":0.68,\"name\":\"堆密度\",\"type\":\"number\",\"value\":0.69},{\"unit\":\"m²/g\",\"min\":350,\"name\":\"比表面积\",\"type\":\"number\",\"value\":401},{\"unit\":\"cm³/g\",\"min\":0.40,\"name\":\"孔容积\",\"type\":\"number\",\"value\":0.3},{\"unit\":\"%\",\"max\":0.30,\"name\":\"磨耗\",\"type\":\"number\",\"value\":0.2}]}]','approved',9,0.000000,'修正模拟测试判定：孔容积实测0.3低于标准0.40，原全量合格判定有误；本次代表数量0.1吨判为不合格，车间调整后申请复检。',333,'2026-10-27 09:55:19',337,'2026-10-27 10:12:35','semi'),(67,327,667,0,1,1,'SIM-SC-20261027-01',0.100000,63,3,'[{\"recordedAt\":\"2026-10-27T10:17:19.719\",\"name\":\"成品技术指标（产品介绍摘录，供模拟验证）\",\"comment\":\"\",\"actorName\":\"模拟质检员\",\"items\":[{\"unit\":\"g/cm³\",\"min\":0.68,\"name\":\"堆密度\",\"type\":\"number\",\"value\":7},{\"unit\":\"m²/g\",\"min\":350,\"name\":\"比表面积\",\"type\":\"number\",\"value\":9400},{\"unit\":\"cm³/g\",\"min\":0.4,\"name\":\"孔容积\",\"type\":\"number\",\"value\":1},{\"unit\":\"%\",\"max\":0.3,\"name\":\"磨耗\",\"type\":\"number\",\"value\":0}]},{\"recordedAt\":\"2026-10-27T10:17:43.709\",\"name\":\"2\",\"comment\":\"\",\"actorName\":\"模拟质检员\",\"items\":[{\"unit\":\"m\",\"min\":1,\"name\":\"1\",\"type\":\"number\",\"value\":2}]}]','approved',8,0.100000,'',333,'2026-10-27 10:15:38',337,'2026-10-27 10:18:12','semi'),(68,327,667,0,2,2,'SIM-SC-20261027-01',0.100000,NULL,1,'[{\"recordedAt\":\"2026-10-27T10:27:05.294\",\"name\":\"成品技术指标（产品介绍摘录，供模拟验证）\",\"comment\":\"\",\"actorName\":\"模拟质检员\",\"items\":[{\"unit\":\"g/cm³\",\"min\":0.68,\"name\":\"堆密度\",\"type\":\"number\",\"value\":1},{\"unit\":\"m²/g\",\"min\":350,\"name\":\"比表面积\",\"type\":\"number\",\"value\":400},{\"unit\":\"cm³/g\",\"min\":0.40,\"name\":\"孔容积\",\"type\":\"number\",\"value\":1},{\"unit\":\"%\",\"max\":0.30,\"name\":\"磨耗\",\"type\":\"number\",\"value\":0.2}]}]','approved',5,0.100000,'',334,'2026-10-27 10:25:48',337,'2026-10-27 10:27:36','finished');
/*!40000 ALTER TABLE `jsh_factory_inspection` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_material_history`
--

DROP TABLE IF EXISTS `jsh_factory_material_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_material_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `request_id` bigint NOT NULL,
  `action` varchar(20) NOT NULL,
  `actor_name` varchar(100) NOT NULL,
  `comment` text NOT NULL,
  `payload_json` mediumtext NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`,`request_id`)
) ENGINE=InnoDB AUTO_INCREMENT=251 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_material_history`
--

LOCK TABLES `jsh_factory_material_history` WRITE;
/*!40000 ALTER TABLE `jsh_factory_material_history` DISABLE KEYS */;
INSERT INTO `jsh_factory_material_history` VALUES (235,327,70,'create','模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":120,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"1\"}]','2026-10-27 09:03:24'),(236,327,70,'submit','模拟一车间主任','领补退料状态更新','{\"status\":\"pending\"}','2026-10-27 09:03:36'),(237,327,70,'withdraw','模拟一车间主任','领补退料状态更新','{\"status\":\"draft\"}','2026-10-27 09:11:04'),(238,327,70,'cancel','模拟一车间主任','领补退料状态更新','{\"status\":\"cancelled\"}','2026-10-27 09:21:25'),(239,327,71,'create','模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":2,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"SIM-RAW-20261026-A\"}]','2026-10-27 09:22:52'),(240,327,70,'delete','模拟一车间主任','删除未确认单据 CL20261027CF7F08AA1DAE','{\"id\":70,\"tenant_id\":327,\"task_head_id\":667,\"number\":\"CL20261027CF7F08AA1DAE\",\"kind\":\"issue\",\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"workflow_status\":\"cancelled\",\"version\":4,\"reason\":\"\",\"lines_json\":\"[{\\\"standard\\\":\\\"模拟原料规格\\\",\\\"unit\\\":\\\"吨\\\",\\\"quantity\\\":120,\\\"name\\\":\\\"模拟原料A\\\",\\\"depotId\\\":19,\\\"model\\\":\\\"模拟型号\\\",\\\"materialId\\\":671,\\\"brand\\\":\\\"\\\",\\\"batchEnabled\\\":true,\\\"barCode\\\":\\\"RAW-MOCK-A\\\",\\\"batchNumber\\\":\\\"1\\\"}]\",\"created_by\":333,\"created_at\":\"2026-10-27T09:03:24\",\"updated_at\":\"2026-10-27T09:21:25\"}','2026-10-27 09:26:05'),(241,327,72,'create','模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":0.01,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"SIM-RAW-20261026-A\"}]','2026-10-27 09:26:23'),(242,327,72,'delete','模拟一车间主任','删除未确认单据 CL2026102744646A7BAA0B','{\"id\":72,\"tenant_id\":327,\"task_head_id\":667,\"number\":\"CL2026102744646A7BAA0B\",\"kind\":\"issue\",\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"workflow_status\":\"draft\",\"version\":1,\"reason\":\"删除功能临时测试\",\"lines_json\":\"[{\\\"standard\\\":\\\"模拟原料规格\\\",\\\"unit\\\":\\\"吨\\\",\\\"quantity\\\":0.01,\\\"name\\\":\\\"模拟原料A\\\",\\\"depotId\\\":19,\\\"model\\\":\\\"模拟型号\\\",\\\"materialId\\\":671,\\\"brand\\\":\\\"\\\",\\\"batchEnabled\\\":true,\\\"barCode\\\":\\\"RAW-MOCK-A\\\",\\\"batchNumber\\\":\\\"SIM-RAW-20261026-A\\\"}]\",\"created_by\":333,\"created_at\":\"2026-10-27T09:26:23\",\"updated_at\":\"2026-10-27T09:26:23\"}','2026-10-27 09:26:34'),(243,327,73,'create','模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":0.01,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"SIM-RAW-20261026-A\"}]','2026-10-27 09:26:37'),(244,327,73,'delete','模拟一车间主任','删除未确认单据 CL2026102729562C5993F7','{\"id\":73,\"tenant_id\":327,\"task_head_id\":667,\"number\":\"CL2026102729562C5993F7\",\"kind\":\"issue\",\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"workflow_status\":\"pending\",\"version\":1,\"reason\":\"删除功能临时测试\",\"lines_json\":\"[{\\\"standard\\\":\\\"模拟原料规格\\\",\\\"unit\\\":\\\"吨\\\",\\\"quantity\\\":0.01,\\\"name\\\":\\\"模拟原料A\\\",\\\"depotId\\\":19,\\\"model\\\":\\\"模拟型号\\\",\\\"materialId\\\":671,\\\"brand\\\":\\\"\\\",\\\"batchEnabled\\\":true,\\\"barCode\\\":\\\"RAW-MOCK-A\\\",\\\"batchNumber\\\":\\\"SIM-RAW-20261026-A\\\"}]\",\"created_by\":333,\"created_at\":\"2026-10-27T09:26:37\",\"updated_at\":\"2026-10-27T09:26:37\"}','2026-10-27 09:26:44'),(245,327,74,'create','模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":0.01,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"SIM-RAW-20261026-A\"}]','2026-10-27 09:26:46'),(246,327,74,'delete','模拟一车间主任','删除未确认单据 CL202610279DCBA21CA8F4','{\"id\":74,\"tenant_id\":327,\"task_head_id\":667,\"number\":\"CL202610279DCBA21CA8F4\",\"kind\":\"issue\",\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"workflow_status\":\"cancelled\",\"version\":1,\"reason\":\"删除功能临时测试\",\"lines_json\":\"[{\\\"standard\\\":\\\"模拟原料规格\\\",\\\"unit\\\":\\\"吨\\\",\\\"quantity\\\":0.01,\\\"name\\\":\\\"模拟原料A\\\",\\\"depotId\\\":19,\\\"model\\\":\\\"模拟型号\\\",\\\"materialId\\\":671,\\\"brand\\\":\\\"\\\",\\\"batchEnabled\\\":true,\\\"barCode\\\":\\\"RAW-MOCK-A\\\",\\\"batchNumber\\\":\\\"SIM-RAW-20261026-A\\\"}]\",\"created_by\":333,\"created_at\":\"2026-10-27T09:26:46\",\"updated_at\":\"2026-10-27T09:26:46\"}','2026-10-27 09:26:53'),(247,327,75,'create','模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":0.01,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"SIM-RAW-20261026-A\"}]','2026-10-27 09:26:56'),(248,327,75,'delete','模拟一车间主任','删除未确认单据 CL20261027BD75100DEC97','{\"id\":75,\"tenant_id\":327,\"task_head_id\":667,\"number\":\"CL20261027BD75100DEC97\",\"kind\":\"issue\",\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"workflow_status\":\"returned\",\"version\":1,\"reason\":\"删除功能临时测试\",\"lines_json\":\"[{\\\"standard\\\":\\\"模拟原料规格\\\",\\\"unit\\\":\\\"吨\\\",\\\"quantity\\\":0.01,\\\"name\\\":\\\"模拟原料A\\\",\\\"depotId\\\":19,\\\"model\\\":\\\"模拟型号\\\",\\\"materialId\\\":671,\\\"brand\\\":\\\"\\\",\\\"batchEnabled\\\":true,\\\"barCode\\\":\\\"RAW-MOCK-A\\\",\\\"batchNumber\\\":\\\"SIM-RAW-20261026-A\\\"}]\",\"created_by\":333,\"created_at\":\"2026-10-27T09:26:56\",\"updated_at\":\"2026-10-27T09:26:56\"}','2026-10-27 09:27:02'),(249,327,71,'submit','模拟一车间主任','领补退料状态更新','{\"status\":\"pending\"}','2026-10-27 09:27:18'),(250,327,71,'confirm','模拟仓库','领补退料状态更新','{\"status\":\"confirmed\"}','2026-10-27 09:27:53');
/*!40000 ALTER TABLE `jsh_factory_material_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_material_request`
--

DROP TABLE IF EXISTS `jsh_factory_material_request`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_material_request` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `task_head_id` bigint NOT NULL,
  `number` varchar(50) NOT NULL,
  `kind` varchar(16) NOT NULL,
  `reference_id` bigint DEFAULT NULL,
  `line_no` int NOT NULL,
  `stage_no` int NOT NULL,
  `workshop_no` int NOT NULL,
  `workflow_status` varchar(16) NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `reason` text NOT NULL,
  `lines_json` mediumtext NOT NULL,
  `created_by` bigint NOT NULL,
  `ledger_head_id` bigint DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `request_number` (`tenant_id`,`number`),
  UNIQUE KEY `request_ledger` (`ledger_head_id`),
  KEY `tenant_id` (`tenant_id`,`task_head_id`)
) ENGINE=InnoDB AUTO_INCREMENT=76 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_material_request`
--

LOCK TABLES `jsh_factory_material_request` WRITE;
/*!40000 ALTER TABLE `jsh_factory_material_request` DISABLE KEYS */;
INSERT INTO `jsh_factory_material_request` VALUES (71,327,667,'CL20261027C63B03CA6DDC','issue',NULL,0,1,1,'confirmed',3,'','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":2,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"SIM-RAW-20261026-A\"}]',333,672,'2026-10-27 09:22:52','2026-10-27 09:27:53');
/*!40000 ALTER TABLE `jsh_factory_material_request` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_order_change`
--

DROP TABLE IF EXISTS `jsh_factory_order_change`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_order_change` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `kind` varchar(20) NOT NULL,
  `workflow_status` varchar(20) NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `reason` varchar(2000) NOT NULL,
  `before_json` mediumtext NOT NULL,
  `after_json` mediumtext NOT NULL,
  `created_by` bigint NOT NULL,
  `created_at` datetime NOT NULL,
  `approved_by` bigint DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `applied_by` bigint DEFAULT NULL,
  `applied_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`,`head_id`,`workflow_status`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_order_change`
--

LOCK TABLES `jsh_factory_order_change` WRITE;
/*!40000 ALTER TABLE `jsh_factory_order_change` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_factory_order_change` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_order_change_history`
--

DROP TABLE IF EXISTS `jsh_factory_order_change_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_order_change_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `change_id` bigint NOT NULL,
  `action` varchar(20) NOT NULL,
  `actor_name` varchar(100) NOT NULL,
  `comment` varchar(2000) NOT NULL,
  `payload_json` mediumtext NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`,`change_id`)
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_order_change_history`
--

LOCK TABLES `jsh_factory_order_change_history` WRITE;
/*!40000 ALTER TABLE `jsh_factory_order_change_history` DISABLE KEYS */;
INSERT INTO `jsh_factory_order_change_history` VALUES (56,327,0,'configure','jingjing','配置变更审批领导','[331]','2026-10-26 15:27:05');
/*!40000 ALTER TABLE `jsh_factory_order_change_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_product_material`
--

DROP TABLE IF EXISTS `jsh_factory_product_material`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_product_material` (
  `tenant_id` bigint NOT NULL,
  `product_id` bigint NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `lines_json` mediumtext NOT NULL,
  `updated_by` bigint NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`tenant_id`,`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_product_material`
--

LOCK TABLES `jsh_factory_product_material` WRITE;
/*!40000 ALTER TABLE `jsh_factory_product_material` DISABLE KEYS */;
INSERT INTO `jsh_factory_product_material` VALUES (327,670,2,'[{\"materialId\":671,\"name\":\"模拟原料A\",\"standard\":\"模拟原料规格\",\"model\":\"模拟型号\",\"barCode\":\"RAW-MOCK-A\",\"unit\":\"吨\",\"remark\":\"模拟关联；真实原料与参考用量待确认，不代表正式配方。\"}]',327,'2026-10-26 16:58:01'),(327,674,2,'[]',327,'2026-10-26 16:55:50');
/*!40000 ALTER TABLE `jsh_factory_product_material` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_production_config`
--

DROP TABLE IF EXISTS `jsh_factory_production_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_production_config` (
  `tenant_id` bigint NOT NULL,
  `reviewer_id` bigint NOT NULL,
  `coordinator_id` bigint NOT NULL,
  `updated_at` datetime NOT NULL,
  `workshop1_director_id` bigint DEFAULT NULL,
  `workshop2_director_id` bigint DEFAULT NULL,
  `workshop3_director_id` bigint DEFAULT NULL,
  PRIMARY KEY (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_production_config`
--

LOCK TABLES `jsh_factory_production_config` WRITE;
/*!40000 ALTER TABLE `jsh_factory_production_config` DISABLE KEYS */;
INSERT INTO `jsh_factory_production_config` VALUES (327,331,332,'2026-10-26 15:27:00',333,334,335);
/*!40000 ALTER TABLE `jsh_factory_production_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_production_history`
--

DROP TABLE IF EXISTS `jsh_factory_production_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_production_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `action` varchar(30) NOT NULL,
  `actor_id` bigint NOT NULL,
  `actor_name` varchar(100) NOT NULL,
  `comment` text NOT NULL,
  `payload_json` mediumtext NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`,`head_id`)
) ENGINE=InnoDB AUTO_INCREMENT=920 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_production_history`
--

LOCK TABLES `jsh_factory_production_history` WRITE;
/*!40000 ALTER TABLE `jsh_factory_production_history` DISABLE KEYS */;
INSERT INTO `jsh_factory_production_history` VALUES (883,327,667,'create',329,'模拟销售员','保存生产任务联系表','{\"requirements\":\"\",\"lines\":[{\"standard\":\"Φ0.5～2 mm\",\"quantity\":25,\"productionQuantity\":25,\"adjustReason\":\"\",\"barCode\":\"ALD-MOCK-052-10G\",\"lineNo\":0,\"shipped\":0,\"reserved\":0,\"name\":\"活性氧化铝小包装干燥剂（模拟）\",\"missing\":25,\"cancelled\":false,\"model\":\"10 g/袋（模拟选择）\",\"id\":670,\"brand\":\"SIM-AL-01（模拟）\"}],\"taskTime\":\"2026-10-13T13:47\"}','2026-10-27 08:42:43'),(884,327,667,'edit',329,'模拟销售员','保存生产任务联系表','{\"requirements\":\"\",\"lines\":[{\"standard\":\"Φ0.5～2 mm\",\"quantity\":25,\"productionQuantity\":25,\"adjustReason\":\"\",\"barCode\":\"ALD-MOCK-052-10G\",\"lineNo\":0,\"shipped\":0,\"reserved\":0,\"name\":\"活性氧化铝小包装干燥剂（模拟）\",\"missing\":25,\"cancelled\":false,\"model\":\"10 g/袋（模拟选择）\",\"id\":670,\"brand\":\"SIM-AL-01（模拟）\"}],\"taskTime\":\"2026-10-13T13:47\"}','2026-10-27 08:43:50'),(885,327,667,'submit',329,'模拟销售员','生产任务状态更新','{\"state\":\"pending\"}','2026-10-27 08:44:03'),(886,327,667,'approve',331,'模拟审批领导','生产任务状态更新','{\"state\":\"approved\"}','2026-10-27 08:46:01'),(895,327,667,'distribute',332,'模拟生产统筹','生产统筹分配产品、工序及车间','[{\"lineNo\":0,\"workshopNo\":1,\"quantity\":25,\"stageNo\":1},{\"lineNo\":0,\"workshopNo\":2,\"quantity\":25,\"stageNo\":2}]','2026-10-27 08:57:43'),(896,327,667,'accept',333,'模拟一车间主任','车间1接单；','{\"workshopNo\":1}','2026-10-27 09:01:49'),(897,327,667,'schedule',333,'模拟一车间主任','车间1主任排班；','[{\"leader\":\"1\",\"lineNo\":0,\"workshopNo\":1,\"quantity\":25,\"endDate\":\"2026-10-09\",\"shift\":\"1\",\"stageNo\":1,\"staff\":\"2\",\"startDate\":\"2026-09-30\"}]','2026-10-27 09:02:45'),(898,327,667,'material_create',333,'模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":120,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"1\"}]','2026-10-27 09:03:25'),(899,327,667,'material_submit',333,'模拟一车间主任','领补退料状态更新','{\"status\":\"pending\"}','2026-10-27 09:03:36'),(900,327,667,'execution_start',333,'模拟一车间主任','','{\"materialsReady\":true,\"version\":7,\"lineNo\":0,\"workshopNo\":1,\"reportDate\":\"2026-10-27\",\"lossQuantity\":0,\"action\":\"start\",\"stageNo\":1,\"comment\":\"\",\"actualStart\":\"2026-10-27T09:03\",\"batchNumber\":\"\"}','2026-10-27 09:03:54'),(901,327,667,'material_withdraw',333,'模拟一车间主任','领补退料状态更新','{\"status\":\"draft\"}','2026-10-27 09:11:04'),(902,327,667,'material_cancel',333,'模拟一车间主任','领补退料状态更新','{\"status\":\"cancelled\"}','2026-10-27 09:21:25'),(903,327,667,'material_create',333,'模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":2,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"SIM-RAW-20261026-A\"}]','2026-10-27 09:22:52'),(904,327,667,'material_delete',333,'模拟一车间主任','删除未确认单据 CL20261027CF7F08AA1DAE','{\"id\":70,\"tenant_id\":327,\"task_head_id\":667,\"number\":\"CL20261027CF7F08AA1DAE\",\"kind\":\"issue\",\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"workflow_status\":\"cancelled\",\"version\":4,\"reason\":\"\",\"lines_json\":\"[{\\\"standard\\\":\\\"模拟原料规格\\\",\\\"unit\\\":\\\"吨\\\",\\\"quantity\\\":120,\\\"name\\\":\\\"模拟原料A\\\",\\\"depotId\\\":19,\\\"model\\\":\\\"模拟型号\\\",\\\"materialId\\\":671,\\\"brand\\\":\\\"\\\",\\\"batchEnabled\\\":true,\\\"barCode\\\":\\\"RAW-MOCK-A\\\",\\\"batchNumber\\\":\\\"1\\\"}]\",\"created_by\":333,\"created_at\":\"2026-10-27T09:03:24\",\"updated_at\":\"2026-10-27T09:21:25\"}','2026-10-27 09:26:05'),(905,327,667,'material_create',333,'模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":0.01,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"SIM-RAW-20261026-A\"}]','2026-10-27 09:26:23'),(906,327,667,'material_delete',333,'模拟一车间主任','删除未确认单据 CL2026102744646A7BAA0B','{\"id\":72,\"tenant_id\":327,\"task_head_id\":667,\"number\":\"CL2026102744646A7BAA0B\",\"kind\":\"issue\",\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"workflow_status\":\"draft\",\"version\":1,\"reason\":\"删除功能临时测试\",\"lines_json\":\"[{\\\"standard\\\":\\\"模拟原料规格\\\",\\\"unit\\\":\\\"吨\\\",\\\"quantity\\\":0.01,\\\"name\\\":\\\"模拟原料A\\\",\\\"depotId\\\":19,\\\"model\\\":\\\"模拟型号\\\",\\\"materialId\\\":671,\\\"brand\\\":\\\"\\\",\\\"batchEnabled\\\":true,\\\"barCode\\\":\\\"RAW-MOCK-A\\\",\\\"batchNumber\\\":\\\"SIM-RAW-20261026-A\\\"}]\",\"created_by\":333,\"created_at\":\"2026-10-27T09:26:23\",\"updated_at\":\"2026-10-27T09:26:23\"}','2026-10-27 09:26:34'),(907,327,667,'material_create',333,'模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":0.01,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"SIM-RAW-20261026-A\"}]','2026-10-27 09:26:37'),(908,327,667,'material_delete',333,'模拟一车间主任','删除未确认单据 CL2026102729562C5993F7','{\"id\":73,\"tenant_id\":327,\"task_head_id\":667,\"number\":\"CL2026102729562C5993F7\",\"kind\":\"issue\",\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"workflow_status\":\"pending\",\"version\":1,\"reason\":\"删除功能临时测试\",\"lines_json\":\"[{\\\"standard\\\":\\\"模拟原料规格\\\",\\\"unit\\\":\\\"吨\\\",\\\"quantity\\\":0.01,\\\"name\\\":\\\"模拟原料A\\\",\\\"depotId\\\":19,\\\"model\\\":\\\"模拟型号\\\",\\\"materialId\\\":671,\\\"brand\\\":\\\"\\\",\\\"batchEnabled\\\":true,\\\"barCode\\\":\\\"RAW-MOCK-A\\\",\\\"batchNumber\\\":\\\"SIM-RAW-20261026-A\\\"}]\",\"created_by\":333,\"created_at\":\"2026-10-27T09:26:37\",\"updated_at\":\"2026-10-27T09:26:37\"}','2026-10-27 09:26:44'),(909,327,667,'material_create',333,'模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":0.01,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"SIM-RAW-20261026-A\"}]','2026-10-27 09:26:46'),(910,327,667,'material_delete',333,'模拟一车间主任','删除未确认单据 CL202610279DCBA21CA8F4','{\"id\":74,\"tenant_id\":327,\"task_head_id\":667,\"number\":\"CL202610279DCBA21CA8F4\",\"kind\":\"issue\",\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"workflow_status\":\"cancelled\",\"version\":1,\"reason\":\"删除功能临时测试\",\"lines_json\":\"[{\\\"standard\\\":\\\"模拟原料规格\\\",\\\"unit\\\":\\\"吨\\\",\\\"quantity\\\":0.01,\\\"name\\\":\\\"模拟原料A\\\",\\\"depotId\\\":19,\\\"model\\\":\\\"模拟型号\\\",\\\"materialId\\\":671,\\\"brand\\\":\\\"\\\",\\\"batchEnabled\\\":true,\\\"barCode\\\":\\\"RAW-MOCK-A\\\",\\\"batchNumber\\\":\\\"SIM-RAW-20261026-A\\\"}]\",\"created_by\":333,\"created_at\":\"2026-10-27T09:26:46\",\"updated_at\":\"2026-10-27T09:26:46\"}','2026-10-27 09:26:53'),(911,327,667,'material_create',333,'模拟一车间主任','主任保存领补退料单','[{\"standard\":\"模拟原料规格\",\"unit\":\"吨\",\"quantity\":0.01,\"name\":\"模拟原料A\",\"depotId\":19,\"model\":\"模拟型号\",\"materialId\":671,\"brand\":\"\",\"batchEnabled\":true,\"barCode\":\"RAW-MOCK-A\",\"batchNumber\":\"SIM-RAW-20261026-A\"}]','2026-10-27 09:26:56'),(912,327,667,'material_delete',333,'模拟一车间主任','删除未确认单据 CL20261027BD75100DEC97','{\"id\":75,\"tenant_id\":327,\"task_head_id\":667,\"number\":\"CL20261027BD75100DEC97\",\"kind\":\"issue\",\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"workflow_status\":\"returned\",\"version\":1,\"reason\":\"删除功能临时测试\",\"lines_json\":\"[{\\\"standard\\\":\\\"模拟原料规格\\\",\\\"unit\\\":\\\"吨\\\",\\\"quantity\\\":0.01,\\\"name\\\":\\\"模拟原料A\\\",\\\"depotId\\\":19,\\\"model\\\":\\\"模拟型号\\\",\\\"materialId\\\":671,\\\"brand\\\":\\\"\\\",\\\"batchEnabled\\\":true,\\\"barCode\\\":\\\"RAW-MOCK-A\\\",\\\"batchNumber\\\":\\\"SIM-RAW-20261026-A\\\"}]\",\"created_by\":333,\"created_at\":\"2026-10-27T09:26:56\",\"updated_at\":\"2026-10-27T09:26:56\"}','2026-10-27 09:27:02'),(913,327,667,'material_submit',333,'模拟一车间主任','领补退料状态更新','{\"status\":\"pending\"}','2026-10-27 09:27:18'),(914,327,667,'material_confirm',338,'模拟仓库','领补退料状态更新','{\"status\":\"confirmed\"}','2026-10-27 09:27:53'),(915,327,667,'execution_report',333,'模拟一车间主任','','{\"materialsReady\":false,\"inputQuantity\":2,\"outputQuantity\":1,\"version\":8,\"lineNo\":0,\"workshopNo\":1,\"reportDate\":\"2026-10-27\",\"lossQuantity\":0.2,\"action\":\"report\",\"stageNo\":1,\"comment\":\"\",\"actualStart\":\"2026-10-27T09:30\",\"batchNumber\":\"SIM-SC-20261027-01\"}','2026-10-27 09:33:10'),(916,327,667,'accept',334,'模拟二车间主任','车间2接单；','{\"workshopNo\":2}','2026-10-27 10:19:57'),(917,327,667,'schedule',334,'模拟二车间主任','车间2主任排班；','[{\"leader\":\"1\",\"lineNo\":0,\"workshopNo\":2,\"quantity\":25,\"endDate\":\"2026-10-09\",\"shift\":\"1\",\"stageNo\":2,\"staff\":\"2\",\"startDate\":\"2026-10-07\"}]','2026-10-27 10:20:58'),(918,327,667,'execution_start',334,'模拟二车间主任','','{\"materialsReady\":true,\"version\":11,\"lineNo\":0,\"workshopNo\":2,\"reportDate\":\"2026-10-27\",\"lossQuantity\":0,\"action\":\"start\",\"stageNo\":2,\"comment\":\"\",\"actualStart\":\"2026-10-27T10:21\",\"batchNumber\":\"\"}','2026-10-27 10:21:11'),(919,327,667,'execution_report',334,'模拟二车间主任','','{\"materialsReady\":false,\"inputQuantity\":0.1,\"outputQuantity\":0.1,\"version\":12,\"lineNo\":0,\"workshopNo\":2,\"reportDate\":\"2026-10-27\",\"lossQuantity\":0,\"action\":\"report\",\"stageNo\":2,\"comment\":\"\",\"actualStart\":\"2026-10-27T10:21\",\"batchNumber\":\"SIM-SC-20261027-01\"}','2026-10-27 10:25:03');
/*!40000 ALTER TABLE `jsh_factory_production_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_production_report`
--

DROP TABLE IF EXISTS `jsh_factory_production_report`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_production_report` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `workshop_no` int NOT NULL,
  `line_no` int NOT NULL,
  `stage_no` int NOT NULL,
  `report_date` date NOT NULL,
  `batch_number` varchar(100) NOT NULL,
  `input_quantity` decimal(18,6) NOT NULL,
  `output_quantity` decimal(18,6) NOT NULL,
  `loss_quantity` decimal(18,6) NOT NULL,
  `comment` varchar(2000) NOT NULL,
  `actor_id` bigint NOT NULL,
  `actor_name` varchar(100) NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `daily_batch` (`tenant_id`,`head_id`,`workshop_no`,`line_no`,`stage_no`,`report_date`,`batch_number`)
) ENGINE=InnoDB AUTO_INCREMENT=104 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_production_report`
--

LOCK TABLES `jsh_factory_production_report` WRITE;
/*!40000 ALTER TABLE `jsh_factory_production_report` DISABLE KEYS */;
INSERT INTO `jsh_factory_production_report` VALUES (99,327,667,1,0,1,'2026-10-27','SIM-SC-20261027-01',2.000000,1.000000,0.200000,'',333,'模拟一车间主任','2026-10-27 09:33:10'),(103,327,667,2,0,2,'2026-10-27','SIM-SC-20261027-01',0.100000,0.100000,0.000000,'',334,'模拟二车间主任','2026-10-27 10:25:03');
/*!40000 ALTER TABLE `jsh_factory_production_report` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_production_start`
--

DROP TABLE IF EXISTS `jsh_factory_production_start`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_production_start` (
  `tenant_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `workshop_no` int NOT NULL,
  `line_no` int NOT NULL,
  `stage_no` int NOT NULL,
  `actual_start` datetime NOT NULL,
  `actor_id` bigint NOT NULL,
  `actor_name` varchar(100) NOT NULL,
  `comment` varchar(2000) NOT NULL,
  PRIMARY KEY (`tenant_id`,`head_id`,`workshop_no`,`line_no`,`stage_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_production_start`
--

LOCK TABLES `jsh_factory_production_start` WRITE;
/*!40000 ALTER TABLE `jsh_factory_production_start` DISABLE KEYS */;
INSERT INTO `jsh_factory_production_start` VALUES (327,667,1,0,1,'2026-10-27 09:03:00',333,'模拟一车间主任',''),(327,667,2,0,2,'2026-10-27 10:21:00',334,'模拟二车间主任','');
/*!40000 ALTER TABLE `jsh_factory_production_start` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_production_task`
--

DROP TABLE IF EXISTS `jsh_factory_production_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_production_task` (
  `head_id` bigint NOT NULL,
  `tenant_id` bigint NOT NULL,
  `number` varchar(50) NOT NULL,
  `workflow_status` varchar(20) NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `requirements` text NOT NULL,
  `lines_json` mediumtext NOT NULL,
  `plan_json` mediumtext NOT NULL,
  `created_by` bigint NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `task_time` varchar(16) DEFAULT NULL COMMENT '销售填写任务时间 YYYY-MM-DDTHH:mm',
  `route_json` mediumtext,
  PRIMARY KEY (`head_id`),
  UNIQUE KEY `production_number` (`tenant_id`,`number`),
  KEY `tenant_id` (`tenant_id`,`workflow_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_production_task`
--

LOCK TABLES `jsh_factory_production_task` WRITE;
/*!40000 ALTER TABLE `jsh_factory_production_task` DISABLE KEYS */;
INSERT INTO `jsh_factory_production_task` VALUES (667,327,'SCLX20261027A708D02B8F08','scheduled',13,'','[{\"standard\":\"Φ0.5～2 mm\",\"quantity\":25,\"productionQuantity\":25,\"adjustReason\":\"\",\"barCode\":\"ALD-MOCK-052-10G\",\"lineNo\":0,\"shipped\":0,\"reserved\":0,\"name\":\"活性氧化铝小包装干燥剂（模拟）\",\"missing\":25,\"cancelled\":false,\"model\":\"10 g/袋（模拟选择）\",\"id\":670,\"brand\":\"SIM-AL-01（模拟）\"}]','[{\"leader\":\"1\",\"lineNo\":0,\"workshopNo\":1,\"quantity\":25,\"endDate\":\"2026-10-09\",\"shift\":\"1\",\"stageNo\":1,\"staff\":\"2\",\"startDate\":\"2026-09-30\"},{\"leader\":\"1\",\"lineNo\":0,\"workshopNo\":2,\"quantity\":25,\"endDate\":\"2026-10-09\",\"shift\":\"1\",\"stageNo\":2,\"staff\":\"2\",\"startDate\":\"2026-10-07\"}]',329,'2026-10-27 08:42:43','2026-10-27 10:25:03','2026-10-13T13:47','[{\"lineNo\":0,\"workshopNo\":1,\"quantity\":25,\"stageNo\":1},{\"lineNo\":0,\"workshopNo\":2,\"quantity\":25,\"stageNo\":2}]');
/*!40000 ALTER TABLE `jsh_factory_production_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_quality_config`
--

DROP TABLE IF EXISTS `jsh_factory_quality_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_quality_config` (
  `tenant_id` bigint NOT NULL,
  `director_id` bigint NOT NULL,
  `inspectors_json` text NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_quality_config`
--

LOCK TABLES `jsh_factory_quality_config` WRITE;
/*!40000 ALTER TABLE `jsh_factory_quality_config` DISABLE KEYS */;
INSERT INTO `jsh_factory_quality_config` VALUES (327,337,'[336]','2026-10-26 15:27:01');
/*!40000 ALTER TABLE `jsh_factory_quality_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_quality_history`
--

DROP TABLE IF EXISTS `jsh_factory_quality_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_quality_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `inspection_id` bigint DEFAULT NULL,
  `action` varchar(30) NOT NULL,
  `actor_id` bigint NOT NULL,
  `actor_name` varchar(100) NOT NULL,
  `payload_json` mediumtext NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `inspection` (`tenant_id`,`inspection_id`)
) ENGINE=InnoDB AUTO_INCREMENT=525 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_quality_history`
--

LOCK TABLES `jsh_factory_quality_history` WRITE;
/*!40000 ALTER TABLE `jsh_factory_quality_history` DISABLE KEYS */;
INSERT INTO `jsh_factory_quality_history` VALUES (470,327,NULL,'configure',327,'jingjing','{\"inspectorIds\":[336],\"directorId\":337}','2026-10-26 15:27:01'),(471,327,NULL,'release_config',327,'jingjing','{\"leaderIds\":[331]}','2026-10-26 15:27:02'),(472,327,NULL,'quality_template',327,'jingjing','{\"name\":\"模拟工序通用检查（占位标准）\",\"id\":9,\"forms\":[{\"name\":\"模拟工序检查（非实际工艺标准）\",\"items\":[{\"name\":\"模拟外观检查\",\"type\":\"text\",\"unit\":\"\",\"expected\":\"模拟合格\"}]}]}','2026-10-26 16:05:15'),(473,327,NULL,'quality_template',327,'jingjing','{\"name\":\"模拟活性氧化铝Φ0.5～2成品指标（资料摘录）\",\"id\":10,\"forms\":[{\"name\":\"成品技术指标（产品介绍摘录，供模拟验证）\",\"items\":[{\"name\":\"堆密度\",\"type\":\"number\",\"unit\":\"g/cm³\",\"min\":\"0.68\"},{\"name\":\"比表面积\",\"type\":\"number\",\"unit\":\"m²/g\",\"min\":\"350\"},{\"name\":\"孔容积\",\"type\":\"number\",\"unit\":\"cm³/g\",\"min\":\"0.40\"},{\"name\":\"磨耗\",\"type\":\"number\",\"unit\":\"%\",\"max\":\"0.30\"}]}]}','2026-10-26 16:05:17'),(474,327,NULL,'standard',327,'jingjing','{\"stageNo\":1,\"inspectionKind\":\"semi\",\"templateId\":9,\"barCode\":\"ALD-MOCK-052-10G\"}','2026-10-26 16:05:20'),(475,327,NULL,'standard',327,'jingjing','{\"stageNo\":2,\"inspectionKind\":\"semi\",\"templateId\":9,\"barCode\":\"ALD-MOCK-052-10G\"}','2026-10-26 16:05:22'),(476,327,NULL,'standard',327,'jingjing','{\"stageNo\":0,\"inspectionKind\":\"finished\",\"templateId\":10,\"barCode\":\"ALD-MOCK-052-10G\"}','2026-10-26 16:05:24'),(477,327,57,'request',333,'模拟一车间主任','{\"lineNo\":0,\"workshopNo\":1,\"quantity\":0.1,\"stageNo\":1,\"finished\":false,\"comment\":\"\",\"headId\":667,\"batchNumber\":\"SIM-SC-20261027-01\"}','2026-10-27 09:35:30'),(478,327,58,'request',333,'模拟一车间主任','{\"lineNo\":0,\"workshopNo\":1,\"quantity\":0.1,\"stageNo\":1,\"finished\":false,\"comment\":\"\",\"headId\":667,\"batchNumber\":\"SIM-SC-20261027-01\"}','2026-10-27 09:36:19'),(479,327,NULL,'standard',337,'模拟质检主任','{\"stageNo\":1,\"inspectionKind\":\"semi\",\"templateId\":10,\"version\":1,\"forms\":[{\"name\":\"模拟工序检查（非实际工艺标准）\",\"items\":[]}],\"barCode\":\"ALD-MOCK-052-10G\"}','2026-10-27 09:41:03'),(480,327,58,'delete',333,'模拟一车间主任','{\"id\":58,\"tenant_id\":327,\"head_id\":667,\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"batch_number\":\"SIM-SC-20261027-01\",\"quantity\":0.100000,\"standard_version\":1,\"forms_json\":\"[{\\\"name\\\":\\\"模拟工序检查（非实际工艺标准）\\\",\\\"items\\\":[{\\\"unit\\\":\\\"\\\",\\\"expected\\\":\\\"模拟合格\\\",\\\"name\\\":\\\"模拟外观检查\\\",\\\"type\\\":\\\"text\\\"}]}]\",\"workflow_status\":\"testing\",\"version\":1,\"comment\":\"\",\"created_by\":333,\"created_at\":\"2026-10-27T09:36:19\",\"inspection_kind\":\"semi\"}','2026-10-27 09:46:42'),(481,327,57,'delete',333,'模拟一车间主任','{\"id\":57,\"tenant_id\":327,\"head_id\":667,\"line_no\":0,\"stage_no\":1,\"workshop_no\":1,\"batch_number\":\"SIM-SC-20261027-01\",\"quantity\":0.100000,\"standard_version\":1,\"forms_json\":\"[{\\\"name\\\":\\\"模拟工序检查（非实际工艺标准）\\\",\\\"items\\\":[{\\\"unit\\\":\\\"\\\",\\\"expected\\\":\\\"模拟合格\\\",\\\"name\\\":\\\"模拟外观检查\\\",\\\"type\\\":\\\"text\\\"}]}]\",\"workflow_status\":\"testing\",\"version\":1,\"comment\":\"\",\"created_by\":333,\"created_at\":\"2026-10-27T09:35:30\",\"inspection_kind\":\"semi\"}','2026-10-27 09:46:44'),(493,327,63,'request',333,'模拟一车间主任','{\"lineNo\":0,\"workshopNo\":1,\"quantity\":0.1,\"stageNo\":1,\"finished\":false,\"comment\":\"\",\"headId\":667,\"batchNumber\":\"SIM-SC-20261027-01\"}','2026-10-27 09:55:19'),(494,327,63,'start',336,'模拟质检员','{\"action\":\"start\",\"version\":1}','2026-10-27 09:55:52'),(495,327,63,'form',336,'模拟质检员','{\"values\":[{\"value\":0.69},{\"value\":401},{\"value\":0.3},{\"value\":0.2}],\"action\":\"form\",\"comment\":\"\",\"formIndex\":0,\"version\":2}','2026-10-27 09:56:40'),(496,327,63,'submit',336,'模拟质检员','{\"action\":\"submit\",\"version\":3}','2026-10-27 09:56:43'),(497,327,63,'return',337,'模拟质检主任','{\"qualifiedQuantity\":0.1,\"action\":\"return\",\"comment\":\"重新测试\",\"version\":4}','2026-10-27 09:58:16'),(498,327,NULL,'standard',337,'模拟质检主任','{\"stageNo\":1,\"inspectionKind\":\"semi\",\"version\":2,\"forms\":[{\"name\":\"成品技术指标（产品介绍摘录，供模拟验证）\",\"items\":[{\"type\":\"number\",\"min\":0.68,\"expected\":\"\",\"unit\":\"g/cm³\",\"name\":\"堆密度\"},{\"type\":\"number\",\"min\":350,\"expected\":\"\",\"unit\":\"m²/g\",\"name\":\"比表面积\"},{\"type\":\"number\",\"min\":0.4,\"expected\":\"\",\"unit\":\"cm³/g\",\"name\":\"孔容积\"},{\"type\":\"number\",\"max\":0.3,\"expected\":\"\",\"unit\":\"%\",\"name\":\"磨耗\"}]},{\"name\":\"2\",\"items\":[{\"name\":\"1\",\"unit\":\"m\",\"type\":\"number\",\"min\":1,\"expected\":\"\"}]}],\"barCode\":\"ALD-MOCK-052-10G\"}','2026-10-27 10:02:45'),(499,327,63,'form',336,'模拟质检员','{\"values\":[{\"value\":0.69},{\"value\":401},{\"value\":0.3},{\"value\":0.2}],\"action\":\"form\",\"comment\":\"\",\"formIndex\":0,\"version\":5}','2026-10-27 10:03:13'),(500,327,63,'submit',336,'模拟质检员','{\"action\":\"submit\",\"version\":6}','2026-10-27 10:03:17'),(501,327,63,'approve',337,'模拟质检主任','{\"qualifiedQuantity\":0.1,\"action\":\"approve\",\"comment\":\"孔容积\",\"version\":7}','2026-10-27 10:03:51'),(509,327,63,'correctDecision',337,'模拟质检主任','{\"previousQualifiedQuantity\":0.100000,\"qualifiedQuantity\":0,\"previousConfirmedAt\":\"2026-10-27T10:03:51\",\"action\":\"correctDecision\",\"comment\":\"修正模拟测试判定：孔容积实测0.3低于标准0.40，原全量合格判定有误；本次代表数量0.1吨判为不合格，车间调整后申请复检。\",\"previousConfirmedBy\":337,\"version\":8,\"previousComment\":\"孔容积\"}','2026-10-27 10:12:35'),(510,327,67,'reinspect',333,'模拟一车间主任','{\"lineNo\":0,\"workshopNo\":1,\"quantity\":0.1,\"stageNo\":1,\"finished\":false,\"comment\":\"1\",\"parentId\":63,\"headId\":667,\"batchNumber\":\"SIM-SC-20261027-01\"}','2026-10-27 10:15:38'),(511,327,67,'start',336,'模拟质检员','{\"action\":\"start\",\"version\":1}','2026-10-27 10:16:38'),(512,327,67,'form',336,'模拟质检员','{\"values\":[{\"value\":7},{\"value\":9400},{\"value\":1},{\"value\":0}],\"action\":\"form\",\"comment\":\"\",\"formIndex\":0,\"version\":2}','2026-10-27 10:17:19'),(513,327,67,'form',336,'模拟质检员','{\"values\":[{\"value\":2}],\"action\":\"form\",\"comment\":\"\",\"formIndex\":1,\"version\":3}','2026-10-27 10:17:43'),(514,327,67,'submit',336,'模拟质检员','{\"action\":\"submit\",\"version\":4}','2026-10-27 10:17:44'),(515,327,67,'approve',337,'模拟质检主任','{\"qualifiedQuantity\":0.1,\"action\":\"approve\",\"comment\":\"\",\"version\":5}','2026-10-27 10:18:12'),(516,327,67,'transfer',333,'模拟一车间主任','{\"inspectionId\":67,\"lineNo\":0,\"workshopNo\":2,\"quantity\":0.1,\"stageNo\":2,\"action\":\"transfer\",\"comment\":\"\",\"version\":6,\"batchNumber\":\"SIM-SC-20261027-01\"}','2026-10-27 10:18:42'),(517,327,67,'receive',334,'模拟二车间主任','{\"action\":\"receive\",\"transferId\":26,\"version\":7}','2026-10-27 10:20:08'),(518,327,68,'request',334,'模拟二车间主任','{\"lineNo\":0,\"workshopNo\":2,\"quantity\":0.100000,\"stageNo\":2,\"finished\":true,\"comment\":\"\",\"headId\":667,\"batchNumber\":\"SIM-SC-20261027-01\"}','2026-10-27 10:25:48'),(519,327,68,'start',336,'模拟质检员','{\"action\":\"start\",\"version\":1}','2026-10-27 10:26:53'),(520,327,68,'form',336,'模拟质检员','{\"values\":[{\"value\":1},{\"value\":400},{\"value\":1},{\"value\":0.2}],\"action\":\"form\",\"comment\":\"\",\"formIndex\":0,\"version\":2}','2026-10-27 10:27:05'),(521,327,68,'submit',336,'模拟质检员','{\"action\":\"submit\",\"version\":3}','2026-10-27 10:27:06'),(522,327,68,'approve',337,'模拟质检主任','{\"qualifiedQuantity\":0.1,\"action\":\"approve\",\"comment\":\"\",\"version\":4}','2026-10-27 10:27:36'),(523,327,68,'finished_receive',338,'模拟仓库','{\"quantity\":0.100000,\"depotId\":20,\"action\":\"receive\",\"comment\":\"\",\"id\":26,\"version\":1,\"batchNumber\":\"SIM-SC-20261027-01\"}','2026-10-27 10:36:23'),(524,327,68,'finished_release',331,'模拟审批领导','{\"quantity\":0.100000,\"action\":\"release\",\"comment\":\"\",\"id\":26,\"version\":2,\"batchNumber\":\"SIM-SC-20261027-01\"}','2026-10-27 10:37:19');
/*!40000 ALTER TABLE `jsh_factory_quality_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_quality_standard`
--

DROP TABLE IF EXISTS `jsh_factory_quality_standard`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_quality_standard` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `bar_code` varchar(100) NOT NULL,
  `stage_no` int NOT NULL,
  `version` int NOT NULL,
  `forms_json` mediumtext NOT NULL,
  `updated_by` bigint NOT NULL,
  `updated_at` datetime NOT NULL,
  `inspection_kind` varchar(20) NOT NULL DEFAULT 'semi',
  `template_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `product_kind_stage` (`tenant_id`,`bar_code`,`inspection_kind`,`stage_no`)
) ENGINE=InnoDB AUTO_INCREMENT=59 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_quality_standard`
--

LOCK TABLES `jsh_factory_quality_standard` WRITE;
/*!40000 ALTER TABLE `jsh_factory_quality_standard` DISABLE KEYS */;
INSERT INTO `jsh_factory_quality_standard` VALUES (54,327,'ALD-MOCK-052-10G',1,3,'[{\"name\":\"成品技术指标（产品介绍摘录，供模拟验证）\",\"items\":[{\"unit\":\"g/cm³\",\"min\":0.68,\"name\":\"堆密度\",\"type\":\"number\"},{\"unit\":\"m²/g\",\"min\":350,\"name\":\"比表面积\",\"type\":\"number\"},{\"unit\":\"cm³/g\",\"min\":0.4,\"name\":\"孔容积\",\"type\":\"number\"},{\"unit\":\"%\",\"max\":0.3,\"name\":\"磨耗\",\"type\":\"number\"}]},{\"name\":\"2\",\"items\":[{\"unit\":\"m\",\"min\":1,\"name\":\"1\",\"type\":\"number\"}]}]',337,'2026-10-27 10:02:45','semi',NULL),(55,327,'ALD-MOCK-052-10G',2,1,'[]',327,'2026-10-26 16:05:22','semi',9),(56,327,'ALD-MOCK-052-10G',0,1,'[]',327,'2026-10-26 16:05:24','finished',10);
/*!40000 ALTER TABLE `jsh_factory_quality_standard` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_quality_template`
--

DROP TABLE IF EXISTS `jsh_factory_quality_template`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_quality_template` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `name` varchar(100) NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `forms_json` mediumtext NOT NULL,
  `updated_by` bigint NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tenant_name` (`tenant_id`,`name`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_quality_template`
--

LOCK TABLES `jsh_factory_quality_template` WRITE;
/*!40000 ALTER TABLE `jsh_factory_quality_template` DISABLE KEYS */;
INSERT INTO `jsh_factory_quality_template` VALUES (9,327,'模拟工序通用检查（占位标准）',1,'[{\"name\":\"模拟工序检查（非实际工艺标准）\",\"items\":[{\"unit\":\"\",\"expected\":\"模拟合格\",\"name\":\"模拟外观检查\",\"type\":\"text\"}]}]',327,'2026-10-26 16:05:15'),(10,327,'模拟活性氧化铝Φ0.5～2成品指标（资料摘录）',1,'[{\"name\":\"成品技术指标（产品介绍摘录，供模拟验证）\",\"items\":[{\"unit\":\"g/cm³\",\"min\":0.68,\"name\":\"堆密度\",\"type\":\"number\"},{\"unit\":\"m²/g\",\"min\":350,\"name\":\"比表面积\",\"type\":\"number\"},{\"unit\":\"cm³/g\",\"min\":0.40,\"name\":\"孔容积\",\"type\":\"number\"},{\"unit\":\"%\",\"max\":0.30,\"name\":\"磨耗\",\"type\":\"number\"}]}]',327,'2026-10-26 16:05:17');
/*!40000 ALTER TABLE `jsh_factory_quality_template` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_quality_transfer`
--

DROP TABLE IF EXISTS `jsh_factory_quality_transfer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_quality_transfer` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `inspection_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `line_no` int NOT NULL,
  `stage_no` int NOT NULL,
  `workshop_no` int NOT NULL,
  `batch_number` varchar(100) NOT NULL,
  `quantity` decimal(18,6) NOT NULL,
  `workflow_status` varchar(20) NOT NULL,
  `comment` varchar(2000) NOT NULL,
  `created_by` bigint NOT NULL,
  `created_at` datetime NOT NULL,
  `received_by` bigint DEFAULT NULL,
  `received_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `inspection` (`tenant_id`,`inspection_id`),
  KEY `destination` (`tenant_id`,`head_id`,`line_no`,`stage_no`,`workshop_no`,`batch_number`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_quality_transfer`
--

LOCK TABLES `jsh_factory_quality_transfer` WRITE;
/*!40000 ALTER TABLE `jsh_factory_quality_transfer` DISABLE KEYS */;
INSERT INTO `jsh_factory_quality_transfer` VALUES (26,327,67,667,0,2,2,'SIM-SC-20261027-01',0.100000,'received','',333,'2026-10-27 10:18:42',334,'2026-10-27 10:20:08');
/*!40000 ALTER TABLE `jsh_factory_quality_transfer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_release_config`
--

DROP TABLE IF EXISTS `jsh_factory_release_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_release_config` (
  `tenant_id` bigint NOT NULL,
  `leader_ids_json` text NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_release_config`
--

LOCK TABLES `jsh_factory_release_config` WRITE;
/*!40000 ALTER TABLE `jsh_factory_release_config` DISABLE KEYS */;
INSERT INTO `jsh_factory_release_config` VALUES (327,'[331]','2026-10-26 15:27:02');
/*!40000 ALTER TABLE `jsh_factory_release_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_return_config`
--

DROP TABLE IF EXISTS `jsh_factory_return_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_return_config` (
  `tenant_id` bigint NOT NULL,
  `leader_ids` text NOT NULL,
  PRIMARY KEY (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_return_config`
--

LOCK TABLES `jsh_factory_return_config` WRITE;
/*!40000 ALTER TABLE `jsh_factory_return_config` DISABLE KEYS */;
INSERT INTO `jsh_factory_return_config` VALUES (327,'[331]');
/*!40000 ALTER TABLE `jsh_factory_return_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_sales_config`
--

DROP TABLE IF EXISTS `jsh_factory_sales_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_sales_config` (
  `tenant_id` bigint NOT NULL,
  `reviewer_id` bigint NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_sales_config`
--

LOCK TABLES `jsh_factory_sales_config` WRITE;
/*!40000 ALTER TABLE `jsh_factory_sales_config` DISABLE KEYS */;
INSERT INTO `jsh_factory_sales_config` VALUES (327,330,'2026-10-26 15:26:59');
/*!40000 ALTER TABLE `jsh_factory_sales_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_sales_history`
--

DROP TABLE IF EXISTS `jsh_factory_sales_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_sales_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `action` varchar(30) NOT NULL,
  `actor_id` bigint NOT NULL,
  `actor_name` varchar(100) NOT NULL,
  `comment` text NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`,`head_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1319 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_sales_history`
--

LOCK TABLES `jsh_factory_sales_history` WRITE;
/*!40000 ALTER TABLE `jsh_factory_sales_history` DISABLE KEYS */;
INSERT INTO `jsh_factory_sales_history` VALUES (1266,327,0,'configure_reviewer',327,'jingjing','固定审核账号ID：330','2026-10-26 15:26:59'),(1267,327,667,'create',329,'模拟销售员','保存含税订单；金额按明细计算','2026-10-27 08:25:51'),(1268,327,667,'submit',329,'模拟销售员','','2026-10-27 08:26:10'),(1269,327,667,'approve',330,'模拟销售经理','','2026-10-27 08:26:52'),(1270,327,668,'create',330,'模拟销售经理','保存含税订单；金额按明细计算','2026-10-27 08:27:17'),(1271,327,669,'create',330,'模拟销售经理','保存含税订单；金额按明细计算','2026-10-27 08:32:37'),(1272,327,669,'submit',330,'模拟销售经理','','2026-10-27 08:32:41'),(1273,327,669,'approve',330,'模拟销售经理','','2026-10-27 08:32:46'),(1274,327,669,'unapprove',330,'模拟销售经理','','2026-10-27 08:32:51'),(1275,327,670,'create',329,'模拟销售员','保存含税订单；金额按明细计算','2026-10-27 08:32:54'),(1276,327,670,'submit',329,'模拟销售员','','2026-10-27 08:32:59'),(1277,327,670,'return',330,'模拟销售经理','回归检查退回修改','2026-10-27 08:33:08'),(1278,327,670,'submit',329,'模拟销售员','','2026-10-27 08:33:10'),(1279,327,670,'approve',330,'模拟销售经理','','2026-10-27 08:33:13'),(1280,327,669,'delete',330,'模拟销售经理','删除订单（保留操作记录）','2026-10-27 08:33:15'),(1281,327,670,'unapprove',330,'模拟销售经理','','2026-10-27 08:33:18'),(1282,327,670,'delete',329,'模拟销售员','删除订单（保留操作记录）','2026-10-27 08:33:20'),(1283,327,668,'submit',330,'模拟销售经理','','2026-10-27 08:34:56'),(1284,327,668,'approve',330,'模拟销售经理','','2026-10-27 08:35:01'),(1285,327,668,'stock_reserve',338,'模拟仓库','仓库确认预留及缺口；未自动修改生产任务','2026-10-27 08:36:21'),(1286,327,667,'stock_reserve',338,'模拟仓库','仓库确认预留及缺口；未自动修改生产任务','2026-10-27 08:36:39'),(1287,327,667,'production_create',329,'模拟销售员','保存生产任务联系表','2026-10-27 08:42:43'),(1288,327,667,'production_edit',329,'模拟销售员','保存生产任务联系表','2026-10-27 08:43:50'),(1289,327,667,'production_submit',329,'模拟销售员','生产任务状态更新','2026-10-27 08:44:03'),(1290,327,667,'production_approve',331,'模拟审批领导','生产任务状态更新','2026-10-27 08:46:01'),(1291,327,671,'create',330,'模拟销售经理','保存含税订单；金额按明细计算','2026-10-27 08:54:38'),(1292,327,671,'submit',330,'模拟销售经理','','2026-10-27 08:54:41'),(1293,327,671,'approve',330,'模拟销售经理','','2026-10-27 08:54:43'),(1294,327,671,'stock_reserve',327,'jingjing','仓库确认预留及缺口；未自动修改生产任务','2026-10-27 08:54:46'),(1295,327,671,'production_create',330,'模拟销售经理','保存生产任务联系表','2026-10-27 08:54:48'),(1296,327,671,'production_submit',330,'模拟销售经理','测试反审核原因','2026-10-27 08:54:53'),(1297,327,671,'production_approve',331,'模拟审批领导','测试反审核原因','2026-10-27 08:54:55'),(1298,327,671,'production_unapprove',331,'模拟审批领导','测试反审核原因','2026-10-27 08:55:09'),(1299,327,671,'production_edit',330,'模拟销售经理','保存生产任务联系表','2026-10-27 08:55:12'),(1300,327,671,'production_submit',330,'模拟销售经理','测试反审核原因','2026-10-27 08:55:14'),(1301,327,671,'production_approve',331,'模拟审批领导','测试反审核原因','2026-10-27 08:55:16'),(1302,327,671,'production_distribute',332,'模拟生产统筹','回归下发','2026-10-27 08:55:21'),(1303,327,671,'stock_release',330,'模拟销售经理','销售订单反审核，自动释放预留','2026-10-27 08:55:26'),(1304,327,671,'unapprove',330,'模拟销售经理','','2026-10-27 08:55:26'),(1305,327,671,'delete',330,'模拟销售经理','删除订单（保留操作记录）','2026-10-27 08:55:28'),(1306,327,667,'production_distribute',332,'模拟生产统筹','生产统筹分配产品、工序及车间','2026-10-27 08:57:43'),(1307,327,667,'production_accept',333,'模拟一车间主任','车间1接单；','2026-10-27 09:01:49'),(1308,327,667,'production_schedule',333,'模拟一车间主任','车间1主任排班；','2026-10-27 09:02:45'),(1309,327,667,'production_execution_start',333,'模拟一车间主任','','2026-10-27 09:03:54'),(1310,327,667,'production_execution_report',333,'模拟一车间主任','','2026-10-27 09:33:10'),(1311,327,667,'production_accept',334,'模拟二车间主任','车间2接单；','2026-10-27 10:19:57'),(1312,327,667,'production_schedule',334,'模拟二车间主任','车间2主任排班；','2026-10-27 10:20:58'),(1313,327,667,'production_execution_start',334,'模拟二车间主任','','2026-10-27 10:21:11'),(1314,327,667,'production_execution_report',334,'模拟二车间主任','','2026-10-27 10:25:03'),(1315,327,667,'stock_reserve',338,'模拟仓库','【模拟发货测试】按用户要求为订单667补入成品24.9吨；非实际生产、非真实质检及放行；仅用于系统发货流程演练。','2026-10-27 10:40:53'),(1316,327,667,'shipping_request',329,'模拟销售员','','2026-10-27 10:49:49'),(1317,327,667,'shipping_paid',339,'模拟财务','','2026-10-27 10:50:35'),(1318,327,667,'shipping_trucks',338,'模拟仓库','','2026-10-27 10:51:34');
/*!40000 ALTER TABLE `jsh_factory_sales_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_sales_order`
--

DROP TABLE IF EXISTS `jsh_factory_sales_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_sales_order` (
  `head_id` bigint NOT NULL,
  `tenant_id` bigint NOT NULL,
  `delivery_date` varchar(10) NOT NULL,
  `requirements` text NOT NULL,
  `workflow_status` varchar(16) NOT NULL DEFAULT 'draft',
  `version` int NOT NULL DEFAULT '1',
  `lines_json` mediumtext NOT NULL,
  `created_by` bigint NOT NULL,
  `updated_at` datetime NOT NULL,
  `payment_terms` varchar(20) NOT NULL DEFAULT 'unconfirmed',
  PRIMARY KEY (`head_id`),
  KEY `tenant_id` (`tenant_id`,`workflow_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_sales_order`
--

LOCK TABLES `jsh_factory_sales_order` WRITE;
/*!40000 ALTER TABLE `jsh_factory_sales_order` DISABLE KEYS */;
INSERT INTO `jsh_factory_sales_order` VALUES (667,327,'2026-10-09','','approved',6,'[{\"id\":670,\"name\":\"活性氧化铝小包装干燥剂（模拟）\",\"brand\":\"SIM-AL-01（模拟）\",\"standard\":\"Φ0.5～2 mm\",\"model\":\"10 g/袋（模拟选择）\",\"barCode\":\"ALD-MOCK-052-10G\",\"unit\":\"吨\",\"operNumber\":25,\"quantity\":25,\"price\":8300,\"unitPrice\":8300,\"allPrice\":207500.00,\"taxLastMoney\":207500.00,\"taxMoney\":0,\"remark\":\"\"}]',329,'2026-10-27 10:49:49','prepay'),(668,327,'2026-10-17','','approved',4,'[{\"id\":670,\"name\":\"活性氧化铝小包装干燥剂（模拟）\",\"brand\":\"SIM-AL-01（模拟）\",\"standard\":\"Φ0.5～2 mm\",\"model\":\"10 g/袋（模拟选择）\",\"barCode\":\"ALD-MOCK-052-10G\",\"unit\":\"吨\",\"operNumber\":30,\"quantity\":30,\"price\":120,\"unitPrice\":120,\"allPrice\":3600.00,\"taxLastMoney\":3600.00,\"taxMoney\":0,\"remark\":\"\"}]',330,'2026-10-27 08:36:21','prepay'),(669,327,'2026-11-10','临时审核规则回归','draft',5,'[{\"id\":677,\"name\":\"SELF-REVIEW-fdaee0d1\",\"brand\":\"模拟牌号\",\"standard\":\"审核回归规格\",\"model\":\"模拟型号\",\"barCode\":\"SELF-REVIEW-fdaee0d1\",\"unit\":\"吨\",\"operNumber\":1,\"quantity\":1,\"price\":1000,\"unitPrice\":1000,\"allPrice\":1000.00,\"taxLastMoney\":1000.00,\"taxMoney\":0,\"remark\":\"\"}]',330,'2026-10-27 08:33:15','prepay'),(670,327,'2026-11-10','临时审核规则回归','draft',7,'[{\"id\":677,\"name\":\"SELF-REVIEW-fdaee0d1\",\"brand\":\"模拟牌号\",\"standard\":\"审核回归规格\",\"model\":\"模拟型号\",\"barCode\":\"SELF-REVIEW-fdaee0d1\",\"unit\":\"吨\",\"operNumber\":1,\"quantity\":1,\"price\":1000,\"unitPrice\":1000,\"allPrice\":1000.00,\"taxLastMoney\":1000.00,\"taxMoney\":0,\"remark\":\"\"}]',329,'2026-10-27 08:33:20','prepay'),(671,327,'2026-11-10','','draft',6,'[{\"id\":678,\"name\":\"PROD-REVERSE-c02a42ae\",\"brand\":\"模拟牌号\",\"standard\":\"回归规格\",\"model\":\"测试\",\"barCode\":\"PROD-REVERSE-c02a42ae\",\"unit\":\"吨\",\"operNumber\":1,\"quantity\":1,\"price\":1000,\"unitPrice\":1000,\"allPrice\":1000.00,\"taxLastMoney\":1000.00,\"taxMoney\":0,\"remark\":\"\"}]',330,'2026-10-27 08:55:28','prepay');
/*!40000 ALTER TABLE `jsh_factory_sales_order` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_shipment`
--

DROP TABLE IF EXISTS `jsh_factory_shipment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_shipment` (
  `head_id` bigint NOT NULL,
  `tenant_id` bigint NOT NULL,
  `workflow_status` varchar(20) NOT NULL,
  `version` int NOT NULL DEFAULT '1',
  `trucks_json` mediumtext NOT NULL,
  `requested_by` bigint NOT NULL,
  `requested_at` datetime NOT NULL,
  `paid_amount` decimal(20,2) DEFAULT NULL,
  `paid_date` date DEFAULT NULL,
  `paid_by` bigint DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `ledger_head_id` bigint DEFAULT NULL,
  `shipped_by` bigint DEFAULT NULL,
  `shipped_at` datetime DEFAULT NULL,
  PRIMARY KEY (`head_id`),
  KEY `tenant_id` (`tenant_id`,`workflow_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_shipment`
--

LOCK TABLES `jsh_factory_shipment` WRITE;
/*!40000 ALTER TABLE `jsh_factory_shipment` DISABLE KEYS */;
INSERT INTO `jsh_factory_shipment` VALUES (667,327,'requested',3,'[{\"driver\":\"45\",\"phone\":\"135468\",\"plate\":\"45\",\"lines\":[{\"depotName\":\"模拟成品仓\",\"lineNo\":0,\"quantity\":0.1,\"depotId\":20,\"batchNumber\":\"SIM-SC-20261027-01\"},{\"depotName\":\"模拟成品仓\",\"lineNo\":0,\"quantity\":24.9,\"depotId\":20,\"batchNumber\":\"SIM-SHIP-667-20261027\"}],\"photos\":[]}]',329,'2026-10-27 10:49:49',207500.00,'2026-10-27',339,'2026-10-27 10:50:35',NULL,NULL,NULL);
/*!40000 ALTER TABLE `jsh_factory_shipment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_shipping_config`
--

DROP TABLE IF EXISTS `jsh_factory_shipping_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_shipping_config` (
  `tenant_id` bigint NOT NULL,
  `finance_id` bigint NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_shipping_config`
--

LOCK TABLES `jsh_factory_shipping_config` WRITE;
/*!40000 ALTER TABLE `jsh_factory_shipping_config` DISABLE KEYS */;
INSERT INTO `jsh_factory_shipping_config` VALUES (327,339,'2026-10-26 15:27:04');
/*!40000 ALTER TABLE `jsh_factory_shipping_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_shipping_history`
--

DROP TABLE IF EXISTS `jsh_factory_shipping_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_shipping_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `action` varchar(30) NOT NULL,
  `actor_id` bigint NOT NULL,
  `actor_name` varchar(100) NOT NULL,
  `comment` varchar(2000) NOT NULL,
  `payload_json` mediumtext NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`,`head_id`)
) ENGINE=InnoDB AUTO_INCREMENT=146 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_shipping_history`
--

LOCK TABLES `jsh_factory_shipping_history` WRITE;
/*!40000 ALTER TABLE `jsh_factory_shipping_history` DISABLE KEYS */;
INSERT INTO `jsh_factory_shipping_history` VALUES (142,327,0,'configure',327,'jingjing','配置到账确认财务账号','{\"financeId\":339}','2026-10-26 15:27:04'),(143,327,667,'request',329,'模拟销售员','','{\"action\":\"request\",\"orderVersion\":5,\"paymentTerms\":\"prepay\"}','2026-10-27 10:49:49'),(144,327,667,'paid',339,'模拟财务','','{\"amount\":207500,\"paidDate\":\"2026-10-27\",\"action\":\"paid\",\"comment\":\"\",\"version\":1}','2026-10-27 10:50:35'),(145,327,667,'trucks',338,'模拟仓库','','{\"action\":\"trucks\",\"trucks\":[{\"plate\":\"45\",\"driver\":\"45\",\"phone\":\"135468\",\"photos\":[],\"lines\":[{\"lineNo\":0,\"depotId\":20,\"batchNumber\":\"SIM-SC-20261027-01\",\"quantity\":0.1},{\"lineNo\":0,\"depotId\":20,\"batchNumber\":\"SIM-SHIP-667-20261027\",\"quantity\":24.9}]}],\"version\":2}','2026-10-27 10:51:34');
/*!40000 ALTER TABLE `jsh_factory_shipping_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_stock_check`
--

DROP TABLE IF EXISTS `jsh_factory_stock_check`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_stock_check` (
  `head_id` bigint NOT NULL,
  `tenant_id` bigint NOT NULL,
  `note` varchar(2000) NOT NULL,
  `checked_by` bigint NOT NULL,
  `checked_at` datetime NOT NULL,
  PRIMARY KEY (`head_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_stock_check`
--

LOCK TABLES `jsh_factory_stock_check` WRITE;
/*!40000 ALTER TABLE `jsh_factory_stock_check` DISABLE KEYS */;
INSERT INTO `jsh_factory_stock_check` VALUES (667,327,'【模拟发货测试】按用户要求为订单667补入成品24.9吨；非实际生产、非真实质检及放行；仅用于系统发货流程演练。',338,'2026-10-27 10:40:53'),(668,327,'',338,'2026-10-27 08:36:21');
/*!40000 ALTER TABLE `jsh_factory_stock_check` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_stock_history`
--

DROP TABLE IF EXISTS `jsh_factory_stock_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_stock_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `tenant_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `action` varchar(30) NOT NULL,
  `actor_name` varchar(100) NOT NULL,
  `note` varchar(2000) NOT NULL,
  `allocations_json` mediumtext NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`,`head_id`)
) ENGINE=InnoDB AUTO_INCREMENT=241 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_stock_history`
--

LOCK TABLES `jsh_factory_stock_history` WRITE;
/*!40000 ALTER TABLE `jsh_factory_stock_history` DISABLE KEYS */;
INSERT INTO `jsh_factory_stock_history` VALUES (236,327,668,'stock_reserve','模拟仓库','仓库确认预留及缺口；未自动修改生产任务','[]','2026-10-27 08:36:21'),(237,327,667,'stock_reserve','模拟仓库','仓库确认预留及缺口；未自动修改生产任务','[]','2026-10-27 08:36:39'),(238,327,671,'stock_reserve','jingjing','仓库确认预留及缺口；未自动修改生产任务','[]','2026-10-27 08:54:46'),(239,327,671,'stock_release','模拟销售经理','销售订单反审核，自动释放预留','[]','2026-10-27 08:55:26'),(240,327,667,'stock_reserve','模拟仓库','【模拟发货测试】按用户要求为订单667补入成品24.9吨；非实际生产、非真实质检及放行；仅用于系统发货流程演练。','[{\"lineNo\":0,\"quantity\":0.1,\"depotId\":20,\"materialId\":670,\"batchNumber\":\"SIM-SC-20261027-01\"},{\"lineNo\":0,\"quantity\":24.9,\"depotId\":20,\"materialId\":670,\"batchNumber\":\"SIM-SHIP-667-20261027\"}]','2026-10-27 10:40:53');
/*!40000 ALTER TABLE `jsh_factory_stock_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_stock_lock`
--

DROP TABLE IF EXISTS `jsh_factory_stock_lock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_stock_lock` (
  `tenant_id` bigint NOT NULL,
  PRIMARY KEY (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_stock_lock`
--

LOCK TABLES `jsh_factory_stock_lock` WRITE;
/*!40000 ALTER TABLE `jsh_factory_stock_lock` DISABLE KEYS */;
INSERT INTO `jsh_factory_stock_lock` VALUES (327);
/*!40000 ALTER TABLE `jsh_factory_stock_lock` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_stock_reservation`
--

DROP TABLE IF EXISTS `jsh_factory_stock_reservation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_stock_reservation` (
  `tenant_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `line_no` int NOT NULL,
  `material_id` bigint NOT NULL,
  `depot_id` bigint NOT NULL,
  `batch_number` varchar(100) NOT NULL,
  `quantity` decimal(24,6) NOT NULL,
  PRIMARY KEY (`tenant_id`,`head_id`,`line_no`,`material_id`,`depot_id`,`batch_number`),
  KEY `lot_reservation` (`tenant_id`,`material_id`,`depot_id`,`batch_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_stock_reservation`
--

LOCK TABLES `jsh_factory_stock_reservation` WRITE;
/*!40000 ALTER TABLE `jsh_factory_stock_reservation` DISABLE KEYS */;
INSERT INTO `jsh_factory_stock_reservation` VALUES (327,667,0,670,20,'SIM-SC-20261027-01',0.100000),(327,667,0,670,20,'SIM-SHIP-667-20261027',24.900000);
/*!40000 ALTER TABLE `jsh_factory_stock_reservation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_factory_workshop_task`
--

DROP TABLE IF EXISTS `jsh_factory_workshop_task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_factory_workshop_task` (
  `tenant_id` bigint NOT NULL,
  `head_id` bigint NOT NULL,
  `workshop_no` int NOT NULL,
  `workflow_status` varchar(16) NOT NULL,
  `accepted_by` bigint DEFAULT NULL,
  `accepted_at` datetime DEFAULT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`tenant_id`,`head_id`,`workshop_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_factory_workshop_task`
--

LOCK TABLES `jsh_factory_workshop_task` WRITE;
/*!40000 ALTER TABLE `jsh_factory_workshop_task` DISABLE KEYS */;
INSERT INTO `jsh_factory_workshop_task` VALUES (327,667,1,'scheduled',333,'2026-10-27 09:01:49','2026-10-27 09:02:45'),(327,667,2,'scheduled',334,'2026-10-27 10:19:57','2026-10-27 10:20:58');
/*!40000 ALTER TABLE `jsh_factory_workshop_task` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_function`
--

DROP TABLE IF EXISTS `jsh_function`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_function` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `number` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '编号',
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '名称',
  `parent_number` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '上级编号',
  `url` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '链接',
  `component` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组件',
  `state` bit(1) DEFAULT NULL COMMENT '收缩',
  `sort` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '排序',
  `enabled` bit(1) DEFAULT NULL COMMENT '启用',
  `type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型',
  `push_btn` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '功能按钮',
  `icon` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '图标',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `url` (`url`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=275 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='功能模块表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_function`
--

LOCK TABLES `jsh_function` WRITE;
/*!40000 ALTER TABLE `jsh_function` DISABLE KEYS */;
INSERT INTO `jsh_function` VALUES (1,'0001','系统管理','0','/system','/layouts/TabLayout',0x01,'0910',0x01,'电脑版','','setting','0'),(13,'000102','角色管理','0001','/system/role','/system/RoleList',0x00,'0130',0x01,'电脑版','1','profile','0'),(14,'000103','用户管理','0001','/system/user','/system/UserList',0x00,'0140',0x01,'电脑版','1','profile','0'),(15,'000104','日志管理','0001','/system/log','/system/LogList',0x00,'0160',0x01,'电脑版','','profile','0'),(16,'000105','菜单管理','0001','/system/function','/system/FunctionList',0x00,'0166',0x01,'电脑版','1','profile','0'),(18,'000109','租户管理','0001','/system/tenant','/system/TenantList',0x00,'0167',0x01,'电脑版','1','profile','0'),(21,'0101','商品管理','0','/material','/layouts/TabLayout',0x00,'0620',0x01,'电脑版',NULL,'shopping','0'),(22,'010101','商品类别','0101','/material/material_category','/material/MaterialCategoryList',0x00,'0230',0x01,'电脑版','1','profile','0'),(23,'010102','产品信息','0101','/material/material','/material/MaterialList',0x00,'0240',0x01,'电脑版','1,3','profile','0'),(24,'0102','基础资料','0','/systemA','/layouts/TabLayout',0x00,'0750',0x01,'电脑版',NULL,'appstore','0'),(25,'01020101','供应商信息','0102','/system/vendor','/system/VendorList',0x00,'0260',0x01,'电脑版','1,3','profile','0'),(26,'010202','仓库信息','0102','/system/depot','/system/DepotList',0x00,'0270',0x01,'电脑版','1','profile','0'),(31,'010206','经手人管理','0102','/system/person','/system/PersonList',0x00,'0284',0x01,'电脑版','1','profile','0'),(32,'0502','采购管理','0','/bill','/layouts/TabLayout',0x00,'0330',0x01,'电脑版','','retweet','0'),(33,'050201','采购入库','0502','/bill/purchase_in','/bill/PurchaseInList',0x00,'0340',0x01,'电脑版','1,2,3,7','profile','0'),(38,'0603','销售管理','0','/billB','/layouts/TabLayout',0x00,'0390',0x01,'电脑版','','shopping-cart','0'),(40,'080107','调拨出库','0801','/bill/allocation_out','/bill/AllocationOutList',0x00,'0807',0x01,'电脑版','1,2,3,7','profile','0'),(41,'060303','销售出库','0603','/bill/sale_out','/bill/SaleOutList',0x00,'0394',0x00,'电脑版','1,2,3,7','profile','0'),(44,'0704','财务管理','0','/financial','/layouts/TabLayout',0x00,'0450',0x01,'电脑版','','money-collect','0'),(59,'030101','进销存统计','0301','/report/in_out_stock_report','/report/InOutStockReport',0x00,'0658',0x01,'电脑版','','profile','0'),(194,'010204','收支项目','0102','/system/in_out_item','/system/InOutItemList',0x00,'0282',0x01,'电脑版','1','profile','0'),(195,'010205','结算账户','0102','/system/account','/system/AccountList',0x00,'0283',0x01,'电脑版','1','profile','0'),(197,'070402','收入单','0704','/financial/item_in','/financial/ItemInList',0x00,'0465',0x01,'电脑版','1,2,3,7','profile','0'),(198,'0301','报表查询','0','/report','/layouts/TabLayout',0x00,'0570',0x01,'电脑版',NULL,'pie-chart','0'),(199,'050204','采购退货','0502','/bill/purchase_back','/bill/PurchaseBackList',0x00,'0345',0x01,'电脑版','1,2,3,7','profile','0'),(200,'060305','客户退货申请与收货','0603','/factory/returns','/factory/ReturnList',0x00,'0396',0x01,'电脑版','1,2,3,7','rollback','0'),(201,'080103','其它入库','0801','/bill/other_in','/bill/OtherInList',0x00,'0803',0x01,'电脑版','1,2,3,7','profile','0'),(202,'080105','其它出库','0801','/bill/other_out','/bill/OtherOutList',0x00,'0805',0x01,'电脑版','1,2,3,7','profile','0'),(203,'070403','支出单','0704','/financial/item_out','/financial/ItemOutList',0x00,'0470',0x01,'电脑版','1,2,3,7','profile','0'),(204,'070404','收款单','0704','/financial/money_in','/financial/MoneyInList',0x00,'0475',0x01,'电脑版','1,2,3,7','profile','0'),(205,'070405','付款单','0704','/financial/money_out','/financial/MoneyOutList',0x00,'0480',0x01,'电脑版','1,2,3,7','profile','0'),(206,'070406','转账单','0704','/financial/giro','/financial/GiroList',0x00,'0490',0x01,'电脑版','1,2,3,7','profile','0'),(207,'030102','账户统计','0301','/report/account_report','/report/AccountReport',0x00,'0610',0x01,'电脑版','','profile','0'),(208,'030103','采购统计','0301','/report/buy_in_report','/report/BuyInReport',0x00,'0620',0x01,'电脑版','','profile','0'),(209,'030104','销售统计','0301','/report/sale_out_report','/report/SaleOutReport',0x00,'0630',0x01,'电脑版','','profile','0'),(210,'040102','零售出库','0401','/bill/retail_out','/bill/RetailOutList',0x00,'0405',0x00,'电脑版','1,2,3,7','profile','0'),(211,'040104','零售退货','0401','/bill/retail_back','/bill/RetailBackList',0x00,'0407',0x00,'电脑版','1,2,3,7','profile','0'),(212,'070407','收预付款','0704','/financial/advance_in','/financial/AdvanceInList',0x00,'0495',0x01,'电脑版','1,2,3,7','profile','0'),(217,'01020102','客户信息','0102','/system/customer','/system/CustomerList',0x00,'0262',0x01,'电脑版','1,3','profile','0'),(218,'01020103','会员信息','0102','/system/member','/system/MemberList',0x00,'0263',0x00,'电脑版','1,3','profile','0'),(220,'010103','多单位','0101','/system/unit','/system/UnitList',0x00,'0245',0x01,'电脑版','1','profile','0'),(225,'0401','零售管理','0','/billC','/layouts/TabLayout',0x00,'0101',0x00,'电脑版','','gift','0'),(226,'030106','入库明细','0301','/report/in_detail','/report/InDetail',0x00,'0640',0x01,'电脑版','','profile','0'),(227,'030107','出库明细','0301','/report/out_detail','/report/OutDetail',0x00,'0645',0x01,'电脑版','','profile','0'),(228,'030108','入库汇总','0301','/report/in_material_count','/report/InMaterialCount',0x00,'0650',0x01,'电脑版','','profile','0'),(229,'030109','出库汇总','0301','/report/out_material_count','/report/OutMaterialCount',0x00,'0655',0x01,'电脑版','','profile','0'),(232,'080109','组装单','0801','/bill/assemble','/bill/AssembleList',0x00,'0809',0x00,'电脑版','1,2,3,7','profile','0'),(233,'080111','拆卸单','0801','/bill/disassemble','/bill/DisassembleList',0x00,'0811',0x00,'电脑版','1,2,3,7','profile','0'),(234,'000105','系统配置','0001','/system/system_config','/system/SystemConfigList',0x00,'0164',0x01,'电脑版','1','profile','0'),(235,'030110','客户对账','0301','/report/customer_account','/report/CustomerAccount',0x00,'0660',0x01,'电脑版','','profile','0'),(236,'000106','商品属性','0001','/material/material_property','/material/MaterialPropertyList',0x00,'0163',0x01,'电脑版','1','profile','0'),(237,'030111','供应商对账','0301','/report/vendor_account','/report/VendorAccount',0x00,'0665',0x01,'电脑版','','profile','0'),(239,'0801','仓库管理','0','/billD','/layouts/TabLayout',0x00,'0420',0x01,'电脑版','','hdd','0'),(241,'050202','采购订单','0502','/bill/purchase_order','/bill/PurchaseOrderList',0x00,'0335',0x01,'电脑版','1,2,3,7','profile','0'),(242,'060301','销售订单','0603','/bill/sale_order','/factory/SalesOrderList',0x00,'0392',0x01,'电脑版','1,2,3,7','profile','0'),(243,'000108','部门管理','0001','/system/organization','/system/OrganizationList',0x01,'0150',0x01,'电脑版','1','profile','0'),(244,'030112','库存预警','0301','/report/stock_warning_report','/report/StockWarningReport',0x00,'0670',0x01,'电脑版','','profile','0'),(245,'000107','插件管理','0001','/system/plugin','/system/PluginList',0x00,'0170',0x01,'电脑版','1','profile','0'),(246,'030113','商品库存','0301','/report/material_stock','/report/MaterialStock',0x00,'0605',0x01,'电脑版','','profile','0'),(247,'010105','多属性','0101','/material/material_attribute','/material/MaterialAttributeList',0x00,'0250',0x01,'电脑版','1','profile','0'),(248,'030150','调拨明细','0301','/report/allocation_detail','/report/AllocationDetail',0x00,'0646',0x01,'电脑版','','profile','0'),(258,'000112','平台配置','0001','/system/platform_config','/system/PlatformConfigList',0x00,'0175',0x01,'电脑版','','profile','0'),(259,'030105','零售统计','0301','/report/retail_out_report','/report/RetailOutReport',0x00,'0615',0x00,'电脑版','','profile','0'),(260,'000113','字典管理','0001','/system/dict','/system/DictList',0x00,'0172',0x01,'电脑版','','profile','0'),(261,'050203','请购单','0502','/bill/purchase_apply','/bill/PurchaseApplyList',0x00,'0330',0x01,'电脑版','1,2,3,7','profile','0'),(262,'080190','订单库存核查','0801','/factory/stock_check','/factory/StockCheckList',0x00,'0421',0x01,'电脑版','1','profile','0'),(263,'factory0901','生产管理','0','/factoryProduction','/layouts/TabLayout',0x00,'0430',0x01,'电脑版','1','tool','0'),(264,'factory090101','生产任务联系表','factory0901','/factory/production_task','/factory/ProductionTaskList',0x00,'0431',0x01,'电脑版','1','profile','0'),(265,'factory090102','车间领补退料','factory0901','/factory/material_request','/factory/MaterialRequestList',0x00,'0432',0x01,'电脑版','1','profile','0'),(266,'factory090103','开工与生产日报','factory0901','/factory/production_execution','/factory/ProductionExecutionList',0x00,'0433',0x01,'电脑版','1','form','0'),(267,'factory090104','半成品送检与流转','factory0901','/factory/quality_transfer','/factory/QualityTransferList',0x00,'0434',0x01,'电脑版','1','experiment','0'),(268,'factory090105','成品质检入库与放行','factory0901','/factory/finished_product','/factory/FinishedProductList',0x00,'0435',0x01,'电脑版','1','safety-certificate','0'),(269,'factoryShipping','发货申请与装车出库','0603','/factory/shipping','/factory/ShipmentList',0x00,'0329',0x01,'电脑版','1','car','0'),(270,'factoryOrderChange','生产中订单变更与取消','0603','/factory/order_change','/factory/OrderChangeList',0x00,'0335',0x01,'电脑版','1','edit','0'),(271,'factoryOrderProgress','订单全过程进度','factoryProgressRoot','/factory/order_progress','/factory/OrderProgressList',0x00,'0301',0x01,'电脑版','1','dashboard','0'),(272,'factoryProgressRoot','业务看板','0','/factoryProgress','/layouts/TabLayout',0x00,'0300',0x01,'电脑版','1','dashboard','0'),(273,'factoryQualityStandard','产品质检标准','0101','/factory/quality_standard','/factory/QualityStandardList',0x00,'0625',0x01,'电脑版','1','experiment','0'),(274,'factoryRawMaterial','原料信息','0101','/material/raw_material','/material/RawMaterialList',0x00,'0101021',0x01,'电脑版','1,3','database','0');
/*!40000 ALTER TABLE `jsh_function` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_in_out_item`
--

DROP TABLE IF EXISTS `jsh_in_out_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_in_out_item` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '名称',
  `type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型',
  `remark` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `enabled` bit(1) DEFAULT NULL COMMENT '启用',
  `sort` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '排序',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='收支项目';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_in_out_item`
--

LOCK TABLES `jsh_in_out_item` WRITE;
/*!40000 ALTER TABLE `jsh_in_out_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_in_out_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_log`
--

DROP TABLE IF EXISTS `jsh_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint DEFAULT NULL COMMENT '用户id',
  `operation` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '操作模块名称',
  `client_ip` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '客户端IP',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `status` tinyint DEFAULT NULL COMMENT '操作状态 0==成功，1==失败',
  `content` varchar(5000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '详情',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `FKF2696AA13E226853` (`user_id`) USING BTREE,
  KEY `create_time` (`create_time`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=8703 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='操作日志';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_log`
--

LOCK TABLES `jsh_log` WRITE;
/*!40000 ALTER TABLE `jsh_log` DISABLE KEYS */;
INSERT INTO `jsh_log` VALUES (8455,120,'用户','127.0.0.1/127.0.0.1','2026-10-26 10:55:56',0,'登录admin',0),(8456,120,'用户','127.0.0.1/127.0.0.1','2026-10-26 10:56:29',0,'登录admin',0),(8457,120,'用户','127.0.0.1/127.0.0.1','2026-10-26 13:19:20',0,'登录admin',0),(8458,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 13:38:53',0,'登录jingjing',327),(8459,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 13:47:08',0,'新增销售员',327),(8460,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 13:48:04',0,'新增',327),(8461,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 13:50:34',0,'修改角色的按钮权限',327),(8462,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 13:56:46',0,'新增审批领导',327),(8463,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 13:58:33',0,'新增',327),(8464,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 14:05:22',0,'修改',327),(8465,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 14:18:08',0,'修改',327),(8466,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 14:23:19',0,'修改角色的按钮权限',327),(8467,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 14:27:30',0,'新增销售经理',327),(8468,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 14:32:51',0,'修改',327),(8469,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 14:39:24',0,'删除[销售员][审批领导][销售经理]',327),(8470,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 14:41:46',0,'新增销售员',327),(8471,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 14:42:26',0,'新增',327),(8472,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 14:44:03',0,'修改角色的按钮权限',327),(8473,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 14:46:19',0,'新增销售经理',327),(8474,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 14:46:57',0,'新增',327),(8475,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 14:47:09',0,'修改角色的按钮权限',327),(8476,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 14:48:11',0,'新增审批领导',327),(8477,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 14:48:53',0,'新增',327),(8478,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 14:49:36',0,'修改角色的按钮权限',327),(8479,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 14:51:31',0,'新增生产统筹',327),(8480,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:01:02',0,'新增',327),(8481,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:02:00',0,'修改角色的按钮权限',327),(8482,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:22:07',0,'登录jingjing',327),(8483,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:22:09',0,'修改销售员',327),(8484,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:22:09',0,'修改',327),(8485,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:22:48',0,'登录jingjing',327),(8486,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:22:49',0,'修改销售员',327),(8487,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:22:49',0,'修改',327),(8488,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:22:49',0,'新增模拟销售员',327),(8489,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:23:53',0,'登录jingjing',327),(8490,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:23:55',0,'修改销售员',327),(8491,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:23:57',0,'修改',327),(8492,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:12',0,'登录jingjing',327),(8493,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:26:14',0,'修改销售员',327),(8494,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:15',0,'修改',327),(8495,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:16',0,'删除[模拟销售员]',327),(8496,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:18',0,'新增',327),(8497,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:18',0,'新增',327),(8498,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:26:20',0,'修改销售经理',327),(8499,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:21',0,'修改',327),(8500,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:23',0,'新增',327),(8501,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:23',0,'新增',327),(8502,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:26:24',0,'修改审批领导',327),(8503,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:26',0,'修改',327),(8504,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:27',0,'新增',327),(8505,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:27',0,'新增',327),(8506,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:26:29',0,'修改生产统筹',327),(8507,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:30',0,'修改',327),(8508,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:32',0,'新增',327),(8509,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:32',0,'新增',327),(8510,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:26:33',0,'新增车间主任',327),(8511,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:35',0,'新增',327),(8512,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:36',0,'新增',327),(8513,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:36',0,'新增',327),(8514,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:38',0,'新增',327),(8515,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:38',0,'新增',327),(8516,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:39',0,'新增',327),(8517,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:39',0,'新增',327),(8518,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:26:41',0,'新增质检员',327),(8519,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:42',0,'新增',327),(8520,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:44',0,'新增',327),(8521,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:44',0,'新增',327),(8522,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:26:45',0,'新增质检主任',327),(8523,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:47',0,'新增',327),(8524,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:48',0,'新增',327),(8525,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:48',0,'新增',327),(8526,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:26:50',0,'新增仓库管理员',327),(8527,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:51',0,'新增',327),(8528,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:53',0,'新增',327),(8529,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:53',0,'新增',327),(8530,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 15:26:54',0,'新增财务人员',327),(8531,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:56',0,'新增',327),(8532,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:26:57',0,'新增',327),(8533,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:26:58',0,'新增',327),(8534,329,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:27:08',0,'登录模拟销售员',327),(8535,330,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:27:09',0,'登录模拟销售经理',327),(8536,331,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:27:11',0,'登录模拟审批领导',327),(8537,332,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:27:12',0,'登录模拟生产统筹',327),(8538,333,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:27:14',0,'登录模拟一车间主任',327),(8539,334,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:27:15',0,'登录模拟二车间主任',327),(8540,335,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:27:16',0,'登录模拟三车间主任',327),(8541,336,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:27:18',0,'登录模拟质检员',327),(8542,337,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:27:19',0,'登录模拟质检主任',327),(8543,338,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:27:21',0,'登录模拟仓库',327),(8544,339,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:27:22',0,'登录模拟财务',327),(8545,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 15:32:29',0,'登录jingjing',327),(8546,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:37:51',0,'新增',327),(8547,327,'仓库','127.0.0.1/127.0.0.1','2026-10-26 15:37:51',0,'新增模拟原料仓',327),(8548,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:38:02',0,'修改',327),(8549,327,'仓库','127.0.0.1/127.0.0.1','2026-10-26 15:38:02',0,'新增模拟成品仓',327),(8550,327,'仓库','127.0.0.1/127.0.0.1','2026-10-26 15:38:12',0,'修改20',327),(8551,327,'系统配置','127.0.0.1/127.0.0.1','2026-10-26 15:42:33',0,'新增配置信息',327),(8552,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:43:04',0,'新增',327),(8553,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:43:21',0,'新增',327),(8554,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:43:27',0,'新增',327),(8555,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:43:31',0,'新增',327),(8556,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:53:30',0,'新增',327),(8557,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:53:44',0,'新增',327),(8558,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 15:53:52',0,'新增',327),(8559,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 16:03:35',0,'登录jingjing',327),(8560,327,'商品类型','127.0.0.1/127.0.0.1','2026-10-26 16:03:37',0,'新增模拟自产成品',327),(8561,327,'商品类型','127.0.0.1/127.0.0.1','2026-10-26 16:03:39',0,'新增模拟干燥剂',327),(8562,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 16:05:07',0,'登录jingjing',327),(8563,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:05:10',0,'新增活性氧化铝小包装干燥剂（模拟）',327),(8564,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:05:12',0,'新增模拟原料A',327),(8565,338,'用户','127.0.0.1/127.0.0.1','2026-10-26 16:05:27',0,'登录模拟仓库',327),(8566,338,'单据','127.0.0.1/127.0.0.1','2026-10-26 16:05:30',0,'新增SIM-RK-20261026-RAW-A[审核]',327),(8567,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 16:07:38',0,'登录jingjing',327),(8568,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 16:33:37',0,'登录jingjing',327),(8569,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:33:40',0,'新增KIND-TEST-9322e3c8d6-product',327),(8570,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:33:46',0,'新增KIND-TEST-9322e3c8d6-raw',327),(8571,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:33:53',0,'删除[KIND-TEST-9322e3c8d6-product]',327),(8572,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:33:55',0,'删除[KIND-TEST-9322e3c8d6-raw]',327),(8573,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 16:55:12',0,'登录jingjing',327),(8574,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:55:15',0,'新增PM-TEST-03ee50bd-0',327),(8575,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:55:18',0,'新增PM-TEST-03ee50bd-1',327),(8576,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:55:21',0,'新增PM-TEST-03ee50bd-2',327),(8577,329,'用户','127.0.0.1/127.0.0.1','2026-10-26 16:55:36',0,'登录模拟销售员',327),(8578,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 16:55:41',0,'新增PM-TEST-03ee50bd',327),(8579,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 16:55:43',0,'新增',327),(8580,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 16:55:46',0,'新增',327),(8581,327,'关联关系','127.0.0.1/127.0.0.1','2026-10-26 16:55:46',0,'新增',327),(8582,340,'用户','127.0.0.1/127.0.0.1','2026-10-26 16:55:46',0,'登录PM-TEST-03ee50bd',327),(8583,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:55:53',0,'删除[PM-TEST-03ee50bd-0]',327),(8584,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:55:56',0,'删除[PM-TEST-03ee50bd-1]',327),(8585,327,'商品','127.0.0.1/127.0.0.1','2026-10-26 16:55:58',0,'删除[PM-TEST-03ee50bd-2]',327),(8586,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 16:56:00',0,'删除[PM-TEST-03ee50bd]',327),(8587,327,'角色','127.0.0.1/127.0.0.1','2026-10-26 16:56:02',0,'删除[PM-TEST-03ee50bd]',327),(8588,327,'用户','127.0.0.1/127.0.0.1','2026-10-26 16:57:22',0,'登录jingjing',327),(8589,327,'商家','127.0.0.1/127.0.0.1','2026-10-26 17:37:46',0,'新增昆山韩林环保设备有限公司',327),(8590,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:20:33',0,'登录jingjing',327),(8591,327,'商品','127.0.0.1/127.0.0.1','2026-10-27 08:22:54',0,'修改活性氧化铝小包装干燥剂（模拟）',327),(8592,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:24:58',0,'登录模拟销售员',327),(8593,329,'单据','127.0.0.1/127.0.0.1','2026-10-27 08:25:52',0,'新增XSDD20261027947FA92B-1FD',327),(8594,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:26:40',0,'登录模拟销售经理',327),(8595,330,'单据','127.0.0.1/127.0.0.1','2026-10-27 08:27:17',0,'新增XSDD20261027A572FFB5-B21',327),(8596,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:32:28',0,'登录jingjing',327),(8597,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:32:29',0,'登录模拟销售经理',327),(8598,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:32:29',0,'登录模拟销售员',327),(8599,327,'商品','127.0.0.1/127.0.0.1','2026-10-27 08:32:32',0,'新增SELF-REVIEW-fdaee0d1',327),(8600,327,'商家','127.0.0.1/127.0.0.1','2026-10-27 08:32:34',0,'新增SELF-REVIEW-fdaee0d1',327),(8601,330,'单据','127.0.0.1/127.0.0.1','2026-10-27 08:32:37',0,'新增XSDD2026102707563DAD-DFF',327),(8602,329,'单据','127.0.0.1/127.0.0.1','2026-10-27 08:32:55',0,'新增XSDD20261027B7697AAB-465',327),(8603,327,'商品','127.0.0.1/127.0.0.1','2026-10-27 08:33:23',0,'删除[SELF-REVIEW-fdaee0d1]',327),(8604,327,'商家','127.0.0.1/127.0.0.1','2026-10-27 08:33:25',0,'删除[SELF-REVIEW-fdaee0d1]',327),(8605,338,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:35:50',0,'登录模拟仓库',327),(8606,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:36:52',0,'登录模拟销售员',327),(8607,331,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:45:48',0,'登录模拟审批领导',327),(8608,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:54:29',0,'登录jingjing',327),(8609,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:54:29',0,'登录模拟销售经理',327),(8610,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:54:29',0,'登录模拟销售员',327),(8611,331,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:54:30',0,'登录模拟审批领导',327),(8612,332,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:54:30',0,'登录模拟生产统筹',327),(8613,327,'商品','127.0.0.1/127.0.0.1','2026-10-27 08:54:33',0,'新增PROD-REVERSE-c02a42ae',327),(8614,327,'商家','127.0.0.1/127.0.0.1','2026-10-27 08:54:36',0,'新增PROD-REVERSE-c02a42ae',327),(8615,330,'单据','127.0.0.1/127.0.0.1','2026-10-27 08:54:39',0,'新增XSDD20261027264D53A0-7AA',327),(8616,327,'商品','127.0.0.1/127.0.0.1','2026-10-27 08:55:31',0,'删除[PROD-REVERSE-c02a42ae]',327),(8617,327,'商家','127.0.0.1/127.0.0.1','2026-10-27 08:55:34',0,'删除[PROD-REVERSE-c02a42ae]',327),(8618,332,'用户','127.0.0.1/127.0.0.1','2026-10-27 08:56:46',0,'登录模拟生产统筹',327),(8619,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:01:40',0,'登录模拟一车间主任',327),(8620,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:20:11',0,'登录jingjing',327),(8621,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:20:11',0,'登录模拟销售经理',327),(8622,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:20:12',0,'登录模拟销售员',327),(8623,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:20:12',0,'登录模拟一车间主任',327),(8624,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:25:56',0,'登录模拟一车间主任',327),(8625,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:26:20',0,'登录jingjing',327),(8626,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:26:21',0,'登录模拟销售经理',327),(8627,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:26:21',0,'登录模拟销售员',327),(8628,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:26:21',0,'登录模拟一车间主任',327),(8629,334,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:26:21',0,'登录模拟二车间主任',327),(8630,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:27:26',0,'登录jingjing',327),(8631,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:27:26',0,'登录模拟销售经理',327),(8632,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:27:26',0,'登录模拟销售员',327),(8633,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:27:26',0,'登录模拟一车间主任',327),(8634,338,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:27:43',0,'登录模拟仓库',327),(8635,338,'单据','127.0.0.1/127.0.0.1','2026-10-27 09:27:54',0,'新增CL20261027C63B03CA6DDC-OUT[审核]',327),(8636,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:30:31',0,'登录模拟一车间主任',327),(8637,336,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:36:43',0,'登录模拟质检员',327),(8638,120,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:39:16',0,'登录admin',0),(8639,120,'关联关系','127.0.0.1/127.0.0.1','2026-10-27 09:39:35',0,'修改',NULL),(8640,337,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:40:06',0,'登录模拟质检主任',327),(8641,336,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:41:21',0,'登录模拟质检员',327),(8642,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:42:34',0,'登录模拟一车间主任',327),(8643,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:46:56',0,'登录jingjing',327),(8644,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:46:56',0,'登录模拟销售经理',327),(8645,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:46:56',0,'登录模拟销售员',327),(8646,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:46:56',0,'登录模拟一车间主任',327),(8647,334,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:46:56',0,'登录模拟二车间主任',327),(8648,336,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:46:57',0,'登录模拟质检员',327),(8649,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:51:41',0,'登录jingjing',327),(8650,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:51:41',0,'登录模拟销售经理',327),(8651,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:51:42',0,'登录模拟销售员',327),(8652,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:51:42',0,'登录模拟一车间主任',327),(8653,334,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:51:42',0,'登录模拟二车间主任',327),(8654,336,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:51:42',0,'登录模拟质检员',327),(8655,336,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:55:36',0,'登录模拟质检员',327),(8656,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:57:10',0,'登录模拟一车间主任',327),(8657,337,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:57:39',0,'登录模拟质检主任',327),(8658,336,'用户','127.0.0.1/127.0.0.1','2026-10-27 09:58:31',0,'登录模拟质检员',327),(8659,337,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:01:21',0,'登录模拟质检主任',327),(8660,336,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:02:56',0,'登录模拟质检员',327),(8661,337,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:03:32',0,'登录模拟质检主任',327),(8662,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:04:14',0,'登录模拟一车间主任',327),(8663,337,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:07:22',0,'登录模拟质检主任',327),(8664,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:11:11',0,'登录jingjing',327),(8665,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:11:11',0,'登录模拟销售经理',327),(8666,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:11:12',0,'登录模拟销售员',327),(8667,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:11:12',0,'登录模拟一车间主任',327),(8668,337,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:11:12',0,'登录模拟质检主任',327),(8669,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:12:33',0,'登录jingjing',327),(8670,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:12:33',0,'登录模拟销售经理',327),(8671,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:12:33',0,'登录模拟销售员',327),(8672,337,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:12:34',0,'登录模拟质检主任',327),(8673,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:15:19',0,'登录模拟一车间主任',327),(8674,337,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:15:54',0,'登录模拟质检主任',327),(8675,336,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:16:27',0,'登录模拟质检员',327),(8676,337,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:17:57',0,'登录模拟质检主任',327),(8677,333,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:18:27',0,'登录模拟一车间主任',327),(8678,334,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:19:31',0,'登录模拟二车间主任',327),(8679,337,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:26:11',0,'登录模拟质检主任',327),(8680,336,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:26:43',0,'登录模拟质检员',327),(8681,337,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:27:22',0,'登录模拟质检主任',327),(8682,334,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:27:54',0,'登录模拟二车间主任',327),(8683,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:30:56',0,'登录jingjing',327),(8684,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:30:56',0,'登录模拟销售经理',327),(8685,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:30:56',0,'登录模拟销售员',327),(8686,334,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:30:56',0,'登录模拟二车间主任',327),(8687,338,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:34:37',0,'登录模拟仓库',327),(8688,338,'单据','127.0.0.1/127.0.0.1','2026-10-27 10:36:23',0,'新增CPRK26[审核]',327),(8689,331,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:37:10',0,'登录模拟审批领导',327),(8690,338,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:37:36',0,'登录模拟仓库',327),(8691,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:40:47',0,'登录jingjing',327),(8692,330,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:40:47',0,'登录模拟销售经理',327),(8693,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:40:47',0,'登录模拟销售员',327),(8694,338,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:40:47',0,'登录模拟仓库',327),(8695,338,'单据','127.0.0.1/127.0.0.1','2026-10-27 10:40:51',0,'新增SIM-RK-SHIP-667-20261027[审核]',327),(8696,329,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:46:48',0,'登录模拟销售员',327),(8697,339,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:50:26',0,'登录模拟财务',327),(8698,338,'用户','127.0.0.1/127.0.0.1','2026-10-27 10:50:51',0,'登录模拟仓库',327),(8699,327,'用户','127.0.0.1/127.0.0.1','2026-10-27 13:14:45',0,'登录jingjing',327),(8700,331,'用户','127.0.0.1/127.0.0.1','2026-10-27 13:59:18',0,'登录模拟审批领导',327),(8701,120,'用户','127.0.0.1/127.0.0.1','2026-10-27 14:18:23',0,'登录admin',0),(8702,120,'关联关系','127.0.0.1/127.0.0.1','2026-10-27 14:19:17',0,'修改角色的按钮权限',NULL);
/*!40000 ALTER TABLE `jsh_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_material`
--

DROP TABLE IF EXISTS `jsh_material`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_material` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `category_id` bigint DEFAULT NULL COMMENT '产品类型id',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '名称',
  `mfrs` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '制造商',
  `model` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '型号',
  `standard` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '规格',
  `brand` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '品牌',
  `mnemonic` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '助记码',
  `color` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '颜色',
  `unit` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '单位-单个',
  `remark` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `img_name` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '图片名称',
  `unit_id` bigint DEFAULT NULL COMMENT '单位Id',
  `expiry_num` int DEFAULT NULL COMMENT '保质期天数',
  `weight` decimal(24,6) DEFAULT NULL COMMENT '基础重量(kg)',
  `enabled` bit(1) DEFAULT NULL COMMENT '启用 0-禁用  1-启用',
  `other_field1` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '自定义1',
  `other_field2` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '自定义2',
  `other_field3` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '自定义3',
  `enable_serial_number` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '是否开启序列号，0否，1是',
  `enable_batch_number` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '是否开启批号，0否，1是',
  `position` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '仓位货架',
  `attribute` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多属性信息',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  `material_kind` varchar(16) NOT NULL DEFAULT 'product' COMMENT 'product=产品,raw=原料',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `FK675951272AB6672C` (`category_id`) USING BTREE,
  KEY `UnitId` (`unit_id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=679 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='产品表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_material`
--

LOCK TABLES `jsh_material` WRITE;
/*!40000 ALTER TABLE `jsh_material` DISABLE KEYS */;
INSERT INTO `jsh_material` VALUES (670,30,'活性氧化铝小包装干燥剂（模拟）',NULL,'10 g/袋（模拟选择）','Φ0.5～2 mm','SIM-AL-01（模拟）',NULL,NULL,'吨','【模拟测试】名称、粒度和四项成品指标参考用户提供产品介绍；10g/袋为本轮模拟选择；基本单位吨，袋数暂不自动换算。自产成品零期初库存，后续生产入库；原料及工艺未知，不代表真实配方。介绍所列标准Q/WYL 01-2020。','',NULL,NULL,NULL,0x01,NULL,NULL,NULL,'0','1',NULL,'{}',327,'0','product'),(671,31,'模拟原料A',NULL,'模拟型号','模拟原料规格','',NULL,NULL,'吨','【模拟测试】占位原料，不代表活性氧化铝真实配方。入库及领料数量仅用于验证系统，不推导真实耗用、成本或产出率。',NULL,NULL,NULL,NULL,0x01,NULL,NULL,NULL,'0','1',NULL,'{}',327,'0','raw'),(672,NULL,'KIND-TEST-9322e3c8d6-product',NULL,'测试型号','测试规格','模拟',NULL,NULL,'吨','临时类型隔离检查，结束后删除',NULL,NULL,NULL,NULL,0x01,NULL,NULL,NULL,'0','1',NULL,'{}',327,'1','product'),(673,NULL,'KIND-TEST-9322e3c8d6-raw',NULL,'测试型号','测试规格','模拟',NULL,NULL,'吨','临时类型隔离检查，结束后删除',NULL,NULL,NULL,NULL,0x01,NULL,NULL,NULL,'0','1',NULL,'{}',327,'1','raw'),(674,NULL,'PM-TEST-03ee50bd-0',NULL,'测试型号','测试规格','模拟',NULL,NULL,'吨',NULL,NULL,NULL,NULL,NULL,0x01,NULL,NULL,NULL,'0','1',NULL,'{}',327,'1','product'),(675,NULL,'PM-TEST-03ee50bd-1',NULL,'测试型号','测试规格','模拟',NULL,NULL,'吨',NULL,NULL,NULL,NULL,NULL,0x01,NULL,NULL,NULL,'0','1',NULL,'{}',327,'1','raw'),(676,NULL,'PM-TEST-03ee50bd-2',NULL,'测试型号','测试规格','模拟',NULL,NULL,'吨',NULL,NULL,NULL,NULL,NULL,0x01,NULL,NULL,NULL,'0','1',NULL,'{}',327,'1','raw'),(677,NULL,'SELF-REVIEW-fdaee0d1',NULL,'模拟型号','审核回归规格','模拟牌号',NULL,NULL,'吨',NULL,NULL,NULL,NULL,NULL,0x01,NULL,NULL,NULL,'0','1',NULL,'{}',327,'1','product'),(678,NULL,'PROD-REVERSE-c02a42ae',NULL,'测试','回归规格','模拟牌号',NULL,NULL,'吨',NULL,NULL,NULL,NULL,NULL,0x01,NULL,NULL,NULL,'0','1',NULL,'{}',327,'1','product');
/*!40000 ALTER TABLE `jsh_material` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_material_attribute`
--

DROP TABLE IF EXISTS `jsh_material_attribute`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_material_attribute` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `attribute_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '属性名',
  `attribute_value` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '属性值',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='产品属性表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_material_attribute`
--

LOCK TABLES `jsh_material_attribute` WRITE;
/*!40000 ALTER TABLE `jsh_material_attribute` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_material_attribute` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_material_category`
--

DROP TABLE IF EXISTS `jsh_material_category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_material_category` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '名称',
  `category_level` smallint DEFAULT NULL COMMENT '等级',
  `parent_id` bigint DEFAULT NULL COMMENT '上级id',
  `sort` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '显示顺序',
  `serial_no` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '编号',
  `remark` varchar(1024) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `FK3EE7F725237A77D8` (`parent_id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='产品类型表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_material_category`
--

LOCK TABLES `jsh_material_category` WRITE;
/*!40000 ALTER TABLE `jsh_material_category` DISABLE KEYS */;
INSERT INTO `jsh_material_category` VALUES (29,'模拟自产成品',1,0,'1','SIM-FG','模拟流程验证资料，不代表真实生产分类','2026-10-26 16:03:37','2026-10-26 16:03:37',327,'0'),(30,'模拟干燥剂',2,29,'2','SIM-FG-DES','模拟流程验证资料，不代表真实生产分类','2026-10-26 16:03:38','2026-10-26 16:03:38',327,'0'),(31,'模拟原料',1,0,'1','SIM-RAW','模拟流程验证资料，不代表真实生产分类','2026-10-26 16:03:40','2026-10-26 16:03:40',327,'0');
/*!40000 ALTER TABLE `jsh_material_category` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_material_current_stock`
--

DROP TABLE IF EXISTS `jsh_material_current_stock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_material_current_stock` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `material_id` bigint DEFAULT NULL COMMENT '产品id',
  `depot_id` bigint DEFAULT NULL COMMENT '仓库id',
  `current_number` decimal(24,6) DEFAULT NULL COMMENT '当前库存数量',
  `current_unit_price` decimal(24,6) DEFAULT NULL COMMENT '当前单价',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `material_id` (`material_id`) USING BTREE,
  KEY `depot_id` (`depot_id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=86 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT COMMENT='产品当前库存';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_material_current_stock`
--

LOCK TABLES `jsh_material_current_stock` WRITE;
/*!40000 ALTER TABLE `jsh_material_current_stock` DISABLE KEYS */;
INSERT INTO `jsh_material_current_stock` VALUES (83,671,19,0.000000,0.000000,327,'0'),(84,670,20,25.000000,0.000000,327,'0'),(85,670,19,0.000000,0.000000,327,'0');
/*!40000 ALTER TABLE `jsh_material_current_stock` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_material_extend`
--

DROP TABLE IF EXISTS `jsh_material_extend`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_material_extend` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `material_id` bigint DEFAULT NULL COMMENT '商品id',
  `bar_code` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '商品条码',
  `commodity_unit` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '商品单位',
  `sku` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多属性',
  `purchase_decimal` decimal(24,6) DEFAULT NULL COMMENT '采购价格',
  `commodity_decimal` decimal(24,6) DEFAULT NULL COMMENT '零售价格',
  `wholesale_decimal` decimal(24,6) DEFAULT NULL COMMENT '销售价格',
  `low_decimal` decimal(24,6) DEFAULT NULL COMMENT '最低售价',
  `default_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '1' COMMENT '是否为默认单位，1是，0否',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `create_serial` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人编码',
  `update_serial` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人编码',
  `update_time` bigint DEFAULT NULL COMMENT '更新时间戳',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_Flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `material_id` (`material_id`) USING BTREE,
  KEY `bar_code` (`bar_code`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT COMMENT='产品价格扩展';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_material_extend`
--

LOCK TABLES `jsh_material_extend` WRITE;
/*!40000 ALTER TABLE `jsh_material_extend` DISABLE KEYS */;
INSERT INTO `jsh_material_extend` VALUES (91,670,'ALD-MOCK-052-10G','吨','',NULL,NULL,NULL,NULL,'1','2026-10-26 16:05:10','jingjing','模拟仓库',1793068850873,327,'0'),(92,671,'RAW-MOCK-A','吨',NULL,NULL,NULL,NULL,NULL,'1','2026-10-26 16:05:12','jingjing','模拟仓库',1793064473509,327,'0'),(93,672,'KIND-TEST-9322e3c8d6-product','吨',NULL,NULL,NULL,NULL,NULL,'1','2026-10-26 16:33:40','jingjing','jingjing',1793003620026,327,'1'),(94,673,'KIND-TEST-9322e3c8d6-raw','吨',NULL,NULL,NULL,NULL,NULL,'1','2026-10-26 16:33:45','jingjing','jingjing',1793003625513,327,'1'),(95,674,'PM-TEST-03ee50bd-0','吨',NULL,NULL,NULL,NULL,NULL,'1','2026-10-26 16:55:15','jingjing','jingjing',1793004914851,327,'1'),(96,675,'PM-TEST-03ee50bd-1','吨',NULL,NULL,NULL,NULL,NULL,'1','2026-10-26 16:55:17','jingjing','jingjing',1793004917699,327,'1'),(97,676,'PM-TEST-03ee50bd-2','吨',NULL,NULL,NULL,NULL,NULL,'1','2026-10-26 16:55:20','jingjing','jingjing',1793004920452,327,'1'),(98,677,'SELF-REVIEW-fdaee0d1','吨',NULL,NULL,NULL,NULL,NULL,'1','2026-10-27 08:32:31','jingjing','模拟销售员',1793061174537,327,'1'),(99,678,'PROD-REVERSE-c02a42ae','吨',NULL,NULL,NULL,NULL,NULL,'1','2026-10-27 08:54:32','jingjing','模拟销售经理',1793062478779,327,'1');
/*!40000 ALTER TABLE `jsh_material_extend` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_material_initial_stock`
--

DROP TABLE IF EXISTS `jsh_material_initial_stock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_material_initial_stock` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `material_id` bigint DEFAULT NULL COMMENT '产品id',
  `depot_id` bigint DEFAULT NULL COMMENT '仓库id',
  `number` decimal(24,6) DEFAULT NULL COMMENT '初始库存数量',
  `low_safe_stock` decimal(24,6) DEFAULT NULL COMMENT '最低库存数量',
  `high_safe_stock` decimal(24,6) DEFAULT NULL COMMENT '最高库存数量',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `material_id` (`material_id`) USING BTREE,
  KEY `depot_id` (`depot_id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=207 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT COMMENT='产品初始库存';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_material_initial_stock`
--

LOCK TABLES `jsh_material_initial_stock` WRITE;
/*!40000 ALTER TABLE `jsh_material_initial_stock` DISABLE KEYS */;
INSERT INTO `jsh_material_initial_stock` VALUES (205,670,20,0.000000,NULL,NULL,327,'0'),(206,670,19,0.000000,NULL,NULL,327,'0');
/*!40000 ALTER TABLE `jsh_material_initial_stock` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_material_property`
--

DROP TABLE IF EXISTS `jsh_material_property`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_material_property` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `native_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '原始名称',
  `enabled` bit(1) DEFAULT NULL COMMENT '是否启用',
  `sort` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '排序',
  `another_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '别名',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='产品扩展字段表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_material_property`
--

LOCK TABLES `jsh_material_property` WRITE;
/*!40000 ALTER TABLE `jsh_material_property` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_material_property` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_msg`
--

DROP TABLE IF EXISTS `jsh_msg`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_msg` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `msg_title` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '消息标题',
  `msg_content` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '消息内容',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '消息类型',
  `user_id` bigint DEFAULT NULL COMMENT '接收人id',
  `status` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '状态，1未读 2已读',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_Flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT COMMENT='消息表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_msg`
--

LOCK TABLES `jsh_msg` WRITE;
/*!40000 ALTER TABLE `jsh_msg` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_msg` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_orga_user_rel`
--

DROP TABLE IF EXISTS `jsh_orga_user_rel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_orga_user_rel` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `orga_id` bigint DEFAULT NULL COMMENT '部门id',
  `user_id` bigint NOT NULL COMMENT '用户id',
  `user_blng_orga_dspl_seq` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户在所属部门中显示顺序',
  `delete_flag` char(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `creator` bigint DEFAULT NULL COMMENT '创建人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `updater` bigint DEFAULT NULL COMMENT '更新人',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `orga_id` (`orga_id`) USING BTREE,
  KEY `user_id` (`user_id`) USING BTREE,
  KEY `creator` (`creator`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='部门用户关系表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_orga_user_rel`
--

LOCK TABLES `jsh_orga_user_rel` WRITE;
/*!40000 ALTER TABLE `jsh_orga_user_rel` DISABLE KEYS */;
INSERT INTO `jsh_orga_user_rel` VALUES (17,NULL,329,NULL,'0','2026-10-26 15:26:18',327,'2026-10-26 15:26:18',327,327),(18,NULL,330,NULL,'0','2026-10-26 15:26:23',327,'2026-10-26 15:26:23',327,327),(19,NULL,331,NULL,'0','2026-10-26 15:26:27',327,'2026-10-26 15:26:27',327,327),(20,NULL,332,NULL,'0','2026-10-26 15:26:32',327,'2026-10-26 15:26:32',327,327),(21,NULL,333,NULL,'0','2026-10-26 15:26:36',327,'2026-10-26 15:26:36',327,327),(22,NULL,334,NULL,'0','2026-10-26 15:26:38',327,'2026-10-26 15:26:38',327,327),(23,NULL,335,NULL,'0','2026-10-26 15:26:39',327,'2026-10-26 15:26:39',327,327),(24,NULL,336,NULL,'0','2026-10-26 15:26:44',327,'2026-10-26 15:26:44',327,327),(25,NULL,337,NULL,'0','2026-10-26 15:26:48',327,'2026-10-26 15:26:48',327,327),(26,NULL,338,NULL,'0','2026-10-26 15:26:53',327,'2026-10-26 15:26:53',327,327),(27,NULL,339,NULL,'0','2026-10-26 15:26:58',327,'2026-10-26 15:26:58',327,327),(28,NULL,340,NULL,'0','2026-10-26 16:55:46',327,'2026-10-26 16:55:46',327,327);
/*!40000 ALTER TABLE `jsh_orga_user_rel` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_organization`
--

DROP TABLE IF EXISTS `jsh_organization`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_organization` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `org_no` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门编号',
  `org_abr` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门简称',
  `parent_id` bigint DEFAULT NULL COMMENT '父部门id',
  `sort` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门显示顺序',
  `remark` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='部门表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_organization`
--

LOCK TABLES `jsh_organization` WRITE;
/*!40000 ALTER TABLE `jsh_organization` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_organization` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_person`
--

DROP TABLE IF EXISTS `jsh_person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_person` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型',
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '姓名',
  `enabled` bit(1) DEFAULT NULL COMMENT '启用',
  `sort` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '排序',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='经手人表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_person`
--

LOCK TABLES `jsh_person` WRITE;
/*!40000 ALTER TABLE `jsh_person` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_person` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_platform_config`
--

DROP TABLE IF EXISTS `jsh_platform_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_platform_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `platform_key` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关键词',
  `platform_key_info` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关键词名称',
  `platform_value` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '值',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='平台参数';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_platform_config`
--

LOCK TABLES `jsh_platform_config` WRITE;
/*!40000 ALTER TABLE `jsh_platform_config` DISABLE KEYS */;
INSERT INTO `jsh_platform_config` VALUES (1,'platform_name','平台名称','晶晶新'),(2,'activation_code','激活码',''),(3,'platform_url','官方网站','http://www.gyjerp.com/'),(4,'bill_print_flag','三联打印启用标记','0'),(5,'bill_print_url','三联打印地址',''),(6,'pay_fee_url','租户续费地址',''),(7,'register_flag','注册启用标记','1'),(8,'app_activation_code','手机端激活码',''),(9,'send_workflow_url','发起流程地址',''),(10,'weixinUrl','微信url',''),(11,'weixinAppid','微信appid',''),(12,'weixinSecret','微信secret',''),(13,'aliOss_endpoint','阿里OSS-endpoint',''),(14,'aliOss_accessKeyId','阿里OSS-accessKeyId',''),(15,'aliOss_accessKeySecret','阿里OSS-accessKeySecret',''),(16,'aliOss_bucketName','阿里OSS-bucketName',''),(17,'aliOss_linkUrl','阿里OSS-linkUrl',''),(18,'bill_excel_url','单据Excel地址',''),(19,'email_from','邮件发送端-发件人',''),(20,'email_auth_code','邮件发送端-授权码',''),(21,'email_smtp_host','邮件发送端-SMTP服务器',''),(22,'checkcode_flag','验证码启用标记','1'),(23,'app_version','手机端版本','');
/*!40000 ALTER TABLE `jsh_platform_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_role`
--

DROP TABLE IF EXISTS `jsh_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_role` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '名称',
  `type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型',
  `price_limit` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '价格屏蔽 1-屏蔽采购价 2-屏蔽零售价 3-屏蔽销售价',
  `value` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '值',
  `description` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `enabled` bit(1) DEFAULT NULL COMMENT '启用',
  `sort` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '排序',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=105 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='角色表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_role`
--

LOCK TABLES `jsh_role` WRITE;
/*!40000 ALTER TABLE `jsh_role` DISABLE KEYS */;
INSERT INTO `jsh_role` VALUES (4,'管理员','全部数据',NULL,NULL,NULL,0x01,NULL,NULL,'0'),(10,'租户','全部数据',NULL,NULL,'',0x01,NULL,NULL,'0'),(92,'销售员','个人数据','1,2,7',NULL,NULL,0x01,NULL,327,'1'),(93,'审批领导','全部数据',NULL,NULL,NULL,0x01,NULL,327,'1'),(94,'销售经理','全部数据','1,2,7',NULL,'销售订单审核、交期协调、销售进度跟踪',0x01,'2',327,'1'),(95,'销售员','个人数据','1,2,4,5,7',NULL,'模拟流程测试岗位：销售员',0x01,'1',327,'0'),(96,'销售经理','全部数据','1,2,4,5,7',NULL,'模拟流程测试岗位：销售经理',0x01,'2',327,'0'),(97,'审批领导','全部数据','',NULL,'模拟流程测试岗位：审批领导',0x01,'3',327,'0'),(98,'生产统筹','全部数据','1,2,3,4,5,6,7',NULL,'模拟流程测试岗位：生产统筹',0x01,'4',327,'0'),(99,'车间主任','全部数据','1,2,3,4,5,6,7',NULL,'模拟流程测试岗位：车间主任',0x01,'5',327,'0'),(100,'质检员','全部数据','1,2,3,4,5,6,7',NULL,'模拟流程测试岗位：质检员',0x01,'6',327,'0'),(101,'质检主任','全部数据','1,2,3,4,5,6,7',NULL,'模拟流程测试岗位：质检主任',0x01,'7',327,'0'),(102,'仓库管理员','全部数据','1,2,3,4,5,6,7',NULL,'模拟流程测试岗位：仓库管理员',0x01,'8',327,'0'),(103,'财务人员','全部数据','',NULL,'模拟流程测试岗位：财务人员',0x01,'9',327,'0'),(104,'PM-TEST-03ee50bd','全部数据','',NULL,'临时用料只读权限检查',0x01,NULL,327,'1');
/*!40000 ALTER TABLE `jsh_role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_sequence`
--

DROP TABLE IF EXISTS `jsh_sequence`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_sequence` (
  `seq_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '序列名称',
  `min_value` bigint NOT NULL COMMENT '最小值',
  `max_value` bigint NOT NULL COMMENT '最大值',
  `current_val` bigint NOT NULL COMMENT '当前值',
  `increment_val` int NOT NULL DEFAULT '1' COMMENT '增长步数',
  `remark` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`seq_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='单据编号表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_sequence`
--

LOCK TABLES `jsh_sequence` WRITE;
/*!40000 ALTER TABLE `jsh_sequence` DISABLE KEYS */;
INSERT INTO `jsh_sequence` VALUES ('depot_number_seq',1,999999999999999999,683,1,'单据编号sequence');
/*!40000 ALTER TABLE `jsh_sequence` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_serial_number`
--

DROP TABLE IF EXISTS `jsh_serial_number`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_serial_number` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `material_id` bigint DEFAULT NULL COMMENT '产品表id',
  `depot_id` bigint DEFAULT NULL COMMENT '仓库id',
  `serial_number` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '序列号',
  `is_sell` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '是否卖出，0未卖出，1卖出',
  `in_price` decimal(24,6) DEFAULT NULL COMMENT '入库单价',
  `remark` varchar(1024) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `creator` bigint DEFAULT NULL COMMENT '创建人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `updater` bigint DEFAULT NULL COMMENT '更新人',
  `in_bill_no` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '入库单号',
  `out_bill_no` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '出库单号',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `material_id` (`material_id`) USING BTREE,
  KEY `depot_id` (`depot_id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=110 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='序列号表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_serial_number`
--

LOCK TABLES `jsh_serial_number` WRITE;
/*!40000 ALTER TABLE `jsh_serial_number` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_serial_number` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_supplier`
--

DROP TABLE IF EXISTS `jsh_supplier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_supplier` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `supplier` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '供应商名称',
  `contacts` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '联系人',
  `phone_num` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '联系电话',
  `email` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '电子邮箱',
  `description` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `isystem` tinyint DEFAULT NULL COMMENT '是否系统自带 0==系统 1==非系统',
  `type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型',
  `enabled` bit(1) DEFAULT NULL COMMENT '启用',
  `advance_in` decimal(24,6) DEFAULT '0.000000' COMMENT '预收款',
  `begin_need_get` decimal(24,6) DEFAULT NULL COMMENT '期初应收',
  `begin_need_pay` decimal(24,6) DEFAULT NULL COMMENT '期初应付',
  `all_need_get` decimal(24,6) DEFAULT NULL COMMENT '累计应收',
  `all_need_pay` decimal(24,6) DEFAULT NULL COMMENT '累计应付',
  `fax` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '传真',
  `telephone` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '手机',
  `address` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '地址',
  `tax_num` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '纳税人识别号',
  `bank_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '开户行',
  `account_number` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '账号',
  `tax_rate` decimal(24,6) DEFAULT NULL COMMENT '税率',
  `sort` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '排序',
  `creator` bigint DEFAULT NULL COMMENT '操作员',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `type` (`type`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=94 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='供应商/客户信息表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_supplier`
--

LOCK TABLES `jsh_supplier` WRITE;
/*!40000 ALTER TABLE `jsh_supplier` DISABLE KEYS */;
INSERT INTO `jsh_supplier` VALUES (91,'昆山韩林环保设备有限公司',NULL,NULL,NULL,NULL,NULL,'客户',0x01,0.000000,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,327,327,'0'),(92,'SELF-REVIEW-fdaee0d1',NULL,NULL,NULL,NULL,NULL,'客户',0x01,0.000000,0.000000,0.000000,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,327,327,'1'),(93,'PROD-REVERSE-c02a42ae',NULL,NULL,NULL,NULL,NULL,'客户',0x01,0.000000,0.000000,0.000000,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,327,327,'1');
/*!40000 ALTER TABLE `jsh_supplier` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_sys_dict_data`
--

DROP TABLE IF EXISTS `jsh_sys_dict_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_sys_dict_data` (
  `dict_code` bigint NOT NULL AUTO_INCREMENT COMMENT '字典编码',
  `dict_sort` int DEFAULT '0' COMMENT '字典排序',
  `dict_label` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '字典标签',
  `dict_value` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '字典键值',
  `dict_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '字典类型',
  `css_class` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '样式属性（其他样式扩展）',
  `list_class` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '表格回显样式',
  `is_default` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'N' COMMENT '是否默认（Y是 N否）',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '0' COMMENT '状态（0正常 1停用）',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`dict_code`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=778 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='字典数据表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_sys_dict_data`
--

LOCK TABLES `jsh_sys_dict_data` WRITE;
/*!40000 ALTER TABLE `jsh_sys_dict_data` DISABLE KEYS */;
INSERT INTO `jsh_sys_dict_data` VALUES (1,1,'男','0','sys_user_sex','','default','Y','0','admin','2021-12-15 21:36:18','admin','2026-04-04 22:38:19','性别男','0'),(2,2,'女','1','sys_user_sex','','default','N','0','admin','2021-12-15 21:36:18','admin','2026-04-04 22:38:27','性别女','0'),(11,1,'正常','0','sys_normal_disable',NULL,'green','N','0','admin','2026-04-03 22:31:34','admin','2026-04-04 22:35:39','正常状态','0'),(12,2,'停用','1','sys_normal_disable',NULL,'red','N','0','admin','2026-04-03 22:32:03','admin','2026-04-04 21:38:10','停用状态','0');
/*!40000 ALTER TABLE `jsh_sys_dict_data` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_sys_dict_type`
--

DROP TABLE IF EXISTS `jsh_sys_dict_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_sys_dict_type` (
  `dict_id` bigint NOT NULL AUTO_INCREMENT COMMENT '字典主键',
  `dict_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '字典名称',
  `dict_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '字典类型',
  `status` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '0' COMMENT '状态（0正常 1停用）',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '创建者',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '' COMMENT '更新者',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `remark` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`dict_id`) USING BTREE,
  UNIQUE KEY `dict_type` (`dict_type`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=207 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='字典类型表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_sys_dict_type`
--

LOCK TABLES `jsh_sys_dict_type` WRITE;
/*!40000 ALTER TABLE `jsh_sys_dict_type` DISABLE KEYS */;
INSERT INTO `jsh_sys_dict_type` VALUES (1,'用户性别','sys_user_sex','0','admin','2021-12-15 21:36:18','admin','2026-04-02 16:20:41','用户性别列表','0'),(12,'系统开关','sys_normal_disable','0','admin','2026-04-03 22:30:57','admin','2026-04-04 21:41:09','系统开关列表','0');
/*!40000 ALTER TABLE `jsh_sys_dict_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_system_config`
--

DROP TABLE IF EXISTS `jsh_system_config`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_system_config` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `company_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '公司名称',
  `company_contacts` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '公司联系人',
  `company_address` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '公司地址',
  `company_tel` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '公司电话',
  `company_fax` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '公司传真',
  `company_post_code` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '公司邮编',
  `sale_agreement` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '销售协议',
  `depot_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '仓库启用标记，0未启用，1启用',
  `customer_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '客户启用标记，0未启用，1启用',
  `minus_stock_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '负库存启用标记，0未启用，1启用',
  `purchase_by_sale_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '以销定购启用标记，0未启用，1启用',
  `multi_level_approval_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '多级审核启用标记，0未启用，1启用',
  `multi_bill_type` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '流程类型，可多选',
  `force_approval_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '强审核启用标记，0未启用，1启用',
  `update_unit_price_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '1' COMMENT '更新单价启用标记，0未启用，1启用',
  `over_link_bill_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '超出关联单据启用标记，0未启用，1启用',
  `in_out_manage_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '出入库管理启用标记，0未启用，1启用',
  `multi_account_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '多账户启用标记，0未启用，1启用',
  `move_avg_price_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '移动平均价启用标记，0未启用，1启用',
  `audit_print_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '先审核后打印启用标记，0未启用，1启用',
  `zero_change_amount_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '零收付款启用标记，0未启用，1启用',
  `customer_static_price_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '客户静态单价启用标记，0未启用，1启用',
  `material_price_tax_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '商品价格含税启用标记，0未启用，1启用',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=COMPACT COMMENT='系统参数';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_system_config`
--

LOCK TABLES `jsh_system_config` WRITE;
/*!40000 ALTER TABLE `jsh_system_config` DISABLE KEYS */;
INSERT INTO `jsh_system_config` VALUES (12,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'1','0','0','0','0',NULL,'0','1','0','0','0','0','0','0','0','0',327,'0');
/*!40000 ALTER TABLE `jsh_system_config` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_tenant`
--

DROP TABLE IF EXISTS `jsh_tenant`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_tenant` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `tenant_id` bigint DEFAULT NULL COMMENT '用户id',
  `login_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '登录名',
  `user_num_limit` int DEFAULT NULL COMMENT '用户数量限制',
  `type` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '租户类型，0免费租户，1付费租户',
  `enabled` bit(1) DEFAULT b'1' COMMENT '启用 0-禁用  1-启用',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `expire_time` datetime DEFAULT NULL COMMENT '到期时间',
  `remark` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `create_time` (`create_time`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='租户';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_tenant`
--

LOCK TABLES `jsh_tenant` WRITE;
/*!40000 ALTER TABLE `jsh_tenant` DISABLE KEYS */;
INSERT INTO `jsh_tenant` VALUES (15,327,'jingjing',1000000,'1',0x01,'2026-10-26 13:20:09','2099-12-31 13:36:52',NULL,'0');
/*!40000 ALTER TABLE `jsh_tenant` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_unit`
--

DROP TABLE IF EXISTS `jsh_unit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_unit` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '名称，支持多单位',
  `basic_unit` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '基础单位',
  `other_unit` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '副单位',
  `other_unit_two` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '副单位2',
  `other_unit_three` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '副单位3',
  `ratio` decimal(24,3) DEFAULT NULL COMMENT '比例',
  `ratio_two` decimal(24,3) DEFAULT NULL COMMENT '比例2',
  `ratio_three` decimal(24,3) DEFAULT NULL COMMENT '比例3',
  `enabled` bit(1) DEFAULT NULL COMMENT '启用',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='多单位表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_unit`
--

LOCK TABLES `jsh_unit` WRITE;
/*!40000 ALTER TABLE `jsh_unit` DISABLE KEYS */;
/*!40000 ALTER TABLE `jsh_unit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_user`
--

DROP TABLE IF EXISTS `jsh_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '用户姓名--例如张三',
  `login_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '登录用户名',
  `password` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '登陆密码',
  `leader_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '是否经理，0否，1是',
  `position` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '职位',
  `department` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '所属部门',
  `email` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '电子邮箱',
  `phonenum` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '手机号码',
  `ismanager` tinyint NOT NULL DEFAULT '1' COMMENT '是否为管理者 0==管理者 1==员工',
  `isystem` tinyint NOT NULL DEFAULT '0' COMMENT '是否系统自带数据 ',
  `status` tinyint DEFAULT '0' COMMENT '状态，0正常，2封禁',
  `description` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户描述信息',
  `remark` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `weixin_open_id` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '微信绑定',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=341 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_user`
--

LOCK TABLES `jsh_user` WRITE;
/*!40000 ALTER TABLE `jsh_user` DISABLE KEYS */;
INSERT INTO `jsh_user` VALUES (120,'管理员','admin','e10adc3949ba59abbe56e057f20f883e','0',NULL,NULL,NULL,NULL,1,0,0,NULL,NULL,NULL,0,'0'),(327,'jingjing','jingjing','e10adc3949ba59abbe56e057f20f883e','0',NULL,NULL,NULL,NULL,1,0,0,NULL,NULL,NULL,327,'0'),(328,'模拟销售员','模拟销售员','e10adc3949ba59abbe56e057f20f883e','0','销售员',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'1'),(329,'模拟销售员','模拟销售员','3f555208306a9305facbce482a1fcaf8','0','销售员',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'0'),(330,'模拟销售经理','模拟销售经理','3f555208306a9305facbce482a1fcaf8','0','销售经理',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'0'),(331,'模拟审批领导','模拟审批领导','3f555208306a9305facbce482a1fcaf8','0','审批领导',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'0'),(332,'模拟生产统筹','模拟生产统筹','3f555208306a9305facbce482a1fcaf8','0','生产统筹',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'0'),(333,'模拟一车间主任','模拟一车间主任','3f555208306a9305facbce482a1fcaf8','0','车间主任',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'0'),(334,'模拟二车间主任','模拟二车间主任','3f555208306a9305facbce482a1fcaf8','0','车间主任',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'0'),(335,'模拟三车间主任','模拟三车间主任','3f555208306a9305facbce482a1fcaf8','0','车间主任',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'0'),(336,'模拟质检员','模拟质检员','3f555208306a9305facbce482a1fcaf8','0','质检员',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'0'),(337,'模拟质检主任','模拟质检主任','3f555208306a9305facbce482a1fcaf8','0','质检主任',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'0'),(338,'模拟仓库','模拟仓库','3f555208306a9305facbce482a1fcaf8','0','仓库管理员',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'0'),(339,'模拟财务','模拟财务','3f555208306a9305facbce482a1fcaf8','0','财务人员',NULL,NULL,NULL,1,0,0,'人工模拟流程测试账号',NULL,NULL,327,'0'),(340,'PM-TEST-03ee50bd','PM-TEST-03ee50bd','3f555208306a9305facbce482a1fcaf8','0',NULL,NULL,NULL,NULL,1,0,0,NULL,NULL,NULL,327,'1');
/*!40000 ALTER TABLE `jsh_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jsh_user_business`
--

DROP TABLE IF EXISTS `jsh_user_business`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jsh_user_business` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类别',
  `key_id` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主id',
  `value` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '值',
  `btn_str` varchar(20000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮权限',
  `tenant_id` bigint DEFAULT NULL COMMENT '租户id',
  `delete_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '删除标记，0未删除，1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `type` (`type`) USING BTREE,
  KEY `key_id` (`key_id`) USING BTREE,
  KEY `tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=370 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户/角色/模块关系表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jsh_user_business`
--

LOCK TABLES `jsh_user_business` WRITE;
/*!40000 ALTER TABLE `jsh_user_business` DISABLE KEYS */;
INSERT INTO `jsh_user_business` VALUES (5,'RoleFunctions','4','[210][225][211][261][32][241][33][199][242][38][41][200][201][239][202][40][232][233][197][44][203][204][205][206][212][246][198][207][259][208][209][226][227][248][228][229][59][235][237][244][22][21][23][220][247][25][24][217][218][26][194][195][31][13][14][243][15][236][234][16][18][245][258][260][1][262][263][264][265][266][267][268][38][269][38][270][38][271][272][273][274]','[{\"funId\": 13, \"btnStr\": \"1\"}, {\"funId\": 14, \"btnStr\": \"1\"}, {\"funId\": 243, \"btnStr\": \"1\"}, {\"funId\": 236, \"btnStr\": \"1\"}, {\"funId\": 234, \"btnStr\": \"1\"}, {\"funId\": 16, \"btnStr\": \"1\"}, {\"funId\": 18, \"btnStr\": \"1\"}, {\"funId\": 245, \"btnStr\": \"1\"}, {\"funId\": 22, \"btnStr\": \"1\"}, {\"funId\": 23, \"btnStr\": \"1,3\"}, {\"funId\": 220, \"btnStr\": \"1\"}, {\"funId\": 247, \"btnStr\": \"1\"}, {\"funId\": 25, \"btnStr\": \"1,3\"}, {\"funId\": 217, \"btnStr\": \"1,3\"}, {\"funId\": 218, \"btnStr\": \"1,3\"}, {\"funId\": 26, \"btnStr\": \"1\"}, {\"funId\": 194, \"btnStr\": \"1\"}, {\"funId\": 195, \"btnStr\": \"1\"}, {\"funId\": 31, \"btnStr\": \"1\"}, {\"funId\": 261, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 241, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 33, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 199, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 242, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 41, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 200, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 210, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 211, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 197, \"btnStr\": \"1,7,2,3\"}, {\"funId\": 203, \"btnStr\": \"1,7,2,3\"}, {\"funId\": 204, \"btnStr\": \"1,7,2,3\"}, {\"funId\": 205, \"btnStr\": \"1,7,2,3\"}, {\"funId\": 206, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 212, \"btnStr\": \"1,7,2,3\"}, {\"funId\": 201, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 202, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 40, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 232, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 233, \"btnStr\": \"1,2,7,3\"}, {\"funId\": 274, \"btnStr\": \"1,3\"}]',NULL,'0'),(32,'RoleFunctions','10','[210][225][211][261][32][241][33][199][242][38][41][200][201][239][202][40][232][233][197][44][203][204][205][206][212][246][198][207][259][208][209][226][227][248][228][229][59][235][237][244][22][21][23][220][247][25][24][217][218][26][194][195][31][13][14][243][15][234][236][262][263][264][265][266][267][268][38][269][38][270][38][271][272][273][274]','[{\"funId\":274,\"btnStr\":\"1,3\"},{\"funId\":13,\"btnStr\":\"1\"},{\"funId\":14,\"btnStr\":\"1\"},{\"funId\":243,\"btnStr\":\"1\"},{\"funId\":236,\"btnStr\":\"1\"},{\"funId\":234,\"btnStr\":\"1\"},{\"funId\":22,\"btnStr\":\"1\"},{\"funId\":23,\"btnStr\":\"1,3\"},{\"funId\":220,\"btnStr\":\"1\"},{\"funId\":247,\"btnStr\":\"1\"},{\"funId\":25,\"btnStr\":\"1,3\"},{\"funId\":217,\"btnStr\":\"1,3\"},{\"funId\":26,\"btnStr\":\"1\"},{\"funId\":194,\"btnStr\":\"1\"},{\"funId\":195,\"btnStr\":\"1\"},{\"funId\":31,\"btnStr\":\"1\"},{\"funId\":272,\"btnStr\":\"1\"},{\"funId\":271,\"btnStr\":\"1\"},{\"funId\":261,\"btnStr\":\"1,2,7,3\"},{\"funId\":241,\"btnStr\":\"1,2,7,3\"},{\"funId\":33,\"btnStr\":\"1,2,7,3\"},{\"funId\":199,\"btnStr\":\"1,7,2,3\"},{\"funId\":242,\"btnStr\":\"1,2,7,3\"},{\"funId\":200,\"btnStr\":\"1,2,7,3\"},{\"funId\":197,\"btnStr\":\"1,2,7,3\"},{\"funId\":203,\"btnStr\":\"1,7,2,3\"},{\"funId\":204,\"btnStr\":\"1,7,2,3\"},{\"funId\":205,\"btnStr\":\"1,2,7,3\"},{\"funId\":206,\"btnStr\":\"1,7,2,3\"},{\"funId\":212,\"btnStr\":\"1,2,7,3\"},{\"funId\":201,\"btnStr\":\"1,2,7,3\"},{\"funId\":202,\"btnStr\":\"1,2,7,3\"},{\"funId\":40,\"btnStr\":\"1,2,7,3\"}]',NULL,'0'),(38,'UserRole','120','[4]',NULL,NULL,'0'),(336,'UserRole','327','[10]',NULL,327,'0'),(337,'RoleFunctions','92','[242][38][264][269][270][200][272][271]','[{\"funId\":269,\"btnStr\":\"1\"},{\"funId\":270,\"btnStr\":\"1\"},{\"funId\":242,\"btnStr\":\"1\"},{\"funId\":200,\"btnStr\":\"1\"},{\"funId\":264,\"btnStr\":\"1\"}]',327,'0'),(338,'RoleFunctions','93','[242][38][271][272][264][269][270][200][246]','[{\"funId\": 22, \"btnStr\": \"1\"}, {\"funId\": 23, \"btnStr\": \"1\"}, {\"funId\": 270, \"btnStr\": \"1\"}, {\"funId\": 242, \"btnStr\": \"2\"}, {\"funId\": 200, \"btnStr\": \"2\"}, {\"funId\": 264, \"btnStr\": \"1\"}, {\"funId\": 268, \"btnStr\": \"1\"}, {\"funId\": 274, \"btnStr\": \"1\"}]',327,'0'),(339,'RoleFunctions','95','[38][200][242][263][264][269][270][271][272]','[{\"funId\":242,\"btnStr\":\"1\"},{\"funId\":264,\"btnStr\":\"1\"},{\"funId\":269,\"btnStr\":\"1\"},{\"funId\":270,\"btnStr\":\"1\"},{\"funId\":200,\"btnStr\":\"1\"}]',327,'0'),(340,'RoleFunctions','96','[38][198][200][242][246][263][264][269][270][271][272]','[{\"funId\":242,\"btnStr\":\"2,7\"}]',327,'0'),(341,'RoleFunctions','97','[21][22][23][38][198][200][246][263][264][268][270][271][272][274]','[{\"funId\": 22, \"btnStr\": \"1\"}, {\"funId\": 23, \"btnStr\": \"1\"}, {\"funId\": 264, \"btnStr\": \"1\"}, {\"funId\": 268, \"btnStr\": \"1\"}, {\"funId\": 270, \"btnStr\": \"1\"}, {\"funId\": 200, \"btnStr\": \"2\"}, {\"funId\": 274, \"btnStr\": \"1\"}]',327,'0'),(342,'RoleFunctions','98','[38][198][246][263][264][265][266][267][268][270][271][272]','[{\"funId\":264,\"btnStr\":\"1\"},{\"funId\":270,\"btnStr\":\"1\"}]',327,'0'),(343,'UserRole','329','[95]',NULL,327,'0'),(344,'UserRole','330','[96]',NULL,327,'0'),(345,'UserRole','331','[97]',NULL,327,'0'),(346,'UserRole','332','[98]',NULL,327,'0'),(347,'RoleFunctions','99','[198][246][263][264][265][266][267][268][271][272]','[{\"funId\":264,\"btnStr\":\"1\"},{\"funId\":265,\"btnStr\":\"1\"},{\"funId\":266,\"btnStr\":\"1\"},{\"funId\":267,\"btnStr\":\"1\"},{\"funId\":268,\"btnStr\":\"1\"}]',327,'0'),(348,'UserRole','333','[99]',NULL,327,'0'),(349,'UserRole','334','[99]',NULL,327,'0'),(350,'UserRole','335','[99]',NULL,327,'0'),(351,'RoleFunctions','100','[263][267][268]','[{\"funId\":267,\"btnStr\":\"1\"},{\"funId\":268,\"btnStr\":\"1\"}]',327,'0'),(352,'UserRole','336','[100]',NULL,327,'0'),(353,'RoleFunctions','101','[267][268][273]','[{\"funId\":267,\"btnStr\":\"1\"},{\"funId\":268,\"btnStr\":\"1\"},{\"funId\":273,\"btnStr\":\"1\"}]',327,'0'),(354,'UserRole','337','[101]',NULL,327,'0'),(355,'RoleFunctions','102','[38][198][200][201][239][246][262][263][265][268][269]','[{\"funId\":262,\"btnStr\":\"1\"},{\"funId\":265,\"btnStr\":\"1\"},{\"funId\":268,\"btnStr\":\"1\"},{\"funId\":269,\"btnStr\":\"1\"},{\"funId\":200,\"btnStr\":\"1\"},{\"funId\":201,\"btnStr\":\"1,2\"}]',327,'0'),(356,'UserRole','338','[102]',NULL,327,'0'),(357,'RoleFunctions','103','[38][269]','[{\"funId\":269,\"btnStr\":\"1\"}]',327,'0'),(358,'UserRole','339','[103]',NULL,327,'0'),(359,'UserDepot','327','[19][20]',NULL,327,'0'),(360,'UserDepot','338','[20][19]',NULL,327,'0'),(361,'UserDepot','335','[19]',NULL,327,'0'),(362,'UserDepot','334','[19]',NULL,327,'0'),(363,'UserDepot','333','[19]',NULL,327,'0'),(364,'UserDepot','330','[20][19]',NULL,327,'0'),(365,'UserDepot','331','[20][19]',NULL,327,'0'),(366,'UserDepot','332','[20][19]',NULL,327,'0'),(367,'RoleFunctions','104','[21][23]','[]',327,'0'),(368,'UserRole','340','[104]',NULL,327,'0'),(369,'UserCustomer','327','[91][92][93]',NULL,327,'0');
/*!40000 ALTER TABLE `jsh_user_business` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'jsh_erp'
--

--
-- Dumping routines for database 'jsh_erp'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-28  9:51:22
