class DdeController < ApplicationController

  def create
    birthdate_params = birthdate_format(params)
    birthdate = birthdate_params[0]
    birthdate_estimated = birthdate_params[1]

    person_params = {
      :given_name   =>  params[:person][:names][:given_name],
      :family_name  =>  params[:person][:names][:family_name],         
      :middle_name  =>  params[:person][:names][:middle_name],
      :gender       =>  params[:person][:gender],          
      :birthdate    =>  birthdate,
      :birthdate_estimated => birthdate_estimated,   
      :attributes => {
        :occupation => "",
        :cellphone_number => params[:home_phone_number],           
                  
        :home_district    => params[:person][:addresses]['address2'],            
        :home_traditional_authority => params[:person][:addresses]['county_district'],
        :home_village     => params[:person][:addresses]['neighborhood_cell'],            
        :current_district => params[:person][:addresses]['state_province'],        
        :current_traditional_authority => params[:person][:addresses]['address1'],      
        :current_village => params[:person][:addresses]['city_village']     
      },
      :identifiers => {}
    }   
    

    dde_url = DDEService.dde_settings['dde_address'] + "/v1/add_person"
    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
      :payload => person_params, :headers => {:Authorization => session[:dde_token]} } )

    #########################################################
    #We check if the DDE record exisit local if not we create it locally
    dde_results  = JSON.parse(output)
    if dde_results.blank?
      flash[:notice] = "Failed to register patient."
      redirect_to("/dde/search?gender=Female") and return
    end

    local_people = DDEService.create_local_person(dde_results)

		if params[:guardian_present] == "YES"
			redirect_to "/relationships/search?patient_id=#{local_people.id}&return_to=/people/redirections?person_id=#{local_people.id}" and return
    else
     next_url = "/people/confirm?found_person_id=#{local_people.first.id}" 
     print_and_redirect("/patients/national_id_label?patient_id=#{local_people.first.id}", next_url) and return
    end

  end

  def edit
  end

  def update
  end

  def merge
  end

  def search
  end

  def document
    found = PatientIdentifier.find(:first, 
      :conditions =>["identifier = ? AND identifier_type = ?",
      params[:id], PatientIdentifierType.find_by_name('DDE person document ID').id]) 
    
    unless found.blank?
      redirect_to "/people/confirm?found_person_id=#{found.patient_id}" and return
    end

    dde_url = DDEService.dde_settings['dde_address'] + "/v1/search_by_doc_id"
    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
      :payload => {:doc_id => params[:id]}, :headers => {:Authorization => session[:dde_token]} } )

    output = JSON.parse(output)[0]
    local_people = DDEService.create_local_person(output)
    redirect_to "/people/redirections?person_id=#{local_people.first.id}" and return
  end

  def confirm
    if request.post?
      PatientIdentifier.create(:patient_id => params[:person_id],
        :identifier => params[:doc_id], 
        :identifier_type => PatientIdentifierType.find_by_name('DDE person document ID').id)

      redirect_to "/people/confirm?found_person_id=#{params[:person_id]}" and return
    end

    dde_url = DDEService.dde_settings['dde_address'] + "/v1/search_by_doc_id"
    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
      :payload => {:doc_id => params[:doc_id]}, :headers => {:Authorization => session[:dde_token]} } )

    names = PersonName.find(:last, :conditions =>["person_id = ?", params[:person_id]])
    addresses = PersonAddress.find(:last, :conditions =>["person_id = ?", params[:person_id]])
    person = Person.find(params[:person_id])  

    @local_results = {
      :name => "#{(names.given_name rescue nil)} #{names.family_name}",
      :birthdate => "#{(person.birthdate.strftime('%d/%b/%Y') rescue nil)}",
      :gender => person.gender,
      :home_district => addresses.address2,
      :home_ta => addresses.county_district,
      :home_village => addresses.neighborhood_cell,
      :current_district => addresses.state_province,
      :current_district => addresses.address1,
      :current_village =>  addresses.city_village
    }

    @dde_results  = JSON.parse(output)[0]
  end

  def search_by_name_and_gender
    
    if params[:identifier].blank?
      search_params = {
        :given_name   =>  params['person']['names']['given_name'],
        :family_name  =>  params['person']['names']['family_name'],
        :gender       =>  params['person']['gender']
      }
   
      dde_url = DDEService.dde_settings['dde_address'] + "/v1/search_by_name_and_gender"
    
      output = RestClient::Request.execute( { :method => :post, :url => dde_url,
        :payload => search_params, :headers => {:Authorization => session[:dde_token]} } )
      dde_search_results  = JSON.parse(output)
      
      local_search_results = PatientService.person_search(search_params)

    else
      dde_url = DDEService.dde_settings['dde_address'] + "/v1/search_by_npid"
      search_params = {:npid => params[:identifier], :doc_id => params[:dde_document_id]} 

      output = RestClient::Request.execute( { :method => :post, :url => dde_url,
          :payload => search_params, :headers => {:Authorization => session[:dde_token]} } )
      dde_search_results  = JSON.parse(output)

      ############################xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
      local_search_results = DDEService.search_local_by_identifier(params[:identifier])
      if local_search_results.length == 1 && dde_search_results.blank?
				person_id = local_search_results[0].person_id

        if params[:identifier].length == 6
          redirect_to "/people/confirm?found_person_id=#{person_id}" and return
        end

        patient_has_dde_id = patient_has_dde_identifier_already?(person_id)
        unless patient_has_dde_id.blank?
					next_url = "/people/confirm?found_person_id=#{person_id}"
					print_and_redirect("/patients/national_id_label?patient_id=#{person_id}", next_url) and return
        end

				message = local_client_to_dde(person_id)
		
        unless message.blank? 
          if message.match(/Search by name and update patient address info/i)
            redirect_to :controller => "dde", 
              :action => "edit_demographics", 
                :patient_id => person_id, :message => message  and return
          end rescue nil
				end


        next_url = "/people/confirm?found_person_id=#{local_search_results[0].person_id}"
				print_and_redirect("/patients/national_id_label?patient_id=#{person_id}", next_url) and return
      elsif local_search_results.length == 1 && dde_search_results.length == 1
				person_id = local_search_results[0].person_id
        dde_person_doc_id = dde_search_results[0]['doc_id']

        local_person_doc = PatientIdentifier.find(:first, 
          :conditions =>["patient_id = ? AND identifier = ? AND identifier_type = ?",
          person_id, dde_person_doc_id,
          PatientIdentifierType.find_by_name('DDE person document ID').id]) 
       
        unless local_person_doc.blank?
          redirect_to "/people/confirm?found_person_id=#{person_id}" and return
        end
        
        redirect_to "/dde/confirm?person_id=#{person_id}&doc_id=#{dde_person_doc_id}" and return
      elsif local_search_results.length == 1 && !dde_search_results.blank?
        redirect_to :controller => 'dde',
          :action => 'dde_duplicates', :npid => params[:identifier] and return
      elsif local_search_results.length > 1 
        redirect_to :controller => 'dde', 
          :action => 'dde_duplicates', :npid => params[:identifier] and return
      elsif local_search_results.blank? && dde_search_results.blank?
        redirect_to :controller => "clinic", 
          :action => "index", :message => "Identifier: #{params[:identifier]} not found"  and return
      end
      ############################xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

      if dde_search_results.length > 1
        redirect_to :controller => 'dde',
          :action => 'dde_duplicates', :npid => params[:identifier] and return
      else
        
        #########################################################
        #We check if the DDE record exisit local if not we create it locally
        local_people = DDEService.create_local_person(dde_search_results[0])
        
        unless local_people.blank?
          redirect_to "/people/confirm?found_person_id=#{local_people.last.id}"
          return
        else
          redirect_to :controller =>'dde', :action => 'dde_duplicates',
            :npid => params[:identifier] and return
        end
        #raise local_person.inspect
        #########################################################
        
            
      end
    end


    @results = []
    (dde_search_results || []).each do |r|
      birthdate_estimated = (r['birthdate_estimated'] == false ? 0 : 1)
      @results << {
        :given_name             =>  r['given_name'],
        :family_name            =>  r['family_name'],
        :name                   =>  r['given_name'].to_s + " " + r['family_name'],
        :gender                 =>  r['gender'],
        :birthdate              =>  r['birthdate'],
        :birth_date             =>  birthdate_formatted(r['birthdate'].to_date, birthdate_estimated),
        :birthdate_estimated    =>  birthdate_estimated,
        :home_district          =>  r['attributes']['home_district'],
        :home_ta                =>  r['attributes']['home_traditional_authority'],
        :home_village           =>  r['attributes']['home_village'],
        :current_residence      =>  r['attributes']['current_village'],
        :npid                   =>  r['npid'],
        :doc_id                 =>  r['doc_id'],
        :person_id              =>  0
      }
    end

    (local_search_results || []).each do |person|
       
      birthdate_estimated = person.birthdate_estimated
      names     = person.names #.last
      addresses = person.addresses.last
      #raise addresses.inspect
      local_person = {
        :given_name             =>  names.last.given_name,
        :family_name            =>  names.last.family_name,
        :name                   =>  names.last.given_name.to_s + " " + names.last.family_name,
        :gender                 =>  (person.gender.first rescue nil),
        :birthdate              =>  (person.birthdate.to_date rescue nil),
        :birth_date             =>  birthdate_formatted(person.birthdate.to_date, birthdate_estimated),
        :birthdate_estimated    =>  birthdate_estimated,
        :home_district          =>  (addresses.address2 rescue nil),
        :home_ta                =>  (addresses.county_district rescue nil),
        :home_village           =>  (addresses.neighborhood_cell rescue nil),
        :current_residence      =>  (addresses.city_village rescue nil),
        :npid                   =>  PatientService.get_patient_identifier(person.patient, "National ID"),
        :doc_id                 =>  PatientService.get_patient_identifier(person.patient, "DDE person document ID"),
        :person_id              =>  person.person_id
      }
      same_record = false
      (@results || []).each do |dde_person|
        same_record = compare_dde_and_local_demographics(dde_person, local_person)
        break if same_record
      end

      if !same_record
        @results << local_person
      end

    end

    #raise @results.to_yaml

    @relation = []
    #render :layout => 'report'
  end

  def duplicates
    @duplicates = []
    people = PatientService.person_search(params[:search_params])
    people.each do |person|
      @duplicates << PatientService.get_patient(person)
    end unless people == "found duplicate identifiers"

    if create_from_dde_server
      @remote_duplicates = []
      #DDEService.search_dde_by_identifier(params[:search_params][:identifier], session[:dde_token])["data"]["hits"].each do |search_result|
      #@remote_duplicates << PatientService.get_remote_dde_person(search_result)
      #end rescue nil
    end

    @selected_identifier = params[:search_params][:identifier]
    render :layout => 'menu'
  end

  def reassign_npid
    dde_url = DDEService.dde_settings['dde_address'] + "/v1/reassign_npid"
    search_params = {:doc_id => params[:doc_id]} 
    
    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
        :payload => search_params, :headers => {:Authorization => session[:dde_token]} } )
    result  = JSON.parse(output)
  
    redirect_to :action => 'search_by_name_and_gender', :identifier => result['npid']
  end

  def reassign_dde_npid(doc_id)
    dde_url = DDEService.dde_settings['dde_address'] + "/v1/assign_npid"
    search_params = {:doc_id => doc_id} 
    
    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
        :payload => search_params, :headers => {:Authorization => session[:dde_token]} } )
    result  = JSON.parse(output)
  
    redirect_to :action => 'search_by_name_and_gender', :identifier => result['npid']
  end

  def dde_duplicates
    dde_url = DDEService.dde_settings['dde_address'] + "/v1/search_by_npid"
    search_params = {:npid => params[:npid]} 

    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
        :payload => search_params, :headers => {:Authorization => session[:dde_token]} } )
    dde_search_results  = JSON.parse(output)


    @results = []
    (dde_search_results || []).each do |r|
      birthdate_estimated = (r['birthdate_estimated'] == false ? 0 : 1)
      @results << {
        :given_name             =>  r['given_name'],
        :family_name            =>  r['family_name'],
        :name                   =>  r['given_name'].to_s + " " + r['family_name'],
        :gender                 =>  r['gender'],
        :birthdate              =>  r['birthdate'],
        :birth_date             =>  birthdate_formatted(r['birthdate'].to_date, birthdate_estimated),
        :birthdate_estimated    =>  birthdate_estimated,
        :home_district          =>  r['attributes']['home_district'],
        :home_ta                =>  r['attributes']['home_traditional_authority'],
        :home_village           =>  r['attributes']['home_village'],
        :current_residence      =>  r['attributes']['current_village'],
        :npid                   =>  r['npid'],
        :doc_id                 =>  r['doc_id'],
        :person_id             =>  0
      }
    end

    local_search_results = DDEService.search_local_by_identifier(params[:npid])

    (local_search_results || []).each do |person|
       
      birthdate_estimated = person.birthdate_estimated
      names     = person.names #.last
      addresses = person.addresses.last
      #raise addresses.inspect
      local_person = {
        :given_name             =>  names.last.given_name,
        :family_name            =>  names.last.family_name,
        :name                   =>  names.last.given_name.to_s + " " + names.last.family_name,
        :gender                 =>  person.gender.first,
        :birthdate              =>  person.birthdate.to_date,
        :birth_date             => birthdate_formatted(person.birthdate.to_date, birthdate_estimated),
        :birthdate_estimated    =>  birthdate_estimated,
        :home_district          =>  addresses.address2,
        :home_ta                =>  addresses.county_district,
        :home_village           =>  addresses.neighborhood_cell,
        :current_residence      =>  addresses.city_village,
        :npid                   =>  PatientService.get_patient_identifier(person.patient, "National ID"),
        :doc_id                 =>  PatientService.get_patient_identifier(person.patient, "DDE person document ID"),
        :person_id              =>  person.person_id
      }
      same_record = false
      (@results || []).each do |dde_person|
        same_record = compare_dde_and_local_demographics(dde_person, local_person)
        break if same_record
      end

      #if !same_record
        @results << local_person
      #end

    end

    #render :layout => 'report'
  end
  
  def select
    if !params[:person][:patient][:identifiers]['National id'].blank? &&
        !params[:person][:names][:given_name].blank? &&
        !params[:person][:names][:family_name].blank?
      redirect_to :action => :search_by_name_and_gender,
        :identifier => params[:person][:patient][:identifiers]['National id'],
        :dde_document_id => params[:dde_document_id]
      return
    end rescue nil
    
    if !params[:identifier].blank? && !params[:given_name].blank? && !params[:family_name].blank?
      redirect_to :action => :search_by_name_and_gender, :identifier => params[:identifier]
    elsif params[:person][:id] != '0' && Person.find(params[:person][:id]).dead == 1
      redirect_to :controller => :patients, :action => :show, :id => params[:person][:id]
    elsif params[:identifier].blank? && params[:person][:id] == '0' && !params[:dde_document_id].blank? # DDE Patient without ID.
      doc_id = params[:dde_document_id]
      reassign_dde_npid(doc_id) and return
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
          dde_demographics = PatientService.generate_dde_demographics(demographics)
          #check if patient is not in DDE first
          dde_identifiers = {"npid" => old_npid, "doc_id" => person.dde_doc_id}
          dde_hits = DDEService.search_dde_by_identifier(dde_identifiers, session[:dde_token])
          patient_exists_in_dde = dde_hits.length > 0

          if (dde_hits.length == 1)
            new_npid =  dde_hits[0]["npid"]
            if (old_npid != new_npid)
              DDEService.assign_new_dde_npid(person, old_npid, new_npid)
              print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient)) and return
            end
          end

          if !patient_exists_in_dde
            dde_results = DDEService.add_dde_patient_after_search_by_name(dde_demographics, session[:dde_token])
            dde_status = dde_results["status"]

            if dde_status.blank? #created
              new_npid = dde_results["person"]["npid"]
              doc_id = dde_results["person"]["_id"]
              #new National ID assignment
              #There is a need to check the validity of the patient national ID before being marked as old ID

              if (doc_id != person.dde_doc_id)
                DDEService.create_dde_document_id(person, doc_id)
              end

              if (old_npid != new_npid)
                DDEService.assign_new_dde_npid(person, old_npid, new_npid)
              end

              print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient)) and return
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

  def dde_login
    @dde_status = GlobalProperty.find_by_property('dde.status').property_value rescue ""
    @dde_status = 'Yes' if @dde_status.match(/ON/i)
    @dde_status = 'No' if @dde_status.match(/OFF/i)

    if request.post?
      dde_status = params[:dde_status]
      if dde_status.squish.downcase == 'yes'
        dde_status = 'ON'
      else
        dde_status = 'OFF'
      end
    
      if (dde_status == 'ON') #Do this part only when DDE is activated
        address = params[:dde_address].to_s + ":" + params[:dde_port].to_s
        data = {
          :username => params[:dde_username],
          :password => params[:dde_password],
          :address => address
        }
         
        dde_token = DDEService.dde_login_from_params(data)

        if dde_token.blank?
          flash[:notice] = "Failed to authorize user. Check your username and password"
          redirect_to("/dde/dde_login") and return
        else
          session[:dde_token] = dde_token
          #create_dde_properties(params, dde_status)
          dde_username    = params[:dde_username]
          dde_port        = params[:dde_port]
          dde_ipaddress   = params[:dde_address]
          
          url = "/dde/dde_add_user?dde_token=#{dde_token}"
          url += "&dde_username=#{dde_username}&dde_port=#{dde_port}"
          url +=  "&dde_ipaddress=#{dde_ipaddress}" 
          redirect_to url and return
        end
      else
        global_property_dde_status = GlobalProperty.find_by_property('dde.status')
        global_property_dde_status = GlobalProperty.new if global_property_dde_status.blank?
        global_property_dde_status.property = 'dde.status'
        global_property_dde_status.property_value = dde_status
        global_property_dde_status.save

        redirect_to("/clinic") and return
      end
      
    end
  end

  def create_dde_properties(params, dde_status)
    ActiveRecord::Base.transaction do
      global_property_dde_address = GlobalProperty.find_by_property('dde.address')
      global_property_dde_address = GlobalProperty.new if global_property_dde_address.blank?
      global_property_dde_address.property = 'dde.address'
      global_property_dde_address.property_value = params[:dde_address]
      global_property_dde_address.save

      global_property_dde_port = GlobalProperty.find_by_property('dde.port')
      global_property_dde_port = GlobalProperty.new if global_property_dde_port.blank?
      global_property_dde_port.property = 'dde.port'
      global_property_dde_port.property_value = params[:dde_port]
      global_property_dde_port.save

      global_property_dde_username = GlobalProperty.find_by_property('dde.username')
      global_property_dde_username = GlobalProperty.new if global_property_dde_username.blank?
      global_property_dde_username.property = 'dde.username'
      global_property_dde_username.property_value = params[:dde_username]
      global_property_dde_username.save

      global_property_dde_password = GlobalProperty.find_by_property('dde.password')
      global_property_dde_password = GlobalProperty.new if global_property_dde_password.blank?
      global_property_dde_password.property = 'dde.password'
      global_property_dde_password.property_value = params[:dde_password]
      global_property_dde_password.save

      global_property_dde_status = GlobalProperty.find_by_property('dde.status')
      global_property_dde_status = GlobalProperty.new if global_property_dde_status.blank?
      global_property_dde_status.property = 'dde.status'
      global_property_dde_status.property_value = dde_status
      global_property_dde_status.save
    end
  end

  def update_dde_properties(params)
    ActiveRecord::Base.transaction do
      # Update dde username and password in db.
      dde_app = DdeApplicationUsers.find_by_program_id(params[:program])
      if dde_app.blank?
        DdeApplicationUsers.create(:program_id => params[:program], 
          :username => params[:username], 
          :port => params[:dde_port], :ipaddress => params[:dde_ipaddress],
          :password => params[:password], :creator => User.current.id)
      else
        dde_app.update_attributes(:username => params[:username], 
          :port => params[:dde_port], :ipaddress => params[:dde_ipaddress],
          :password => params[:password], :creator => User.current.id)
      end
    end

    # Update dde token session
    property = GlobalProperty.find_by_property('dde.status')
    if property.blank?
      GlobalProperty.create(:property => 'dde.status', :property_value => 'ON')
    else
      property.update_attributes(:property_value => 'ON')
    end
    
