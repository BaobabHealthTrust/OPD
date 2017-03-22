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
    RestClient.post(CONFIG['credentials']['dashboard_url'],data)
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
    hash[:general_data] = {:national_id=>national_id,:facility=>facility,
                        :obs_date=>obs_date,:gender=>gender,:age=>age,:zone=>zone}

    if enc_params[:encounter][:encounter_type_name] == "NOTES"
      hash[:symptoms] = enc_params[:complaints]#.to_a.reject!{|s| s==""} #remove blank string
      #TODO: check unnecessary strings.
    end
    if enc_params[:encounter][:encounter_type_name] == "OUTPATIENT DIAGNOSIS"
     observations = enc_params[:observations]
  	 hash[:diagnosis] = pull_diagnoses(observations,obs_date,national_id,
                                       patient_id,age,gender)
     hash[:symptoms] = pull_symptoms(patient_id)
    end
    push_to_couch(hash) rescue nil
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
                                      diagnosis_concept_ids,obs_date,patient_id])
    diagnosis_obs.each do |obs|
      next if obs.value_coded.blank? #Interested only in coded answers
      next if national_id.blank?
      diagnosis_full_name = Concept.find(obs.value_coded).fullname() rescue''
      diagnoses.push diagnosis_full_name
    end
   diagnoses
  end

 def self.pull_symptoms( patient_id)
     #symptoms = params[:complaints]
    # return symptoms
   enc_type = EncounterType.find_by_name("notes")
   encounter_ids = Encounter.find(:all,:conditions=>["DATE(encounter_datetime) = ?
                                  AND patient_id = ? AND encounter_type = ? ",
                                  Date.today.to_s,patient_id,enc_type.id]).map(&:id)

   complaint_obs = Observation.find(:all,:conditions=>["encounter_id IN (?)",encounter_ids])
   #group and symptom
    child_obs = {}
    group_and_symptom = []
   complaint_obs .map do |complaint_ob|
      next if complaint_ob.obs_group_id.blank?
      child_obs[complaint_ob.obs_group_id] = complaint_ob.value_text
   end
   child_obs.each do |key,value|
      parent_ob = Observation.find(:first,:conditions=>["obs_id = ?",key]).value_text rescue nil
      group_symp_comb = parent_ob+":"+value if parent_ob
      group_and_symptom << group_symp_comb
   end
 return group_and_symptom
 end
def syndrome_map
   #map_hash = {:SG_FEVER=>"",:SG_URI=>"",:SG_LRI=>"",:SG_RI=>"",:SG_GI=>"",
               #:SG_UGI=>"",:SG_LGI=>:NCD=>"",:IDSR_DZ=>""}

   #["fever","Influenza like illness","respiratory"]
   #["Gastrointestinal","Haema"]
   #["Nephro","Trauma","Cardiovascular"]
   #["General","Other"]

 end

end
