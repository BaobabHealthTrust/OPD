-- MySQL dump 10.13  Distrib 5.5.24, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: anc_development
-- ------------------------------------------------------
-- Server version	5.5.24-0ubuntu0.12.04.1

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
-- Table structure for table `location_tag`
--

DROP TABLE IF EXISTS `location_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `location_tag` (
  `location_tag_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `creator` int(11) NOT NULL,
  `date_created` datetime NOT NULL,
  `retired` smallint(6) NOT NULL DEFAULT '0',
  `retired_by` int(11) DEFAULT NULL,
  `date_retired` datetime DEFAULT NULL,
  `retire_reason` varchar(255) DEFAULT NULL,
  `uuid` char(38) NOT NULL,
  PRIMARY KEY (`location_tag_id`),
  UNIQUE KEY `location_tag_uuid_index` (`uuid`),
  KEY `location_tag_creator` (`creator`),
  KEY `location_tag_retired_by` (`retired_by`),
  CONSTRAINT `location_tag_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `location_tag_retired_by` FOREIGN KEY (`retired_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `location_tag`
--

LOCK TABLES `location_tag` WRITE;
/*!40000 ALTER TABLE `location_tag` DISABLE KEYS */;
INSERT INTO `location_tag` VALUES (1,'Workstation Location',NULL,1,'2011-04-27 14:58:31',0,NULL,NULL,NULL,'018a95de-7602-11e2-8692-30f9edafac54'),(2,'Northern TB DOT Sites',NULL,1,'2011-04-27 14:58:31',0,NULL,NULL,NULL,'018a9947-7602-11e2-8692-30f9edafac54'),(3,'Northern TB Registration Centres',NULL,1,'2011-04-27 14:58:31',0,NULL,NULL,NULL,'018a9a53-7602-11e2-8692-30f9edafac54'),(4,'Central TB DOT Sites',NULL,1,'2011-04-27 14:58:31',0,NULL,NULL,NULL,'018a9b41-7602-11e2-8692-30f9edafac54'),(5,'Central TB Registration Centres',NULL,1,'2011-04-27 14:58:31',0,NULL,NULL,NULL,'018a9c1d-7602-11e2-8692-30f9edafac54'),(6,'South TB DOT Sites',NULL,1,'2011-04-27 14:58:31',0,NULL,NULL,NULL,'018a9cf7-7602-11e2-8692-30f9edafac54'),(7,'South TB Registration Centres',NULL,1,'2011-04-27 14:58:31',0,NULL,NULL,NULL,'018a9dce-7602-11e2-8692-30f9edafac54'),(8,'Ward',NULL,1,'2011-04-27 14:58:31',0,NULL,NULL,NULL,'018a9e9a-7602-11e2-8692-30f9edafac54'),(9,'KCH referral section',NULL,1,'2011-04-27 14:58:31',0,NULL,NULL,NULL,'018a9f7d-7602-11e2-8692-30f9edafac54'),(10,'Facility adult sections',NULL,1,'2011-04-27 14:58:31',0,NULL,NULL,NULL,'018aa04c-7602-11e2-8692-30f9edafac54'),(11,'Facility peads sections',NULL,1,'2011-04-27 14:58:31',0,NULL,NULL,NULL,'018aa117-7602-11e2-8692-30f9edafac54');
/*!40000 ALTER TABLE `location_tag` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `location_tag_map`
--

DROP TABLE IF EXISTS `location_tag_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `location_tag_map` (
  `location_id` int(11) NOT NULL,
  `location_tag_id` int(11) NOT NULL,
  PRIMARY KEY (`location_id`,`location_tag_id`),
  KEY `location_tag_map_tag` (`location_tag_id`),
  CONSTRAINT `location_tag_map_location` FOREIGN KEY (`location_id`) REFERENCES `location` (`location_id`),
  CONSTRAINT `location_tag_map_tag` FOREIGN KEY (`location_tag_id`) REFERENCES `location_tag` (`location_tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `location_tag_map`
--

LOCK TABLES `location_tag_map` WRITE;
/*!40000 ALTER TABLE `location_tag_map` DISABLE KEYS */;
INSERT INTO `location_tag_map` VALUES (721,1),(722,1),(723,1),(724,1),(725,1),(726,1),(727,1),(728,1),(729,1),(730,1),(731,1),(732,1),(733,1),(734,1),(737,1),(8,4),(71,4),(80,4),(114,4),(126,4),(127,4),(142,4),(143,4),(196,4),(199,4),(219,4),(223,4),(265,4),(274,4),(293,4),(312,4),(349,4),(352,4),(384,4),(387,4),(414,4),(419,4),(429,4),(463,4),(511,4),(526,4),(531,4),(545,4),(577,4),(677,4),(696,4),(701,4),(703,4),(712,4),(720,4),(736,4),(196,5),(293,5),(419,5),(696,5),(701,5),(703,5),(712,5),(736,5),(738,8),(739,8),(740,8),(741,8),(742,8),(743,8),(744,8),(745,8),(746,8),(747,8),(748,8),(749,8),(750,8),(751,8),(752,8),(753,8),(754,8),(755,8),(738,9),(739,9),(740,9),(741,9),(742,9),(743,9),(744,9),(745,9),(746,9),(747,9),(748,9),(749,9),(750,9),(751,9),(752,9),(753,9),(754,9),(755,9),(738,10),(739,10),(740,10),(741,10),(742,10),(743,10),(744,10),(745,10),(746,10),(747,10),(750,11),(751,11),(752,11),(753,11),(754,11),(755,11);
/*!40000 ALTER TABLE `location_tag_map` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-03-07 15:58:45
