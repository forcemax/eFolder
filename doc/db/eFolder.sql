-- MySQL dump 10.13  Distrib 5.1.41, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: eFolder
-- ------------------------------------------------------
-- Server version	5.1.41-3ubuntu12.8

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `AdultList`
--

DROP TABLE IF EXISTS `AdultList`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `AdultList` (
  `FileKey` varchar(22) NOT NULL DEFAULT '',
  `FileOwner` varchar(12) NOT NULL DEFAULT '',
  `FilePath` text NOT NULL,
  `AdultHit` int(11) DEFAULT '0',
  `LastHitDate` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `HitUserQueue` varchar(254) DEFAULT NULL,
  PRIMARY KEY (`FileKey`),
  KEY `FileOwner` (`FileOwner`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `CONFIG`
--

DROP TABLE IF EXISTS `CONFIG`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `CONFIG` (
  `G_FIELD` varchar(254) DEFAULT NULL,
  `G_VAL` varchar(254) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `FileList`
--

DROP TABLE IF EXISTS `FileList`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `FileList` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `FilePath` text,
  `FileName` varchar(254) DEFAULT NULL,
  `FileSize` int(11) DEFAULT NULL,
  `FileOwner` varchar(14) NOT NULL DEFAULT '',
  `CreateTime` varchar(12) DEFAULT NULL,
  `FileKey` varchar(22) NOT NULL DEFAULT '',
  `Adult` char(1) NOT NULL DEFAULT 'C',
  `updated` smallint(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `Owner_Idx` (`FileOwner`),
  KEY `FileKey_Idx` (`FileKey`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `FileListIndex`
--

DROP TABLE IF EXISTS `FileListIndex`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `FileListIndex` (
  `adult` char(1) NOT NULL DEFAULT '',
  `idx_path` varchar(254) NOT NULL DEFAULT '',
  `id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`adult`,`idx_path`,`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `eFolder_DBServer`
--

DROP TABLE IF EXISTS `eFolder_DBServer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eFolder_DBServer` (
  `mdate` datetime DEFAULT '0000-00-00 00:00:00',
  `mtime` varchar(12) DEFAULT '',
  `Server` varchar(16) NOT NULL DEFAULT '',
  `Marking` varchar(16) DEFAULT 'OFF',
  `Ping` char(2) DEFAULT 'NO',
  `LA` varchar(6) DEFAULT '999.99',
  `PortCheck` char(2) DEFAULT 'NO',
  `Uptime` int(11) DEFAULT '0',
  `Threads` int(11) DEFAULT '99999',
  `Questions` int(11) DEFAULT '0',
  `SlowQuery` int(11) DEFAULT '99999',
  `Opens` int(11) DEFAULT '99999',
  `OpenTable` int(11) DEFAULT '99999',
  `QueryAvg` float DEFAULT '99999',
  `Mysqlnum` int(3) DEFAULT '999',
  PRIMARY KEY (`Server`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `eFolder_Fxx`
--

DROP TABLE IF EXISTS `eFolder_Fxx`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eFolder_Fxx` (
  `mdate` datetime DEFAULT '0000-00-00 00:00:00',
  `mtime` varchar(12) DEFAULT '',
  `Server` varchar(16) NOT NULL DEFAULT '',
  `Marking` varchar(16) DEFAULT 'OFF',
  `Ping` char(2) DEFAULT 'NO',
  `LA` varchar(6) DEFAULT '999.99',
  `Apachenum` varchar(4) DEFAULT '9999',
  `Currentnum` int(5) DEFAULT '99999',
  `lsuser` char(2) DEFAULT 'NO',
  `DBCheck` varchar(64) DEFAULT 'NO-ALL',
  PRIMARY KEY (`Server`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `eFolder_ShareSession`
--

DROP TABLE IF EXISTS `eFolder_ShareSession`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eFolder_ShareSession` (
  `SessionId` int(11) NOT NULL AUTO_INCREMENT,
  `UserId` varchar(255) DEFAULT NULL,
  `Password` varchar(255) DEFAULT NULL,
  `DownFile` varchar(255) DEFAULT NULL,
  `DownLoadCount` int(11) DEFAULT NULL,
  `DownLoadTimeOut` date DEFAULT NULL,
  `DownLoadPassword` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`SessionId`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `eFolder_Storage`
--

DROP TABLE IF EXISTS `eFolder_Storage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eFolder_Storage` (
  `mdate` datetime DEFAULT '0000-00-00 00:00:00',
  `mtime` varchar(12) DEFAULT '',
  `Server` varchar(16) NOT NULL DEFAULT '',
  `Marking` varchar(16) DEFAULT 'OFF',
  `Ping` char(2) DEFAULT 'NO',
  `LA` varchar(6) DEFAULT '999.99',
  `a_stat` varchar(36) DEFAULT 'NO,NO,NO',
  `a_percent` int(3) DEFAULT '100',
  `a_used` int(5) DEFAULT '99999',
  `a_left` int(5) DEFAULT '0',
  `a_volnum` int(11) DEFAULT '99999',
  `b_stat` varchar(36) DEFAULT 'NO,NO,NO',
  `b_percent` int(3) DEFAULT '100',
  `b_used` int(5) DEFAULT '99999',
  `b_left` int(5) DEFAULT '0',
  `b_volnum` int(11) DEFAULT '99999',
  `3ware_chk` varchar(36) DEFAULT 'NO',
  PRIMARY KEY (`Server`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `eFolder_UserSession`
--

DROP TABLE IF EXISTS `eFolder_UserSession`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eFolder_UserSession` (
  `SessionId` int(11) NOT NULL DEFAULT '0',
  `UserID` varchar(16) NOT NULL DEFAULT '',
  `Password` varchar(16) DEFAULT NULL,
  `ClientName` varchar(16) DEFAULT NULL,
  `TimeOut` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `HostAddress` varchar(16) DEFAULT NULL,
  `Authorized` varchar(255) DEFAULT NULL,
  `AdultAuth` char(1) DEFAULT '2',
  PRIMARY KEY (`SessionId`, `ClientName`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8 MAX_ROWS=1000000;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `eFolder_Veto`
--

DROP TABLE IF EXISTS `eFolder_Veto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eFolder_Veto` (
  `Veto` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`Veto`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `log_history`
--

DROP TABLE IF EXISTS `log_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `log_history` (
  `idx` int(11) NOT NULL AUTO_INCREMENT,
  `Server` varchar(100) NOT NULL DEFAULT '',
  `Message` text NOT NULL,
  `LA` varchar(6) DEFAULT '999.99',
  `Date` datetime DEFAULT '0000-00-00 00:00:00',
  `check` char(3) NOT NULL DEFAULT '0',
  PRIMARY KEY (`idx`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `network_group`
--

DROP TABLE IF EXISTS `network_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `network_group` (
  `code` varchar(4) NOT NULL DEFAULT '',
  `name` varchar(12) NOT NULL DEFAULT '',
  PRIMARY KEY (`code`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `server_type`
--

DROP TABLE IF EXISTS `server_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `server_type` (
  `GroupCode` varchar(4) NOT NULL DEFAULT '0',
  `Active` char(3) NOT NULL DEFAULT 'OFF',
  `ServerType` varchar(8) NOT NULL DEFAULT '',
  `Server` varchar(8) NOT NULL DEFAULT '',
  PRIMARY KEY (`ServerType`,`Server`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `test`
--

DROP TABLE IF EXISTS `test`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `test` (
  `expiredate` date DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `userto_tbl`
--

DROP TABLE IF EXISTS `userto_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `userto_tbl` (
  `GroupCode` varchar(4) NOT NULL DEFAULT '',
  `userid` varchar(12) NOT NULL DEFAULT '',
  `up` varchar(12) DEFAULT NULL,
  `down` varchar(12) DEFAULT NULL,
  `folder` varchar(12) DEFAULT NULL,
  PRIMARY KEY (`GroupCode`,`userid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

DROP TABLE IF EXISTS `member`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `member` (
  `number` int(11) NOT NULL AUTO_INCREMENT,
  `id` varchar(14) NOT NULL DEFAULT '',
  `passwd` varchar(50) NOT NULL DEFAULT '',
  `passwd_q` varchar(255) NOT NULL DEFAULT '',
  `passwd_a` varchar(255) NOT NULL DEFAULT '',
  `name` varchar(20) NOT NULL DEFAULT '',
  `reg_num1` varchar(10) NOT NULL DEFAULT '',
  `reg_num2` varchar(7) NOT NULL DEFAULT '',
  `email` varchar(50) NOT NULL DEFAULT '',
  `zip1` char(3) DEFAULT NULL,
  `zip2` char(3) DEFAULT NULL,
  `addr` varchar(255) DEFAULT NULL,
  `tel1` char(3) DEFAULT NULL,
  `tel2` varchar(4) DEFAULT NULL,
  `tel3` varchar(4) DEFAULT NULL,
  `hp1` char(3) DEFAULT NULL,
  `hp2` varchar(4) DEFAULT NULL,
  `hp3` varchar(4) DEFAULT NULL,
  `job` varchar(20) DEFAULT NULL,
  `info` text,
  `mdate` varchar(20) NOT NULL DEFAULT '',
  `coin` double DEFAULT NULL,
  `mileage` double DEFAULT NULL,
  `charge_num` int(12) NOT NULL DEFAULT '0',
  `charge_size` bigint(20) NOT NULL DEFAULT '0',
  `storage` char(1) NOT NULL DEFAULT '0',
  `check` char(3) DEFAULT '0',
  `etc` char(3) DEFAULT '0',
  `sms` varchar(11) DEFAULT '0',
  `adult` varchar(5) DEFAULT '0',
  PRIMARY KEY (`number`),
  UNIQUE KEY `id` (`id`),
  KEY `id_index` (`id`),
  KEY `mb_regnum1_idx` (`reg_num1`),
  KEY `mb_regnum2_idx` (`reg_num2`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;


/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-01-05 10:59:36
