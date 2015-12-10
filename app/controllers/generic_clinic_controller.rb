class GenericClinicController < ApplicationController
  def index
  	session[:cohort] = nil
    @facility = Location.current_health_center.name rescue ''

    @location = Location.find(session[:location_id]).name rescue ""

    @date = (session[:datetime].to_date rescue Date.today).strftime("%Y-%m-%d")

    @user = current_user.name rescue ""

    @roles = current_user.user_roles.collect{|r| r.role} rescue []

    render :template => 'clinic/index', :layout => false
  end

  def reports
    @reports = [
      ["Cohort","/cohort_tool/cohort_menu"],
      ["Supervision","/clinic/supervision"],
      ["Data Cleaning Tools", "/report/data_cleaning"],
      ["Stock report","/drug/date_select"]
    ]

    render :template => 'clinic/reports', :layout => 'clinic' 
  end

  def supervision
    @supervision_tools = [["Data that was Updated","summary_of_records_that_were_updated"],
      ["Drug Adherence Level","adherence_histogram_for_all_patients_in_the_quarter"],
      ["Visits by Day", "visits_by_day"],
      ["Non-eligible Patients in Cohort", "non_eligible_patients_in_cohort"]]

    @landing_dashboard = 'clinic_supervision'

    render :template => 'clinic/supervision', :layout => 'clinic' 
  end

  def properties
    @settings = [
      ["Set clinic days","/properties/clinic_days"],
      ["View clinic holidays","/properties/clinic_holidays"],
      ["Set clinic holidays","/properties/set_clinic_holidays"],
      ["Set site code", "/properties/site_code"],
      ["Set appointment limit", "/properties/set_appointment_limit"]
    ]
    render :template => 'clinic/properties', :layout => 'clinic' 
  end

  def management
    @reports = [
      ["New stock","delivery"],
      ["Edit stock","edit_stock"],
      ["Print Barcode","print_barcode"],
      ["Expiring drugs","date_select"],
      ["Removed from shelves","date_select"],
      ["Stock report","date_select"]
    ]
    render :template => 'clinic/management', :layout => 'clinic' 
  end

  def printing
    render :template => 'clinic/printing', :layout => 'clinic' 
  end

  def users
    render :template => 'clinic/users', :layout => 'clinic' 
  end

  def administration
    @reports =  [
      ['/clinic/users','User accounts/settings'],
      ['/clinic/management','Drug Management'],
      ['/clinic/location_management','Location Management']
    ]
    @landing_dashboard = 'clinic_administration'
    render :template => 'clinic/administration', :layout => 'clinic' 
  end

  def overview_tab
    simple_overview_property = CoreService.get_global_property_value("simple_application_dashboard") rescue nil

    simple_overview = false
    if simple_overview_property != nil
      if simple_overview_property == 'true'
        simple_overview = true
      end
    end

    @types = CoreService.get_global_property_value("statistics.show_encounter_types") rescue EncounterType.all.map(&:name).join(",")
    @types = @types.split(/,/).delete_if.each{|t|t.match(/Registration/i)}
    @types.delete_if.each{|t|t.match(/Appointment/i)}
    #@types


    @me = Encounter.statistics(@types,:joins => {:patient =>{:person => {}}},
      :conditions => ['encounter_datetime BETWEEN ? AND ? AND encounter.creator = ?',
        Date.today.strftime('%Y-%m-%d 00:00:00'), Date.today.strftime('%Y-%m-%d 23:59:59'),
        current_user.user_id])
    @me_below_14 = Encounter.statistics(@types,:joins => {:patient =>{:person => {}}},
      :conditions => ['DATEDIFF(NOW(), person.birthdate)/365 < ? AND encounter_datetime BETWEEN ? AND ? AND encounter.creator = ?',
        14, Date.today.strftime('%Y-%m-%d 00:00:00'),Date.today.strftime('%Y-%m-%d 23:59:59'),
        current_user.user_id])

    @me_above_14 = Encounter.statistics(@types,:joins => {:patient =>{:person => {}}},
      :conditions => ['DATEDIFF(NOW(), person.birthdate)/365 >= ? AND encounter_datetime BETWEEN ? AND ? AND encounter.creator = ?',
        14, Date.today.strftime('%Y-%m-%d 00:00:00'),Date.today.strftime('%Y-%m-%d 23:59:59'),
        current_user.user_id])

    @today = Encounter.statistics(@types,
      :conditions => ['encounter_datetime BETWEEN ? AND ?',
        Date.today.strftime('%Y-%m-%d 00:00:00'),
        Date.today.strftime('%Y-%m-%d 23:59:59')])
    @today_below_14 = Encounter.statistics(@types,:joins => {:patient =>{:person => {}}},
      :conditions => ['DATEDIFF(NOW(), person.birthdate)/365 < ? AND encounter_datetime BETWEEN ? AND ?',
        14, Date.today.strftime('%Y-%m-%d 00:00:00'), Date.today.strftime('%Y-%m-%d 23:59:59')])

    @today_above_14 = Encounter.statistics(@types,:joins => {:patient =>{:person => {}}},
      :conditions => ['DATEDIFF(NOW(), person.birthdate)/365 >= ? AND encounter_datetime BETWEEN ? AND ?',
        14, Date.today.strftime('%Y-%m-%d 00:00:00'), Date.today.strftime('%Y-%m-%d 23:59:59')])
    @me_reg_below_14 = Patient.find(:all,:joins => [:person], :conditions => ['DATEDIFF(NOW(),
       person.birthdate)/365 < ? AND DATE(patient.date_created) =? AND patient.creator =? ',
        14, Date.today, current_user.user_id]).count
    @me_reg_above_14 = Patient.find(:all,:joins => [:person], :conditions => ['DATEDIFF(NOW(), 
       person.birthdate)/365 >= ? AND DATE(patient.date_created) =? AND patient.creator =? ',
        14, Date.today, current_user.user_id]).count
    @today_reg_below_14 = Patient.find(:all,:joins => [:person], :conditions => ['DATEDIFF(NOW(),
       person.birthdate)/365 < ? AND DATE(patient.date_created) =?', 14, Date.today]).count
    @today_reg_above_14 = Patient.find(:all,:joins => [:person], :conditions => ['DATEDIFF(NOW(),
       person.birthdate)/365 >= ? AND DATE(patient.date_created) =? ', 14, Date.today]).count
    
    @me_ret_pt_below_14 =  Encounter.find(:all, :joins => [:type, [:patient => :person] ],
      :group=>'patient.patient_id', :conditions => ['encounter_type_id IN (?) AND 
       DATE(patient.date_created) <> ? AND DATE(encounter.encounter_datetime) =?  AND
       encounter.creator = ? AND DATEDIFF(NOW(),person.birthdate)/365 < ?',
        EncounterType.find(:all, :conditions => ['name IN (?)',@types]).map(&:encounter_type_id),
        Date.today, Date.today,current_user.user_id,14] ).count
    #raise  @me_ret_pt_below_14.inspect
    @me_ret_pt_above_14 =  Encounter.find(:all, :joins => [:type, [:patient => :person] ],
      :group=>'patient.patient_id', :conditions => ['encounter_type_id IN (?) AND 
       DATE(patient.date_created) <> ? AND DATE(encounter.encounter_datetime) =?  AND
       encounter.creator = ? AND DATEDIFF(NOW(),person.birthdate)/365 >= ?',
        EncounterType.find(:all, :conditions => ['name IN (?)',@types]).map(&:encounter_type_id),
        Date.today, Date.today,current_user.user_id,14] ).count
    @ret_pt_below_14 =  Encounter.find(:all, :joins => [:type, [:patient => :person] ],
      :group=>'patient.patient_id', :conditions => ['encounter_type_id IN (?) AND
       DATE(patient.date_created) <> ? AND DATE(encounter.encounter_datetime) =? AND DATEDIFF(NOW(),person.birthdate)/365 < ?',
        EncounterType.find(:all, :conditions => ['name IN (?)',@types]).map(&:encounter_type_id),
        Date.today, Date.today,14] ).count

    @ret_pt_above_14 =  Encounter.find(:all, :joins => [:type, [:patient => :person] ],
      :group=>'patient.patient_id', :conditions => ['encounter_type_id IN (?) AND
       DATE(patient.date_created) <> ? AND DATE(encounter.encounter_datetime) =? AND DATEDIFF(NOW(),person.birthdate)/365 >= ?',
        EncounterType.find(:all, :conditions => ['name IN (?)',@types]).map(&:encounter_type_id),
        Date.today, Date.today,14] ).count
   
    if !simple_overview
      @year = Encounter.statistics(@types,
        :conditions => ['encounter_datetime BETWEEN ? AND ?',
          Date.today.strftime('%Y-01-01 00:00:00'),
          Date.today.strftime('%Y-12-31 23:59:59')])
      @ever = Encounter.statistics(@types)
    end

    @user = current_user.name  rescue "Me"

    if simple_overview
      render :template => 'clinic/overview_simple.rhtml' , :layout => false
      return
    end
    render :layout => false
  end

  def reports_tab
    @reports = [
      ["Cohort","/cohort_tool/cohort_menu"],
      ["Supervision","/clinic/supervision_tab"],
      ["Data Cleaning Tools", "/clinic/data_cleaning_tab"],
      ["View appointments","/report/select_date"]
    ]

    @reports = [
      ["Diagnosis","/drug/date_select?goto=/report/age_group_select?type=diagnosis"],
      # ["Patient Level Data","/drug/date_select?goto=/report/age_group_select?type=patient_level_data"],
      ["Disaggregated Diagnosis","/drug/date_select?goto=/report/age_group_select?type=disaggregated_diagnosis"],
      ["Referrals","/drug/date_select?goto=/report/opd?type=referrals"],
      #["Total Visits","/drug/date_select?goto=/report/age_group_select?type=total_visits"],
      #["User Stats","/drug/date_select?goto=/report/age_group_select?type=user_stats"],
      ["User Stats","/"],
      # ["Total registered","/drug/date_select?goto=/report/age_group_select?type=total_registered"],
      ["Diagnosis (By address)","/drug/date_select?goto=/report/age_group_select?type=diagnosis_by_address"],
      ["Diagnosis + demographics","/drug/date_select?goto=/report/age_group_select?type=diagnosis_by_demographics"]
    ] if Location.current_location.name.match(/Outpatient/i)
    render :layout => false
  end

  def data_cleaning_tab
    @reports = [
      ['Missing Prescriptions' , '/cohort_tool/select?report_type=dispensations_without_prescriptions'],
      ['Missing Dispensations' , '/cohort_tool/select?report_type=prescriptions_without_dispensations'],
      ['Multiple Start Reasons' , '/cohort_tool/select?report_type=patients_with_multiple_start_reasons'],
      ['Out of range ARV number' , '/cohort_tool/select?report_type=out_of_range_arv_number'],
      ['Data Consistency Check' , '/cohort_tool/select?report_type=data_consistency_check']
    ]
    render :layout => false
  end

  def properties_tab
    if current_program_location.match(/HIV program/i)
      @settings = [
        ["Set Clinic Days","/properties/clinic_days"],
        ["View Clinic Holidays","/properties/clinic_holidays"],
        ["Ask Pills remaining at home","/properties/creation?value=ask_pills_remaining_at_home"],
        ["Set Clinic Holidays","/properties/set_clinic_holidays"],
        ["Set Site Code", "/properties/site_code"],
        ["Manage Roles", "/properties/set_role_privileges"],
        ["Use Extended Staging Format", "/properties/creation?value=use_extended_staging_format"],
        ["Use User Selected Task(s)", "/properties/creation?value=use_user_selected_activities"],
        ["Use Filing Numbers", "/properties/creation?value=use_filing_numbers"],
        ["Show Lab Results", "/properties/creation?value=show_lab_results"],
        ["Set Appointment Limit", "/properties/set_appointment_limit"]
      ]
    else
      @settings = []
    end
    render :layout => false
  end

  def administration_tab
    @reports =  [
      ['/clinic/users_tab','User Accounts/Settings'],
      ['/clinic/location_management_tab','Location Management'],
      ['/patients/patient_merge','Merge Patients'],
      ['/clinic/preferred_diagnosis','Set Top 10 Diagnoses'],
      ['/clinic/preferred_drugs','Set Top 10 Drugs']
    ]
    if current_user.admin?
      @reports << ['/clinic/management_tab','Drug Management']
    end
    @landing_dashboard = 'clinic_administration'
    render :layout => false
  end

  def supervision_tab
    @reports = [
      ["Data that was Updated","/cohort_tool/select?report_type=summary_of_records_that_were_updated"],
      ["Drug Adherence Level","/cohort_tool/select?report_type=adherence_histogram_for_all_patients_in_the_quarter"],
      ["Visits by Day", "/cohort_tool/select?report_type=visits_by_day"],
      ["Non-eligible Patients in Cohort", "/cohort_tool/select?report_type=non_eligible_patients_in_cohort"]
    ]
    @landing_dashboard = 'clinic_supervision'
    render :layout => false
  end

  def users_tab
    render :layout => false
  end

  def location_management
    @reports =  [
      ['/location/new?act=create','Add location'],
      ['/location.new?act=delete','Delete location'],
      ['/location/new?act=print','Print location']
    ]
    render :template => 'clinic/location_management', :layout => 'clinic' 
  end

  def location_management_tab
    @reports =  [
      ['/location/new?act=print','Print location']
    ]
    if current_user.admin?
      @reports << ['/location/new?act=create','Add location']
      @reports << ['/location/new?act=delete','Delete location']
    end
    render :layout => false
  end

  def management_tab
    @reports = [
      ["Enter receipts<br />(from warehouse)","delivery"],
      ["Enter verified stock count<br />(supervision)","delivery?id=verification"],
      ["Print<br />Barcode","print_barcode"],
      ["Expiring<br />drugs","date_select"],
      ["Enter drug relocation<br />(in or out) / disposal","edit_stock"],
      ["Stock<br />report","date_select"]
    ]
    render :layout => false
  end
  
  def lab_tab
    #only applicable in the sputum submission area
    enc_date = session[:datetime].to_date rescue Date.today
    @types = ['LAB ORDERS', 'SPUTUM SUBMISSION', 'LAB RESULTS', 'GIVE LAB RESULTS']
    @me = Encounter.statistics(@types, :conditions => ['DATE(encounter_datetime) = ? AND encounter.creator = ?', enc_date, current_user.user_id])
    @today = Encounter.statistics(@types, :conditions => ['DATE(encounter_datetime) = ?', enc_date])
    @user = User.find(current_user.user_id).name rescue ""

    render :template => 'clinic/lab_tab.rhtml' , :layout => false
  end

  def preferred_diagnosis
    diagnosis_set = CoreService.get_global_property_value("application_diagnosis_concept")
		diagnosis_set = "Qech outpatient diagnosis list" if diagnosis_set.blank?
		diagnosis_concept_set = ConceptName.find_by_name(diagnosis_set).concept
		diagnosis_concepts = Concept.find(:all, :joins => [:concept_sets, :concept_names],
      :conditions => ['concept_set = ?', diagnosis_concept_set.id] , :group => "concept.concept_id",
      :order => "name ASC",
      :limit => 20)

    @diagnosis_hash = {}
		diagnosis_concepts.each do |concept|
      concept_id = concept.concept_id
			concept_fullname = concept.fullname
      @diagnosis_hash[concept_id] = {:name => concept_fullname}
    end

    @diagnosis_hash = @diagnosis_hash.sort_by{|k, v|v[:name]}

    @preferred_diagnoses = {}
    preferred_diagnosis_concept_ids = GlobalProperty.find(:last, :conditions => ["property =?", 'preferred.diagnosis.concept_id']).property_value.split(", ") rescue []
    preferred_diagnosis_concept_ids.each do |concept_id|
      diagnosis_name = Concept.find(concept_id).fullname
      @preferred_diagnoses[concept_id] = {:name => diagnosis_name}
    end

    render :layout => false
  end

  def diagnosis_search

		diagnosis_set = CoreService.get_global_property_value("application_diagnosis_concept")
		diagnosis_set = "Qech outpatient diagnosis list" if diagnosis_set.blank?
		diagnosis_concept_set = ConceptName.find_by_name(diagnosis_set).concept
		diagnosis_concepts = Concept.find(:all, :joins => [:concept_sets, :concept_names],
      :conditions => ['concept_set = ? AND name LIKE ?', diagnosis_concept_set.id, '%' + params[:search_string] + '%'],
      :group => "concept.concept_id",
      :order => "name ASC",
      :limit => 20)

    diagnosis_hash = {}
		diagnosis_concepts.each do |concept|
      concept_id = concept.concept_id
			concept_fullname = concept.fullname
      diagnosis_hash[concept_id] = {:name => concept_fullname}
    end

		render :json => diagnosis_hash.sort_by{|k, v|v[:name]} and return
	end

  def save_diagnoses
    ActiveRecord::Base.transaction do
      property_name = 'preferred.diagnosis.concept_id'
      old_property = GlobalProperty.find(:last, :conditions => ["property =?", property_name])
      old_property.delete unless old_property.blank?

      new_property = GlobalProperty.new()
      new_property.property = property_name
      new_property.property_value = (params[:concept_ids].join(', ') rescue '')
      new_property.save
    end

    redirect_to("/clinic/preferred_diagnosis") and return
  end

  def preferred_drugs
    @generic_drugs = MedicationService.generic
    @preferred_drugs = []
    preferred_diagnosis_concept_ids = GlobalProperty.find(:last, 
      :conditions => ["property =?", 'preferred.drugs.concept_id']).property_value.split(", ") rescue []
    
    preferred_diagnosis_concept_ids.each do |concept_id|
      drug_name = Concept.find(concept_id).fullname
      @preferred_drugs << [concept_id, drug_name]
    end

    render :layout => false
  end

  def preferred_drugs_search
    search_string = params[:search_string].upcase
    generic_drugs = MedicationService.generic
    
    generic_drugs = generic_drugs.map{|generic_drug|
			drug_name = generic_drug[0]
			drug_name.upcase.include?(search_string) ? generic_drug : nil rescue nil
		}.compact

    hash = {}
    
    generic_drugs.each do |drug|
      name = drug[0]
      concept_id  = drug[1]
      hash[concept_id] = name
    end

    render :json => hash
  end

  def save_preferred_drugs
    ActiveRecord::Base.transaction do
      property_name = 'preferred.drugs.concept_id'
      old_property = GlobalProperty.find(:last, :conditions => ["property =?", property_name])
      old_property.delete unless old_property.blank?

      new_property = GlobalProperty.new()
      new_property.property = property_name
      new_property.property_value = (params[:concept_ids].join(', ') rescue '')
      new_property.save
    end

    redirect_to("/clinic/preferred_drugs") and return
  end
  
end
