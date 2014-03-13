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
				'NO' AS pregnant,
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
						p.death_date,
						age(LEFT(p.birthdate,10),LEFT(encounter_datetime,10),
                                LEFT(p.date_created,10),p.birthdate_estimated) AS age
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
				'NO' AS pregnant,
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
						p.death_date,
						age(LEFT(p.birthdate,10),LEFT(encounter_datetime,10),
                                LEFT(p.date_created,10),p.birthdate_estimated) AS age
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
			WHERE
				o.concept_id IN (6542 , 8345, 8348)
			GROUP BY o.encounter_id
					")
	end

	def get_all_report_values()
		#get all the primary diagnosis
		primary_diagnosis = get_opd_primary_diagnosis()
		#get all the secondary diagnosis
		secondary_diagnosis = get_opd_secondary_diagnosis()
		#add all the diagnosis into one array
		all_diagnosis = primary_diagnosis + secondary_diagnosis
	
		#create a hash of the reporting values to be returned
		report_values = {:malaria_uncomplicated => 0,
						 :malaria_more_than_5_uncomplicated => 0,
						 :malaria_less_than_5_uncomplicated => 0,
						 :malaria_severe => 0,
						 :malaria_more_than_5_severe => 0,
						 :malaria_less_than_5_severe => 0,
						 :malaria_in_pregnant_women => 0,
						 :malaria_uncomplicated_in_pregnant_women => 0,
						 :malaria_severe_in_pregnant_women => 0,
						 :pneumonia => 0,
						 :pneumonia_severe_less_5 => 0,
						 :pneumonia_very_severe_less_than_5 => 0,
						 :diarrhoea => 0,
						 :diarrhoea_with_dehydration => 0,
             :urethral_discharge => 0,
             :male_urethral_discharge => 0,
             :urinary_schistosomiasis => 0,
             :intestinal_schistosomiasis => 0,
             :genital_ulcers => 0,
             :male_genital_ulcer => 0,
             :female_genital_ulcer => 0,
             :cholera => 0,
             :measles => 0,
      			 :diarrhoea_with_blood => 0,
             :meningitis => 0,
             :plague => 0
				}

		#loop through all_diagnoses, group by diagnoses to identify different elements
		all_diagnosis.group_by(&:diagnosis).each do |diagnosis, diagnosis_list|
			if diagnosis.to_s.downcase == 'malaria'
				#write code for malaria here
				#update the values
				
				report_values[:malaria_in_pregnant_women] = diagnosis_list.reject{|p| p.pregnant.downcase=='no'}.count
				
				diagnosis_list.group_by(&:detailed_diagnosis).each do |malaria_dx, malaria_detail|

					#Malaria Uncomplicated
					if malaria_dx.to_s.downcase == 'uncomplicated'
						report_values[:malaria_uncomplicated]=malaria_detail.count
						report_values[:malaria_more_than_5_uncomplicated]=malaria_detail.reject{|d| d.age.to_i<5}.count
						report_values[:malaria_less_than_5_uncomplicated]=malaria_detail.reject{|d| d.age.to_i>=5}.count
						report_values[:malaria_uncomplicated_in_pregnant_women] = diagnosis_list.reject{|p| p.pregnant.downcase=='no'}.count
											
					#Malaria Severve
					elsif malaria_dx.to_s.downcase == 'severe'
						report_values[:malaria_severe] = malaria_detail.count
						report_values[:malaria_more_than_5_severe]=malaria_detail.reject{|d| d.age.to_i<5}.count
						report_values[:malaria_less_than_5_severe]=malaria_detail.reject{|d| d.age.to_i>=5}.count
						report_values[:malaria_severe_in_pregnant_women] = diagnosis_list.reject{|p| p.pregnant.downcase=='no'}.count
					end
				end		 
			end
			
			if diagnosis.to_s.downcase == 'pneumonia'

				report_values[:pneumonia] = diagnosis_list.count

				diagnosis_list.group_by(&:detailed_diagnosis).each do |pneumonia_dx, pneumonia_detail|

					#Pneumonia severe
					if pneumonia_dx.to_s.downcase == 'severe'
						report_values[:pneumonia_severe_less_5]=pneumonia_detail.reject{|d| d.age.to_i<5}.count
						
					#Pneumonia Very severe
					elsif pneumonia_dx.to_s.downcase == 'very severe'
						report_values[:neumonia_very_severe_less_than_5]=pneumonia_detail.reject{|d| d.age.to_i<5}.count
					end
				end
			end
			
			if diagnosis.to_s.downcase == 'diarrhoea'

				report_values[:diarrhoea] = diagnosis_list.count

				diagnosis_list.group_by(&:detailed_diagnosis).each do |diarrhoea_dx, diarrhoea_detail|

					#diarrhoea with_dehydration
					if diarrhoea_dx.to_s.downcase == 'dehydration'
						report_values[:diarrhoea_with_dehydration]=diarrhoea_detail.count
					end
					
					#diarrhoea with blood
					if diarrhoea_dx.to_s.downcase == 'blood'
						report_values[:diarrhoea_with_blood]=diarrhoea_detail.count
					end
				end
			end
=begin			
			if diagnosis.to_s.downcase == 'aids'

				report_values[:new_aids_cases] = diagnosis_list.count

				diagnosis_list.group_by(&:detailed_diagnosis).each do |diarrhoea_dx, diarrhoea_detail|

					#diarrhoea with_dehydration
					if diarrhoea_dx.to_s.downcase == 'dehydration'
						report_values[:diarrhoea_with_dehydration]=diarrhoea_detail.count
					end
				end
			end
=end			
			if diagnosis.to_s.downcase == 'urethral discharge'

        report_values[:urethral_discharge] = diagnosis_list.count

        diagnosis_list.group_by(&:gender).each do |u_discharge_dx, u_discharge_detail|
          #diarrhoea with_dehydration
          if u_discharge_dx.to_s.downcase == 'm'
            report_values[:male_urethral_discharge]= u_discharge_detail.count
          end
        end
      end
      
      if diagnosis.to_s.downcase == 'urinary schistosomiasis'
        report_values[:urinary_schistosomiasis] = diagnosis_list.count
      end
      if diagnosis.to_s.downcase == 'intestinal schistosomiasis'
        report_values[:intestinal_schistosomiasis] = diagnosis_list.count
      end   

		if diagnosis.to_s.downcase == 'genital ulcers, lgv'

		  report_values[:genital_ulcers] =diagnosis_list.count

			diagnosis_list.group_by(&:gender).each do |u_genital_ulcer_dx, u_genital_ulcer_detail|

        if u_genital_ulcer_dx.to_s.downcase == 'm'
          report_values[:male_genital_ulcer]= u_genital_ulcer_detail.count
        elsif u_genital_ulcer_dx.to_s.downcase == 'f'
          report_values[:female_genital_ulcer] = u_genital_ulcer_detail.count
        end
     end
	  end
    
    if diagnosis.to_s.downcase == 'cholera'
      report_values[:cholera] = diagnosis_list.count
    end    

    if diagnosis.to_s.downcase == 'measles'
      report_values[:measles] = diagnosis_list.count
    end

    if diagnosis.to_s.downcase == 'meningitis'
      report_values[:meningitis] = diagnosis_list.count
    end    

    if diagnosis.to_s.downcase == 'plague'
      report_values[:plague] = diagnosis_list.count
    end
    
    if diagnosis.to_s.downcase == 'neonatal tetanus'
      report_values[:neonatal_tetanus] = diagnosis_list.count
    end
   end
    
		return report_values
	end
end

