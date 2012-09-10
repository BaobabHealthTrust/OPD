-- MySQL dump 10.11
--
-- Host: localhost    Database: openmrs_1_5
-- ------------------------------------------------------
-- Server version	5.0.67

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


/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

SET @'workstation_tag_id' = (SELECT location_tag_id FROM location_tag WHERE name = 'Workstation Location');
INSERT INTO `location_tag_map` (`location_id`, `location_tag_id`) SELECT `location_id`, @'workstation_tag_id' FROM `location` WHERE `description` = 'Workstation Location';

SET @'ward_tag_id' = (SELECT location_tag_id FROM location_tag WHERE name = 'Ward');
INSERT INTO `location_tag_map` (`location_id`, `location_tag_id`) SELECT `location_id`, @'ward_tag_id' FROM `location` WHERE `description` = 'Ward';

SET @'kch_referral_section_tag_id' = (SELECT location_tag_id FROM location_tag WHERE name = 'KCH referral section');
INSERT INTO `location_tag_map` (`location_id`, `location_tag_id`) SELECT `location_id`, @'kch_referral_section_tag_id' FROM `location` WHERE `description` = 'Ward';

SET @'facility_adults_sections_tag_id' = (SELECT location_tag_id FROM location_tag WHERE name = 'Facility adult sections');
INSERT INTO `location_tag_map` (`location_id`, `location_tag_id`) SELECT `location_id`, @'facility_adults_sections_tag_id' FROM `location` WHERE `name` IN ("Ante-Natal Ward","Burns","Gynaecology Ward","Labour Ward","Post-Natal Ward","Post-Natal Ward(Low Risk)","Post-Natal Ward(High Risk)","Ward 3A","Ward 4B","Ward 5A","Ward 5B","Ward 6A");

SET @'facility_peads_sections_tag_id' = (SELECT location_tag_id FROM location_tag WHERE name = 'Facility peads sections');
INSERT INTO `location_tag_map` (`location_id`, `location_tag_id`) SELECT `location_id`, @'facility_peads_sections_tag_id' FROM `location` WHERE `name` IN ("Malaria Research Ward","Moyo Ward","Oncology Ward","Peadiatrics Nursery Ward","Paeiatrics Special Care Ward","Paediatrics Surgical Ward");

SET @'workstation_tag_id' = (SELECT location_tag_id FROM location_tag WHERE name = 'Central TB DOT Sites');
INSERT INTO `location_tag_map` (`location_id`, `location_tag_id`) SELECT `location_id`, @'workstation_tag_id' FROM `location` WHERE `name` IN ("UNC Project Bwaila Hospital", "Kamuzu Central Hospital", "Lighthouse", "Nkhoma Hospita", "St Gabriel Hospital", "Likuni Hospital", "Partners in hope", "Dae-Yang Hospital", "Kabudula Rural Hospital", "Mitundu Rural hospital", "Kawale Urban Health centre", " UNC Project Kawale", "Kamuzu Barracks Dispensary", "SOS clinic", "Area 18 urban Health centre", " UNC project Area 18", "Kang'oma Health Centre", "UNC Project Area 25", " Area 25 urban Health centre", "Chiwamba Health Centre", "Lumbadzi Health centre", "Ngoni Health centre", "Mbabvi Health centre", "Ukwe Health centre", "Nsaru Health centre", "Malembo Health Centre", "Chokowa Health Centre (Lilongwe)", "Khongoni Health Centre", "Chileka Health Centre (Lilongwe)", "Ndaula Health Centre", "Ming'ongo Health Centre", "Malingunde Health Centre", "Dickson Health Centre", "Chiunjiza Health Centre", "Mlale Hospital", "Kachale Health Centre", "Chadza Health Cetntre", "Nathenje Health Centre", "Matapila ealth Centre", "Mtenthera Health Centre", "Diamphwe Health Centre", "Chimbalanga Health Centre", "Nthondo Health Centre", "Chitedze Health Centre", "Nambuma Health Centre ", "Mbang'ombe 1 Health Centre", "Baylor Childrens centre");

SET @'workstation_tag_id' = (SELECT location_tag_id FROM location_tag WHERE name = 'Central TB Registration Centres');
INSERT INTO `location_tag_map` (`location_id`, `location_tag_id`) SELECT `location_id`, @'workstation_tag_id' FROM `location` WHERE `name` IN ("UNC Project Bwaila Hospital", "Kamuzu Central Hospital", "Lighthouse", "Nkhoma Hospita", "St Gabriel Hospital", "Likuni Hospital", "Partners in hope", "Dae-Yang Hospital", "Kabudula Rural Hospital", "Mitundu Rural hospital");

/* Remove unwanted relationships */;
DELETE FROM relationship_type WHERE b_is_to_a NOT IN ("Parent", "Child", "Sibling", "Spouse/Partner", "Village Health Worker","TB Index Person","TB contact Person","Other");
-- Dump completed on 2010-03-17 15:18:37
