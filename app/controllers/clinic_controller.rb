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
    render :template => 'clinic/administration', :layout => 'clinic' 
  end

  def reports_tab
    @reports = [
      ["Cohort","/cohort_tool/cohort_menu"],
      ["Supervision","/clinic/supervision_tab"],
      ["Data Cleaning Tools", "/clinic/data_cleaning_tab"],
      ["OPD Reports", "/clinic/opd_tab"]
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

	def opd_tab
    @reports = [
						      ["OPD General", "/cohort_tool/opd_report_index"],
						      ["Disaggregated Diagnosis", "/cohort_tool/opd_menu?report_name=disaggregated_diagnosis"],
      						["Diagnosis (By address)", "/cohort_tool/opd_menu?report_name=diagnosis_by_address"],
      						["Patient Level Data", "/cohort_tool/opd_menu?report_name=patient_level_data"],
      						["Diagnosis Report", "/cohort_tool/opd_menu?report_name=diagnosis_report"],
      						["Total Registered", "/cohort_tool/opd_menu?report_name=total_registered"],
      						["Referrals", "/cohort_tool/opd_menu?report_name=referral"]
               ] 
    render :layout => false
	end

  def properties_tab
    @settings = [
      ["Set Clinic Days","/properties/clinic_days"],
      ["View Clinic Holidays","/properties/clinic_holidays"],
      ["Set Clinic Holidays","/properties/set_clinic_holidays"],
      ["Set Site Code", "/properties/site_code"],
      ["Manage Roles", "/properties/set_role_privileges"],
      ["Use Extended Staging Format", "/properties/creation?value=use_extended_staging_format"],
      ["Use User Selected Task(s)", "/properties/creation?value=use_user_selected_activities"],
      ["Use Filing Numbers", "/properties/creation?value=use_filing_numbers"],
      ["Show Lab Results", "/properties/creation?value=show_lab_results"],
      ["Set Appointment Limit", "/properties/set_appointment_limit"]
    ]
    render :layout => false
  end

end
