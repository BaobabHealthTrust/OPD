SET @'ward_tag_id' = (SELECT location_tag_id FROM location_tag WHERE name = 'Ward');

INSERT INTO `location_tag_map` (`location_id`, `location_tag_id`) 
	SELECT `location_id`, @'ward_tag_id' FROM `location` WHERE `description` = 'Ward' AND `location_id` NOT IN (SELECT `location_id` FROM `location_tag_map` WHERE `location_tag_id` = @'ward_tag_id');
