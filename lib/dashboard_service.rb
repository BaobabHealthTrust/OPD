module DashBoardService
  require 'yaml'
  CONFIG = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__),
  "../config/dashboard.yml")))

  def self.push_to_couch(data)

     auth_token = RestClient.post(CONFIG['credentials']['url'],
                                  :username =>CONFIG['credentials']['username'],
                                  :password=>CONFIG['credentials']['password'])
     #embedd token with data
     data[:auth_token] = auth_token
     RestClient::Request.execute(:method=>:post,
                                 :url=>CONFIG['credentials']['dashboard_url'],
                                 :payload=>data,
                                 :content_type=>:json)
   rescue RestClient::Exception => e
     raise e.http_body
  end

  def self.push_to_dashboard(enc_params)
    patient_id = enc_params[:encounter][:patient_id]
    person = Person.find(patient_id)
    national_id = PatientService.get_national_id(Patient.find(patient_id))
    age = PatientService.cul_age(person.birthdate, person.birthdate_estimated)
	  zone =  CoreService.get_global_property_value("zone")
    facility = Location.current_health_center.name rescue 'Location Not Set'
    obs_date =  enc_params[:encounter][:encounter_datetime].to_date
    complaints =  enc_params[:complaints].to_a
    observation = enc_params[:observations]
    hash = {}

    if enc_params[:encounter][:encounter_type_name] == "NOTES"
      hash = {:general_data =>{:national_id =>national_id,
  												:facility =>facility,
  												:obs_date=>enc_params[:encounter][:encounter_datetime].to_date,
                          :gender =>person.gender,
  												:age =>age,:zone =>zone},
  			:symptoms=> enc_params[:complaints].to_a,
  			:diagnosis=>{:diagnosis_full_name =>"",:diagnosis_category => ""}}
    end

    if enc_params[:encounter][:encounter_type_name] == "OUTPATIENT DIAGNOSIS"
      hash = {:general_data =>{:national_id =>national_id,
  												:facility =>facility,
  												:obs_date=>obs_date,
                          :gender =>person.gender,
  												:age =>age,:zone =>zone},
  			:symptoms=>{},
  			:diagnosis => pull_diagnoses(observation)}
    end
    #raise hash.inspect
    push_to_couch(hash)
  end

  def self.pull_diagnoses(observation)
    patient_id = ''
    obs_date = ''
    diagnoses = []
    zone = ""
    facility = Location.current_health_center.name rescue 'Location Not Set'

    observation.each do|z|
      patient_id = z[:patient_id]
      obs_date = z[:obs_datetime]
    end
    concept_names = [
          'PRIMARY DIAGNOSIS', 'DETAILED PRIMARY DIAGNOSIS', 'SECONDARY DIAGNOSIS',
          'DETAILED SECONDARY DIAGNOSIS', 'SPECIFIC SECONDARY DIAGNOSIS',
          'ADDITIONAL DIAGNOSIS']
    diagnosis_concept_ids = []
    concept_names.each do |concept_name|
      diagnosis_concept_id = ConceptName.find_by_name(concept_name).concept_id
      diagnosis_concept_ids << diagnosis_concept_id
    end
    diagnosis_obs = Observation.find(:all, :conditions => ["concept_id IN (?) AND DATE(obs_datetime) = ? AND person_id = ?", diagnosis_concept_ids,obs_date.to_date, patient_id])
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
      age = PatientService.cul_age(birthdate, birthdate_estimated,
                                     obs.date_created.to_date,
                                     obs.date_created.to_date)
      national_id = PatientService.get_national_id(person.patient) rescue nil
      next if national_id.blank?
      diagnosis_short_name = Concept.find(obs.value_coded).shortname rescue''
      diagnosis_full_name = Concept.find(obs.value_coded).fullname() rescue''
      diag_hash = {:full_name => diagnosis_full_name, :short_name => diagnosis_short_name}
      diagnoses.push diag_hash
    end
    diagnoses
  end

end
