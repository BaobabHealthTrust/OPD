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

  def malaria_dashboard
    outpatient_encounter_type_id = EncounterType.find_by_name("OUTPATIENT DIAGNOSIS").encounter_type_id
    lab_orders_encounter_type_id = EncounterType.find_by_name("LAB ORDERS").encounter_type_id
    lab_result_encounter_type_id = EncounterType.find_by_name("LAB RESULTS").encounter_type_id

    tests_ordered_concept_id = Concept.find_by_name("TESTS ORDERED").concept_id
    malaria_concept_id = Concept.find_by_name("MALARIA").concept_id
    malaria_test_result_concept_id = Concept.find_by_name("MALARIA TEST RESULT").concept_id
    unknown_concept_id = Concept.find_by_name("UNKNOWN").concept_id
    diagnosis_concept_ids = ["PRIMARY DIAGNOSIS", "SECONDARY DIAGNOSIS", "ADDITIONAL DIAGNOSIS"].collect do |concept_name|
      Concept.find_by_name(concept_name).concept_id
    end


    malaria_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{outpatient_encounter_type_id}
        AND o.concept_id IN (#{diagnosis_concept_ids.join(', ')}) AND o.value_coded = #{malaria_concept_id}
        AND e.voided=0 AND DATE(e.encounter_datetime) <= '#{Date.today}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @malaria_cases_count = malaria_observations.count

    microscopy_order_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_orders_encounter_type_id}
        AND o.concept_id = #{tests_ordered_concept_id} AND UPPER(o.value_text) = 'MICROSCOPY'
        AND e.voided=0 AND DATE(e.encounter_datetime) <= '#{Date.today}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")
    
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>MICROSCOPY QUERIES START>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    @microscopy_total_orders = microscopy_order_observations
    microscopy_order_accession_numbers = microscopy_order_observations.map(&:accession_number).compact

    microscopy_positive_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{microscopy_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = 'THICK SMEAR POSITIVE'
        AND e.voided=0 AND DATE(e.encounter_datetime) <= '#{Date.today}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @microscopy_positive_results_count = microscopy_positive_results_observations.count

    microscopy_negative_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{microscopy_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = 'THICK SMEAR NEGATIVE'
        AND e.voided=0 AND DATE(e.encounter_datetime) <= '#{Date.today}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @microscopy_negative_results_count = microscopy_negative_results_observations.count

    microscopy_uknown_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{microscopy_order_accession_numbers.join(', ')})
        AND o.value_coded = #{unknown_concept_id}
        AND e.voided=0 AND DATE(e.encounter_datetime) <= '#{Date.today}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @microscopy_uknown_results_count = microscopy_uknown_results_observations.count
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>mRDT QUERIES>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


    mrdt_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_orders_encounter_type_id}
        AND o.concept_id = #{tests_ordered_concept_id} AND UPPER(o.value_text) = 'MRDT'
        AND e.voided=0 AND DATE(e.encounter_datetime) <= '#{Date.today}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @mrdt_total_orders = mrdt_observations.count
    mrdtder_accession_numbers = mrdt_observations.map(&:accession_number).compact
    
    render :layout => false
  end
  
end
