-- MySQL dump 10.13  Distrib 5.1.41, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: eAccountManager
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
-- Table structure for table `BACKUP_cachefile_tbl`
--

DROP TABLE IF EXISTS `BACKUP_cachefile_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `BACKUP_cachefile_tbl` (
  `username_col` varchar(14) NOT NULL DEFAULT '',
  `md5cache` varchar(22) NOT NULL DEFAULT '',
  `md5org` varchar(22) NOT NULL DEFAULT '',
  `orgfile_col` text NOT NULL,
  `cachefile_col` text NOT NULL,
  `cachehit_col` int(11) NOT NULL DEFAULT '0',
  `createdate_col` datetime DEFAULT NULL,
  `filesize_col` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`username_col`,`md5cache`),
  KEY `org` (`md5org`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `account_tbl`
--

DROP TABLE IF EXISTS `account_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `account_tbl` (
  `idx_col` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username_col` varchar(32) NOT NULL DEFAULT '',
  `quota_col` int(11) NOT NULL DEFAULT '0',
  `server_col` varchar(16) NOT NULL DEFAULT '',
  `partition_col` varchar(8) NOT NULL DEFAULT '',
  `sharetype_col` int(11) DEFAULT '2',
  `sharepassword_col` varchar(254) DEFAULT NULL,
  PRIMARY KEY (`idx_col`,`username_col`),
  KEY `at_username_idx` (`username_col`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `adduser_tbl`
--

DROP TABLE IF EXISTS `adduser_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `adduser_tbl` (
  `username_col` varchar(32) NOT NULL DEFAULT '',
  `mdate_col` varchar(32) NOT NULL DEFAULT '',
  `flag_col` int(2) DEFAULT '0',
  PRIMARY KEY (`username_col`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `cachefile_tbl`
--

DROP TABLE IF EXISTS `cachefile_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cachefile_tbl` (
  `username_col` varchar(14) NOT NULL DEFAULT '',
  `md5cache` varchar(22) NOT NULL DEFAULT '',
  `md5org` varchar(22) NOT NULL DEFAULT '',
  `orgfile_col` text NOT NULL,
  `cachefile_col` text NOT NULL,
  `cachehit_col` int(11) NOT NULL DEFAULT '0',
  `createdate_col` datetime DEFAULT NULL,
  `filesize_col` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`username_col`,`md5cache`),
  KEY `org` (`md5org`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `command_tbl`
--

DROP TABLE IF EXISTS `command_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `command_tbl` (
  `idx_col` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `state_col` enum('N','R','S','W','F') NOT NULL DEFAULT 'N',
  `cmdtype_col` int(10) unsigned NOT NULL DEFAULT '0',
  `arg_col` varchar(128) NOT NULL DEFAULT '',
  `date_col` date NOT NULL DEFAULT '0000-00-00',
  `description_col` text,
  PRIMARY KEY (`idx_col`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `deleteuser_tbl`
--

DROP TABLE IF EXISTS `deleteuser_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `deleteuser_tbl` (
  `username_col` varchar(32) NOT NULL DEFAULT '',
  `mdate_col` varchar(32) NOT NULL DEFAULT '',
  `flag_col` int(2) DEFAULT '0',
  PRIMARY KEY (`username_col`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `group_tbl`
--

DROP TABLE IF EXISTS `group_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `group_tbl` (
  `idx_col` int(10) unsigned NOT NULL DEFAULT '0',
  `groupname_col` varchar(32) NOT NULL DEFAULT '',
  `quota_col` int(11) NOT NULL DEFAULT '0',
  `server_col` varchar(16) NOT NULL DEFAULT '',
  `partition_col` varchar(8) NOT NULL DEFAULT '',
  PRIMARY KEY (`idx_col`,`groupname_col`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `mount_tbl`
--

DROP TABLE IF EXISTS `mount_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mount_tbl` (
  `idx_col` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `owner_col` varchar(32) NOT NULL DEFAULT '',
  `member_col` varchar(32) NOT NULL DEFAULT '',
  `sharepassword_col` varchar(254) DEFAULT NULL,
  PRIMARY KEY (`owner_col`,`member_col`),
  UNIQUE KEY `idx_col` (`idx_col`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `session_tbl`
--

DROP TABLE IF EXISTS `session_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `session_tbl` (
  `idx_col` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `session_col` varchar(64) NOT NULL DEFAULT '',
  `username_col` varchar(32) NOT NULL DEFAULT '',
  `expire_col` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`idx_col`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `team_tbl`
--

DROP TABLE IF EXISTS `team_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `team_tbl` (
  `idx_col` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `teamid_col` varchar(32) NOT NULL DEFAULT '',
  `teamname_col` varchar(255) DEFAULT '',
  `teamdesc_col` varchar(255) DEFAULT '',
  PRIMARY KEY (`idx_col`,`teamid_col`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `teammount_tbl`
--

DROP TABLE IF EXISTS `teammount_tbl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `teammount_tbl` (
  `idx_col` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `userid_col` varchar(14) NOT NULL DEFAULT '',
  `teamid_col` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`idx_col`),
  KEY `idx_userid` (`userid_col`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;



--
-- Table structure for table `tmpSize`
--

DROP TABLE IF EXISTS `tmpSize`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tmpSize` (
  `UserName` char(255) DEFAULT NULL,
  `TOTAL_USAGE` double(17,0) DEFAULT NULL,
  KEY `UserName` (`UserName`)
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

-- Dump completed on 2011-01-05 10:59:27
