require "underlined_diseases_alerts/version"

module UnderlinedDiseasesAlerts
  def self.previous_body_weight(patient_id)
  Encounter.find_by_sql("SELECT * FROM obs where obs_id =
             (select max(obs_id) from obs
              where concept_id = 5089
              and person_id = #{patient_id})")
  end

  def  self.underline_diseases_set(patient_id)
  concept_set_id = ConceptName.find_by_name('underlined IDSR diseases').concept_id
  concept_ids = ConceptSet.find(:all,:conditions=>["concept_set=?",concept_set_id]).map(&:concept_id)
  underlined_obs = Observation.find(:all,:conditions=>["value_coded IN (?) and person_id = ?",concept_ids,patient_id]).map(&:answer_string)
  end
end
