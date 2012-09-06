-- MySQL dump 10.13  Distrib 5.5.24, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: bart2_development
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
SET FOREIGN_KEY_CHECKS=0;

--
-- Table structure for table `pharmacy_obs`
--

DROP TABLE IF EXISTS `pharmacy_obs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pharmacy_obs` (
  `pharmacy_module_id` int(11) NOT NULL AUTO_INCREMENT,
  `pharmacy_encounter_type` int(11) NOT NULL DEFAULT '0',
  `drug_id` int(11) NOT NULL DEFAULT '0',
  `value_numeric` double DEFAULT NULL,
  `value_coded` int(11) DEFAULT NULL,
  `value_text` varchar(15) DEFAULT NULL,
  `expiry_date` date DEFAULT NULL,
  `encounter_date` date NOT NULL DEFAULT '0000-00-00',
  `creator` int(11) NOT NULL,
  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `changed_by` int(11) DEFAULT NULL,
  `date_changed` datetime DEFAULT NULL,
  `voided` tinyint(1) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(225) DEFAULT NULL,
  PRIMARY KEY (`pharmacy_module_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pharmacy_obs`
--

LOCK TABLES `pharmacy_obs` WRITE;
/*!40000 ALTER TABLE `pharmacy_obs` DISABLE KEYS */;
/*!40000 ALTER TABLE `pharmacy_obs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `program_encounter_type_map`
--

DROP TABLE IF EXISTS `program_encounter_type_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `program_encounter_type_map` (
  `program_encounter_type_map_id` int(11) NOT NULL AUTO_INCREMENT,
  `program_id` int(11) DEFAULT NULL,
  `encounter_type_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`program_encounter_type_map_id`),
  KEY `program_mapping` (`program_id`,`encounter_type_id`),
  KEY `referenced_encounter_type` (`encounter_type_id`),
  CONSTRAINT `referenced_encounter_type` FOREIGN KEY (`encounter_type_id`) REFERENCES `encounter_type` (`encounter_type_id`),
  CONSTRAINT `referenced_program_encounter_type_map` FOREIGN KEY (`program_id`) REFERENCES `program` (`program_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `program_encounter_type_map`
--

LOCK TABLES `program_encounter_type_map` WRITE;
/*!40000 ALTER TABLE `program_encounter_type_map` DISABLE KEYS */;
/*!40000 ALTER TABLE `program_encounter_type_map` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `program_location_restriction`
--

DROP TABLE IF EXISTS `program_location_restriction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `program_location_restriction` (
  `program_location_restriction_id` int(11) NOT NULL AUTO_INCREMENT,
  `program_id` int(11) DEFAULT NULL,
  `location_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`program_location_restriction_id`),
  KEY `program_mapping` (`program_id`,`location_id`),
  KEY `referenced_location` (`location_id`),
  CONSTRAINT `referenced_location` FOREIGN KEY (`location_id`) REFERENCES `location` (`location_id`),
  CONSTRAINT `referenced_program` FOREIGN KEY (`program_id`) REFERENCES `program` (`program_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `program_location_restriction`
--

LOCK TABLES `program_location_restriction` WRITE;
/*!40000 ALTER TABLE `program_location_restriction` DISABLE KEYS */;
/*!40000 ALTER TABLE `program_location_restriction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `program_orders_map`
--

DROP TABLE IF EXISTS `program_orders_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `program_orders_map` (
  `program_orders_map_id` int(11) NOT NULL AUTO_INCREMENT,
  `program_id` int(11) DEFAULT NULL,
  `concept_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`program_orders_map_id`),
  KEY `program_mapping` (`program_id`,`concept_id`),
  KEY `referenced_concept_id` (`concept_id`),
  CONSTRAINT `referenced_concept_id` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`),
  CONSTRAINT `referenced_program_orders_type_map` FOREIGN KEY (`program_id`) REFERENCES `program` (`program_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `program_orders_map`
--

LOCK TABLES `program_orders_map` WRITE;
/*!40000 ALTER TABLE `program_orders_map` DISABLE KEYS */;
/*!40000 ALTER TABLE `program_orders_map` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `program_patient_identifier_type_map`
--

DROP TABLE IF EXISTS `program_patient_identifier_type_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `program_patient_identifier_type_map` (
  `program_patient_identifier_type_map_id` int(11) NOT NULL AUTO_INCREMENT,
  `program_id` int(11) DEFAULT NULL,
  `patient_identifier_type_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`program_patient_identifier_type_map_id`),
  KEY `program_mapping` (`program_id`,`patient_identifier_type_id`),
  KEY `referenced_patient_identifier_type` (`patient_identifier_type_id`),
  CONSTRAINT `referenced_patient_identifier_type` FOREIGN KEY (`patient_identifier_type_id`) REFERENCES `patient_identifier_type` (`patient_identifier_type_id`),
  CONSTRAINT `referenced_program_patient_identifier_type_map` FOREIGN KEY (`program_id`) REFERENCES `program` (`program_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `program_patient_identifier_type_map`
--

LOCK TABLES `program_patient_identifier_type_map` WRITE;
/*!40000 ALTER TABLE `program_patient_identifier_type_map` DISABLE KEYS */;
/*!40000 ALTER TABLE `program_patient_identifier_type_map` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `program_relationship_type_map`
--

DROP TABLE IF EXISTS `program_relationship_type_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `program_relationship_type_map` (
  `program_relationship_type_map_id` int(11) NOT NULL AUTO_INCREMENT,
  `program_id` int(11) DEFAULT NULL,
  `relationship_type_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`program_relationship_type_map_id`),
  KEY `program_mapping` (`program_id`,`relationship_type_id`),
  KEY `referenced_relationship_type` (`relationship_type_id`),
  CONSTRAINT `referenced_program_relationship_type_map` FOREIGN KEY (`program_id`) REFERENCES `program` (`program_id`),
  CONSTRAINT `referenced_relationship_type` FOREIGN KEY (`relationship_type_id`) REFERENCES `relationship_type` (`relationship_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `program_relationship_type_map`
--

LOCK TABLES `program_relationship_type_map` WRITE;
/*!40000 ALTER TABLE `program_relationship_type_map` DISABLE KEYS */;
/*!40000 ALTER TABLE `program_relationship_type_map` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `regimen`
--

DROP TABLE IF EXISTS `regimen`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regimen` (
  `regimen_id` int(11) NOT NULL AUTO_INCREMENT,
  `concept_id` int(11) NOT NULL DEFAULT '0',
  `regimen_index` varchar(5) DEFAULT NULL,
  `min_weight` int(3) NOT NULL DEFAULT '0',
  `max_weight` int(3) NOT NULL DEFAULT '200',
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `retired` smallint(6) NOT NULL DEFAULT '0',
  `retired_by` int(11) DEFAULT NULL,
  `date_retired` datetime DEFAULT NULL,
  `program_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`regimen_id`),
  KEY `map_concept` (`concept_id`),
  CONSTRAINT `map_concept` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`)
) ENGINE=InnoDB AUTO_INCREMENT=191 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `regimen`
--

LOCK TABLES `regimen` WRITE;
/*!40000 ALTER TABLE `regimen` DISABLE KEYS */;
/*!40000 ALTER TABLE `regimen` ENABLE KEYS */;
UNLOCK TABLES;


DROP TABLE IF EXISTS `regimen_drug_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `regimen_drug_order` (
  `regimen_drug_order_id` int(11) NOT NULL AUTO_INCREMENT,
  `regimen_id` int(11) NOT NULL DEFAULT '0',
  `drug_inventory_id` int(11) DEFAULT '0',
  `dose` double DEFAULT NULL,
  `equivalent_daily_dose` double DEFAULT NULL,
  `units` varchar(255) DEFAULT NULL,
  `frequency` varchar(255) DEFAULT NULL,
  `prn` tinyint(1) NOT NULL DEFAULT '0',
  `complex` tinyint(1) NOT NULL DEFAULT '0',
  `quantity` int(11) DEFAULT NULL,
  `instructions` text,
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `voided` smallint(6) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) DEFAULT NULL,
  `uuid` char(38) NOT NULL,
  PRIMARY KEY (`regimen_drug_order_id`),
  UNIQUE KEY `regimen_drug_order_uuid_index` (`uuid`),
  KEY `regimen_drug_order_creator` (`creator`),
  KEY `user_who_voided_regimen_drug_order` (`voided_by`),
  KEY `map_regimen` (`regimen_id`),
  KEY `map_drug_inventory` (`drug_inventory_id`),
  CONSTRAINT `map_drug_inventory` FOREIGN KEY (`drug_inventory_id`) REFERENCES `drug` (`drug_id`),
  CONSTRAINT `map_regimen` FOREIGN KEY (`regimen_id`) REFERENCES `regimen` (`regimen_id`),
  CONSTRAINT `regimen_drug_order_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_voided_regimen_drug_order` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=277 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `regimen_drug_order`

LOCK TABLES `regimen_drug_order` WRITE;
/*!40000 ALTER TABLE `regimen_drug_order` DISABLE KEYS */;
/*!40000 ALTER TABLE `regimen_drug_order` ENABLE KEYS */;
UNLOCK TABLES;
--
-- Table structure for table `task`
--

DROP TABLE IF EXISTS `task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `task` (
  `task_id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) DEFAULT NULL,
  `encounter_type` varchar(255) DEFAULT NULL,
  `description` text,
  `location` varchar(255) DEFAULT NULL,
  `gender` varchar(50) DEFAULT NULL,
  `has_obs_concept_id` int(11) DEFAULT NULL,
  `has_obs_value_coded` int(11) DEFAULT NULL,
  `has_obs_value_drug` int(11) DEFAULT NULL,
  `has_obs_value_datetime` datetime DEFAULT NULL,
  `has_obs_value_numeric` double DEFAULT NULL,
  `has_obs_value_text` text,
  `has_obs_scope` text,
  `has_program_id` int(11) DEFAULT NULL,
  `has_program_workflow_state_id` int(11) DEFAULT NULL,
  `has_identifier_type_id` int(11) DEFAULT NULL,
  `has_relationship_type_id` int(11) DEFAULT NULL,
  `has_order_type_id` int(11) DEFAULT NULL,
  `has_encounter_type_today` varchar(255) DEFAULT NULL,
  `skip_if_has` smallint(6) DEFAULT '0',
  `sort_weight` double DEFAULT NULL,
  `creator` int(11) NOT NULL,
  `date_created` datetime NOT NULL,
  `voided` smallint(6) DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) DEFAULT NULL,
  `changed_by` int(11) DEFAULT NULL,
  `date_changed` datetime DEFAULT NULL,
  `uuid` char(38) DEFAULT NULL,
  PRIMARY KEY (`task_id`),
  KEY `task_creator` (`creator`),
  KEY `user_who_voided_task` (`voided_by`),
  KEY `user_who_changed_task` (`changed_by`),
  CONSTRAINT `task_creator` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_changed_task` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_voided_task` FOREIGN KEY (`voided_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=96 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `task`
--

LOCK TABLES `task` WRITE;
/*!40000 ALTER TABLE `task` DISABLE KEYS */;
INSERT INTO `task` VALUES (1,'/encounters/new/registration?patient_id={patient}','REGISTRATION','Always do a Registration here','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,1,1,'2011-06-22 15:39:43',0,NULL,NULL,NULL,1,'2011-06-22 15:39:43','15f49016-9cd5-11e0-96f5-544249e49b14'),(2,'/encounters/new/art_initial?show&patient_id={patient}','ART_INITIAL','Not enrolled in HIV programn','HIV Reception',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,NULL,1,2,1,'2011-06-22 15:42:50',0,NULL,NULL,NULL,1,'2011-06-22 15:42:50','85b2b6e4-9cd5-11e0-96f5-544249e49b14'),(3,'/encounters/new/llh_hiv_staging?show&patient_id={patient}','HIV STAGING','Ever received ART = YES','HIV Reception',NULL,7754,1065,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,NULL,0,3,1,'2011-06-22 15:45:58',0,NULL,NULL,NULL,1,'2011-06-22 15:45:58','f5725c50-9cd5-11e0-96f5-544249e49b14'),(4,'/encounters/new/hiv_reception?show&patient_id={patient}','HIV RECEPTION','Always do a HIV RECEPTION here','HIV Reception',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,NULL,0,4,1,'2011-06-22 15:51:48',0,NULL,NULL,NULL,1,'2011-06-22 15:51:48','c68ec26a-9cd6-11e0-96f5-544249e49b14'),(5,'/encounters/new/vitals?patient_id={patient}','VITALS','Patient present = YES','Vitals',NULL,1805,1065,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,NULL,0,5,1,'2011-06-22 15:56:21',0,NULL,NULL,NULL,1,'2011-06-22 15:56:50','6914d15a-9cd7-11e0-96f5-544249e49b14'),(6,'/encounters/new/llh_hiv_staging?show&patient_id={patient}','HIV STAGING','Not on ART','HIV Clinician Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,NULL,0,6,1,'2011-06-22 16:20:15',0,NULL,NULL,NULL,1,'2011-06-22 16:20:15','bf8bbb90-9cda-11e0-96f5-544249e49b14'),(7,'/encounters/new/pre_art_visit?show&patient_id={patient}','PART_FOLLOWUP','If patient has no staging condition: Reason for starting = Unknown','HIV Clinician Station',NULL,7563,1067,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,NULL,0,7,1,'2011-06-22 16:24:40',0,NULL,NULL,NULL,1,'2011-06-22 16:24:40','5da2e948-9cdb-11e0-96f5-544249e49b14'),(8,'/encounters/new/art_visit?show&patient_id={patient}','ART VISIT','On ART','HIV Clinician Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,NULL,0,8,1,'2011-06-22 16:33:36',0,NULL,NULL,NULL,1,'2011-06-22 16:33:36','9d7ad548-9cdc-11e0-96f5-544249e49b14'),(9,'/encounters/new/art_visit?show&patient_id={patient}','ART VISIT','On ART','HIV Nurse Station',NULL,1805,1065,NULL,NULL,NULL,NULL,'TODAY',1,7,NULL,NULL,NULL,NULL,0,9,1,'2011-06-22 16:34:58',0,NULL,NULL,NULL,1,'2011-06-22 16:34:58','cdc5f26e-9cdc-11e0-96f5-544249e49b14'),(10,'/encounters/new/art_adherence?show&patient_id={patient}','ART ADHERENCE','ART ADHERENCE','HIV Nurse Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,'ART VISIT',0,10,1,'2011-06-22 16:39:17',0,NULL,NULL,NULL,1,'2011-06-22 16:39:33','685fc890-9cdd-11e0-96f5-544249e49b14'),(11,'/regimens/new?patient_id={patient}','TREATMENT','If ART visit today == YES','HIV Clinician Station',NULL,5073,1065,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,NULL,0,11,1,'2011-06-22 16:46:41',0,NULL,NULL,NULL,1,'2011-06-22 16:51:09','70d521a4-9cde-11e0-96f5-544249e49b14'),(12,'/regimens/new?patient_id={patient}','TREATMENT','If ART visit today == YES','HIV Nurse Station',NULL,5073,1065,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,NULL,0,12,1,'2011-06-22 16:55:03',0,NULL,NULL,NULL,1,'2011-06-22 16:56:00','9c18b302-9cdf-11e0-96f5-544249e49b14'),(13,'/patients/treatment_dashboard/{patient}','DISPENSING','If a patient has been prescribed drugs','HIV Nurse Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'RECENT',1,NULL,NULL,NULL,NULL,'TREATMENT',0,13,1,'2011-06-22 17:00:52',0,NULL,NULL,NULL,1,'2011-06-22 17:00:52','6c53f676-9ce0-11e0-96f5-544249e49b14'),(14,'/patients/treatment_dashboard/{patient}','DISPENSING','If a patient has been prescribed drugs','HIV Pharmacy Station',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'RECENT',1,NULL,NULL,NULL,NULL,'TREATMENT',0,14,1,'2011-06-22 17:03:21',0,NULL,NULL,NULL,1,'2011-06-22 17:03:42','c50eae8c-9ce0-11e0-96f5-544249e49b14'),(15,'/encounters/new/art_visit?show&patient_id={patient}','ART VISIT','Patient not present == YES','HIV Nurse Station',NULL,1805,1066,NULL,NULL,NULL,NULL,'TODAY',1,7,NULL,NULL,NULL,NULL,0,15,1,'2011-06-22 17:05:29',0,NULL,NULL,NULL,1,'2011-06-22 17:05:29','1140ff6c-9ce1-11e0-96f5-544249e49b14'),(16,'/encounters/new/art_visit?show&patient_id={patient}','ART VISIT','Patient not present == YES','HIV Clinician Station',NULL,1805,1066,NULL,NULL,NULL,NULL,'TODAY',1,7,NULL,NULL,NULL,NULL,0,16,1,'2011-06-22 18:04:48',0,NULL,NULL,NULL,1,'2011-06-22 18:05:01','5a7db88e-9ce9-11e0-96f5-544249e49b14'),(17,'/patients/treatment_dashboard/{patient}',NULL,'No where to go','Outpatient',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,17,1,'2011-06-23 09:56:06',0,NULL,NULL,NULL,1,'2011-06-23 09:56:52','400f0a5e-9d6e-11e0-be0c-544249e49b14'),(18,'/patients/show/{patient}',NULL,'No whereto go','*',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,0,18,1,'2011-06-23 10:23:00',0,NULL,NULL,NULL,1,'2011-06-23 10:23:25','019dfbaa-9d72-11e0-be0c-544249e49b14'),(58,'/encounters/new/art_initial?show&patient_id={patient}','ART_INITIAL','Not enrolled in HIV programn','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,NULL,1,1,1,'2010-02-26 11:25:51',0,NULL,NULL,NULL,1,'2010-02-26 11:25:51','eeba2f84-22b8-11df-b344-0026181bb84d'),(59,'/encounters/new/hiv_reception?show&patient_id={patient}','HIV RECEPTION','Always','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,3,1,'2010-02-26 11:47:13',0,NULL,NULL,NULL,1,'2010-02-26 11:47:13','ea6de076-22bb-11df-b344-0026181bb84d'),(60,'/encounters/new/vitals?patient_id={patient}','VITALS','PATIENT_PRESENT = YES','Retrospective',NULL,1805,1065,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,4,1,'2010-02-26 13:45:50',0,NULL,NULL,NULL,1,'2010-02-26 13:45:50','7cc4fc2e-22cc-11df-b344-0026181bb84d'),(61,'/encounters/new/llh_hiv_staging?show&patient_id={patient}','HIV STAGING','EVER RECEIVED ART = YES','Retrospective',NULL,7754,1065,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,2,1,'2010-02-26 13:45:50',0,NULL,NULL,NULL,1,'2010-02-26 13:45:50','7cc4fc2e-22cc-11df-b344-0026181bb84d'),(62,'/patients/show/{patient}',NULL,'EID patients go straight to Dashboard for now','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',4,NULL,NULL,NULL,NULL,NULL,0,0,1,'2011-04-30 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(63,'/patients/show/{patient}',NULL,'Stop here if ART ELIGIBILITY = UNKNOWN','Retrospective',NULL,7563,1067,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,98,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(64,'/patients/show/{patient}',NULL,'If TREATMENT today','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'TREATMENT',0,99,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(65,'/encounters/new/art_visit?show&patient_id={patient}','ART VISIT','In state On ART','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,7,NULL,NULL,NULL,NULL,0,2,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(66,'/encounters/new/art_adherence?show&patient_id={patient}','ART ADHERENCE','ART ADHERENCE','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,'ART VISIT',0,3,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,1,'2011-03-08 15:59:44',NULL),(67,'/regimens/new?patient_id={patient}','TREATMENT','If ART Visit today AND REFER TO ART CLINICIAN = NO','Retrospective',NULL,6969,1066,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,'ART VISIT',0,4,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(68,'/patients/show/{patient}','TREATMENT','If ART Visit today AND REFER TO ART CLINICIAN = YES','Retrospective',NULL,6969,1065,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,'ART VISIT',0,5,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(69,'/encounters/new/appointment?patient_id={patient}','APPOINTMENT','If DISPENSE today','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'DISPENSE',0,7,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(70,'/encounters/new/llh_hiv_staging?show&patient_id={patient}','HIV STAGING','Not in state On ART','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,7,NULL,NULL,NULL,NULL,1,1,1,'2010-02-26 14:00:23',0,NULL,NULL,NULL,1,'2010-02-26 14:00:23','84dd80dc-22ce-11df-b344-0026181bb84d'),(71,'/patients/show/{patient}',NULL,'ART ELIGIBILITY = UNKNOWN','Retrospective',NULL,7563,1067,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,97,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(72,'/encounters/new/art_visit?show&patient_id={patient}','ART VISIT','NOT ART ELIGIBILITY = UNKNOWN','Retrospective',NULL,7563,1067,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,1,3,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(73,'/regimens/new?patient_id={patient}','TREATMENT','ART VISIT today','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,'ART VISIT',0,5,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(74,'/encounters/new/art_visit?show&patient_id={patient}',NULL,'REFER TO CLINICIAN = YES','Retrospective',NULL,6969,1065,NULL,NULL,NULL,NULL,'RECENT',NULL,NULL,NULL,NULL,NULL,NULL,0,4,1,'2011-01-13 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(75,'/patients/show/{patient}',NULL,'EID patients go straight to Dashboard for now','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',4,NULL,NULL,NULL,NULL,NULL,0,0,1,'2011-04-30 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(76,'/patients/treatment/{patient}','DISPENSING','If a patient has been prescribed drugs','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'RECENT',1,NULL,NULL,NULL,NULL,'TREATMENT',0,6,1,'2011-03-08 15:33:20',0,NULL,NULL,NULL,1,'2011-03-08 15:33:20','a1dafc96-4988-11e0-8fc9-544249e49b14'),(77,'/encounters/new/art_initial?show&patient_id={patient}','ART_INITIAL','NotenrolledinHIVprogramn','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,NULL,1,1,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,1,'0000-00-00 00:00:00','eeba2f84-22b8-11df-b344-0026181bb84d'),(78,'/encounters/new/hiv_reception?show&patient_id={patient}','HIVRECEPTION','Always','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,3,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,1,'0000-00-00 00:00:00','ea6de076-22bb-11df-b344-0026181bb84d'),(79,'/encounters/new/vitals?patient_id={patient}','VITALS','PATIENT_PRESENT=YES','Retrospective',NULL,1805,1065,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,4,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,1,'0000-00-00 00:00:00','7cc4fc2e-22cc-11df-b344-0026181bb84d'),(80,'/encounters/new/hiv_staging?show&patient_id={patient}','HIVSTAGING','EVERRECEIVEDART=YES','Retrospective',NULL,7754,1065,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,2,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,1,'0000-00-00 00:00:00','7cc4fc2e-22cc-11df-b344-0026181bb84d'),(81,'/patients/show/{patient}',NULL,'EIDpatientsgostraighttoDashboardfornow','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',4,NULL,NULL,NULL,NULL,NULL,0,0,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(82,'/patients/show/{patient}',NULL,'StophereifARTELIGIBILITY=UNKNOWN','Retrospective',NULL,7563,1067,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,98,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(83,'/patients/show/{patient}',NULL,'IfTREATMENTtoday','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'TREATMENT',0,99,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(84,'/encounters/new/art_visit?show&patient_id={patient}','ARTVISIT','InstateOnART','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,7,NULL,NULL,NULL,NULL,0,2,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(85,'/encounters/new/art_adherence?show&patient_id={patient}','ARTADHERENCE','ARTADHERENCE','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,'ARTVISIT',0,3,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,1,'0000-00-00 00:00:00',NULL),(86,'/regimens/new?patient_id={patient}','TREATMENT','IfARTVisittodayANDREFERTOARTCLINICIAN=NO','Retrospective',NULL,6969,1066,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,'ARTVISIT',0,4,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(87,'/patients/show/{patient}','TREATMENT','IfARTVisittodayANDREFERTOARTCLINICIAN=YES','Retrospective',NULL,6969,1065,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,'ARTVISIT',0,5,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(88,'/encounters/new/appointment?patient_id={patient}','APPOINTMENT','IfDISPENSEtoday','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,'DISPENSE',0,7,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(89,'/encounters/new/hiv_staging?show&patient_id={patient}','HIVSTAGING','NotinstateOnART','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,7,NULL,NULL,NULL,NULL,1,1,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,1,'0000-00-00 00:00:00','84dd80dc-22ce-11df-b344-0026181bb84d'),(90,'/patients/show/{patient}',NULL,'ARTELIGIBILITY=UNKNOWN','Retrospective',NULL,7563,1067,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,0,97,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(91,'/encounters/new/art_visit?show&patient_id={patient}','ARTVISIT','NOTARTELIGIBILITY=UNKNOWN','Retrospective',NULL,7563,1067,NULL,NULL,NULL,NULL,'TODAY',NULL,NULL,NULL,NULL,NULL,NULL,1,3,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(92,'/regimens/new?patient_id={patient}','TREATMENT','ARTVISITtoday','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',1,NULL,NULL,NULL,NULL,'ARTVISIT',0,5,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(93,'/encounters/new/art_visit?show&patient_id={patient}',NULL,'REFERTOCLINICIAN=YES','Retrospective',NULL,6969,1065,NULL,NULL,NULL,NULL,'RECENT',NULL,NULL,NULL,NULL,NULL,NULL,0,4,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(94,'/patients/show/{patient}',NULL,'EIDpatientsgostraighttoDashboardfornow','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'TODAY',4,NULL,NULL,NULL,NULL,NULL,0,0,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,NULL,NULL,NULL),(95,'/patients/treatment/{patient}','DISPENSING','Ifapatienthasbeenprescribeddrugs','Retrospective',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'RECENT',1,NULL,NULL,NULL,NULL,'TREATMENT',0,6,1,'0000-00-00 00:00:00',0,NULL,NULL,NULL,1,'0000-00-00 00:00:00','a1dafc96-4988-11e0-8fc9-544249e49b14');
/*!40000 ALTER TABLE `task` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
SET FOREIGN_KEY_CHECKS=1;

-- Dump completed on 2012-09-04 10:57:29
