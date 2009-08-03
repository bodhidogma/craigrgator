-- MySQL dump 10.11
--
-- Host: localhost    Database: craigr
-- ------------------------------------------------------
-- Server version	5.0.83

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
-- Current Database: `craigr`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `craigr` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_bin */;

USE `craigr`;

--
-- Table structure for table `cars`
--

DROP TABLE IF EXISTS `cars`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cars` (
  `id` int(11) NOT NULL auto_increment,
  `watch` int(11) NOT NULL default '0' COMMENT 'Interested!',
  `title` varchar(128) collate utf8_bin NOT NULL default '',
  `cdate` datetime NOT NULL,
  `link` varchar(128) collate utf8_bin NOT NULL default '',
  `rawinfo` text collate utf8_bin COMMENT 'raw description',
  `info` text collate utf8_bin,
  `location` varchar(64) collate utf8_bin default '',
  `dealer` varchar(64) collate utf8_bin NOT NULL default '',
  `year` smallint(4) default '0',
  `make` varchar(32) collate utf8_bin default '',
  `model` varchar(32) collate utf8_bin default '',
  `color` varchar(32) collate utf8_bin default '',
  `miles` int(11) default '0',
  `price` int(11) default '0',
  `trans` varchar(32) collate utf8_bin default '' COMMENT 'Transmission',
  `features` text collate utf8_bin,
  `keywords` text collate utf8_bin,
  `ts` timestamp NOT NULL default CURRENT_TIMESTAMP COMMENT 'timestamp',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `link` (`link`)
) ENGINE=MyISAM AUTO_INCREMENT=34 DEFAULT CHARSET=utf8 COLLATE=utf8_bin ROW_FORMAT=DYNAMIC COMMENT='cars and trucks';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-08-03  0:57:58
