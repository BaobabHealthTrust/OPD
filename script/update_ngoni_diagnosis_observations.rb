# voiding the current diagnosis observations and creating new diagnosis observations
# and also creating vitals encounters and their observations
# then change all the diagnosis encounter_type to outpatient diagnosis
# update weight observations

start_time = Time.now()
puts "Start Time: #{start_time.strftime('%Y-%m-%d %H:%M:%S')}"
logger = Logger.new(Rails.root.join("log",'update_diagnosis_observations.log'))
logger.info "Start Time: #{start_time.strftime('%Y-%m-%d %H:%M:%S')}"
total_saved = 0
total_not_saved = 0

primary_diagnosis_concept_id = ConceptName.find_by_name('PRIMARY DIAGNOSIS').concept_id

diagnosis_concept_id = ConceptName.find_by_name('DIAGNOSIS').concept_id

outpatient_diagnosis_encounter_type_id = EncounterType.find_by_name('OUTPATIENT DIAGNOSIS').encounter_type_id

diagnosis_obs = Observation.find_by_sql("SELECT o.*, e.provider_id, e.form_id, e.encounter_datetime
                                         FROM encounter e
                                         LEFT JOIN obs o ON o.encounter_id = e.encounter_id
                                         WHERE e.encounter_type = #{outpatient_diagnosis_encounter_type_id}
                                         AND o.concept_id = #{diagnosis_concept_id}
                                         AND e.voided = 0
                                         AND o.voided = 0")
diagnosis_obs.each do |diagnosis|
  
    #create the primary diagnosis
    if diagnosis.value_coded
        value_coded_name_id = ConceptName.find_by_sql("SELECT concept_name_id FROM concept_name WHERE concept_id = #{diagnosis.value_coded}").map{|c| c.concept_name_id}
        #create the primary diagnosis
        obs = {}
        obs[:concept_id] = primary_diagnosis_concept_id
        obs[:value_coded] = diagnosis.value_coded
        obs[:value_coded_name_id] = value_coded_name_id.first
        obs[:encounter_id] = diagnosis.encounter_id
        obs[:obs_datetime] = diagnosis.obs_datetime
        obs[:person_id] = diagnosis.person_id
        obs[:location_id] = diagnosis.location_id
        obs[:creator] = diagnosis.creator
        Observation.create(obs)
        total_saved += 1
        msg = "Total saved => #{total_saved} concept => #{obs[:concept_id]} value_coded => #{obs[:value_coded]} encounter => #{obs[:encounter_id]}"
        logger.info msg
        puts msg
        #void the diagnosis
        diagnosis.voided = 1
        diagnosis.date_created = Date.today
        diagnosis.void_reason = "Migration"
        diagnosis.save!
      else
        total_not_saved += 1
        logger.info "Total unsaved => #{total_not_saved} concept => #{diagnosis.concept_id} obs_id => #{diagnosis.obs_id} encounter => #{diagnosis.encounter_id}"
      end
end
#updating referral encounters

referred_encounter_type_id = EncounterType.find_by_name('REFERRED').encounter_type_id rescue 16

referral_encounter_type_id = EncounterType.find_by_name('REFERRAL').encounter_type_id

referred_to_hospital_concept_id = ConceptName.find_by_name('REFER TO OTHER HOSPITAL').concept_id

referral_hospital_concept_id = ConceptName.find_by_name('REFER TO CLINIC').concept_id

referred_encounters = Encounter.find_all_by_encounter_type(referred_encounter_type_id)

referred_encounters.each do |encounter|
  encounter.encounter_type = referral_encounter_type_id
  encounter.save!
end

referred_obs = Observation.find_by_sql("SELECT o.*, e.provider_id, e.form_id, e.encounter_datetime
                                        FROM encounter e
                                        LEFT JOIN obs o ON o.encounter_id = e.encounter_id
                                        WHERE e.encounter_type = #{referral_encounter_type_id}
                                        AND o.concept_id = #{referred_to_hospital_concept_id}
                                        AND e.voided = 0
                                        AND o.voided = 0")

#updating referral observations
referred_obs.each do |referred|

    unless referred.value_text.blank?
        obs = {}
        obs[:concept_id] = referral_hospital_concept_id
        obs[:value_text] = referred.value_text
        obs[:encounter_id] = referred.encounter_id
        obs[:obs_datetime] = referred.obs_datetime
        obs[:person_id] = referred.person_id
        obs[:location_id] = referred.location_id
        obs[:creator] = referred.creator
        Observation.create(obs)
        total_saved += 1
        msg = "Total saved => #{total_saved} concept => #{obs[:concept_id]} value_coded => #{obs[:value_text]} encounter => #{obs[:encounter_id]}"
        logger.info msg
        puts msg
        referred.voided = 1
        referred.date_created = Date.today
        referred.void_reason = "Migration"
        referred.save!
      else
        total_not_saved += 1
        logger.info "Total unsaved => #{total_not_saved} concept => #{referred.concept_id} obs_id => #{referred.obs_id} encounter => #{referred.encounter_id}"
      end
end

#update weight observations
normal_weight_concept_id = ConceptName.find_by_name("Normal weight").concept_id
weight_concept_id = ConceptName.find_by_name("Weight").concept_id

normal_weight_obs = Observation.find(:all, :conditions =>   ["concept_id = ? ", normal_weight_concept_id])
normal_weight_obs.each do |ob|
  ob.concept_id = weight_concept_id
  ob.save!
end

#adding programs to migrated patients with registered patients


Encounter.find_by_sql("
				SELECT * FROM encounter e
				WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'REGISTRATION')
				AND patient_id not IN (SELECT DISTINCT(patient_id) FROM patient_program WHERE program_id = 14)").each {|patient |

  current = Patient.find(patient.patient_id)

				if current.patient_programs.in_programs("OPD PROGRAM").blank?
					current = current.patient_programs.create(
							  :program_id => 14,
                :creator => 1,
                :location_id => patient.location_id,
							  :date_enrolled => patient.encounter_datetime)
          puts "working program for patient #{patient.patient_id}"
        end

				}

 concept_name = ConceptName.find_all_by_name("Following")

  state = ProgramWorkflowState.find(:first, :conditions => ["concept_id IN (?)",concept_name.map{|c|c.concept_id}] ).program_workflow_state_id

PatientProgram.find_by_sql("
        SELECT * FROM patient_program
        WHERE patient_program_id NOT IN (SELECT patient_program_id FROM patient_state)").each {|pg|
        states = PatientState.new(
          :patient_program_id => pg.patient_program_id,
          :start_date => pg.date_enrolled,
          :state => state,
          :creator => 1
          )
        states.save!


          puts "working states for patient #{pg.patient_id}"

        }


end_time = Time.now()
logger.info "End Time : #{end_time.strftime('%Y-%m-%d %H:%M:%S')}"
puts "End Time : #{end_time.strftime('%Y-%m-%d %H:%M:%S')}\n\n"
logger.info "Total saved : #{total_saved}"
logger.info "Total not saved : #{total_not_saved}"
logger.info "Completed successfully !!"
