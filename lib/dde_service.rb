module DDEService
  require 'rest_client'
  
  def self.dde_settings
    data = {}
    program_id    = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env]["program_id"]
    dde_protocol  = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env]["dde_protocol"]
    dde_user = DdeApplicationUsers.find_by_program_id(program_id)
    
    dde_ip = dde_user.ipaddress
    dde_port = dde_user.port
    dde_username = dde_user.username
    dde_password = dde_user.password


    data["dde_ip"] = dde_ip
    data["dde_port"] = dde_port
    data["dde_username"] = dde_username
    data["dde_password"] = dde_password
    data["dde_address"] = "#{dde_protocol}://#{dde_ip}:#{dde_port}"

    return data
  end

  def self.search_local_by_identifier(identifier)
    Person.find(:all, :conditions =>["i.identifier = ?", identifier],
      :joins => "INNER JOIN patient_identifier i ON i.patient_id = person.person_id")
  end

  def self.initial_dde_authentication_token
    dde_address = "#{dde_settings["dde_address"]}/v1/login"
    passed_params = {:username => "admin", :password => "bht.dde3!"}
    headers = {:content_type => "json" }
    received_params = RestClient.post(dde_address, passed_params.to_json, headers = headers)
    dde_token = JSON.parse(received_params)["access_token"]
    return dde_token
  end

  def self.dde_authentication_token
    dde_address = "#{dde_settings["dde_address"]}/v1/login"
    dde_username = dde_settings["dde_username"]
    dde_password = dde_settings["dde_password"]

    passed_params = {:username => dde_username, :password => dde_password}
    headers = {:content_type => "json" }
    received_params = RestClient.post(dde_address, passed_params, headers = headers){|response, request, result|response}
    dde_token = JSON.parse(received_params)["access_token"]
    return dde_token
  end

  def self.dde_login(params)
    dde_address = "#{dde_settings["dde_address"]}/v1/login"
    dde_username = params[:username]
    dde_password = params[:password]
    passed_params = {:username => dde_username, :password => dde_password}
    headers = {:content_type => "json" }
    received_params = RestClient.post(dde_address, passed_params.to_json, headers = headers){|response, request, result|response}
    dde_token = JSON.parse(received_params)["access_token"]
    return dde_token
  end

  def self.dde_login_from_params(params)
    dde_address = "http://#{params[:address]}/v1/login"
    dde_username = params[:username]
    dde_password = params[:password]
    passed_params = {:username => dde_username, :password => dde_password}
    headers = {:content_type => "json" }
    received_params = RestClient.post(dde_address, passed_params.to_json, headers = headers){|response, request, result|response}
    dde_token = JSON.parse(received_params)["access_token"]
    return dde_token
  end

  def self.dde_locations(dde_address, token, name = "")
    dde_url = "#{dde_address}/v1/get_locations"
    received_params = RestClient::Request.execute( { :method => :post, :url => dde_url,
      :payload => {:name => name}, :headers => {:Authorization => token} } )

    return JSON.parse(received_params)
  end

  def self.add_dde_user(dde_address, data, token)
    dde_address = "#{dde_address}/v1/add_user"
    passed_params = {
      :username => data["username"],
      :password => data["password"],
      :email => "test@gmail.com",
      :location => data["location"],
    }
    headers = {:content_type => "json", :Authorization => token }
    received_params = RestClient.post(dde_address, passed_params, headers = headers){|response, request, result|response}
    dde_status = JSON.parse(received_params)["status"]
    return dde_status
  end

  def self.get_dde_location(url, doc_id,token)
    dde_location_uri = "#{url}/v1/find_location"
    passed_params = {:location_id => doc_id}
    headers = {:content_type => "json", :Authorization => token}
    dde_response = RestClient.post(dde_location_uri, passed_params, headers = headers)
    return JSON.parse(dde_response)
  end

  def self.verify_dde_token_authenticity(dde_token)

    dde_address = "#{dde_settings["dde_address"]}/v1/verify_token"
    passed_params = {
      :token => dde_token
    }

    headers = {:content_type => "json" }
    received_params = RestClient.post(dde_address, passed_params.to_json, headers = headers){|response, request, result|response}
    verification_status = JSON.parse(received_params)["status"]

    return verification_status
  end

  def self.search_dde_by_identifier(dde_identifiers,  dde_token)

    if dde_identifiers["doc_id"].blank?
      dde_address = "#{dde_settings["dde_address"]}/v1/search_by_npid"
      passed_params = {
        :npid => dde_identifiers["npid"]
      }
    else
      dde_address = "#{dde_settings["dde_address"]}/v1/search_by_doc_id"
      passed_params = {
        :doc_id => dde_identifiers["doc_id"]
      }
    end

    headers = {:content_type => "json", :Authorization => dde_token }
    received_params = RestClient.post(dde_address, passed_params.to_json, headers = headers){|response, request, result|response}

    search_results = JSON.parse(received_params)
    return search_results
  end

  def self.search_dde_by_name_and_gender(params, token)
    passed_params = {
      :given_name => params["given_name"],
      :family_name => params["family_name"],
      :gender => params["gender"]
    }

    dde_address = "#{dde_settings["dde_address"]}/v1/search_by_name_and_gender"
    output = RestClient::Request.execute( { :method => :post, :url => dde_address,
        :payload => passed_params, :headers => {:Authorization => token} } )

    results = JSON.parse(output)
    status = results["status"].to_i rescue nil

    unless status.blank?
      return [] if status == 400
    end

    return results
  end

  def self.dde_advanced_search(params)
    passed_params = {
      :given_name => params[:given_name],
      :family_name => params[:family_name],
      :gender => params[:gender],
      :birthdate => params[:birthdate],
      :home_district => params[:home_district],
      :token => self.dde_authentication_token
    }

    dde_address = "#{dde_settings["dde_address"]}/v1/search_by_name_and_gender"
    received_params = RestClient.post(dde_address, passed_params)
    results = JSON.parse(received_params)["data"]["hits"]
    return results
  end

  def self.add_dde_patient(params, dde_token)
    dde_address = "#{dde_settings["dde_address"]}/v1/add_person"
    person = Person.new
    birthdate = "#{params["person"]['birth_year']}-#{params["person"]['birth_month']}-#{params["person"]['birth_day']}"
    birthdate = birthdate.to_date.strftime("%Y-%m-%d") rescue birthdate

    if params["person"]["birth_year"] == "Unknown"
      self.set_birthdate_by_age(person, params["person"]['age_estimate'], Date.today)
    else
      self.set_birthdate(person, params["person"]["birth_year"], params["person"]["birth_month"], params["person"]["birth_day"])
    end

    unless params["person"]['birthdate_estimated'].blank?
      person.birthdate_estimated = params["person"]['birthdate_estimated'].to_i
    end

    passed_params = {
      "family_name" => params["person"]["names"]["family_name"],
      "given_name" => params["person"]["names"]["given_name"],
      "middle_name" => params["person"]["names"]["middle_name"],
      "gender" => params["person"]["gender"],
      "attributes" => {
        "current_village" => params["person"]["addresses"]["city_village"],
        "current_traditional_authority" => params["person"]["addresses"]["township_division"],
        "current_district" => params["person"]["addresses"]["state_province"],

        "home_village" => params["person"]["addresses"]["neighborhood_cell"],
        "home_traditional_authority" => params["person"]["addresses"]["county_district"],
        "home_district" => params["person"]["addresses"]["address2"]
      },

      "birthdate" => person.birthdate.to_date.strftime("%Y-%m-%d"),
      "identifiers" => {},
      "birthdate_estimated" => (person.birthdate_estimated.to_i == 1)
    }

    headers = {:content_type => "json", :Authorization => dde_token }
    received_params = RestClient.post(dde_address, passed_params, headers=headers){|response, request, result|response}
    results = JSON.parse(received_params)
    return results
  end

  def self.create_local_patient_from_dde(data)
    city_village = data["attributes"]["current_village"]
    state_province = data["attributes"]["current_district"]
    neighborhood_cell = data["attributes"]["home_village"]
    county_district = data["attributes"]["home_traditional_authority"]
    address1 = data["attributes"]["current_village"]
    address2 = data["attributes"]["home_district"]


    demographics = {
      "person" =>
        {
        "occupation" => (data['attributes']['occupation'] rescue nil) ,
        "cell_phone_number" => (data['attributes']['cellphone_number'] rescue nil),
        "home_phone_number" => (data['attributes']['homephone_number'] rescue nil),
        "identifiers" => {"National id" => data["npid"]},
        "addresses"=>{
          "address1"=>address1,
          "address2"=>address2,
          "city_village"=>city_village,
          "state_province"=>state_province,
          "neighborhood_cell"=>neighborhood_cell,
          "county_district"=>county_district
        },

        "age_estimate" => data["birthdate_estimated"] ,
        "birth_month"=> data["birthdate"].to_date.month ,
        "patient" =>{"identifiers"=>
            {"National id"=> data["npid"] }
        },
        "gender" => data["gender"] ,
        "birth_day" => data["birthdate"].to_date.day ,
        "names"=>
          {
          "family_name" => (data['family_name'] rescue nil) ,
          "given_name" => (data['given_name'] rescue nil)
        },
        "birth_year" => data["birthdate"].to_date.year }
    }

    person = ""
    ActiveRecord::Base.transaction do
      person = PatientService.create_from_form(demographics["person"])
      self.create_dde_document_id(person, data["doc_id"])
    end

    return person
  end

  def self.create_dde_document_id(person, doc_id)
    patient_identifier_type = PatientIdentifierType.find_by_name("DDE person document ID")
    patient_identifier_type_id = patient_identifier_type.id

    patient_identifier = PatientIdentifier.new
    patient_identifier.patient_id = person.person_id
    patient_identifier.identifier_type = patient_identifier_type_id

    patient_identifier.identifier = doc_id
    patient_identifier.save
  end

  def self.generate_dde_demographics(data)
    cell_phone_number = data["person"]["attributes"]["cell_phone_number"]

    occupation = data["person"]["attributes"]["occupation"]

    middle_name = data["person"]["names"]["middle_name"]
    identifiers = data["person"]["patient"]["identifiers"]

    person = Person.new
    if data["person"]["birth_year"] == "Unknown"
      self.set_birthdate_by_age(person, data["person"]['age_estimate'], Date.today)
    else
      self.set_birthdate(person, data["person"]["birth_year"], data["person"]["birth_month"], data["person"]["birth_day"])
    end

    unless data["person"]['birthdate_estimated'].blank?
      person.birthdate_estimated = data["person"]['birthdate_estimated'].to_i
    end

    home_ta = data["person"]["addresses"]["county_district"]

    home_district = data["person"]["addresses"]["address2"]

    demographics = {
      "family_name" => data["person"]["names"]["family_name"],
      "given_name" => data["person"]["names"]["given_name"],
      "middle_name" => middle_name,
      "gender" => data["person"]["gender"].first,
      "birthdate_estimated" => (person.birthdate_estimated.to_i == 1),
      "attributes" => {
        "occupation" => occupation,
        "cellphone_number" => cell_phone_number,
        "current_village" => data["person"]["addresses"]["city_village"],
        "current_traditional_authority" => "N/A",
        "current_district" => data["person"]["addresses"]["state_province"],

        "home_village" => data["person"]["addresses"]["neighborhood_cell"],
        "home_traditional_authority" => home_ta,
        "home_district" => home_district
      },
      "birthdate" => person.birthdate.to_date.strftime("%Y-%m-%d"),
      "identifiers" => identifiers
    }

    return demographics
  end

  def self.generate_dde_data_to_be_updated(person, dde_token)
    data = PatientService.demographics(person)
    gender = {'M' => 'Male', 'F' => 'Female'}

    #occupation = data["person"]["attributes"]["occupation"]
    #occupation = "Unknown" if occupation.blank?

    middle_name = data["person"]["names"]["middle_name"]
    middle_name = "N/A" if middle_name.blank?

    npid = data["person"]["patient"]["identifiers"]["National id"]
    #old_npid = data["person"]["patient"]["identifiers"]["Old Identification Number"]
    #cell_phone_number = data["person"]["attributes"]["cell_phone_number"]
    #occupation = data["person"]["attributes"]["occupation"]
    #home_phone_number = data["person"]["attributes"]["home_phone_number"]
    #office_phone_number = data["person"]["attributes"]["office_phone_number"]

    #attributes = {}
    #attributes["cell_phone_number"] = cell_phone_number unless cell_phone_number.blank?
    #attributes["occupation"] = occupation unless occupation.blank?
    #attributes["home_phone_number"] = home_phone_number unless home_phone_number.blank?
    #attributes["office_phone_number"] = office_phone_number unless office_phone_number.blank?

    #identifiers = {}
    #identifiers["Old Identification Number"] = old_npid unless old_npid.blank?
    #identifiers["National id"] = old_npid unless npid.blank?

    identifiers =  self.patient_identifier_map(person)
    attributes =  self.person_attributes_map(person)

    home_ta = data["person"]["addresses"]["county_district"]
    home_ta = "Other" if home_ta.blank?

    home_district = data["person"]["addresses"]["address2"]
    home_district = "Other" if home_district.blank?

    demographics = {
      "npid" => npid,
      "family_name" => data["person"]["names"]["family_name"],
      "given_name" => data["person"]["names"]["given_name"],
      "middle_name" => middle_name,
      "gender" => gender[data["person"]["gender"]],
      "attributes" => attributes,
      "birthdate" => person.birthdate.to_date.strftime("%Y-%m-%d"),
      "identifiers" => identifiers,
      "birthdate_estimated" => (person.birthdate_estimated.to_i == 1),
      "current_residence" => data["person"]["addresses"]["city_village"],
      "current_village" => data["person"]["addresses"]["city_village"],
      "current_ta" => "N/A",
      "current_district" => data["person"]["addresses"]["state_province"],

      "home_village" => data["person"]["addresses"]["neighborhood_cell"],
      "home_ta" => home_ta,
      "home_district" => home_district,
      "token" => dde_token
    }.delete_if{|k, v|v.to_s.blank?}

    return demographics
  end

  def self.add_dde_patient_after_search_by_identifier(data, token)
    dde_address = "#{dde_settings["dde_address"]}/v1/add_person"
    headers = {:content_type => "json", :Authorization => token }
    received_params = RestClient.post(dde_address, data, headers = headers){|response, request, result|response}
    received_params = JSON.parse(received_params)
    return received_params
  end

  def self.add_dde_patient_after_search_by_name(data, token)
    dde_address = "#{dde_settings["dde_address"]}/v1/add_person"
    headers = {:content_type => "json", :Authorization => token }
    received_params = RestClient.post(dde_address, data, headers = headers){|response, request, result|response}
    received_params = JSON.parse(received_params)
    return received_params
  end

  def self.merge_dde_patients(primary_pt_demographics, secondary_pt_demographics, dde_token)
    data = {
      "primary_record" => primary_pt_demographics,
      "secondary_record" => secondary_pt_demographics,
      "token" => dde_token
    }

    dde_address = "#{dde_settings["dde_address"]}/v1/merge_records"
    headers = {:content_type => "json" }
    received_params = RestClient.post(dde_address, data.to_json, headers)
    results = JSON.parse(received_params)
    return results
  end

  def self.assign_new_dde_npid(person, old_npid, new_npid)
    national_patient_identifier_type_id = PatientIdentifierType.find_by_name("National id").patient_identifier_type_id
    old_patient_identifier_type_id = PatientIdentifierType.find_by_name("Old Identification Number").patient_identifier_type_id

    patient_national_identifier = person.patient.patient_identifiers.find(:last, :conditions => ["identifier_type =?",
        national_patient_identifier_type_id])

    ActiveRecord::Base.transaction do
      new_old_identification_identifier = person.patient.patient_identifiers.new
      new_old_identification_identifier.identifier_type = old_patient_identifier_type_id
      new_old_identification_identifier.identifier = old_npid
      new_old_identification_identifier.save

      new_national_identification_identifier = person.patient.patient_identifiers.new
      new_national_identification_identifier.identifier_type = national_patient_identifier_type_id
      new_national_identification_identifier.identifier = new_npid
      new_national_identification_identifier.save

      patient_national_identifier.void
    end

    return new_npid
  end

  def self.dde_openmrs_address_map
    data = {
      "city_village" => "current_residence",
      "state_province" => "current_district",
      "neighborhood_cell" => "home_village",
      "county_district" => "home_ta",
      "address2" => "home_district",
      "address1" => "current_residence"
    }
    return data
  end

  def self.patient_identifier_map(person)
    identifier_map = {}
    patient_identifiers = person.patient.patient_identifiers
    patient_identifiers.each do |pt|
      key = pt.type.name
      value = pt.identifier
      next if value.blank?
      identifier_map[key] = value
    end
    return identifier_map
  end

  def self.person_attributes_map(person)
    attributes_map = {}
    person_attributes = person.person_attributes
    person_attributes.each do |pa|
      key = pa.type.name.downcase.gsub(/\s/,'_') #From Home Phone Number to home_phone_number
      value = pa.value
      next if value.blank?
      attributes_map[key] = value
    end
    return attributes_map
  end

  def self.update_local_demographics_from_dde(person, data)
    names = data["names"]
    #identifiers = data["patient"]["identifiers"] rescue {}
    addresses = data["addresses"]
    attributes = data["attributes"]
    birthdate = data["birthdate"]
    birthdate_estimated = data["birthdate_estimated"]
    gender = data["gender"]

    person_name = person.names[0]
    person_address = person.addresses[0]


    city_village = addresses["current_residence"] rescue nil
    state_province = addresses["current_district"] rescue nil
    neighborhood_cell = addresses["home_village"] rescue nil
    county_district = addresses["home_ta"] rescue nil
    address2 = addresses["home_district"] rescue nil
    address1 = addresses["current_residence"] rescue nil

    person.update_attributes({
        :gender => gender,
        :birthdate => birthdate.to_date,
        :birthdate_estimated => birthdate_estimated
      })

    person_name.given_name = names["given_name"]
    person_name.middle_name = names["middle_name"]
    person_name.family_name = names["family_name"]
    person_name.save

    person_address.address1 = address1
    person_address.address2 = address2
    person_address.city_village = city_village
    person_address.county_district = county_district
    person_address.state_province = state_province
    person_address.neighborhood_cell = neighborhood_cell
    person_address.save

    (attributes || {}).each do |key, value|
      person_attribute_type = PersonAttributeType.find_by_name(key)
      next if person_attribute_type.blank?
      person_attribute_type_id = person_attribute_type.id
      person_attrib = person.person_attributes.find_by_person_attribute_type_id(person_attribute_type_id)

      if person_attrib.blank?
        person_attrib = PersonAttribute.new
        person_attrib.person_id = person.person_id
        person_attrib.person_attribute_type_id = person_attribute_type_id
      end

      person_attrib.value = value
      person_attrib.save
    end
  end

  def self.create_local_person(dde_person)

		given_name             =  dde_person['given_name']
		family_name            =  dde_person['family_name']
		gender                 =  dde_person['gender']
		birthdate              =  dde_person['birthdate']
		birthdate_estimated    =  dde_person['birthdate_estimated']
		home_district          =  dde_person['attributes']['home_district']
		home_ta                =  dde_person['attributes']['home_traditional_authority']
		home_village           =  dde_person['attributes']['home_village']
		current_residence      =  dde_person['attributes']['current_village']

		npid                   =  dde_person['npid']
		doc_id                 =  dde_person['doc_id']

		people = self.search_local_by_identifier(doc_id)
		return people unless people.blank?

		people = self.search_local_by_identifier(npid) unless npid.blank?

		if people.blank?
			return [self.create_local_patient_from_dde(dde_person)]
		end

		if people.length == 1
			name = people.first.names.last

			if (given_name.to_s.downcase != name.given_name.to_s.downcase)
				return nil
			elsif (family_name.to_s.downcase != name.family_name.to_s.downcase)
				return nil
			elsif (people.last.gender.to_s.downcase.first != gender.first.to_s.downcase)
				return nil
			elsif (birthdate.to_date != people.last.birthdate.to_date)
				return nil
			end

			PatientIdentifier.create(:identifier => doc_id, :patient_id => people.last.person_id,
				:identifier_type => PatientIdentifierType.find_by_name('DDE person document ID').id)
	
			return people
		end

		return nil
  end
  
  def self.get_patient_identifier(patient, identifier_type)
    patient_identifier_type_id = PatientIdentifierType.find_by_name(identifier_type).patient_identifier_type_id rescue nil
    patient_identifier = PatientIdentifier.find(:first, :select => "identifier",
      :conditions  =>["patient_id = ? and identifier_type = ?", patient.id, patient_identifier_type_id],
      :order => "date_created DESC" ).identifier rescue nil
    return patient_identifier
  end
  
  def self.get_attribute(person, attribute)
    PersonAttribute.find(:first,:conditions =>["voided = 0 AND person_attribute_type_id = ? AND person_id = ?",
        PersonAttributeType.find_by_name(attribute).id, person.id]).value rescue nil
  end


end

