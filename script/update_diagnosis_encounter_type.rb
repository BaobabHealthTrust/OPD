#
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
