class LocationController < GenericLocationController

  def disease_surveillance_api
    hash = {}
    facility = Location.current_health_center.name rescue 'Location Not Set'
    start_date = params[:start_date].to_date rescue Date.today
    end_date = params[:end_date].to_date rescue Date.today
    zone = CoreService.get_global_property_value("zone")
    concept_names = [
      'PRIMARY DIAGNOSIS', 'DETAILED PRIMARY DIAGNOSIS', 'SECONDARY DIAGNOSIS',
      'DETAILED SECONDARY DIAGNOSIS', 'SPECIFIC SECONDARY DIAGNOSIS', 'ADDITIONAL DIAGNOSIS']
    
    diagnosis_concept_ids = []
    concept_names.each do |concept_name|
        diagnosis_concept_id = ConceptName.find_by_name(concept_name).concept_id
        diagnosis_concept_ids << diagnosis_concept_id
    end

    diagnosis_obs = Observation.find(:all, :conditions => ["concept_id IN (?) AND DATE(obs_datetime) >= ? AND
        DATE(obs_datetime) <= ?", diagnosis_concept_ids, start_date, end_date])
    count = 1
    diagnosis_obs.each do |obs|
        next if obs.value_coded.blank? #Interested only in coded answers
        parent_obs = Observation.find(:all, :conditions => ["obs_group_id =?", obs.id])
        next unless parent_obs.blank? #Not interested in parent obs that has child obs
        obs_id = obs.id
        person = obs.person
        birthdate = person.birthdate.to_date rescue 1900
        birthdate_estimated = person.birthdate_estimated
        gender = person.gender
        age = PatientService.cul_age(birthdate, birthdate_estimated, obs.date_created.to_date, obs.date_created.to_date)
        national_id = PatientService.get_national_id(person.patient) rescue nil
        next if national_id.blank?
        diagnosis_short_name = Concept.find(obs.value_coded).shortname
        diagnosis_full_name = Concept.find(obs.value_coded).fullname
        hash[count] = {
                      "national_id" => national_id, 
                      "gender" => gender, 
                      "age" => age,
                      "diagnosis_short_name" => diagnosis_short_name,
                      "diagnosis_full_name" => diagnosis_full_name,
                      "obs_date" => obs.obs_datetime.to_date,
                      "facility" => facility,
                      "obs_id" => obs_id,
                      "zone" => zone
        }
        count = count + 1
    end
    
    render :text => hash.to_json and return
  end
  
end
