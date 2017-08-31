class GenericPeopleController < ApplicationController
    
	def index
		redirect_to "/clinic"
	end

	def new
		@occupations = occupations
	end

	def identifiers
	end

  def create_confirm
    @search_results = {}                                                        
    @patients = []
     
    (PatientService.search_demographics_from_remote(params[:user_entered_params]) || []).each do |data|            
      national_id = data["person"]["data"]["patient"]["identifiers"]["National id"] rescue nil
      national_id = data["person"]["value"] if national_id.blank? rescue nil    
      national_id = data["npid"]["value"] if national_id.blank? rescue nil      
      national_id = data["person"]["data"]["patient"]["identifiers"]["old_identification_number"] if national_id.blank? rescue nil
                                                                              
      next if national_id.blank?                                                
      results = PersonSearch.new(national_id)                                   
      results.national_id = national_id                                         
      results.current_residence = data["person"]["data"]["addresses"]["city_village"]
      results.person_id = 0                                                     
      results.home_district = data["person"]["data"]["addresses"]["address2"]   
      results.neighborhood_cell = data["person"]["data"]["addresses"]["neighborhood_cell"]   
      results.traditional_authority =  data["person"]["data"]["addresses"]["county_district"]
      results.name = data["person"]["data"]["names"]["given_name"] + " " + data["person"]["data"]["names"]["family_name"]
      gender = data["person"]["data"]["gender"]                                 
      results.occupation = data["person"]["data"]["occupation"]                 
      results.sex = (gender == 'M' ? 'Male' : 'Female')                         
      results.birthdate_estimated = (data["person"]["data"]["birthdate_estimated"]).to_i
      results.birth_date = birthdate_formatted((data["person"]["data"]["birthdate"]).to_date , results.birthdate_estimated)
      results.birthdate = (data["person"]["data"]["birthdate"]).to_date         
      results.age = cul_age(results.birthdate.to_date , results.birthdate_estimated)
      @search_results[results.national_id] = results                            
    end if create_from_dde_server

    (params[:people_ids] || []).each do |person_id|
      patient = PatientService.get_patient(Person.find(person_id))

      results = PersonSearch.new(patient.national_id || patient.patient_id)     
      results.national_id = patient.national_id                                 
      results.birth_date = patient.birth_date                                   
      results.current_residence = patient.current_residence                     
      results.guardian = patient.guardian                                       
      results.person_id = patient.person_id                                     
      results.home_district = patient.home_district                             
      results.neighborhood_cell = patient.home_village                            
      results.current_district = patient.current_district                       
      results.traditional_authority = patient.traditional_authority             
      results.mothers_surname = patient.mothers_surname                         
      results.dead = patient.dead                                               
      results.arv_number = patient.arv_number                                   
      results.eid_number = patient.eid_number                                   
      results.pre_art_number = patient.pre_art_number                           
      results.name = patient.name                                               
      results.sex = patient.sex                                                 
      results.age = patient.age                                                 
      @search_results.delete_if{|x,y| x == results.national_id }
      @patients << results
    end

    (@search_results || {}).each do | npid , data |
      @patients << data
    end

    @parameters = params[:user_entered_params]
    render :layout => 'menu'
  end

	def create_remote
		person_params = {"occupation"=> params[:occupation],
			"age_estimate"=> params['patient_age']['age_estimate'],
			"cell_phone_number"=> params['cell_phone']['identifier'],
			"birth_month"=> params[:patient_month],
			"addresses"=>{ "address2" => params['p_address']['identifier'],
        "address1" => params['p_address']['identifier'],
        "city_village"=> params['patientaddress']['city_village'],
        "county_district"=> params[:birthplace] },
			"gender" => params['patient']['gender'],
			"birth_day" => params[:patient_day],
			"names"=> {"family_name2"=>"Unknown",
        "family_name"=> params['patient_name']['family_name'],
        "given_name"=> params['patient_name']['given_name'] },
			"birth_year"=> params[:patient_year] }

		#raise person_params.to_yaml
		if current_user.blank?
		  user = User.authenticate('admin', 'test')
		  sign_in(:user, user) if !user.blank?
      set_current_user		  
		end rescue []

		if Location.current_location.blank?
			Location.current_location = Location.find(CoreService.get_global_property_value('current_health_center_id'))
		end rescue []

		person = PatientService.create_from_form(person_params)
		if person
			patient = Patient.new()
			patient.patient_id = person.id
			patient.save
			PatientService.patient_national_id_label(patient)
		end
		render :text => PatientService.remote_demographics(person).to_json
	end

	def remote_demographics
		# Search by the demographics that were passed in and then return demographics
		people = PatientService.find_person_by_demographics(params)
		result = people.empty? ? {} : PatientService.demographics(people.first)
		render :text => result.to_json
	end
  
	def art_information
		national_id = params["person"]["patient"]["identifiers"]["National id"] rescue nil
    national_id = params["person"]["patient"] if national_id.blank? rescue nil
		art_info = Patient.art_info_for_remote(national_id)
		art_info = art_info_for_remote(national_id)
		render :text => art_info.to_json
	end
  
  def search
    found_person = nil
    if params[:identifier]
      local_results = PatientService.search_by_identifier(params[:identifier])

			if local_results.blank? and (params[:identifier].match(/#{Location.current_health_center.neighborhood_cell}-ARV/i) || params[:identifier].match(/-TB/i))
				flash[:notice] = "No matching person found with number #{params[:identifier]}"
				redirect_to :action => 'find_by_tb_number' if params[:identifier].match(/-TB/i)
				redirect_to :action => 'find_by_arv_number' if params[:identifier].match(/#{Location.current_health_center.neighborhood_cell}-ARV/i)
			end

      if local_results.length > 1
        redirect_to :action => 'duplicates' ,:search_params => params
        return
      elsif local_results.length == 1
        ####################################################hack to handle duplicates ########################################################
        person_to_be_chcked = PatientService.demographics(Person.find(local_results.first[:person_id].to_i))
        if CoreService.get_global_property_value('search.from.remote.app').to_s == 'true'
          remote_app_address = CoreService.get_global_property_value('remote.app.address').to_s
          uri = "http://#{remote_app_address}/check_for_duplicates/remote_app_search"
          search_from_remote_params =  {"identifier" => params[:identifier],
            "given_name" => person_to_be_chcked['person']['names']['given_name'],
            "family_name" => person_to_be_chcked['person']['names']['family_name'],
            "gender" => person_to_be_chcked['person']['gender'] }

          output = RestClient.post(uri,search_from_remote_params) rescue []
          remote_result = JSON.parse(output) rescue []
          unless remote_result.blank?
            redirect_to :controller =>'check_for_duplicates', :action => 'view',
              :identifier => params[:identifier] and return
          end
        end
        #################################################### end of: hack to handle duplicates ########################################################

        if create_from_dde_server
          dde_search_results = PatientService.search_dde_by_identifier(params[:identifier], session[:dde_token])
          dde_hits = dde_search_results["data"]["hits"] rescue []
          old_npid = person_to_be_chcked["person"]["patient"]["identifiers"]["National id"] #No need for rescue here. Let it crash so that we know the problem

          ####################### REPLACING DDE TEMP ID ########################
          if (dde_hits.length  == 1)
            new_npid = dde_hits[0]["npid"]
            #new National ID assignment
            #There is a need to check the validity of the patient national ID before being marked as old ID

            if (old_npid != new_npid) #if DDE has returned a new ID, Let's assume it is right
              p = Person.find(local_results.first[:person_id].to_i)
              PatientService.assign_new_dde_npid(p, old_npid, new_npid)
              national_id_replaced = true
            end

            PatientService.update_local_demographics_from_dde(Person.find(local_results.first[:person_id].to_i), dde_hits[0]) rescue nil
          end
          ######################## REPLACING DDE TEMP ID END####################

          if dde_hits.length > 1
            #Locally available and remotely available + duplicates
            redirect_to("/people/dde_duplicates?npid=#{params[:identifier]}") and return
          end

          if dde_hits.length == 0
            #Locally available and remotely NOT available
            old_npid = params[:identifier]
            person = Person.find(local_results.first[:person_id].to_i)
            dde_demographics = PatientService.generate_dde_demographics(person_to_be_chcked, session[:dde_token])
            #dde_demographics = {"person" => dde_demographics}
            dde_response = PatientService.add_dde_patient_after_search_by_identifier(dde_demographics)
            dde_status = dde_response["status"]

            if dde_status.to_s == '201'
              new_npid = dde_response["data"]["npid"]
            end

            if dde_status.to_s == '409' #conflict
              dde_return_path = dde_response["return_path"]
              dde_response = PatientService.add_dde_conflict_patient(dde_return_path, dde_demographics, session[:dde_token])
              new_npid = dde_response["data"]["npid"]
            end

            PatientService.assign_new_dde_npid(person, old_npid, new_npid)
            national_id_replaced = true
          end
        end
        found_person = local_results.first
      else
        # TODO - figure out how to write a test for this
        # This is sloppy - creating something as the result of a GET

        if create_from_dde_server
          #Results not found locally
          dde_search_results = PatientService.search_dde_by_identifier(params[:identifier], session[:dde_token])
          dde_hits = dde_search_results["data"]["hits"] rescue []
          if dde_hits.length == 1
            found_person = PatientService.create_local_patient_from_dde(dde_hits[0])
          end

          if dde_hits.length > 1
            redirect_to("/people/dde_duplicates") and return
          end

        end

        if create_from_remote
          found_person_data = PatientService.find_remote_person_by_identifier(params[:identifier])
          found_person = PatientService.create_from_form(found_person_data['person']) unless found_person_data.blank?
        end
      end

      if found_person

        if params[:relation]
          redirect_to search_complete_url(found_person.id, params[:relation]) and return
        elsif national_id_replaced.to_s == "true"
          #creating patient's footprint so that we can track them later when they visit other sites
          #DDEService.create_footprint(PatientService.get_patient(found_person).national_id, "ART - #{ART_VERSION}")
          print_and_redirect("/patients/national_id_label?patient_id=#{found_person.id}", next_task(found_person.patient)) and return
          redirect_to :action => 'confirm', :found_person_id => found_person.id, :relation => params[:relation] and return
        else
          #creating patient's footprint so that we can track them later when they visit other sites
          #DDEService.create_footprint(PatientService.get_patient(found_person).national_id, "ART - #{ART_VERSION}")
          redirect_to :action => 'confirm',:found_person_id => found_person.id, :relation => params[:relation] and return
        end
      end
    end

    @relation = params[:relation]
    @people = PatientService.person_search(params)
    @search_results = {}
    @patients = []

    (PatientService.search_dde_by_name_and_gender(params, session[:dde_token]) || []).each do |data|
      national_id = data["npid"]
      next if national_id.blank?
      results = PersonSearch.new(national_id)
      results.national_id = national_id

      unless data["addresses"]["home_ta"].blank?
        results.traditional_authority = data["addresses"]["home_ta"]
      else
        results.traditional_authority = nil
      end

      unless data["addresses"]["home_district"].blank?
        results.home_district = data["addresses"]["home_district"]
      else
        results.home_district = nil
      end

      unless data["addresses"]["current_residence"].blank?
        results.current_residence =  data["addresses"]["current_residence"]
      else
        results.current_residence = nil
      end


      results.person_id = 0
      results.name = data["names"]["given_name"] + " " + data["names"]["family_name"]
      gender = data["gender"]
      results.occupation = (data["attributes"]["occupation"] rescue nil)
      results.sex = (gender == 'M' ? 'Male' : 'Female')
      results.birthdate_estimated = (data["birthdate_estimated"]).to_i
      results.birth_date = birthdate_formatted((data["birthdate"]).to_date , results.birthdate_estimated)
      results.birthdate = (data["birthdate"]).to_date
      results.age = cul_age(results.birthdate.to_date , results.birthdate_estimated)
      @search_results[results.national_id] = results
    end if create_from_dde_server

    (@people || []).each do | person |
      patient = PatientService.get_patient(person) rescue nil
      next if patient.blank?
      results = PersonSearch.new(patient.national_id || patient.patient_id)
      results.national_id = patient.national_id
      results.birth_date = patient.birth_date
      results.current_residence = patient.current_residence
      results.guardian = patient.guardian
      results.person_id = patient.person_id
      results.home_district = patient.home_district
      results.current_district = patient.current_district
      results.traditional_authority = patient.traditional_authority
      results.mothers_surname = patient.mothers_surname
      results.dead = patient.dead
      results.arv_number = patient.arv_number
      results.eid_number = patient.eid_number
      results.pre_art_number = patient.pre_art_number
      results.name = patient.name
      results.sex = patient.sex
      results.age = patient.age
      @search_results.delete_if{|x,y| x == results.national_id }
      @patients << results
    end

		(@search_results || {}).each do | npid , data |
			@patients << data
		end
	end

  def search_from_dde
		found_person = PatientService.person_search_from_dde(params)
    if found_person
      if params[:relation]
        redirect_to search_complete_url(found_person.id, params[:relation]) and return
      else
        redirect_to :action => 'patient_dashboard',:controller =>'patients',
          :found_person_id => found_person.id,
          :relation => params[:relation] and return
      end
    else
      redirect_to :action => 'search' and return
    end
  end
   
	def confirm
		session_date = session[:datetime] || Date.today
		if request.post?
			redirect_to search_complete_url(params[:found_person_id], params[:relation]) and return
		end
		@found_person_id = params[:found_person_id] 
		@relation = params[:relation]
		@person = Person.find(@found_person_id) rescue nil
    @current_hiv_program_state = PatientProgram.find(:first, :joins => :location, :conditions => ["program_id = ? AND patient_id = ? AND location.location_id = ?", Program.find_by_concept_id(Concept.find_by_name('HIV PROGRAM').id).id,@person.patient, Location.current_health_center]).patient_states.last.program_workflow_state.concept.fullname rescue ''
    @transferred_out = @current_hiv_program_state.upcase == "PATIENT TRANSFERRED OUT"? true : nil
    defaulter = Patient.find_by_sql("SELECT current_defaulter(#{@person.patient.patient_id}, '#{session_date}') 
                                     AS defaulter 
                                     FROM patient_program LIMIT 1")[0].defaulter rescue 0
    @defaulted = defaulter == 0 ? nil : true     
    @task = main_next_task(Location.current_location, @person.patient, session_date.to_date)
		@arv_number = PatientService.get_patient_identifier(@person, 'ARV Number')
		@patient_bean = PatientService.get_patient(@person)                                                             
    render :layout => false	
	end

	def tranfer_patient_in
		@data_demo = {}
		if request.post?
			params[:data].split(',').each do | data |
				if data[0..4] == "Name:"
					@data_demo['name'] = data.split(':')[1]
					next
				end
				if data.match(/guardian/i)
					@data_demo['guardian'] = data.split(':')[1]
					next
				end
				if data.match(/sex/i)
					@data_demo['sex'] = data.split(':')[1]
					next
				end
				if data[0..3] == 'DOB:'
					@data_demo['dob'] = data.split(':')[1]
					next
				end
				if data.match(/National ID:/i)
					@data_demo['national_id'] = data.split(':')[1]
					next
				end
				if data[0..3] == "BMI:"
					@data_demo['bmi'] = data.split(':')[1]
					next
				end
				if data.match(/ARV number:/i)
					@data_demo['arv_number'] = data.split(':')[1]
					next
				end
				if data.match(/Address:/i)
					@data_demo['address'] = data.split(':')[1]
					next
				end
				if data.match(/1st pos HIV test site:/i)
					@data_demo['first_positive_hiv_test_site'] = data.split(':')[1]
					next
				end
				if data.match(/1st pos HIV test date:/i)
					@data_demo['first_positive_hiv_test_date'] = data.split(':')[1]
					next
				end
				if data.match(/FU:/i)
					@data_demo['agrees_to_followup'] = data.split(':')[1]
					next
				end
				if data.match(/1st line date:/i)
					@data_demo['date_of_first_line_regimen'] = data.split(':')[1]
					next
				end
				if data.match(/SR:/i)
					@data_demo['reason_for_art_eligibility'] = data.split(':')[1]
					next
				end
			end
		end
		render :layout => "menu"
	end

	# This method is just to allow the select box to submit, we could probably do this better
	def select
    if !params[:person][:patient][:identifiers]['National id'].blank? &&
        !params[:person][:names][:given_name].blank? &&
        !params[:person][:names][:family_name].blank?
      redirect_to :action => :search, :identifier => params[:person][:patient][:identifiers]['National id']
      return
    end rescue nil

    if !params[:identifier].blank? && !params[:given_name].blank? && !params[:family_name].blank?
      redirect_to :action => :search, :identifier => params[:identifier]
    elsif params[:person][:id] != '0' && Person.find(params[:person][:id]).dead == 1
      redirect_to :controller => :patients, :action => :show, :id => params[:person][:id]
    else
      if params[:person][:id] != '0'

        person = Person.find(params[:person][:id])
        #patient = DDEService::Patient.new(person.patient)
        patient_id = PatientService.get_patient_identifier(person.patient, "National id")
        old_npid = patient_id

        if create_from_dde_server
          unless params[:patient_guardian].blank?
            print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", "/patients/guardians_dashboard/#{person.id}") and return
					end
          demographics = PatientService.demographics(person)
          dde_demographics = PatientService.generate_dde_demographics(demographics, session[:dde_token])
          #check if patient is not in DDE first
          dde_search_results = PatientService.search_dde_by_identifier(old_npid, session[:dde_token])
          dde_hits = dde_search_results["data"]["hits"] rescue []
          patient_exists_in_dde = dde_hits.length > 0

          if (dde_hits.length == 1)
            new_npid =  dde_hits[0]["npid"]
            if (old_npid != new_npid)
              PatientService.assign_new_dde_npid(person, old_npid, new_npid)
              print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient)) and return
            end
          end
          
          if !patient_exists_in_dde
            dde_response = PatientService.add_dde_patient_after_search_by_name(dde_demographics)

            dde_status = dde_response["status"]

            if dde_status.to_s == '201' #created
              new_npid = dde_response["data"]["npid"]
              #new National ID assignment
              #There is a need to check the validity of the patient national ID before being marked as old ID

              if (old_npid != new_npid)
                PatientService.assign_new_dde_npid(person, old_npid, new_npid)
              end
              print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient)) and return
            end

            if dde_status.to_s == '409' #conflict
              dde_return_path = dde_response["return_path"]
              data = {}
              data["return_path"] = dde_return_path
              data["data"] = dde_response["data"]
              data["params"] = demographics
              session[:dde_conflicts] = data
              redirect_to("/people/display_dde_conflicts") and return
              #PatientService.add_dde_conflict_patient(dde_return_path, params, session[:dde_token])
            end
          end
          #creating patient's footprint so that we can track them later when they visit other sites
          #DDEService.create_footprint(PatientService.get_patient(person).national_id, "ART - #{ART_VERSION}")
        end

      end
      redirect_to search_complete_url(params[:person][:id], params[:relation]) and return unless params[:person][:id].blank? || params[:person][:id] == '0'

      redirect_to :action => :new, :gender => params[:gender],
        :given_name => params[:given_name], :family_name => params[:family_name],
        :family_name2 => params[:family_name2], :address2 => params[:address2],
        :identifier => params[:identifier], :relation => params[:relation]
    end
	end
 
  def create
    #raise params.inspect
    #raise session[:dde_token].inspect
    if confirm_before_creating and not params[:force_create] == 'true' and params[:relation].blank?
      @parameters = params
      birthday_params = params.reject{|key,value| key.match(/gender/) }
      unless birthday_params.empty?
        if params[:person]['birth_year'] == "Unknown"
          birthdate = Date.new(Date.today.year - params[:person]["age_estimate"].to_i, 7, 1)
        else
          year = params[:person]["birth_year"].to_i
          month = params[:person]["birth_month"]
          day = params[:person]["birth_day"].to_i

          month_i = (month || 0).to_i
          month_i = Date::MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
          month_i = Date::ABBR_MONTHNAMES.index(month) if month_i == 0 || month_i.blank?

          if month_i == 0 || month == "Unknown"
            birthdate = Date.new(year.to_i,7,1)
          elsif day.blank? || day == "Unknown" || day == 0
            birthdate = Date.new(year.to_i,month_i,15)
          else
            birthdate = Date.new(year.to_i,month_i,day.to_i)
          end
        end
      end

      start_birthdate = (birthdate - 5.year)
      end_birthdate   = (birthdate + 5.year)

      given_name_code = @parameters[:person][:names]['given_name'].soundex
      family_name_code = @parameters[:person][:names]['family_name'].soundex
      gender = @parameters[:person]['gender']
      ta = @parameters[:person][:addresses]['county_district']
      home_district = @parameters[:person][:addresses]['address2']
      home_village = @parameters[:person][:addresses]['neighborhood_cell']

      people = Person.find(:all,:joins =>"INNER JOIN person_name pn
       ON person.person_id = pn.person_id
       INNER JOIN person_name_code pnc ON pnc.person_name_id = pn.person_name_id
       INNER JOIN person_address pad ON pad.person_id = person.person_id",
        :conditions =>["(pad.address2 LIKE (?) OR pad.county_district LIKE (?)
       OR pad.neighborhood_cell LIKE (?)) AND pnc.given_name_code LIKE (?)
       AND pnc.family_name_code LIKE (?) AND person.gender = '#{gender}'
       AND (person.birthdate >= ? AND person.birthdate <= ?)","%#{home_district}%",
          "%#{ta}%","%#{home_village}%","%#{given_name_code}%","%#{family_name_code}%",
          start_birthdate,end_birthdate],:group => "person.person_id")

      if people
        people_ids = []
        (people).each do |person|
          people_ids << person.id
        end
      end


      #............................................................................
      @dde_search_results = {}
      (PatientService.search_demographics_from_remote(params) || []).each do |data|
        national_id = data["person"]["data"]["patient"]["identifiers"]["National id"] rescue nil
        national_id = data["person"]["value"] if national_id.blank? rescue nil
        national_id = data["npid"]["value"] if national_id.blank? rescue nil
        national_id = data["person"]["data"]["patient"]["identifiers"]["old_identification_number"] if national_id.blank? rescue nil

        next if national_id.blank?
        results = PersonSearch.new(national_id)
        results.national_id = national_id
        results.current_residence = data["person"]["data"]["addresses"]["city_village"]
        results.person_id = 0
        results.home_district = data["person"]["data"]["addresses"]["address2"]
        results.neighborhood_cell = data["person"]["data"]["addresses"]["neighborhood_cell"]
        results.traditional_authority =  data["person"]["data"]["addresses"]["county_district"]
        results.name = data["person"]["data"]["names"]["given_name"] + " " + data["person"]["data"]["names"]["family_name"]
        gender = data["person"]["data"]["gender"]
        results.occupation = data["person"]["data"]["occupation"]
        results.sex = (gender == 'M' ? 'Male' : 'Female')
        results.birthdate_estimated = (data["person"]["data"]["birthdate_estimated"]).to_i
        results.birth_date = birthdate_formatted((data["person"]["data"]["birthdate"]).to_date , results.birthdate_estimated)
        results.birthdate = (data["person"]["data"]["birthdate"]).to_date
        results.age = cul_age(results.birthdate.to_date , results.birthdate_estimated)
        @dde_search_results[results.national_id] = results
        break
      end if create_from_dde_server
      #............................................................................
      #if params
      if not people_ids.blank? or not @dde_search_results.blank?
        redirect_to :action => :create_confirm , :people_ids => people_ids ,
          :user_entered_params => @parameters and return
      end
    end

    hiv_session = false
    if current_program_location == "HIV program"
      hiv_session = true
    end
    success = false

    Person.session_datetime = session[:datetime].to_date rescue Date.today
    identifier = params[:identifier] rescue nil

    if identifier.blank?
      identifier = params[:person][:patient][:identifiers]['National id']
    end rescue nil

    if create_from_dde_server
      unless identifier.blank?
        #params[:person].merge!({"identifiers" => {"National id" => identifier}})
        success = true
        #person = PatientService.create_from_form(params[:person])
        if identifier.length != 6
          #patient = DDEService::Patient.new(person.patient)
          #national_id_replaced = patient.check_old_national_id(identifier)
        end
      else
        # person = PatientService.create_patient_from_dde(params)
        dde_response = PatientService.add_dde_patient(params, session[:dde_token])
        dde_status = dde_response["status"]

        if dde_status.to_s == '201'
          npid = dde_response["data"]["npid"]
          params["person"].merge!({"identifiers" => {"National id" => npid}})
          person = PatientService.create_from_form(params["person"])
        end

        if dde_status.to_s == '409' #conflict
          dde_return_path = dde_response["return_path"]
          data = {}
          data["return_path"] = dde_return_path
          data["data"] = dde_response["data"]
          data["params"] = params
          session[:dde_conflicts] = data
          redirect_to("/people/display_dde_conflicts") and return
          #PatientService.add_dde_conflict_patient(dde_return_path, params, session[:dde_token])
        end
        success = true
      end

      #If we are creating from DDE then we must create a footprint of the just created patient to
      #enable future
      DDEService.create_footprint(PatientService.get_patient(person).national_id, "OPD")


      #for now ART will use BART1 for patient/person creation until we upgrade BART1 to ART
      #if GlobalProperty.find_by_property('create.from.remote') and property_value == 'yes'
      #then we create person from remote machine
    elsif create_from_remote
      person_from_remote = PatientService.create_remote_person(params)
      person = PatientService.create_from_form(person_from_remote["person"]) unless person_from_remote.blank?

      if !person.blank?
        success = true
        PatientService.get_remote_national_id(person.patient)
      end
    else
      success = true
      params[:person].merge!({"identifiers" => {"National id" => identifier}}) unless identifier.blank?
      person = PatientService.create_from_form(params[:person])
    end

    if params[:person][:patient] && success
      PatientService.patient_national_id_label(person.patient)
      unless (params[:relation].blank?)
        redirect_to search_complete_url(person.id, params[:relation]) and return
      else
        print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
      end
    else
      # Does this ever get hit?
      redirect_to :action => "index"
    end 
  end

  def display_dde_conflicts
    @dde_conflicts = session[:dde_conflicts]["data"]
    @demographics = session[:dde_conflicts]["params"]
    render :layout => "menu"
  end

  def create_new_dde_conflict_patient
    dde_return_path = session[:dde_conflicts]["return_path"]
    dde_params = session[:dde_conflicts]["params"]
    dde_token = session[:dde_token]
    dde_response = PatientService.add_dde_conflict_patient(dde_return_path, dde_params, dde_token)
    npid = dde_response["data"]["npid"]
    dde_params["person"].merge!({"identifiers" => {"National id" => npid}})
    person = PatientService.create_from_form(dde_params["person"])
    print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
  end

  def create_dde_existing_patient_locally
    npid = params[:npid]
    dde_params = session[:dde_conflicts]["params"]
    dde_params["person"].merge!({"identifiers" => {"National id" => npid}})
    person = PatientService.create_from_form(dde_params["person"])
    print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
  end
  
  def set_datetime
    if request.post?
      unless params[:set_day]== "" or params[:set_month]== "" or params[:set_year]== ""
        # set for 1 second after midnight to designate it as a retrospective date
        date_of_encounter = Time.mktime(params[:set_year].to_i,
          params[:set_month].to_i,
          params[:set_day].to_i,0,0,1)
        session[:datetime] = date_of_encounter #if date_of_encounter.to_date != Date.today
      end
      unless params[:id].blank?
        redirect_to next_task(Patient.find(params[:id])) 
      else
        redirect_to :action => "index"
      end
    end
    @patient_id = params[:id]
  end

  def reset_datetime
    session[:datetime] = nil
    session[:date_reset] = true
    if params[:id].blank?
      redirect_to :action => "index" and return
    else
      redirect_to "/patients/show/#{params[:id]}" and return
    end
  end

  def find_by_arv_number
    if request.post?
      redirect_to :action => 'search' ,
        :identifier => "#{site_prefix}-ARV-#{params[:arv_number]}" and return
    end
  end
  
  # List traditional authority containing the string given in params[:value]
  def traditional_authority
    district_id = District.find_by_name("#{params[:filter_value]}").id
    traditional_authority_conditions = ["name LIKE (?) AND district_id = ?", "#{params[:search_string]}%", district_id]

    traditional_authorities = TraditionalAuthority.find(:all,:conditions => traditional_authority_conditions, :order => 'name')
    traditional_authorities = traditional_authorities.map do |t_a|
      "<li value='#{t_a.name}'>#{t_a.name}</li>"
    end
    render :text => traditional_authorities.join('') + "<li value='Other'>Other</li>" and return
  end

  # Regions containing the string given in params[:value]
  def region
    region_conditions = ["name LIKE (?)", "#{params[:value]}%"]

    regions = Region.find(:all,:conditions => region_conditions)
    regions = regions.map do |r|
      "<li value='#{r.name}'>#{r.name}</li>"
    end
    render :text => regions.join('') and return
  end

  # Districts containing the string given in params[:value]
  def district
    region_id = Region.find_by_name("#{params[:filter_value]}").id
    region_conditions = ["name LIKE (?) AND region_id = ? ", "#{params[:search_string]}%", region_id]

    districts = District.find(:all,:conditions => region_conditions, :order => 'name')
    districts = districts.map do |d|
      "<li value='#{d.name}'>#{d.name}</li>"
    end
    render :text => districts.join('') + "<li value='Other'>Other</li>" and return
  end

  def tb_initialization_district
    districts = District.find(:all, :order => 'name')
    districts = districts.map do |d|
      "<li value='#{d.name}'>#{d.name}</li>"
    end
    render :text => districts.join('') + "<li value='Other'>Other</li>" and return
  end

  # Villages containing the string given in params[:value]
  def village
    traditional_authority_id = TraditionalAuthority.find_by_name("#{params[:filter_value]}").id
    village_conditions = ["name LIKE (?) AND traditional_authority_id = ?", "#{params[:search_string]}%", traditional_authority_id]

    villages = Village.find(:all,:conditions => village_conditions, :order => 'name')
    villages = villages.map do |v|
      "<li value='#{v.name}'>#{v.name}</li>"
    end
    render :text => villages.join('') + "<li value='Other'>Other</li>" and return
  end
  
  # Landmark containing the string given in params[:value]
  def landmark
    landmarks = PersonAddress.find(:all, :select => "DISTINCT address1" , :conditions => ["city_village = (?) AND address1 LIKE (?)", "#{params[:filter_value]}", "#{params[:search_string]}%"])
    landmarks = landmarks.map do |v|
      "<li value='#{v.address1}'>#{v.address1}</li>"
    end
    render :text => landmarks.join('') + "<li value='Other'>Other</li>" and return
  end

