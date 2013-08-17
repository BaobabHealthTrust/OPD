#add SD role
INSERT INTO role VALUES ('System Developer','System Developers');
#add oligad as sd user.
INSERT INTO user_role VALUES (1, 'System Developer');
#add oligad as super_user
INSERT INTO user_role VALUES (1, 'superuser');
#add oligad as provider
INSERT INTO user_role VALUES (1, 'provider');

#create person
#INSERT INTO person (person_id,gender, dead,creator,date_created)
#VALUES (1,'M',0,1,NOW());

#Create Person Name
#INSERT INTO person_name(person_name_id,person_id,given_name,family_name,creator)
#VALUES (1,1,'Super','User',1);

/*create user
#INSERT INTO users(user_id,username,password,salt,creator,date_created) VALUES (220,'admin',
#                  '4a1750c8607d0fa237de36c6305715c223415189','c788c6ad82a157b712392ca695dfcf2eed193d7f',
#                  1,NOW());
*/
#Add concept name tag map
SET FOREIGN_KEY_CHECKS = 0;
CREATE TABLE `concept_name_tag_map` (
  `concept_name_id` int(11) NOT NULL,
  `concept_name_tag_id` int(11) NOT NULL,
  KEY `map_name` (`concept_name_id`),
  KEY `map_name_tag` (`concept_name_tag_id`),
  CONSTRAINT `mapped_concept_name` FOREIGN KEY (`concept_name_id`) REFERENCES `concept_name` (`concept_name_id`),
  CONSTRAINT `mapped_concept_name_tag` FOREIGN KEY (`concept_name_tag_id`) REFERENCES `concept_name_tag` (`concept_name_tag_id`)
);
SET FOREIGN_KEY_CHECKS = 1;

#ADD CONCEPT NAME TAG TABLE
SET FOREIGN_KEY_CHECKS = 0;
CREATE TABLE `concept_name_tag` (
  `concept_name_tag_id` int(11) NOT NULL AUTO_INCREMENT,
  `tag` varchar(50) NOT NULL,
  `description` text NOT NULL,
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `voided` smallint(6) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `date_voided` datetime DEFAULT NULL,
  `void_reason` varchar(255) DEFAULT NULL,
  `uuid` char(38) NOT NULL,
  PRIMARY KEY (`concept_name_tag_id`),
  UNIQUE KEY `concept_name_tag_id` (`concept_name_tag_id`),
  UNIQUE KEY `concept_name_tag_id_2` (`concept_name_tag_id`),
  UNIQUE KEY `concept_name_tag_unique_tags` (`tag`),
  UNIQUE KEY `concept_name_tag_uuid_index` (`uuid`),
  KEY `user_who_created_name_tag` (`creator`),
  KEY `user_who_voided_name_tag` (`voided_by`)
) ENGINE=InnoDB AUTO_INCREMENT=399 DEFAULT CHARSET=utf8;
SET FOREIGN_KEY_CHECKS = 1;


##Add AND Alter Columns

ALTER TABLE `concept_name` ADD COLUMN `voided` INT(6) NOT NULL  DEFAULT 0 ;

ALTER TABLE `concept_name` ADD COLUMN `voided_by` INT(11) NOT NULL  AFTER `voided` ;

ALTER TABLE `concept_name` ADD COLUMN `date_voided` DATETIME  NULL  AFTER `voided_by` ;

ALTER TABLE `concept_name` ADD COLUMN `void_reason` VARCHAR(255) NULL  AFTER `date_voided` ;

ALTER TABLE `concept_word` ADD COLUMN `concept_name_id` INT(11) NOT NULL ;

ALTER TABLE `patient_program` ADD COLUMN `location_id` INT(11) NULL;

ALTER TABLE `obs` ADD COLUMN `value_coded_name_id` INT(11) NULL AFTER `value_coded`;


#ADD concept DESCRIPTION TABLE
SET FOREIGN_KEY_CHECKS = 0;
CREATE TABLE `concept_description` (
  `concept_description_id` int(11) NOT NULL AUTO_INCREMENT,
  `concept_id` int(11) NOT NULL DEFAULT '0',
  `description` text NOT NULL,
  `locale` varchar(50) NOT NULL DEFAULT '',
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `changed_by` int(11) DEFAULT NULL,
  `date_changed` datetime DEFAULT NULL,
  PRIMARY KEY (`concept_description_id`),
  KEY `concept_being_described` (`concept_id`),
  KEY `user_who_created_description` (`creator`),
  KEY `user_who_changed_description` (`changed_by`),
  CONSTRAINT `description_for_concept` FOREIGN KEY (`concept_id`) REFERENCES `concept` (`concept_id`),
  CONSTRAINT `user_who_changed_description` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_created_description` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6180 DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;

#DELETE NULL ENCOUNTERS
DELETE FROM encounter WHERE encounter_type IS NULL;

