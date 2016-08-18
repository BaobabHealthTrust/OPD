require 'yaml'
module DashBoardService
CONFIG = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__),
                                                    "../config/dashboard.yml")))
  def self.push_to_couch(data)
    #get token_authentication
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
    # Initialise variables
    hash = {}
    patient_id = enc_params[:encounter][:patient_id]
    person = Person.find(patient_id)
    national_id = PatientService.get_national_id(Patient.find(patient_id))
    age = PatientService.cul_age(person.birthdate, person.birthdate_estimated)
    gender = person.gender
	  zone =  CoreService.get_global_property_value("zone")
    facility = Location.current_health_center.name rescue 'Location Not Set'
    obs_date =  enc_params[:encounter][:encounter_datetime].to_date

    #store common information
    hash[:general_data] = {:national_id =>national_id,:facility =>facility,
                        :obs_date=>obs_date,:gender =>gender,:age =>age,:zone =>zone}

    if enc_params[:encounter][:encounter_type_name] == "NOTES"
  			hash[:symptoms] = enc_params[:complaints].to_a
    end
    if enc_params[:encounter][:encounter_type_name] == "OUTPATIENT DIAGNOSIS"
     observations = enc_params[:observations]
  	 hash[:diagnosis] = pull_diagnoses(observations,obs_date,national_id,
                                       patient_id,age,gender)
    end
    push_to_couch(hash)
  end

  def self.pull_diagnoses(observation,obs_date,national_id,patient_id,age,gender)
    diagnoses = []
    concept_names = ['PRIMARY DIAGNOSIS','DETAILED PRIMARY DIAGNOSIS',
      'SECONDARY DIAGNOSIS','DETAILED SECONDARY DIAGNOSIS', 'SPECIFIC SECONDARY DIAGNOSIS',
      'ADDITIONAL DIAGNOSIS']
    diagnosis_concept_ids = ConceptName.find(:all,
                       :conditions => ["name IN (?)",concept_names]).map(&:concept_id)

    diagnosis_obs = Observation.find(:all,
                                     :conditions =>["concept_id IN (?) AND
                                      DATE(obs_datetime) = ? AND person_id = ?",
                                      diagnosis_concept_ids,obs_date.to_date,patient_id])
    diagnosis_obs.each do |obs|
      next if obs.value_coded.blank? #Interested only in coded answers
      parent_obs = Observation.find(:all,:conditions=>["obs_group_id =?",obs.id])
      next unless parent_obs.blank? #Not interested in parent obs that has child obs
      next if national_id.blank?
      diagnosis_short_name = Concept.find(obs.value_coded).shortname rescue''
      diagnosis_full_name = Concept.find(obs.value_coded).fullname() rescue''
      diag_hash = {:full_name => diagnosis_full_name, :short_name => diagnosis_short_name}
      diagnoses.push diag_hash
    end
   diagnoses
  end

end
