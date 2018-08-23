class GenericApplicationController < ActionController::Base
  Mastercard
  PatientIdentifierType
  PatientIdentifier
  PersonAttribute
  PersonAttributeType
  WeightHeight
  CohortTool
  Encounter
  EncounterType
  Location
  DrugOrder
  User
  Task
  GlobalProperty
  Person
  Regimen
  Relationship
  ConceptName
  Concept
  Settings
	require "fastercsv"

	helper :all
	helper_method :next_task
	filter_parameter_logging :password
	before_filter :authenticate_user!, :except => ['normal_visits','transfer_in_visits', 're_initiation_visits','patients_without_any_encs','login', 'logout','remote_demographics','art_stock_info',
    'create_remote', 'mastercard_printable', 'get_token',
    'cohort','demographics_remote', 'export_on_art_patients', 'art_summary',
    'art_summary_dispensation', 'print_rules', 'rule_variables', 'print',
    'new_prescription', 'search_for_drugs','mastercard_printable',
    'remote_app_search', 'remotely_reassign_new_identifier',
    'create_person_from_anc', 'create_person_from_dmht',
    'find_person_from_dmht', 'reassign_remote_identifier',
    'revised_cohort_to_print', 'revised_cohort_survival_analysis_to_print',
    'revised_women_cohort_survival_analysis_to_print',
    'revised_children_cohort_survival_analysis_to_print', 'create', 'render_date_enrolled_in_art', 'search_remote_people'
  ]

  before_filter :set_current_user, :except => ['login', 'logout','remote_demographics','art_stock_info',
    'create_remote', 'mastercard_printable', 'get_token', 'given_names',
    'cohort','demographics_remote', 'export_on_art_patients', 'art_summary',
    'art_summary_dispensation', 'print_rules', 'rule_variables',
    'print','new_prescription', 'search_for_drugs',
    'mastercard_printable', 'remote_app_search',
    'remotely_reassign_new_identifier', 'create_person_from_anc',
    'create_person_from_dmht', 'find_person_from_dmht',
    'reassign_remote_identifier','revised_cohort_to_print',
    'revised_cohort_survival_analysis_to_print',
    'revised_women_cohort_survival_analysis_to_print',
    'revised_children_cohort_survival_analysis_to_print', 'render_date_enrolled_in_art', 'search_remote_people'
  ]

	before_filter :location_required, :except => ['patients_without_any_encs','login', 'logout', 'given_names', 'location',
    'demographics','create_remote',
    'mastercard_printable','art_stock_info',
    'remote_demographics', 'get_token',
    'cohort','demographics_remote', 'export_on_art_patients', 'art_summary',
    'art_summary_dispensation', 'print_rules', 'rule_variables',
    'print','new_prescription', 'search_for_drugs','mastercard_printable',
    'remote_app_search', 'remotely_reassign_new_identifier',
    'create_person_from_anc', 'create_person_from_dmht',
    'find_person_from_dmht', 'reassign_remote_identifier',
    'revised_cohort_to_print', 'revised_cohort_survival_analysis_to_print',
    'revised_women_cohort_survival_analysis_to_print',
    'revised_children_cohort_survival_analysis_to_print', 'render_date_enrolled_in_art', 'search_remote_people'
  ]

	before_filter :set_return_uri, :except => ['create_person_from_anc', 'create_person_from_dmht', 'given_names',
    'find_person_from_dmht', 'reassign_remote_identifier', 'create', 'render_date_enrolled_in_art', 'search_remote_people']

  before_filter :set_dde_token

  def set_dde_token
    if create_from_dde_server
      unless current_user.blank?
        if session[:dde_token].blank?
          dde_token = DDEService.dde_authentication_token
          puts "Am in"
          session[:dde_token] = dde_token
        else
          token_status = DDEService.verify_dde_token_authenticity(session[:dde_token])
          if token_status.to_s == '401' || token_status.blank?
            dde_token = DDEService.dde_authentication_token
            session[:dde_token] = dde_token
          end
        end
      end
    else
      session[:dde_token] = nil  
    end
  end

  def create_from_dde
    return false
  end

	def rescue_action_in_public(exception)
		@message = exception.message
		@backtrace = exception.backtrace.join("\n") unless exception.nil?
		logger.info @message
		logger.info @backtrace
		render :file => "#{RAILS_ROOT}/app/views/errors/error.rhtml", :layout=> false, :status => 404
	end if RAILS_ENV == 'development' || RAILS_ENV == 'test'

  def rescue_action(exception)
    @message = exception.message
    @backtrace = exception.backtrace.join("\n") unless exception.nil?
    logger.info @message
    logger.info @backtrace
    render :file => "#{RAILS_ROOT}/app/views/errors/error.rhtml", :layout=> false, :status => 404
  end if RAILS_ENV == 'production'

  def print_and_redirect(print_url, redirect_url, message = "Printing, please wait...", show_next_button = false, patient_id = nil)
    @print_url = print_url
    @redirect_url = redirect_url
    @message = message
    @show_next_button = show_next_button
    @patient_id = patient_id
    render :template => 'print/print', :layout => nil
  end
  
  def print_location_and_redirect(print_url, redirect_url, message = "Printing, please wait...", show_next_button = false, patient_id = nil)
    @print_url = print_url
    @redirect_url = redirect_url
    @message = message
    @show_next_button = show_next_button
    render :template => 'print/print_location', :layout => nil
  end

  def show_lab_results
    CoreService.get_global_property_value('show.lab.results').to_s == "true" rescue false
  end

  def use_filing_number
    CoreService.get_global_property_value('use.filing.number').to_s == "true" rescue false
  end 

  def cervical_cancer_activated
    CoreService.get_global_property_value('activate.cervical.cancer.screening').to_s == "true" rescue false
  end

  def generic_locations
    field_name = "name"

    Location.find_by_sql("SELECT *
          FROM location
          WHERE location_id IN (SELECT location_id
                         FROM location_tag_map
                          WHERE location_tag_id = (SELECT location_tag_id
                                 FROM location_tag
                                 WHERE name = 'Workstation Location' LIMIT 1))
             ORDER BY name ASC").collect{|name| name.send(field_name)} rescue []
  end

  def site_prefix
    site_prefix = Location.current_health_center.neighborhood_cell
    return site_prefix
  end

	def use_user_selected_activities
		CoreService.get_global_property_value('use.user.selected.activities').to_s == "true" rescue false
	end
  
  def tb_dot_sites_tag
    CoreService.get_global_property_value('tb_dot_sites_tag') rescue nil
  end

  def create_from_remote                                                        
    CoreService.get_global_property_value('create.from.remote').to_s == "true" rescue false
  end

  def create_from_dde_server
    program_id  = YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env]["program_id"]
    #CoreService.get_global_property_value('create.from.dde.server').to_s == "true" rescue false
    dde_status = GlobalProperty.find_by_property('dde.status').property_value.to_s.squish rescue 'NO'#New DDE API
    if (dde_status.upcase == 'ON')
      dde_user = DdeApplicationUsers.find_by_program_id(program_id)
      if dde_user.blank?
        return false
      end
      return true
    else
      return false
    end
  end

  def military_site?
    return false
  end

  def concept_set(concept_name)
    concept_id = ConceptName.find_by_name(concept_name).concept_id
    set = ConceptSet.find_all_by_concept_set(concept_id, :order => 'sort_weight')
    options = set.map{|item|next if item.concept.blank? ; [item.concept.fullname, item.concept.fullname] }

    return options
  end

  def concept_set_diff(concept_name, exclude_concept_name)
    concept_id = ConceptName.find_by_name(concept_name).concept_id
    
    set = ConceptSet.find_all_by_concept_set(concept_id, :order => 'sort_weight')
    options = set.map{|item|next if item.concept.blank? ; [item.concept.fullname, item.concept.fullname] }

    exclude_concept_id = ConceptName.find_by_name(exclude_concept_name).concept_id
    exclude_set = ConceptSet.find_all_by_concept_set(exclude_concept_id, :order => 'sort_weight')
    exclude_options = exclude_set.map{|item|next if item.concept.blank? ; [item.concept.fullname, item.concept.fullname] }

    final_options = (options - exclude_options)
    return final_options
  end


  def next_task(patient)
    session_date = session[:datetime].to_date rescue Date.today
    task = nil
    begin
      return task.url if task.present? && task.url.present?
      return "/patients/show/#{patient.id}" 
    rescue
      return "/patients/show/#{patient.id}" 
    end
  end

  def current_user_roles
    user_roles = UserRole.find(:all,:conditions =>["user_id = ?", current_user.id]).collect{|r|r.role}
    RoleRole.find(:all,:conditions => ["child_role IN (?)", user_roles]).collect{|r|user_roles << r.parent_role}
    return user_roles.uniq
  end

  def current_program_location
    current_user_activities = current_user.activities
    if Location.current_location.name.downcase == 'outpatient'
      return "OPD"
    elsif current_user_activities.include?('Manage Lab Orders') or current_user_activities.include?('Manage Lab Results') or
        current_user_activities.include?('Manage Sputum Submissions') or current_user_activities.include?('Manage TB Clinic Visits') or
        current_user_activities.include?('Manage TB Reception Visits') or current_user_activities.include?('Manage TB Registration Visits') or
        current_user_activities.include?('Manage HIV Status Visits')
      return 'TB program'
    else #if current_user_activities
      return 'HIV program'
    end
  end

	def location_required
		if not located? and params[:location]
			location = Location.find(params[:location]) rescue nil
			self.current_location = location if location
		end

		if not located? and session[:sso_location]
			location = Location.find(session[:sso_location]) rescue nil
			self.current_location = location if location
		end

		located? || location_denied
	end

	def set_return_uri
		if params[:return_uri]
			session[:return_uri] = params[:return_uri]
		end
	end

  def located?
    self.current_location
  end

  # Redirect as appropriate when an access request fails.
  #
  # The default action is to redirect to the location screen.
  def location_denied
    respond_to do |format|
      format.html do
        store_location
        redirect_to '/location'
      end
    end
  end

  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.request_uri
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.  Set an appropriately modified
  #   after_filter :store_location, :only => [:index, :new, :show, :edit]
  # for any controller you want to be bounce-backable.
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  # Accesses the current user from the session.
  # Future calls avoid the database because nil is not equal to false.
  def current_location
    @current_location ||= location_from_session unless @current_location == false
    Location.current_location = @current_location unless @current_location == false
    @current_location
  end

  # Store the given location id in the session.
  def current_location=(new_location)
    session[:location_id] = new_location ? new_location.id : nil
    @current_location = new_location || false
  end

  # Called from #current_location.  First attempt to get the location id stored in the session.
  def location_from_session
    self.current_location = Location.find_by_location_id(session[:location_id]) if session[:location_id]
  end

  def set_current_user
    User.current = current_user
  end


  private

  def find_patient
    @patient = Patient.find(params[:patient_id] || session[:patient_id] || params[:id]) rescue nil
  end

  def has_patient_been_on_art_before(patient)
    on_art = false
    patient_states = PatientProgram.find(:first, :conditions => ["program_id = ? AND location_id = ? AND patient_id = ?",      
        Program.find_by_concept_id(Concept.find_by_name('HIV PROGRAM').id).id,
        Location.current_health_center,patient.id]).patient_states rescue []

    (patient_states || []).each do |state|
      if state.program_workflow_state.concept.fullname.match(/antiretrovirals/i)
        on_art = true
      end
    end
    return on_art
  end
end
