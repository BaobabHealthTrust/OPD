class ClinicController < GenericClinicController

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

  def administration
    @reports =  [
                  ['/clinic/users','User accounts/settings'],
                  ['/clinic/management','Drug Management'], 
                  ['/clinic/location_management','Location Management']
                ]
    @landing_dashboard = 'clinic_administration'
#    render :template => 'clinic/administration', :layout => 'clinic' 
  end

  def reports_tab
    session[:observation] = nil
    session[:people] = nil
    @reports = [
						      ["OPD General", "/cohort_tool/opd_report_index"],
						      ["Disaggregated Diagnosis", "/cohort_tool/opd_menu?report_name=disaggregated_diagnosis"],
      						["Diagnosis (By address)", "/cohort_tool/opd_menu?report_name=diagnosis_by_address"],
      						#["Patient Level Data", "/cohort_tool/opd_menu?report_name=patient_level_data"],
      						["Diagnosis Report", "/cohort_tool/opd_menu?report_name=diagnosis_report"],
      						["Total Registered", "/cohort_tool/opd_menu?report_name=total_registered"],
      						["Referrals", "/cohort_tool/opd_menu?report_name=referral"],
      						["Transfer Out", "/cohort_tool/opd_menu?report_name=transfer_out"],
      						["Shift Report", "/cohort_tool/opd_menu?report_name=shift_report"],
      						["Graphical Reports", "/clinic/reports_tab_graphs"],
      						["Update DHIS2", "/report/update_dhis"]
               ] 
        #if allowed_hiv_viewer
        	#@reports << ["Patient Level Data", "/cohort_tool/opd_menu?report_name=patient_level_data"]
        #end
    render :layout => false
  end
  
  def reports_tab_graphs
	   session[:observation] = nil
    session[:people] = nil
    @facility = Location.current_health_center.name rescue ''

    @location = Location.find(session[:location_id]).name rescue ""

    @date = (session[:datetime].to_date rescue Date.today).strftime("%Y-%m-%d")

    @user = current_user.name rescue ""

    @roles = current_user.user_roles.collect{|r| r.role} rescue []

    @reports = [
						      ["OPD General", "/cohort_tool/opd_report_index_graph"],
	     						["Diagnosis Report", "/cohort_tool/opd_menu?report_name=diagnosis_report_graph"],
	     						["Total Registered", "/cohort_tool/opd_menu?report_name=total_registered_graph"],
      						["Transfer Out", "/cohort_tool/opd_menu?report_name=referals_graph"]
      						
               ] 
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
    @settings = [
      ["Manage Roles", "/properties/set_role_privileges"],
      ["Confirm patient creation", "/properties/creation?value=confirm_before_creating_a_patient"],
      ["Ask social history questions", "/properties/creation?value=ask_social_history_questions"],
      ["Ask Life threatening questions", "/properties/creation?value=ask_life_threatening_condition_questions"],
      ["Ask triage category questions", "/properties/creation?value=ask_triage_category_questions"],
      ["Ask vitals before diagnosis (children)", "/properties/creation?value=ask_vitals_questions_before_diagnosis"],
      ["Ask social determinats questions", "/properties/creation?value=ask_social_determinants_questions"],
      ["Ask complaints under vitals", "/properties/creation?value=ask_complaints_under_vitals"],
      ["Ask complaints before diagnosis", "/properties/creation?value=ask_complaints_before_diagnosis"],
      ["Show Lab Results", "/properties/creation?value=show_lab_results"],
      ["show column prescription Interface", "/properties/creation?value=use_column_interface"],
      ["show Tasks button on patient dashboard", "/properties/creation?value=show_tasks_button"],
      ["Point of care system?", "/properties/creation?value=point_of_care_system"]
    ]
    render :layout => false
  end

end
