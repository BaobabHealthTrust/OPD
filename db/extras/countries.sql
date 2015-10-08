-- MySQL dump 10.13  Distrib 5.5.38, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: countries
-- ------------------------------------------------------
-- Server version	5.5.38-0ubuntu0.14.04.1

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
-- Table structure for table `dde_country`
--

DROP TABLE IF EXISTS `dde_country`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dde_country` (
  `country_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(125) DEFAULT NULL,
  `weight` int(11) DEFAULT NULL,
  PRIMARY KEY (`country_id`)
) ENGINE=InnoDB AUTO_INCREMENT=196 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dde_country`
--

LOCK TABLES `dde_country` WRITE;
/*!40000 ALTER TABLE `dde_country` DISABLE KEYS */;
INSERT INTO `dde_country` VALUES (1,'Afghanistan',100),(2,'Albania',100),(3,'Algeria',100),(4,'Andorra',100),(5,'Angola',100),(6,'Antigua',100),(7,'Argentina',100),(8,'Armenia',100),(9,'Australia',100),(10,'Austria',100),(11,'Azerbaijan',100),(12,'Bahamas',100),(13,'Bahrain',100),(14,'Bangladesh',100),(15,'Barbados',100),(16,'Belarus',100),(17,'Belgium',100),(18,'Belize',100),(19,'Benin',100),(20,'Bhutan',100),(21,'Bolivia',100),(22,'Bosnia Herzegovina',100),(23,'Botswana',100),(24,'Brazil',100),(25,'Brunei',100),(26,'Bulgaria',100),(27,'Burkina',100),(28,'Burundi',3),(29,'Cambodia',100),(30,'Cameroon',100),(31,'Canada',100),(32,'Cape Verde',100),(33,'Chad',100),(34,'Chile',100),(35,'China',100),(36,'Colombia',100),(37,'Comoros',100),(38,'Congo',100),(39,'Congo',100),(40,'Costa Rica',100),(41,'Croatia',100),(42,'Cuba',100),(43,'Cyprus',100),(44,'Czech Republic',100),(45,'Denmark',100),(46,'Djibouti',100),(47,'Dominica',100),(48,'Dominican Republic',100),(49,'East Timor',100),(50,'Ecuador',100),(51,'Egypt',100),(52,'El Salvador',100),(53,'Equatorial Guinea',100),(54,'Eritrea',100),(55,'Estonia',100),(56,'Ethiopia',100),(57,'Fiji',100),(58,'Finland',100),(59,'France',100),(60,'Gabon',100),(61,'Gambia',100),(62,'Georgia',100),(63,'Germany',100),(64,'Ghana',100),(65,'Greece',100),(66,'Grenada',100),(67,'Guatemala',100),(68,'Guinea',100),(69,'Guinea-Bissau',100),(70,'Guyana',100),(71,'Haiti',100),(72,'Honduras',100),(73,'Hungary',100),(74,'Iceland',100),(75,'India',100),(76,'Indonesia',100),(77,'Iran',100),(78,'Iraq',100),(79,'Ireland',100),(80,'Israel',100),(81,'Italy',100),(82,'Ivory Coast',100),(83,'Jamaica',100),(84,'Japan',100),(85,'Jordan',100),(86,'Kazakhstan',100),(87,'Kenya',100),(88,'Kiribati',100),(89,'Korea North',100),(90,'Korea South',100),(91,'Kosovo',100),(92,'Kuwait',100),(93,'Kyrgyzstan',100),(94,'Laos',100),(95,'Latvia',100),(96,'Lebanon',100),(97,'Lesotho',100),(98,'Liberia',100),(99,'Libya',100),(100,'Liechtenstein',100),(101,'Lithuania',100),(102,'Luxembourg',100),(103,'Macedonia',100),(104,'Madagascar',100),(105,'Malawi',1),(106,'Malaysia',100),(107,'Maldives',100),(108,'Mali',100),(109,'Malta',100),(110,'Marshall Islands',100),(111,'Mauritania',100),(112,'Mauritius',100),(113,'Mexico',100),(114,'Micronesia',100),(115,'Moldova',100),(116,'Monaco',100),(117,'Mongolia',100),(118,'Montenegro',100),(119,'Morocco',100),(120,'Mozambique',2),(121,'Myanmar, {Burma}',100),(122,'Namibia',100),(123,'Nauru',100),(124,'Nepal',100),(125,'Netherlands',100),(126,'New Zealand',100),(127,'Nicaragua',100),(128,'Niger',100),(129,'Nigeria',3),(130,'Norway',100),(131,'Oman',100),(132,'Pakistan',100),(133,'Palau',100),(134,'Panama',100),(135,'Papua New Guinea',100),(136,'Paraguay',100),(137,'Peru',100),(138,'Philippines',100),(139,'Poland',100),(140,'Portugal',100),(141,'Qatar',100),(142,'Romania',100),(143,'Russian Federation',100),(144,'Rwanda',3),(145,'St Kitts & Nevis',100),(146,'St Lucia',100),(147,'Saint Vincent & the Grenadines',100),(148,'Samoa',100),(149,'San Marino',100),(150,'Sao Tome & Principe',100),(151,'Saudi Arabia',100),(152,'Senegal',100),(153,'Serbia',100),(154,'Seychelles',100),(155,'Sierra Leone',100),(156,'Singapore',100),(157,'Slovakia',100),(158,'Slovenia',100),(159,'Solomon Islands',100),(160,'Somalia',100),(161,'South Africa',100),(162,'South Sudan',100),(163,'Spain',100),(164,'Sri Lanka',100),(165,'Sudan',100),(166,'Suriname',100),(167,'Swaziland',100),(168,'Sweden',100),(169,'Switzerland',100),(170,'Syria',100),(171,'Taiwan',100),(172,'Tajikistan',100),(173,'Tanzania',2),(174,'Thailand',100),(175,'Togo',100),(176,'Tonga',100),(177,'Trinidad & Tobago',100),(178,'Tunisia',100),(179,'Turkey',100),(180,'Turkmenistan',100),(181,'Tuvalu',100),(182,'Uganda',100),(183,'Ukraine',100),(184,'United Arab Emirates',100),(185,'United Kingdom',100),(186,'United States',100),(187,'Uruguay',100),(188,'Uzbekistan',100),(189,'Vanuatu',100),(190,'Vatican City',100),(191,'Venezuela',100),(192,'Vietnam',100),(193,'Yemen',100),(194,'Zambia',2),(195,'Zimbabwe',100);
/*!40000 ALTER TABLE `dde_country` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dde_nationality`
--

