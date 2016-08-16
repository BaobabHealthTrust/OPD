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
    hash = {}

    if enc_params[:encounter][:encounter_type_name] == "NOTES"
    hash = {:general_data =>{:national_id =>national_id,
												:facility =>facility,
												:obs_date=>enc_params[:encounter][:encounter_datetime].to_date,
                        :gender =>person.gender,
												:age =>age,:zone =>zone,},
			:symptoms=> enc_params[:complaints].to_a,
			:diagnosis=>{:diagnosis_full_name =>"",:diagnosis_category => ""}}
    end
    push_to_couch(hash)
  end
end
