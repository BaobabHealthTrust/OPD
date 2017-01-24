require 'rest-client'
class DhisCouch < ActiveRecord::Base

  #belongs_to :dhis, :foreign_key => "condition"



def create_update_validation_result(rule, date, disease_condition)

    #We substitute mysql with couch DB for storing results
    file = "#{Rails.root}/config/couchdb_config.yml"
    couchdb_details = YAML.load(File.read(file))
    database = couchdb_details
    data = {
      "date_checked" => date.strftime("%Y%m%d"),
      "rule" => rule.desc,
      
      "site_name" => couchdb_details["site_name"],
      "disease_condition"=>
      "patient_type" =>patient_cases,
      "number_of_patients => patient_value
    }
    #raise data['site_name']

    ValidationResult.add_record(data)
  end      



	def data_consistency_check
		data_to_couch={}
		@idsr_monthly[:]
		
	end