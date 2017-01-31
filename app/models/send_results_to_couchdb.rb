require 'rest-client'
class SendResultsToCouchdb < ActiveRecord::Base
  #belongs_to :dhis, :foreign_key => "condition"

  def self.add_record(data)

  	file = "#{Rails.root}/config/couchdb_config.yml"
  	couchdb_details = YAML.load(File.read(file))
    database = couchdb_details["source_database"]    
    username = couchdb_details["source_username"]
    password = couchdb_details["source_password"]
    port = couchdb_details["source_port"]
	ip_address = couchdb_details["source_address"]
	
	#raise "#{Rails.root}"
	`curl -X PUT http://#{username}:#{password}@#{ip_address}:#{port}/#{database}`
	`cd #{Rails.root}/db && curl -X PUT -d @couch_views.js http://#{username}:#{password}@#{ip_address}:#{port}/#{database}/_design/query`
	#all reports starts from first of the month to the last day of the month
	key = data['site_name'].strip.gsub(' ', '_') + "_" + data['report_month'].to_time.strftime("%Y%m%d")
 	info = JSON.parse(`curl -X GET http://#{username}:#{password}@#{ip_address}:#{port}/#{database}/_design/query/_view/by_site_name_and_report_month?key=\\\"#{key}\\\"`)
 	uuid = info['rows'].first['id'] rescue nil
 	doc = JSON.parse(`curl -X GET http://#{username}:#{password}@#{ip_address}:#{port}/#{database}/#{uuid}`) rescue nil
 	#raise doc.to_json
 	if !doc['report_month'].blank? 
		doc["conditions"] = data['conditions']
		doc["status_code"] = data['status_code']
		doc["updated_on"] = data['updated_on']
				
		RestClient.post("http://#{username}:#{password}@#{ip_address}:#{port}/#{database}", doc.to_json, :content_type => "application/json")
	else
		url = "http://#{username}:#{password}@#{ip_address}:#{port}/#{database}/"
		RestClient.post(url, data.to_json, :content_type => "application/json")
	end
	return 200
  end
end