=begin
  #This method was taken out of encounter model. It is been used in
  #people/index (view) which seems not to be used at present.
  def count_by_type_for_date(date)
    # This query can be very time consuming, because of this we will not consider
    # that some of the encounters on the specific date may have been voided
    ActiveRecord::Base.connection.select_all("SELECT count(*) as number, encounter_type FROM encounter GROUP BY encounter_type")
    todays_encounters = Encounter.find(:all, :include => "type", :conditions => ["DATE(encounter_datetime) = ?",date])
    encounters_by_type = Hash.new(0)
    todays_encounters.each{|encounter|
      next if encounter.type.nil?
      encounters_by_type[encounter.type.name] += 1
    }
    encounters_by_type
  end
=end

  def art_info_for_remote(national_id)

    patient = PatientService.search_by_identifier(national_id).first.patient rescue []
    return {} if patient.blank?

    results = {}
    result_hash = {}

    if PatientService.art_patient?(patient)
      clinic_encounters = ["APPOINTMENT","HIV CLINIC CONSULTATION","VITALS","HIV STAGING",'ART ADHERENCE','DISPENSING','HIV CLINIC REGISTRATION']
      clinic_encounter_ids = EncounterType.find(:all,:conditions => ["name IN (?)",clinic_encounters]).collect{| e | e.id }
      first_encounter_date = patient.encounters.find(:first,
        :order => 'encounter_datetime',
        :conditions => ['encounter_type IN (?)',clinic_encounter_ids]).encounter_datetime.strftime("%d-%b-%Y") rescue 'Uknown'

      last_encounter_date = patient.encounters.find(:first,
        :order => 'encounter_datetime DESC',
        :conditions => ['encounter_type IN (?)',clinic_encounter_ids]).encounter_datetime.strftime("%d-%b-%Y") rescue 'Uknown'


      art_start_date = PatientService.patient_art_start_date(patient.id).strftime("%d-%b-%Y") rescue 'Uknown'
      last_given_drugs = patient.person.observations.recent(1).question("ARV REGIMENS RECEIVED ABSTRACTED CONSTRUCT").last rescue nil
      last_given_drugs = last_given_drugs.value_text rescue 'Uknown'

      program_id = Program.find_by_name('HIV PROGRAM').id
      outcome = PatientProgram.find(:first,:conditions =>["program_id = ? AND patient_id = ?",program_id,patient.id],:order => "date_enrolled DESC")
      art_clinic_outcome = outcome.patient_states.last.program_workflow_state.concept.fullname rescue 'Unknown'

      date_tested_positive = patient.person.observations.recent(1).question("FIRST POSITIVE HIV TEST DATE").last rescue nil
      date_tested_positive = date_tested_positive.to_s.split(':')[1].strip.to_date.strftime("%d-%b-%Y") rescue 'Uknown'

      cd4_info = patient.person.observations.recent(1).question("CD4 COUNT").all rescue []
      cd4_data_and_date_hash = {}

      (cd4_info || []).map do | obs |
        cd4_data_and_date_hash[obs.obs_datetime.to_date.strftime("%d-%b-%Y")] = obs.value_numeric
      end

      result_hash = {
        'art_start_date' => art_start_date,
        'date_tested_positive' => date_tested_positive,
        'first_visit_date' => first_encounter_date,
        'last_visit_date' => last_encounter_date,
        'cd4_data' => cd4_data_and_date_hash,
        'last_given_drugs' => last_given_drugs,
        'art_clinic_outcome' => art_clinic_outcome,
        'arv_number' => PatientService.get_patient_identifier(patient, 'ARV Number')
      }
    end

    results["person"] = result_hash
    return results
  end

  def art_info_for_remote(national_id)
    patient = PatientService.search_by_identifier(national_id).first.patient rescue []
    return {} if patient.blank?

    results = {}
    result_hash = {}
    
    if PatientService.art_patient?(patient)
      clinic_encounters = ["APPOINTMENT","HIV CLINIC CONSULTATION","VITALS","HIV STAGING",'ART ADHERENCE','DISPENSING','HIV CLINIC REGISTRATION']
      clinic_encounter_ids = EncounterType.find(:all,:conditions => ["name IN (?)",clinic_encounters]).collect{| e | e.id }
      first_encounter_date = patient.encounters.find(:first, 
        :order => 'encounter_datetime',
        :conditions => ['encounter_type IN (?)',clinic_encounter_ids]).encounter_datetime.strftime("%d-%b-%Y") rescue 'Uknown'

      last_encounter_date = patient.encounters.find(:first, 
        :order => 'encounter_datetime DESC',
        :conditions => ['encounter_type IN (?)',clinic_encounter_ids]).encounter_datetime.strftime("%d-%b-%Y") rescue 'Uknown'
      

      art_start_date = patient.art_start_date.strftime("%d-%b-%Y") rescue 'Uknown'
      last_given_drugs = patient.person.observations.recent(1).question("ARV REGIMENS RECEIVED ABSTRACTED CONSTRUCT").last rescue nil
      last_given_drugs = last_given_drugs.value_text rescue 'Uknown'

      program_id = Program.find_by_name('HIV PROGRAM').id
      outcome = PatientProgram.find(:first,:conditions =>["program_id = ? AND patient_id = ?",program_id,patient.id],:order => "date_enrolled DESC")
      art_clinic_outcome = outcome.patient_states.last.program_workflow_state.concept.fullname rescue 'Unknown'

      date_tested_positive = patient.person.observations.recent(1).question("FIRST POSITIVE HIV TEST DATE").last rescue nil
      date_tested_positive = date_tested_positive.to_s.split(':')[1].strip.to_date.strftime("%d-%b-%Y") rescue 'Uknown'
      
      cd4_info = patient.person.observations.recent(1).question("CD4 COUNT").all rescue []
      cd4_data_and_date_hash = {}

      (cd4_info || []).map do | obs |
        cd4_data_and_date_hash[obs.obs_datetime.to_date.strftime("%d-%b-%Y")] = obs.value_numeric
      end

      result_hash = {
        'art_start_date' => art_start_date,
        'date_tested_positive' => date_tested_positive,
        'first_visit_date' => first_encounter_date,
        'last_visit_date' => last_encounter_date,
        'cd4_data' => cd4_data_and_date_hash,
        'last_given_drugs' => last_given_drugs,
        'art_clinic_outcome' => art_clinic_outcome,
        'arv_number' => PatientService.get_patient_identifier(patient, 'ARV Number')
      }
    end

    results["person"] = result_hash
    return results
  end
  
  def occupations
    ['','Driver','Housewife','Messenger','Business','Farmer','Salesperson','Teacher',
      'Student','Security guard','Domestic worker', 'Police','Office worker',
      'Preschool child','Mechanic','Prisoner','Craftsman','Healthcare Worker','Soldier'].sort.concat(["Other","Unknown"])
  end

  def edit
    # only allow these fields to prevent dangerous 'fields' e.g. 'destroy!'
    valid_fields = ['birthdate','gender']
    unless valid_fields.include? params[:field]
      redirect_to :controller => 'patients', :action => :demographics, :id => params[:id]
      return
    end

    @person = Person.find(params[:id])
    if request.post? && params[:field]
      if params[:field]== 'gender'
        @person.gender = params[:person][:gender]
      elsif params[:field] == 'birthdate'
        if params[:person][:birth_year] == "Unknown"
          @person.set_birthdate_by_age(params[:person]["age_estimate"])
        else
          PatientService.set_birthdate(@person, params[:person]["birth_year"],
            params[:person]["birth_month"],
            params[:person]["birth_day"])
        end
        @person.birthdate_estimated = 1 if params[:person]["birthdate_estimated"] == 'true'
        @person.save
      end
      @person.save
      redirect_to :controller => :patients, :action => :edit_demographics, :id => @person.id
    else
      @field = params[:field]
      @field_value = @person.send(@field)
    end
  end
  
  def dde_search
    @dde_server = GlobalProperty.find_by_property("dde_server_ip").property_value rescue ""
    @dde_server_username = GlobalProperty.find_by_property("dde_server_username").property_value rescue ""
    @dde_server_password = GlobalProperty.find_by_property("dde_server_password").property_value rescue ""
    
    url = "http://#{@dde_server_username}:#{@dde_server_password}@#{@dde_server}" + 
      "/people/find.json?given_name=#{params[:given_name]}" + 
      "&family_name=#{params[:family_name]}&gender=#{params[:gender]}"
    
    result = RestClient.get(url)
    
    render :text => result, :layout => false
  end

  def demographics
    @person = Person.find(params[:id])
		@patient_bean = PatientService.get_patient(@person)
		render :layout => 'menu'
  end

  def duplicates
    @duplicates = []
    people = PatientService.person_search(params[:search_params])
    people.each do |person|
      @duplicates << PatientService.get_patient(person)
    end unless people == "found duplicate identifiers"

    if create_from_dde_server
      @remote_duplicates = []
      PatientService.search_from_dde_by_identifier(params[:search_params][:identifier]).each do |person|
        @remote_duplicates << PatientService.get_dde_person(person)
      end
    end

    @selected_identifier = params[:search_params][:identifier]
    @logo = CoreService.get_global_property_value("logo")
    render :layout => 'menu'
  end
 
  def reassign_dde_national_id
    person = DDEService.reassign_dde_identification(params[:dde_person_id],params[:local_person_id])
    print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
  end

  def remote_duplicates
    if params[:patient_id]
      @primary_patient = PatientService.get_patient(Person.find(params[:patient_id]))
    else
      @primary_patient = nil
    end
    
    @dde_duplicates = []
    if create_from_dde_server
      PatientService.search_from_dde_by_identifier(params[:identifier]).each do |person|
        @dde_duplicates << PatientService.get_dde_person(person)
      end
    end

    if @primary_patient.blank? and @dde_duplicates.blank?
      redirect_to :action => 'search',:identifier => params[:identifier] and return
    end
    render :layout => 'menu'
  end

  def reassign_national_identifier
    patient = Patient.find(params[:person_id])
    if create_from_dde_server
      passed_params = PatientService.demographics(patient.person)
      new_npid = PatientService.create_from_dde_server_only(passed_params)
      npid = PatientIdentifier.new()
      npid.patient_id = patient.id
      npid.identifier_type = PatientIdentifierType.find_by_name('National ID')
      npid.identifier = new_npid
      npid.save
    else
      PatientIdentifierType.find_by_name('National ID').next_identifier({:patient => patient})
    end
    npid = PatientIdentifier.find(:first,
      :conditions => ["patient_id = ? AND identifier = ?
           AND voided = 0", patient.id,params[:identifier]])
    npid.voided = 1
    npid.void_reason = "Given another national ID"
    npid.date_voided = Time.now()
    npid.voided_by = current_user.id
    npid.save
    
    print_and_redirect("/patients/national_id_label?patient_id=#{patient.id}", next_task(patient))
  end

  def create_person_from_dde
    person = DDEService.get_remote_person(params[:remote_person_id])

    print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
  end

  
  protected
  
	def search_complete_url(found_person_id, primary_person_id)
		unless (primary_person_id.blank?)
			# Notice this swaps them!
			new_relationship_url(:patient_id => primary_person_id, :relation => found_person_id)
		else
			#
			# Hack reversed to continue testing overnight
			#
			# TODO: This needs to be redesigned!!!!!!!!!!!
			#
			#url_for(:controller => :encounters, :action => :new, :patient_id => found_person_id)
			patient = Person.find(found_person_id).patient
			show_confirmation = CoreService.get_global_property_value('show.patient.confirmation').to_s == "true" rescue false
			if show_confirmation
				#url_for(:controller => :people, :action => :confirm , :found_person_id =>found_person_id)
				url_for(:controller => :patients , :action => :patient_dashboard , :found_person_id =>found_person_id)
			else
				next_task(patient)
			end
		end
	end

  def cul_age(birthdate , birthdate_estimated , date_created = Date.today, today = Date.today)
                                                                                
    # This code which better accounts for leap years                            
    patient_age = (today.year - birthdate.year) + ((today.month - birthdate.month) + ((today.day - birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)
                                                                                
    # If the birthdate was estimated this year, we round up the age, that way if
    # it is March and the patient says they are 25, they stay 25 (not become 24)
    birth_date = birthdate                                                      
    estimate = birthdate_estimated == 1                                         
    patient_age += (estimate && birth_date.month == 7 && birth_date.day == 1  &&
        today.month < birth_date.month && date_created.year == today.year) ? 1 : 0
  end                                                                           
                                                                                
  def birthdate_formatted(birthdate,birthdate_estimated)                        
    if birthdate_estimated == 1                                                 
      if birthdate.day == 1 and birthdate.month == 7                            
        birthdate.strftime("??/???/%Y")                                         
      elsif birthdate.day == 15                                                 
        birthdate.strftime("??/%b/%Y")                                          
      elsif birthdate.day == 1 and birthdate.month == 1                         
        birthdate.strftime("??/???/%Y")                                         
      end                                                                       
    else                                                                        
      birthdate.strftime("%d/%b/%Y")                                            
    end                                                                         
  end 
end
 
