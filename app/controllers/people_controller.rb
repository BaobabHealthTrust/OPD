class PeopleController < GenericPeopleController

  def demographics
    # Search by the demographics that were passed in and then return demographics
    people = PatientService.find_person_by_demographics(params)
    result = people.empty? ? {} : PatientService.demographics(people.first)
    render :text => result.to_json
  end
  
  def confirm
    session_date = session[:datetime] || Date.today
    if request.post?
      redirect_to search_complete_url(params[:found_person_id], params[:relation]) and return
    end
    @found_person_id = params[:found_person_id] 
    @relation = params[:relation]
    @person = Person.find(@found_person_id) rescue nil
    @task = main_next_task(Location.current_location, @person.patient, session_date.to_date)
    @arv_number = PatientService.get_patient_identifier(@person, 'ARV Number')
	  @patient_bean = PatientService.get_patient(@person)
    render :layout => false
  end

=begin 
  def create
    success = false
    Person.session_datetime = session[:datetime].to_date rescue Date.today
    identifier = params[:identifier] rescue nil
    if identifier.blank?
      identifier = params[:person][:patient][:identifiers]['National id']
    end rescue nil

    if create_from_dde_server
      unless identifier.blank?
        params[:person].merge!({"identifiers" => {"National id" => identifier}})
        success = true
        person = PatientService.create_from_form(params[:person])
        if identifier.length != 6
           patient = DDEService::Patient.new(person.patient)
           national_id_replaced = patient.check_old_national_id(identifier)
        end
      else
        person = PatientService.create_patient_from_dde(params)
        success = true
      end

    #for now BART2 will use BART1 for patient/person creation until we upgrade BART1 to 2
    #if GlobalProperty.find_by_property('create.from.remote') and property_value == 'yes'
    #then we create person from remote machine
    elsif create_from_remote
      person_from_remote = PatientService.create_remote_person(params)
      person = PatientService.create_from_form(person_from_remote["person"]) unless person_from_remote.blank?

      if !person.blank?
        success = true
        #person.patient.remote_national_id
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

       tb_session = false
       if current_user.activities.include?('Manage Lab Orders') or current_user.activities.include?('Manage Lab Results') or
        current_user.activities.include?('Manage Sputum Submissions') or current_user.activities.include?('Manage TB Clinic Visits') or
         current_user.activities.include?('Manage TB Reception Visits') or current_user.activities.include?('Manage TB Registration Visits') or
          current_user.activities.include?('Manage HIV Status Visits')
         tb_session = true
       end

        #raise use_filing_number.to_yaml
        if use_filing_number and not tb_session
          PatientService.set_patient_filing_number(person.patient)
          archived_patient = PatientService.patient_to_be_archived(person.patient)
          message = PatientService.patient_printing_message(person.patient,archived_patient,creating_new_patient = true)
          unless message.blank?
            print_and_redirect("/patients/filing_number_and_national_id?patient_id=#{person.id}" , next_task(person.patient),message,true,person.id)
          else
            print_and_redirect("/patients/filing_number_and_national_id?patient_id=#{person.id}", next_task(person.patient))
          end
        else
          print_and_redirect("/patients/national_id_label?patient_id=#{person.id}", next_task(person.patient))
        end
      end
    else
      # Does this ever get hit?
      redirect_to :action => "index"
    end
  end
=end

  def dde_duplicates
    @dde_duplicates = {}
    session[:duplicate_npid] = params[:npid]
    dde_search_results = PatientService.search_dde_by_identifier(params[:npid], session[:dde_token])
    dde_hits = dde_search_results["data"]["hits"] rescue []
    i = 1

    dde_hits.each do |dde_hit|
      @dde_duplicates[i] = {}
      @dde_duplicates[i]["first_name"] = dde_hit["names"]["given_name"]
      @dde_duplicates[i]["family_name"] = dde_hit["names"]["family_name"]
      @dde_duplicates[i]["gender"] = dde_hit["gender"]
      @dde_duplicates[i]["birthdate"] = dde_hit["birthdate"]
      @dde_duplicates[i]["npid"] = dde_hit["_id"]
      @dde_duplicates[i]["current_village"] = dde_hit["addresses"]["current_village"]
      @dde_duplicates[i]["home_village"] = dde_hit["addresses"]["home_village"]
      @dde_duplicates[i]["current_residence"] = dde_hit["addresses"]["current_residence"]
      @dde_duplicates[i]["home_district"] = dde_hit["addresses"]["home_district"]
      i = i + 1;
    end

    render :layout => 'menu'
  end
  
end
 
