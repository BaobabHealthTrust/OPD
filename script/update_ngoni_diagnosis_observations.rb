# voiding the current diagnosis observations and creating new diagnosis observations
# and also creating vitals encounters and their observations
# then change all the diagnosis encounter_type to outpatient diagnosis

start_time = Time.now().strftime('%Y-%m-%d %H:%M:%S')
puts "Start Time: #{start_time}\n\n"
logger = Logger.new(Rails.root.join("log",'update_diagnosis_observations.log'))
logger.info "Start Time: #{start_time}"
total_saved = 0
total_not_saved = 0

primary_diagnosis_concept_id = ConceptName.find_by_name('PRIMARY DIAGNOSIS').concept_id

diagnosis_obs = Observation.find_by_sql("SELECT o.*, e.provider_id, e.form_id, e.encounter_datetime FROM encounter e
                                          LEFT JOIN obs o ON o.encounter_id = e.encounter_id
                                          WHERE e.encounter_type = 8
                                          AND e.voided = 0
                                          AND o.voided = 0")

diagnosis_obs.each do |aDiagnosis|
  
    #create the primary diagnosis
    if aDiagnosis.value_coded
        value_coded_name_id = ConceptName.find_by_sql("SELECT concept_name_id FROM concept_name WHERE concept_id = #{aDiagnosis.value_coded}").map{|c| c.concept_name_id}
        #create the primary diagnosis
        obs = {}
        obs[:concept_id] = primary_diagnosis_concept_id
        obs[:value_coded] = aDiagnosis.value_coded
        obs[:value_coded_name_id] = value_coded_name_id.first
        obs[:encounter_id] = aDiagnosis.encounter_id
        obs[:obs_datetime] = aDiagnosis.obs_datetime
        obs[:person_id] = aDiagnosis.person_id
        obs[:location_id] = aDiagnosis.location_id
        obs[:creator] = aDiagnosis.creator
        Observation.create(obs)
        total_saved += 1
        logger.info "Total saved => #{total_saved} concept => #{obs[:concept_id]} value_coded => #{obs[:value_coded]} encounter => #{obs[:encounter_id]}"
        #void the diagnosis
        aDiagnosis.voided = 1
        aDiagnosis.date_created = Date.today
        aDiagnosis.void_reason = "Migration"
        aDiagnosis.save
      else
        total_not_saved += 1
        logger.info "Total unsaved => #{total_not_saved} concept => #{aDiagnosis.concept_id} obs_id => #{aDiagnosis.obs_id} encounter => #{aDiagnosis.encounter_id}"
      end
end

#update the diagnosis encounter_type to outpatient diagnosis encounter_type
#
outpatient_diagnosis_encounter_type_id = EncounterType.find_by_name('OUTPATIENT DIAGNOSIS').encounter_type_id
diagnosis_encounter_type = EncounterType.find_by_name('DIAGNOSIS').encounter_type_id

#pull out all diagnosis encounters that are not voided
diagnosis_encounters = Encounter.find_by_sql("SELECT * FROM encounter
                                              WHERE encounter_type = #{diagnosis_encounter_type} 
                                              AND voided = 0 ")

diagnosis_encounters.each do |aDiagnosis_encounter|
  #change the diagnosis encounter_type_id to outpatient_diagnosis encounter_type_id
  aDiagnosis_encounter.encounter_type = outpatient_diagnosis_encounter_type_id
  aDiagnosis_encounter.date_created = Date.today
  aDiagnosis_encounter.save
end

end_time = Time.now().strftime('%Y-%m-%d %H:%M:%S')
#end_time = Time.now()

logger.info "End Time : #{end_time}"
puts "Start Time : #{end_time}\n\n"
logger.info "Total saved : #{total_saved}"
logger.info "Total not saved : #{total_not_saved}"
logger.info "It took : #{end_time - start_time}"
logger.info "Completed successfully !!\n\n"