=begin
    dde_address = GlobalProperty.find_by_property('dde.address').property_value
    dde_port    = GlobalProperty.find_by_property('dde.port').property_value
    address = dde_address.to_s + ":" + dde_port.to_s
=end
    data = {
      :username => params['username'],
      :password => params['password'],
      :address => "#{params[:dde_ipaddress]}:#{params[:dde_port]}"
    }

    dde_token = DDEService.dde_login_from_params(data)

    unless dde_token.blank?
      session[:dde_token] = dde_token
    end

  end

  def get_dde_locations
    dde_protocol = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env]["dde_protocol"]
    dde_url = "#{dde_protocol}://#{params[:dde_location]}"
    dde_locations = DDEService.dde_locations(dde_url, params[:dde_token], params[:name])

    li_elements = "<li></li>"
    dde_locations.each do |location|
      doc_id = location["doc_id"]
      location_name = location["name"]
      li_elements += "<li value='#{doc_id}'>#{location_name}</li>"
    end
    li_elements += "<li></li>"
    render :text => li_elements and return
  end

  def dde_add_user
    if request.post?
      data = {
        "username" => params[:username],
        "password" => params[:password],
        "location" => params[:location]
      }

      dde_protocol = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env]["dde_protocol"]
      dde_url = "#{dde_protocol}://#{params[:dde_ipaddress]}:#{params[:dde_port]}"
      
      # Get location name from dde to compare with the current site.
      location = DDEService.get_dde_location(dde_url, params[:location], params[:dde_token])
      app_location = Location.current_health_center.name rescue ""

      unless app_location == location["name"]
        redirect_to :controller => "dde", :action => "dde_add_user",
          :dde_token => params[:dde_token], :dde_username => params[:username],
          :dde_port => params[:dde_port], :dde_ipaddress => params[:dde_ipaddress],
          :message => "Please enter the collect location (i.e #{app_location})" and return
      end

      dde_status = DDEService.add_dde_user(dde_url, data, params[:dde_token])
      unless dde_status.to_i == 200
        flash[:notice] = "Failed to create user"
        redirect_to("/dde/dde_add_user") and return
      end
      update_dde_properties(params)
      redirect_to("/clinic") and return
    end
  end

  def programs
    program_id  = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env]["program_id"]
    programs = Program.find(:all, :conditions =>["program_id = #{program_id} 
      AND name LIKE (?)","%#{params[:name]}%"],:limit => 10)

    li_elements = "<li></li>"
    (programs || []).each do |program|
      program_id  =  program.id
      name        = program.name
      li_elements += "<li value='#{program_id}'>#{name}</li>"
    end
    li_elements += "<li></li>"
    render :text => li_elements and return
  end

  def edit_demographics
    patient = Patient.find(params[:patient_id])
    person  = patient.person
    doc_id = DDEService.get_patient_identifier(patient, "DDE person document ID")

    name    = person.names.last rescue nil
    address = person.addresses.last rescue nil
     
    @patient_obj = {
      :given_name           => (name.given_name rescue nil),
      :family_name          => (name.family_name rescue nil),
      :middle_name          => (name.middle_name rescue nil),
      :gender               => person.gender,
      :birthdate            => person.birthdate,
      
      :home_district        => (address.address2 rescue nil),
      :home_ta              => (address.county_district rescue nil),
      :home_village         => (address.neighborhood_cell rescue nil),
      :current_district     => (address.state_province rescue nil) ,
      :current_ta           => (address.address1 rescue nil) ,
      :current_village      => (address.city_village rescue nil) ,


      :cell_phone           => DDEService.get_attribute(person, "Cell Phone Number"),
      :home_phone_number    => DDEService.get_attribute(person, "Home Phone Number") ,
      :occupation           => DDEService.get_attribute(person, "Occupation"),
      :patient_id           => patient.id,
      :doc_id               => doc_id 
    }
    
  end

  def district
    region_id = Region.find_by_name("#{params[:filter_value]}").id
    region_conditions = ["name LIKE (?) AND region_id = ? ", "#{params[:search_string]}%", region_id]

    districts = District.find(:all,:conditions => region_conditions, :order => 'name')
    districts = districts.map do |d|
      "<li value=\"#{d.name}\">#{d.name}</li>"
    end
    render :text => districts.join('') and return
  end
	
  # List traditional authority containing the string given in params[:value]
  def traditional_authority
    district_id = District.find_by_name("#{params[:filter_value]}").id
    traditional_authority_conditions = ["name LIKE (?) AND district_id = ?", "%#{params[:search_string]}%", district_id]

    traditional_authorities = TraditionalAuthority.find(:all,:conditions => traditional_authority_conditions, :order => 'name')
    traditional_authorities = traditional_authorities.map do |t_a|
      "<li value=\"#{t_a.name}\">#{t_a.name}</li>"
    end
    render :text => traditional_authorities.join('') and return
  end

  # Villages containing the string given in params[:value]
  def village
    traditional_authority_id = TraditionalAuthority.find_by_name("#{params[:filter_value]}").id
    village_conditions = ["name LIKE (?) AND traditional_authority_id = ?", "%#{params[:search_string]}%", traditional_authority_id]

    villages = Village.find(:all,:conditions => village_conditions, :order => 'name')
    villages = villages.map do |v|
      "<li value=\"" + v.name + "\">" + v.name + "</li>"
    end
    render :text => villages.join('') and return
  end

  def update_address
    #raise address_params.inspect
    if params[:address_type] == 'home_district'
      address_params = {
        :attributes => {
          :home_district  =>  params[:person][:addresses][:address2],
          :home_traditional_authority => params[:person][:addresses][:county_district],
          :home_village =>  params[:person][:addresses][:neighborhood_cell]
        },
        :doc_id => params[:document_id]
      }
    else
      address_params = {
        :attributes => {
          :current_district  =>  params[:person][:addresses][:address2],
          :current_traditional_authority => params[:person][:addresses][:county_district],
          :current_village =>  params[:person][:addresses][:neighborhood_cell]
        },
        :doc_id => params[:document_id]
      }
    end

    dde_url = DDEService.dde_settings['dde_address'] + "/v1/update_person"
    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
      :payload => address_params, :headers => {:Authorization => session[:dde_token]} } )

    addresses = PersonAddress.find(:all, :conditions =>["person_id = ?", params[:patient_id]])
    
    (addresses || []).each do |address|
      if params[:address_type] == 'home_district'
        address.update_attributes(:address2 => params[:person][:addresses][:address2],
          :county_district => params[:person][:addresses][:county_district],
          :neighborhood_cell => params[:person][:addresses][:neighborhood_cell])
      else
        address.update_attributes(:state_province => params[:person][:addresses][:address2],
          :address1 => params[:person][:addresses][:county_district],
          :city_village => params[:person][:addresses][:neighborhood_cell])
      end
    end

    redirect_to "/dde/edit_demographics?patient_id=#{params[:patient_id]}" and return
  end

  def update_names
    # update given name
    unless params[:person][:names][:given_name].blank?
      name_params = {
        :given_name  =>  params[:person][:names][:given_name],
        :doc_id => params[:document_id]
       }
    end

    # updates family name
    unless params[:person][:names][:family_name].blank?
      name_params = {
        :family_name  =>  params[:person][:names][:given_name],
        :doc_id => params[:document_id]
       }
    end
    #raise name_params.inspect

    dde_url = DDEService.dde_settings['dde_address'] + "/v1/update_person"
    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
      :payload => name_params, :headers => {:Authorization => session[:dde_token]} } )

    names = PersonName.find(:all, :conditions =>["person_id = ?", params[:patient_id]])

    (names || []).each do |name|
      unless params[:person][:names][:given_name].blank?
        name.update_attributes(:given_name => params[:person][:names][:given_name])
      end

      unless params[:person][:names][:family_name].blank?
        name.update_attributes(:family_name => params[:person][:names][:family_name])
      end
    end

    redirect_to "/dde/edit_demographics?patient_id=#{params[:patient_id]}" and return

  end

  def update_attribute
    attribute = ''
    # update phone number
    unless params[:person][:cell_phone_number].blank?
      attr_params = {
        :attributes => {
          :cellphone_number => params[:person][:cell_phone_number]
        },
        :doc_id => params[:document_id]
       }
       attribute_type = PersonAttributeType.find_by_name('Cell Phone Number')
    end

    # updates occupation
    unless params[:person][:occupation].blank?
      attr_params = {
        :attributes => {
          :occupation => params[:person][:occupation]
        },
        :doc_id => params[:document_id]
       }
       attribute_type = PersonAttributeType.find_by_name('Occupation')
    end

    dde_url = DDEService.dde_settings['dde_address'] + "/v1/update_person"
    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
      :payload => attr_params, :headers => {:Authorization => session[:dde_token]} } )


    person_attributes = PersonAttribute.find(:all,
      :conditions =>["voided = 0 AND person_attribute_type_id = ? AND person_id = ?",
        attribute_type.id, params[:patient_id]])

    #raise person_attributes.inspect

    if !person_attributes.blank?
      (person_attributes || []).each do |attr|
        unless params[:person][:cell_phone_number].blank?
          attr.update_attributes(:value => params[:person][:cell_phone_number])
        end

        unless params[:person][:occupation].blank?
          attr.update_attributes(:value => params[:person][:occupation])
        end 
      end
    else
      unless params[:person][:cell_phone_number].blank?
        attribute = params[:person][:cell_phone_number]
      end

      unless params[:person][:occupation].blank?
        attribute = params[:person][:occupation]
      end

      PersonAttribute.create(
        :person_id => params[:patient_id],
        :value => attribute,
        :person_attribute_type_id => attribute_type.id
      )

    end

    redirect_to "/dde/edit_demographics?patient_id=#{params[:patient_id]}" and return
  end

  def update_birthdate
    birthday_params = params[:person]
    unless birthday_params.empty?
		  if birthday_params["birth_year"] == "Unknown"
			  birthdate = Date.new(Date.today.year - birthday_params["age_estimate"].to_i, 7, 1)
        birthdate_estimated = 1
		  else
        
			  year = birthday_params["birth_year"]
        month = birthday_params["birth_month"]
        day = birthday_params["birth_day"]

        month_i = (month || 0).to_i
        month_i = Date::MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
        month_i = Date::ABBR_MONTHNAMES.index(month) if month_i == 0 || month_i.blank?

        if month_i == 0 || month == "Unknown"
          birthdate = Date.new(year.to_i,7,1)
          birthdate_estimated = 1
        elsif day.blank? || day == "Unknown" || day == 0
          birthdate = Date.new(year.to_i,month_i,15)
          birthdate_estimated = 1
        else
          birthdate = Date.new(year.to_i,month_i,day.to_i)
          birthdate_estimated = 0
        end
		  end
    else
      birthdate_estimated = 0
		end

    dob_params = {
        :birthdate  =>  birthdate,
        :birthdate_estimated => birthdate_estimated,
        :doc_id => params[:document_id]
       }

    dde_url = DDEService.dde_settings['dde_address'] + "/v1/update_person"
    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
      :payload => dob_params, :headers => {:Authorization => session[:dde_token]} } )

    person = Person.find(params[:patient_id])
    person.update_attributes(
      :birthdate => birthdate,
      :birthdate_estimated => birthdate_estimated
    )

    redirect_to "/dde/edit_demographics?patient_id=#{params[:patient_id]}" and return
    
  end

  def potential_duplicates
    person_params = {
      :given_name   =>  params[:person][:names][:given_name],
      :family_name  =>  params[:person][:names][:family_name],         
      :middle_name  =>  params[:person][:names][:middle_name],
      :gender       =>  params[:person][:gender],          
      :birthdate    =>  params[:person][:birthdate],
      :birthdate_estimated => "1",   
      :attributes => {
        :home_district    => params[:person][:addresses]['home_district'],            
        :home_traditional_authority => params[:person][:addresses]['home_traditional_authority'],
        :home_village     => params[:person][:addresses]['home_village']
      }
    }   

    dde_url = DDEService.dde_settings['dde_address'] + "/v1/search/people"
    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
      :payload => person_params, :headers => {:Authorization => session[:dde_token]} } )

    render :text => output and return
  end

  def npid_label
        
    patient_has_dde_id = patient_has_dde_identifier_already?(params[:person_id])
  
    if patient_has_dde_id.blank?
      message = local_client_to_dde(params[:person_id])
		
      unless message.blank? 
        if message.match(/Search by name and update patient address info/i)
          redirect_to :controller => "dde", 
            :action => "edit_demographics", 
              :patient_id =>params[:person_id], :message => message  and return
        end rescue nil
      end
    end
     
    next_url = "/patients/show/#{params[:person_id]}"
    print_and_redirect("/patients/national_id_label?patient_id=#{params[:person_id]}", next_url) and return
  end

  def reassign_local_client_npid
    
		message = local_client_to_dde(params[:person_id])
		
		unless message.blank? 
      if message.match(/Search by name and update patient address info/i)
			  redirect_to :controller => "dde", 
				  :action => "edit_demographics", 
            :patient_id =>params[:person_id], :message => message  and return
      end rescue nil
		end
    
    print_and_redirect("/patients/national_id_label?patient_id=#{params[:person_id]}", "/") and return
  end

  private

  def birthdate_formatted(birthdate, birthdate_estimated)
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

  def compare_dde_and_local_demographics(dde_person, local_person)

    if (dde_person[:doc_id].to_s.downcase == local_person[:doc_id].to_s.downcase && !local_person[:doc_id].blank?)
      return true
    elsif (dde_person[:given_name].to_s.downcase != local_person[:given_name].to_s.downcase)
      return false
    elsif (dde_person[:family_name].to_s.downcase != local_person[:family_name].to_s.downcase)
      return false
    elsif (dde_person[:gender].to_s.downcase != local_person[:gender].to_s.downcase)
      return false
    elsif (dde_person[:birthdate].to_s.downcase != local_person[:birthdate].to_s.downcase)
      return false
    elsif (dde_person[:birthdate_estimated].to_s.downcase != local_person[:birthdate_estimated].to_s.downcase)
      return false
    elsif (dde_person[:home_district].to_s.downcase != local_person[:home_district].to_s.downcase)
      return false
    elsif (dde_person[:home_ta].to_s.downcase != local_person[:home_ta].to_s.downcase)
      return false
    elsif (dde_person[:home_village].to_s.downcase != local_person[:home_village].to_s.downcase)
      return false
    end

    return true
    
  end

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
				url_for(:controller => :people, :action => :confirm , :found_person_id =>found_person_id)
			else
				next_task(patient)
			end
		end
	end

  def birthdate_format(params)
    birthdate_estimated = 1

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
        birthdate_estimated = 0
      end
    end

    return [birthdate, birthdate_estimated]
  end

  def local_client_to_dde(patient_id)
		names = PersonName.find(:last, :conditions => ["person_id = ?", patient_id])
		person	=	Person.find(patient_id)
		person_addresses = PersonAddress.find(:last, :conditions => ["person_id = ?", patient_id])

		person_params = {
      :given_name   =>  names.given_name,
      :family_name  =>  names.family_name,
      :middle_name  =>  names.middle_name,
      :gender       =>  person.gender,
      :birthdate    =>  person.birthdate,
      :birthdate_estimated => person.birthdate_estimated,
      :attributes => { 
        :occupation => "",
        :cellphone_number => nil,
                  
        :home_district    => (person_addresses.address2 rescue nil),            
        :home_traditional_authority => (person_addresses.county_district rescue nil),
        :home_village     => (person_addresses.neighborhood_cell rescue nil),    
        :current_district => (person_addresses.state_province rescue nil),       
        :current_traditional_authority => (person_addresses.address1 rescue nil),
        :current_village => (person_addresses.city_village rescue nil)
      },
      :identifiers => {}
    }

    dde_url = DDEService.dde_settings['dde_address'] + "/v1/add_person"
    output = RestClient::Request.execute( { :method => :post, :url => dde_url,
      :payload => person_params, :headers => {:Authorization => session[:dde_token]} } )
        
    identifier_type = PatientIdentifierType.find_by_name('National id').id

    dde_results  = JSON.parse(output)

		ActiveRecord::Base.transaction do
			if dde_results['message'].match(/missing/i)
				return dde_results['message'] + " <span style='color: white;'>Search by name and update patient address info<span>"
			end if dde_results['message']

      PatientIdentifier.create(:identifier => dde_results['npid'], 
        :patient_id => patient_id, :identifier_type => identifier_type)

      PatientIdentifier.create(:identifier => dde_results['doc_id'], 
        :patient_id => patient_id, :identifier_type => PatientIdentifierType.find_by_name('DDE person document ID').id)

		
      identifiers = PatientIdentifier.find(:all, 
        :conditions => ["patient_id = ? AND identifier_type = ?
        AND LENGTH(identifier) <> 6", patient_id, identifier_type])		
    
      (identifiers || []).each do |i|
        i.update_attributes(:voided => 1, :void_reason => "Reassigned new ID: #{dde_results['npid']}")
      end
		end
  end

  def patient_has_dde_identifier_already?(patient_id)

    identifier_type = PatientIdentifierType.find_by_name('National id').id

		identifiers = PatientIdentifier.find(:all, 
			:conditions => ["patient_id = ? AND identifier_type = ?
      AND LENGTH(identifier) = 6", patient_id, identifier_type])		

    unless identifiers.blank?	
      old_identifiers = PatientIdentifier.find(:all, 
        :conditions => ["patient_id = ? AND identifier_type = ?
        AND LENGTH(identifier) <> 6", patient_id, identifier_type])		
    
      (old_identifiers || []).each do |i|
        i.update_attributes(:voided => 1, :void_reason => "Reassigned new ID")
      end
    end

      return identifiers.first rescue nil 
    end


  end
