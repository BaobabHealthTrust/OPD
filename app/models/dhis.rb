class Dhis
	attr_accessor :start_date, :end_date
	
	def initialize(start_date, end_date)
		@start_date = start_date
		@end_date = "#{end_date} 23:59:59"
	end
	
	def get_opd_secondary_diagnosis(start_date=@start_date, end_date=@end_date, program="OPD PROGRAM")
		#Get a result containing visits with secondary diagnosis
		
		PatientProgram.find_by_sql("
			SELECT 
				x.*,
				o.encounter_id,
				o.concept_id,
				GROUP_CONCAT(cn.name) as diagnosis,
				GROUP_CONCAT(dcn.name) as detailed_diagnosis,
				GROUP_CONCAT(scn.name) as specific_diagnosis
			FROM
				(SELECT 
					patient_id,
						encounter_id,
						encounter_datetime,
						p.gender,
						p.birthdate,
						p.death_date
				FROM
					encounter e
				LEFT JOIN person p ON e.patient_id = p.person_id
				WHERE
					e.patient_id IN (SELECT 
						    patient_id
						FROM
						    patient_program pp
						WHERE
						    pp.program_id = 14 AND pp.voided = 0) AND e.encounter_type = 8 AND e.encounter_datetime BETWEEN '#{start_date}' AND '#{end_date}') x
					LEFT JOIN
				obs o ON x.encounter_id = o.encounter_id
					LEFT JOIN
				concept_name cn ON cn.concept_id = o.value_coded AND cn.concept_name_id = o.value_coded_name_id AND o.concept_id = 6543
					LEFT JOIN
				concept_name dcn ON dcn.concept_id = o.value_coded AND dcn.concept_name_id = o.value_coded_name_id AND o.concept_id = 8346
					LEFT JOIN
				concept_name scn ON scn.concept_id = o.value_coded AND scn.concept_name_id = o.value_coded_name_id AND o.concept_id = 8347
					LEFT JOIN
				concept_name sscn ON sscn.concept_id = o.value_coded AND sscn.concept_name_id = o.value_coded_name_id AND o.concept_id = 6543
					LEFT JOIN
				concept_name dsscn ON dsscn.concept_id = o.value_coded AND dsscn.concept_name_id = o.value_coded_name_id AND o.concept_id = 8346
					LEFT JOIN
				concept_name ssscn ON ssscn.concept_id = o.value_coded AND ssscn.concept_name_id = o.value_coded_name_id AND o.concept_id = 8347
			WHERE
				o.concept_id IN (6543, 8346, 8347)
			GROUP BY o.encounter_id
					")
	end
	
	def get_opd_primary_diagnosis(start_date=@start_date, end_date=@end_date, program="OPD PROGRAM")
		#Get all patients within OPD program,
		#Having Encounter type "OUT PATIENT DIAGONOSIS WITHIN PERIOD"
		
		PatientProgram.find_by_sql("
			SELECT 
				x.*,
				o.encounter_id,
				o.concept_id,
				GROUP_CONCAT(cn.name) as diagnosis,
				GROUP_CONCAT(dcn.name) as detailed_diagnosis,
				GROUP_CONCAT(scn.name) as specific_diagnosis
			FROM
				(SELECT 
					patient_id,
						encounter_id,
						encounter_datetime,
						p.gender,
						p.birthdate,
						p.death_date
				FROM
					encounter e
				LEFT JOIN person p ON e.patient_id = p.person_id
				WHERE
					e.patient_id IN (SELECT 
						    patient_id
						FROM
						    patient_program pp
						WHERE
						    pp.program_id = 14 AND pp.voided = 0) AND e.encounter_type = 8 AND e.encounter_datetime BETWEEN '#{start_date}' AND '#{end_date}') x
					LEFT JOIN
				obs o ON x.encounter_id = o.encounter_id
					LEFT JOIN
				concept_name cn ON cn.concept_id = o.value_coded AND cn.concept_name_id = o.value_coded_name_id AND o.concept_id = 6542
					LEFT JOIN
				concept_name dcn ON dcn.concept_id = o.value_coded AND dcn.concept_name_id = o.value_coded_name_id AND o.concept_id = 8345
					LEFT JOIN
				concept_name scn ON scn.concept_id = o.value_coded AND scn.concept_name_id = o.value_coded_name_id AND o.concept_id = 8348
					LEFT JOIN
				concept_name sscn ON sscn.concept_id = o.value_coded AND sscn.concept_name_id = o.value_coded_name_id AND o.concept_id = 6543
					LEFT JOIN
				concept_name dsscn ON dsscn.concept_id = o.value_coded AND dsscn.concept_name_id = o.value_coded_name_id AND o.concept_id = 8346
					LEFT JOIN
				concept_name ssscn ON ssscn.concept_id = o.value_coded AND ssscn.concept_name_id = o.value_coded_name_id AND o.concept_id = 8347
			WHERE
				o.concept_id IN (6542 , 8345, 8348)
			GROUP BY o.encounter_id
					")
	end
end

