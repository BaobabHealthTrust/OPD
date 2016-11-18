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
      #["OPD General", "/cohort_tool/opd_report_index"],
      ["Disaggregated Diagnosis", "/cohort_tool/opd_menu?report_name=disaggregated_diagnosis"],
      ["Diagnosis (By address)", "/cohort_tool/opd_menu?report_name=diagnosis_by_address"],
      #["Patient Level Data", "/cohort_tool/opd_menu?report_name=patient_level_data"],
      ["Diagnosis Report", "/cohort_tool/opd_menu?report_name=diagnosis_report"],
      ["Diagnosis Specific Report", "/cohort_tool/diagnosis_specific_report_menu?report_name=diagnosis_specific_report"],
      ["Total Registered", "/cohort_tool/opd_menu?report_name=total_registered"],
      ["Referrals", "/cohort_tool/opd_menu?report_name=referral"],
      #["Transfer Out", "/cohort_tool/opd_menu?report_name=transfer_out"],
      #["Shift Report", "/cohort_tool/opd_menu?report_name=shift_report"],
      #["Graphical Reports", "/clinic/reports_tab_graphs"],
      ["Update DHIS2", "/report/update_dhis"],
      ["Malaria Report", "/report/malaria_report_menu"],
      ["LA Report", "/report/la_report_menu"]
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
      ["Point of care system?", "/properties/creation?value=point_of_care_system"],
      ["Activate Malaria Feature", "/properties/creation?value=is_this_malaria_enabled_facility?"],
      ["Shares Database with BART2?", "/properties/creation?value=does_this_system_share_database_with_bart?"],
      ["Do you print specimen labels?", "/properties/creation?value=specimen_label_print?"],
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
    @microscopy_total_orders = microscopy_order_observations.count
    microscopy_order_accession_numbers = microscopy_order_observations.map(&:accession_number).compact
    microscopy_order_accession_numbers = [0] if microscopy_order_accession_numbers.blank?
    
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
    mrdt_order_accession_numbers = mrdt_observations.map(&:accession_number).compact
    mrdt_order_accession_numbers = [0] if mrdt_order_accession_numbers.blank?

    mrdt_positive_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{mrdt_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = 'MALARIA RDT POSITIVE'
        AND e.voided=0 AND DATE(e.encounter_datetime) <= '#{Date.today}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")
    
    @mrdt_positive_results_count = mrdt_positive_results_observations.count

    mrdt_negative_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{mrdt_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = 'MALARIA RDT NEGATIVE'
        AND e.voided=0 AND DATE(e.encounter_datetime) <= '#{Date.today}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @mrdt_negative_results_count = mrdt_negative_results_observations.count

    mrdt_unknown_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{mrdt_order_accession_numbers.join(', ')})
        AND o.value_coded = #{unknown_concept_id}
        AND e.voided=0 AND DATE(e.encounter_datetime) <= '#{Date.today}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @mrdt_unknown_results_count = mrdt_unknown_results_observations.count

    #>>>>>>>>>>>>>>>>DRUG PRESCRIPTION <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    treatment_encounter_type_id = EncounterType.find_by_name("TREATMENT").encounter_type_id
    dispensing_encounter_type_id = EncounterType.find_by_name("DISPENSING").encounter_type_id
    amount_dispensed_concept = Concept.find_by_name('Amount dispensed').id
    drug_order_type_id = OrderType.find_by_name("Drug Order").order_type_id

    la_one_drug_id = Drug.find_by_name("Lumefantrine + Arthemether 1 x 6").drug_id rescue 0 #Add this drug to meta-data
    la_two_drug_id = Drug.find_by_name("Lumefantrine + Arthemether 2 x 6").drug_id
    la_three_drug_id = Drug.find_by_name("Lumefantrine + Arthemether 3 x 6").drug_id
    la_four_drug_id = Drug.find_by_name("Lumefantrine + Arthemether 4 x 6").drug_id

    #as total_prescribed_drugs
    @total_la_one_prescribed_drugs = Order.find_by_sql("
        SELECT SUM((ABS(DATEDIFF(o.auto_expire_date, o.start_date)) * do.equivalent_daily_dose)) as total_prescribed_drugs
        FROM encounter e INNER JOIN encounter_type et
        ON e.encounter_type = et.encounter_type_id INNER JOIN orders o
        ON e.encounter_id = o.encounter_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{treatment_encounter_type_id}
        AND do.drug_inventory_id = #{la_one_drug_id} AND
        o.order_type_id = #{drug_order_type_id} AND e.encounter_datetime <= \"#{Date.today} 23:59:59\"
        AND e.voided=0 GROUP BY do.drug_inventory_id" 
    ).last.total_prescribed_drugs rescue 0

    @total_la_one_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e 
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND do.drug_inventory_id = #{la_one_drug_id}
        AND obs.concept_id = #{amount_dispensed_concept} AND e.voided=0 GROUP BY d.drug_id"
    ).last.total_dispensed_drugs rescue 0

    @total_la_two_prescribed_drugs = Order.find_by_sql("
        SELECT SUM((ABS(DATEDIFF(o.auto_expire_date, o.start_date)) * do.equivalent_daily_dose)) as total_prescribed_drugs
        FROM encounter e INNER JOIN encounter_type et
        ON e.encounter_type = et.encounter_type_id INNER JOIN orders o
        ON e.encounter_id = o.encounter_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{treatment_encounter_type_id}
        AND do.drug_inventory_id = #{la_two_drug_id} AND
        o.order_type_id = #{drug_order_type_id} AND e.encounter_datetime <= \"#{Date.today} 23:59:59\"
        AND e.voided=0 GROUP BY do.drug_inventory_id"
    ).last.total_prescribed_drugs rescue 0

    @total_la_two_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND do.drug_inventory_id = #{la_two_drug_id}
        AND obs.concept_id = #{amount_dispensed_concept} AND e.voided=0 GROUP BY d.drug_id"
    ).last.total_dispensed_drugs rescue 0

    @total_la_three_prescribed_drugs = Order.find_by_sql("
        SELECT SUM((ABS(DATEDIFF(o.auto_expire_date, o.start_date)) * do.equivalent_daily_dose)) as total_prescribed_drugs
        FROM encounter e INNER JOIN encounter_type et
        ON e.encounter_type = et.encounter_type_id INNER JOIN orders o
        ON e.encounter_id = o.encounter_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{treatment_encounter_type_id}
        AND do.drug_inventory_id = #{la_three_drug_id} AND
        o.order_type_id = #{drug_order_type_id} AND e.encounter_datetime <= \"#{Date.today} 23:59:59\"
        AND e.voided=0 GROUP BY do.drug_inventory_id"
    ).last.total_prescribed_drugs rescue 0

    @total_la_three_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND do.drug_inventory_id = #{la_three_drug_id}
        AND obs.concept_id = #{amount_dispensed_concept} AND e.voided=0 GROUP BY d.drug_id"
    ).last.total_dispensed_drugs rescue 0
    
    @total_la_four_prescribed_drugs = Order.find_by_sql("
        SELECT SUM((ABS(DATEDIFF(o.auto_expire_date, o.start_date)) * do.equivalent_daily_dose)) as total_prescribed_drugs
        FROM encounter e INNER JOIN encounter_type et
        ON e.encounter_type = et.encounter_type_id INNER JOIN orders o
        ON e.encounter_id = o.encounter_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{treatment_encounter_type_id}
        AND do.drug_inventory_id = #{la_four_drug_id} AND
        o.order_type_id = #{drug_order_type_id} AND e.encounter_datetime <= \"#{Date.today} 23:59:59\"
        AND e.voided=0 GROUP BY do.drug_inventory_id"
    ).last.total_prescribed_drugs rescue 0

    @total_la_four_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND do.drug_inventory_id = #{la_four_drug_id}
        AND obs.concept_id = #{amount_dispensed_concept} AND e.voided=0 GROUP BY d.drug_id"
    ).last.total_dispensed_drugs rescue 0

    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    render :layout => false
  end

  def load_malaria_dashboard_data
=begin
    malaria_ip_addresses = CoreService.get_global_property_value("malaria_ip_addresses").split(", ") rescue []
    malaria_data = {}
    malaria_ip_addresses.each do |ip_address|

      JSON.parse(RestClient.get(ip_address))
    end
=end
  end
  
end