DROP TABLE IF EXISTS `dde_nationality`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dde_nationality` (
  `nationality_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(125) DEFAULT NULL,
  `weight` int(11) DEFAULT NULL,
  PRIMARY KEY (`nationality_id`)
) ENGINE=InnoDB AUTO_INCREMENT=194 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dde_nationality`
--

LOCK TABLES `dde_nationality` WRITE;
/*!40000 ALTER TABLE `dde_nationality` DISABLE KEYS */;
INSERT INTO `dde_nationality` VALUES (1,'Afghan',100),(2,'Albanian',100),(3,'Algerian',100),(4,'American',100),(5,'Andorran',100),(6,'Angolan',100),(7,'Antiguans',100),(8,'Argentinean',100),(9,'Armenian',100),(10,'Australian',100),(11,'Austrian',100),(12,'Azerbaijani',100),(13,'Bahamian',100),(14,'Bahraini',100),(15,'Bangladeshi',100),(16,'Barbadian',100),(17,'Barbudans',100),(18,'Batswana',100),(19,'Belarusian',100),(20,'Belgian',100),(21,'Belizean',100),(22,'Beninese',100),(23,'Bhutanese',100),(24,'Bolivian',100),(25,'Bosnian',100),(26,'Brazilian',100),(27,'British',100),(28,'Bruneian',100),(29,'Bulgarian',100),(30,'Burkinabe',100),(31,'Burmese',100),(32,'Burundian',3),(33,'Cambodian',100),(34,'Cameroonian',100),(35,'Canadian',100),(36,'Cape Verdean',100),(37,'Central African',100),(38,'Chadian',100),(39,'Chilean',100),(40,'Chinese',100),(41,'Colombian',100),(42,'Comoran',100),(43,'Congolese',100),(44,'Costa Rican',100),(45,'Croatian',100),(46,'Cuban',100),(47,'Cypriot',100),(48,'Czech',100),(49,'Danish',100),(50,'Djibouti',100),(51,'Dominican',100),(52,'Dutch',100),(53,'East Timorese',100),(54,'Ecuadorean',100),(55,'Egyptian',100),(56,'Emirian',100),(57,'Equatorial Guinean',100),(58,'Eritrean',100),(59,'Estonian',100),(60,'Ethiopian',100),(61,'Fijian',100),(62,'Filipino',100),(63,'Finnish',100),(64,'French',100),(65,'Gabonese',100),(66,'Gambian',100),(67,'Georgian',100),(68,'German',100),(69,'Ghanaian',100),(70,'Greek',100),(71,'Grenadian',100),(72,'Guatemalan',100),(73,'Guinea-Bissauan',100),(74,'Guinean',100),(75,'Guyanese',100),(76,'Haitian',100),(77,'Herzegovinian',100),(78,'Honduran',100),(79,'Hungarian',100),(80,'I-Kiribati',100),(81,'Icelander',100),(82,'Indian',100),(83,'Indonesian',100),(84,'Iranian',100),(85,'Iraqi',100),(86,'Irish',100),(87,'Israeli',100),(88,'Italian',100),(89,'Ivorian',100),(90,'Jamaican',100),(91,'Japanese',100),(92,'Jordanian',100),(93,'Kazakhstani',100),(94,'Kenyan',100),(95,'Kittian and Nevisian',100),(96,'Kuwaiti',100),(97,'Kyrgyz',100),(98,'Laotian',100),(99,'Latvian',100),(100,'Lebanese',100),(101,'Liberian',100),(102,'Libyan',100),(103,'Liechtensteiner',100),(104,'Lithuanian',100),(105,'Luxembourger',100),(106,'Macedonian',100),(107,'Malagasy',100),(108,'Malawian',1),(109,'Malaysian',100),(110,'Maldivan',100),(111,'Malian',100),(112,'Maltese',100),(113,'Marshallese',100),(114,'Mauritanian',100),(115,'Mauritian',100),(116,'Mexican',100),(117,'Micronesian',100),(118,'Moldovan',100),(119,'Monacan',100),(120,'Mongolian',100),(121,'Moroccan',100),(122,'Mosotho',100),(123,'Motswana',100),(124,'Mozambican',2),(125,'Namibian',100),(126,'Nauruan',100),(127,'Nepalese',100),(128,'New Zealander',100),(129,'Nicaraguan',100),(130,'Nigerian',3),(131,'Nigerien',100),(132,'North Korean',100),(133,'Northern Irish',100),(134,'Norwegian',100),(135,'Omani',100),(136,'Pakistani',100),(137,'Palauan',100),(138,'Panamanian',100),(139,'Papua New Guinean',100),(140,'Paraguayan',100),(141,'Peruvian',100),(142,'Polish',100),(143,'Portuguese',100),(144,'Qatari',100),(145,'Romanian',100),(146,'Russian',100),(147,'Rwandan',100),(148,'Saint Lucian',100),(149,'Salvadoran',100),(150,'Samoan',100),(151,'San Marinese',100),(152,'Sao Tomean',100),(153,'Saudi',100),(154,'Scottish',100),(155,'Senegalese',100),(156,'Serbian',100),(157,'Seychellois',100),(158,'Sierra Leonean',100),(159,'Singaporean',100),(160,'Slovakian',100),(161,'Slovenian',100),(162,'Solomon Islander',100),(163,'Somali',3),(164,'South African',100),(165,'South Korean',100),(166,'Spanish',100),(167,'Sri Lankan',100),(168,'Sudanese',100),(169,'Surinamer',100),(170,'Swazi',100),(171,'Swedish',100),(172,'Swiss',100),(173,'Syrian',100),(174,'Taiwanese',100),(175,'Tajik',100),(176,'Tanzanian',2),(177,'Thai',100),(178,'Togolese',100),(179,'Tongan',100),(180,'Trinidadian or Tobagonian',100),(181,'Tunisian',100),(182,'Turkish',100),(183,'Tuvaluan',100),(184,'Ugandan',100),(185,'Ukrainian',100),(186,'Uruguayan',100),(187,'Uzbekistani',100),(188,'Venezuelan',100),(189,'Vietnamese',100),(190,'Welsh',100),(191,'Yemenite',100),(192,'Zambian',2),(193,'Zimbabwean',100);
/*!40000 ALTER TABLE `dde_nationality` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-10-06 13:46:35
