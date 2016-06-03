class GenericReportController < ApplicationController

  include PdfHelper

  def weekly_report
    @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
    if @start_date > @end_date
      flash[:notice] = 'Start date is greater that end date'
      redirect_to :action => 'select'
      return
    end
    @diagnoses = ConceptName.find(:all,
                                  :joins =>
                                        "INNER JOIN obs ON
                                         concept_name.concept_id = obs.value_coded AND obs.voided = 0",
                                  :conditions => ["date_format(obs_datetime, '%Y-%m-%d') >= ? AND date_format(obs_datetime, '%Y-%m-%d') <= ?",
                                            @start_date, @end_date],
                                  :group =>   "name",
                                  :select => "concept_name.concept_id,concept_name.name,obs.value_coded,obs.obs_datetime,obs.voided")
    @patient = Person.find(:all,
                           :joins => 
                                "INNER JOIN obs ON 
                                 person.person_id = obs.person_id AND obs.voided = 0",
                           :conditions => ["date_format(obs_datetime, '%Y-%m-%d') >= ? AND date_format(obs_datetime, '%Y-%m-%d') <= ?",
                                            @start_date, @end_date],
                           :select => "person.voided,obs.value_coded,obs.obs_datetime,obs.voided ")
  
    @times = []                         
    @data_hash = Hash.new
    start_date = @start_date
    end_date = @end_date

    while start_date >= @start_date and start_date <= @end_date
      @times << start_date
      start_date = 1.weeks.from_now(start_date.monday)
      end_date = start_date-1.day
      #end_date = 4.days.from_now(start_date)
      if end_date >= @end_date
        end_date = @end_date
      end
    end
    
    @times.each{|t|
      @diagnoses_hash = {}
      patients = []
      @patient.each{|p|
        next_start_day = 1.weeks.from_now(t.monday)
        end_day = next_start_day - 1.day
        if end_day >= @end_date
          end_day = @end_date
        end
        patients << p if p.obs_datetime.to_date >= t and p.obs_datetime.to_date <= end_day
      }
      @diagnoses.each{|d|
        count = 0
        patients.each{|patient|
          count += 1  if patient.value_coded == d.value_coded
        }
        @diagnoses_hash[d.name] = count
      }
      @data_hash["#{t}"] = @diagnoses_hash
    }

    #Now create an array to use for sorting when we get to the view
    @sort_array = []
    sort_hash = {}

    @diagnoses.each{|d|
      sum = 0
      @times.each{|t|
        @data_hash.each{|time,data|
          if t.to_date == time.to_date 
            data.each{|k,v|
            if k == d.name
              sum = sum + v 
            end
          }
          end
      }


    }
    sort_hash[d.name] = sum

    }

  sort_hash = sort_hash.sort{|a,b| -1*( a[1]<=>b[1])}
   sort_hash.each{|x| @sort_array << x[0]}

  # make_and_send_pdf('/report/weekly_report', 'weekly_report.pdf')

  end

  def disaggregated_diagnosis

  @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
  @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
   if @start_date > @end_date
      flash[:notice] = 'Start date is greater that end date'
      redirect_to :action => 'select'
      return
    end

  #getting an array of all diagnoses recorded within the chosen period - to avoid including existent but non recorded diagnoses
  diagnoses = ConceptName.find(:all,
                                  :joins =>
                                        "INNER JOIN obs ON
                                         concept_name.concept_id = obs.value_coded AND obs.voided = 0",
                                  :conditions => ["date_format(obs_datetime, '%Y-%m-%d') >= ? AND date_format(obs_datetime, '%Y-%m-%d') <= ?",
                                            @start_date, @end_date],
                                  :group =>   "name",
                                  :select => "concept_name.concept_id,concept_name.name,obs.value_coded,obs.obs_datetime,obs.voided")
  #getting list of all patients who were diagnosed within the set period-to avoid getting all patients                          
  @patient = Person.find(:all,
                           :joins => 
                                "INNER JOIN obs ON 
                                 person.person_id = obs.person_id AND obs.voided = 0",
                           :conditions => ["date_format(obs_datetime, '%Y-%m-%d') >= ? AND date_format(obs_datetime, '%Y-%m-%d') <= ?",
                                            @start_date, @end_date],
                           :select => "person.gender,person.birthdate,person.birthdate_estimated,person.date_created,
                                      person.voided,obs.value_coded,obs.obs_datetime,obs.voided ")
  
  sort_hash = Hash.new

  #sorting the diagnoses using frequency with the highest first
  diagnoses.each{|diagnosis|
    count = 0
    @patient.each{|patient|
      if patient.value_coded == diagnosis.value_coded
        count += 1
      end
    }
    sort_hash[diagnosis.name] = count
  
  }
  #A sorted array of diagnoses to be sent to be sent to form
  @diagnoses = Array.new

   sort_hash = sort_hash.sort{|a,b| -1*( a[1]<=>b[1])}
   diagnosis_names = []
   sort_hash.each{|x| diagnosis_names << x[0]}
   diagnosis_names.each{|d|
     diagnoses.each{|diag|
       @diagnoses << diag if d == diag.name     
     }
   }
   
   @patient_record = []
   @patient.each do |patient|
   patient_bean = PatientService.get_patient(patient.person)
   @patient_record << {
   					   'age' => patient_bean.age, 
   					   'sex' => patient_bean.sex,
					   'value_coded' => patient.value_coded
					  }
   end
   
  end

  def referral
     @start_date = Date.new(params[:start_year].to_i,params[:start_month].to_i,params[:start_day].to_i) rescue nil
    @end_date = Date.new(params[:end_year].to_i,params[:end_month].to_i,params[:end_day].to_i) rescue nil
      if @start_date > @end_date
        flash[:notice] = 'Start date is greater that end date'
        redirect_to :action => 'select'
        return
      end

    @referrals = Observation.find(:all, :conditions => ["concept_id = ? AND date_format(obs_datetime, '%Y-%m-%d') >= ? AND 
                                  date_format(obs_datetime, '%Y-%m-%d') <= ?", 2227, @start_date, @end_date])
    @facilities = Observation.find(:all, :conditions => ["concept_id = ?", 2227], :group => "value_text")
  end

  def report_date_select
  end
  
  def select
  end

  def select_remote_options
    render :layout => false
  end

  def remote_report
    s_day = params[:post]['start_date(3i)'].to_i #2
    s_month = params[:post]['start_date(2i)'].to_i #12
    s_year = params[:post]['start_date(1i)'].to_i  #2008
    e_day = params[:post]['end_date(3i)'].to_i #18
    e_month = params[:post]['end_date(2i)'].to_i #1
    e_year = params[:post]['end_date(1i)'].to_i # 2009
    parameters = {'start_year' => s_year, 'start_month' => s_month, 'start_day' => s_day,'end_year' => e_year, 'end_month' => e_month, 'end_day' => e_day}

    if params[:report] == 'Weekly report'
      redirect_to :action => 'weekly_report', :params => parameters
    elsif params[:report] == 'Disaggregated Diagnoses'
      redirect_to :action => 'disaggregated_diagnosis', :params => parameters
    elsif params[:report] == 'Referrals'
      redirect_to :action => 'referral', :params => parameters
    end

  end

  def generate_pdf_report
    make_and_send_pdf('/report/weekly_report', 'weekly_report.pdf')
  end

  def mastercard
  end

  def data_cleaning

      @reports = {
                    'Missing Prescriptions'=>'dispensations_without_prescriptions',
                    'Missing Dispensations'=>'prescriptions_without_dispensations',
                    'Multiple Start Reasons at Different times'=>'patients_with_multiple_start_reasons',
                    'Out of range ARV number'=>'out_of_range_arv_number',
                    'Data Consistency Check'=>'data_consistency_check'
                 }
    @landing_dashboard = params[:dashboard]
    render :template => 'report/data_cleaning', :layout => 'clinic'
  end

  def appointment_dates
    @report = []
    if (!params[:date].blank?) # retrieve appointment dates for a given day
      @date       = params[:date].to_date
      @patients   = all_appointment_dates(@date)
    elsif (!params[:start_date].blank? && !params[:end_date].blank?) # retrieve appointment dates for a given date range
      @start_date = params[:start_date].to_date
      @end_date   = params[:end_date].to_date
      @patients   = all_appointment_dates(@start_date, @end_date)
    elsif (!params[:quarter].blank?) # retrieve appointment dates for a quarter
      date_range  = Report.generate_cohort_date_range(params[:quarter])
      @start_date  = date_range.first.to_date
      @end_date    = date_range.last.to_date
      @patients   = all_appointment_dates(@start_date, @end_date)
    end

    @patients.each do |patient|
    	patient_bean = PatientService.get_patient(patient.person)
    	
        last_appointment_date = last_appointment_date(patient.id, @date)
        drugs_given_to_patient = patient_present?(patient.id, last_appointment_date)
        drugs_given_to_guardian = guardian_present?(patient.id, last_appointment_date)
        drugs_given_to_both_patient_and_guardian = patient_and_guardian_present?(patient.id, last_appointment_date)

        visit_by = "Guardian visit" if drugs_given_to_guardian
        visit_by = "Patient visit" if drugs_given_to_patient
        visit_by = "PG visit" if drugs_given_to_both_patient_and_guardian

        phone_number = nil
        
        PatientService.phone_numbers(patient.person).each do |type,number|
            case type
                when "Cell phone number"
                    phone_number = number if number.match(/\d+/)
                when "Home phone number"
                    phone_number = number if number.match(/\d+/)
                when "Office phone number"
                    phone_number = number if number.match(/\d+/)
            end
        end rescue nil
        
        last_visit = last_appointment_date.strftime('%Y-%m-%d') rescue ""
        outcome = outcome(patient.id, @date)
        @report << {'arv_number'=> patient_bean.arv_number, 'name'=> patient_bean.name,
                   'birthdate'=> patient_bean.birth_date, 'last_visit'=> last_visit,
                   'visit_by'=> visit_by, 'phone_number'=>phone_number, 'outcome'=>outcome, 'patient_id'=>patient.id}

    end
    
    render :layout => 'appointment_dates'
  end

  def missed_appointments

    @report_url =  params[:report_url] 
    @patients =  all_appointment_dates(params[:date])
    @report  = []
    
    @patients.each do |patient_data_row|

        next if (Encounter.find_by_sql("SELECT encounter_id
                                         FROM encounter
                                         WHERE patient_id=#{patient_data_row.patient_id}
                                               AND DATE(date_created)=DATE('#{params[:date]}')
                                               AND voided = 0").map{|e|e.encounter_id}.count > 0)    
        
        patient        = Person.find(patient_data_row[:patient_id].to_i)
    	patient_bean   = PatientService.get_patient(patient.person)
        last_visit = last_appointment_date(patient.id, params[:date]).strftime('%Y-%m-%d') rescue ""
        
        @report << {'patient_id' => patient_data_row[:patient_id], 'arv_number' => patient_bean.arv_number, 'name' => patient_bean.name,
                   'birthdate' => patient_bean.birth_date, 'national_id' => patient_bean.national_id, 'gender' => patient_bean.sex,
                   'age'=> patient_bean.age, 'phone_numbers' => PatientService.phone_numbers(patient), 'last_visit'=> last_visit,
                   'date_started'=>patient_data_row[:date_started]}
    end
    @report
  end
  
  def non_eligible_patients_in_art
    @report_type = params[:report_type]
    start_date = params[:start_date]
    end_date   = params[:end_date]
    encounter_type = EncounterType.find_by_name("DISPENSING").encounter_type_id
    
    @report  = []

    patient_with_dispensations = Encounter.find_by_sql("
        SELECT * 
        FROM (
                SELECT patient_id, DATE(encounter_datetime) AS encounter_datetime
                FROM encounter
                WHERE encounter_type = #{encounter_type} AND DATE(encounter_datetime) >= DATE('#{start_date}')
                      AND DATE(encounter_datetime) < DATE('#{end_date}')
                ORDER BY patient_id ASC, encounter_datetime ASC) AS patient_with_dispensations
        GROUP BY patient_id")
    
    patient_with_dispensations.each do |patient_data_row|
        person = Person.find(patient_data_row[:patient_id].to_i)
        
        next if !PatientService.reason_for_art_eligibility(Patient.find(patient_data_row[:patient_id].to_i)).blank?
        
        outcome = outcome(person.id, patient_data_row[:encounter_datetime])
        art_date = art_start_date(person.id)
        @report << {'patient_id'=> patient_data_row[:patient_id], 'arv_number'=> PatientService.get_patient_identifier(person, 'ARV Number'), 'name'=> person.name,
                   'birthdate'=> person.birthdate, 'national_id' => PatientService.get_national_id(person.patient) , 'gender' => person.gender,
                   'age'=> person.age, 'phone_numbers'=> PatientService.phone_numbers(person),
                   'art_start_date'=>art_start_date(person.id), "date_registered_at_clinic" => person.patient.date_created.strftime('%d-%b-%Y'),
                   'art_start_age' => age_at(art_date, person.birthdate), 'start_reason' => PatientService.reason_for_art_eligibility(person.patient), 'outcome' => outcome(person.id, end_date)}
    end
    
     @report
  end

  def data_cleaning_tab
      @reports = {
                    'Missing Prescriptions'=>'dispensations_without_prescriptions',
                    'Missing Dispensations'=>'prescriptions_without_dispensations',
                    'Multiple Start Reasons at Different times'=>'patients_with_multiple_start_reasons',
                    'Out of range ARV number'=>'out_of_range_arv_number',
                    'Data Consistency Check'=>'data_consistency_check'
                 }
    @landing_dashboard = params[:dashboard]
    
    render :layout => false
  end

  def age_group_select
    @options = ["","< 6 months",
                "6 months to < 1 yr",
                "1 to < 5","5 to 14",
                "> 14 to < 20","20 to < 30",
                "30 to < 40","40 to < 50",
                "50 and above","none"]
                
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @report = params[:type] 
    render :layout => 'application'
  end

  def opd
    @diagnosis = params[:diagnosis]
    @start_date = params[:start_date].to_date
    @end_date = params[:end_date].to_date
    @report = params[:report]
    @report = params[:type] if not params[:type].blank? and @report.blank?
    @age_group = params[:age_group]
    if @report == 'diagnosis_by_address'
      @data = Report.opd_diagnosis_by_location(@diagnosis , @start_date,@end_date,@age_group)
    elsif @report == 'diagnosis'
      @data = Report.opd_diagnosis(@start_date,@end_date,@age_group)
    elsif @report == 'diagnosis_by_demographics'
      @data = Report.opd_diagnosis_plus_demographics(@diagnosis , @start_date,@end_date,@age_group)
    elsif @report == 'disaggregated_diagnosis'
      @data = Report.opd_disaggregated_diagnosis(@start_date,@end_date,@age_group)
    elsif @report == 'referrals'
      @data = Report.opd_referrals(@start_date,@end_date)
    end
    render :layout => 'menu'
  end

  def recorded_diagnosis
    concept_id = ConceptName.find_by_name("DIAGNOSIS").concept_id
    @names = Observation.find(:all,:joins => "INNER JOIN concept_name c ON obs.value_coded_name_id = c.concept_name_id",
                              :select => "name",
                              :conditions => ["obs.concept_id = ? AND name LIKE (?)",
                              concept_id,"%#{params[:search_string]}%"],:group =>'name').map{|c|c.name}
    render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"
  end
  
    
  def last_appointment_date(patient_id, date=Date.today)
    encounter_type_id = EncounterType.find_by_name("HIV Reception").id
    enc = Encounter.find(:first,:conditions =>["patient_id=? and encounter_type=#{encounter_type_id} and Date(encounter_datetime) <=DATE(?)",patient_id, date.to_date],:order => "encounter_datetime desc")
    enc.encounter_datetime rescue nil
  end
  
  def patient_present?(patient_id, date=Date.today)
      encounter_type_id = EncounterType.find_by_name("HIV Reception").id
      concept_id  = ConceptName.find_by_name("Patient present").concept_id
      encounter = Encounter.find_by_sql("SELECT *
                                        FROM encounter
                                        WHERE patient_id = #{patient_id} AND DATE(date_created) = DATE('#{date.strftime("%Y-%m-%d")}') AND encounter_type = #{encounter_type_id}
                                        ORDER BY date_created DESC").last rescue nil
                                        
      patient_present = encounter.observations.find_last_by_concept_id(concept_id).to_s unless encounter.nil?

      return false if patient_present.blank?
      return false if patient_present.match(/No/)
      return true
  end

  def guardian_present?(patient_id, date=Date.today)
      encounter_type_id = EncounterType.find_by_name("HIV Reception").id
      concept_id  = ConceptName.find_by_name("Guardian present").concept_id
      encounter = Encounter.find_by_sql("SELECT *
                                        FROM encounter
                                        WHERE patient_id = #{patient_id} AND DATE(date_created) = DATE('#{date.strftime("%Y-%m-%d")}') AND encounter_type = #{encounter_type_id}
                                        ORDER BY date_created DESC").last rescue nil

      guardian_present=encounter.observations.find_last_by_concept_id(concept_id).to_s unless encounter.nil?

      return false if guardian_present.blank?
      return false if guardian_present.match(/No/)
      return true
  end

  def patient_and_guardian_present?(patient_id, date=Date.today)
      patient_present = self.patient_present?(patient_id, date)
      guardian_present = self.guardian_present?(patient_id, date)

      return false if !patient_present || !guardian_present
      return true
  end

  def outcome(patient_id, on_date=Date.today)
    state = PatientState.find(:first,
                              :joins => "INNER JOIN patient_program p ON p.patient_program_id = patient_state.patient_program_id",
                              :conditions =>["patient_state.voided = 0 AND p.voided = 0 AND p.patient_id = #{patient_id} AND DATE(start_date) <= DATE('#{on_date}')"],:order => "start_date DESC")
                              
   state.program_workflow_state.concept.shortname rescue state.program_workflow_state.concept.fullname rescue 'Unknown state'     
  end
  
  def art_start_date(patient_id)
    selected_state = nil
    
    Patient.find(patient_id).patient_programs.in_programs("HIV PROGRAM").each do |program|
        program.patient_states.each do |state|
            if !state.to_s.match(/On ARVs/).nil?
                if selected_state.nil?
                    selected_state = state
                elsif selected_state.date_created.to_date < state.date_created.to_date
                    selected_state = state
                end
            end
        end
    end
    
    selected_state.date_created.to_date rescue nil
  end
  
  def age_at(date, dob)
        
      year = nil
      
      if !date.blank? && !dob.blank?
       day_diff = date.day - dob.day
       month_diff = date.month - dob.month - (day_diff < 0 ? 1 : 0)
       year = date.year - dob.year - (month_diff < 0 ? 1 : 0)
      end 
      
      year  
  end

  def all_appointment_dates(start_date, end_date = nil)

    end_date = start_date if end_date.nil?

    appointment_date_concept_id = Concept.find_by_name("APPOINTMENT DATE").concept_id rescue nil

    appointments = Patient.find(:all,
      :joins      => 'INNER JOIN obs ON patient.patient_id = obs.person_id',
      :conditions => ["DATE(obs.value_datetime) >= ? AND DATE(obs.value_datetime) <= ? AND obs.concept_id = ? AND obs.voided = 0", start_date.to_date, end_date.to_date, appointment_date_concept_id],
      :group      => "obs.person_id")

    appointments
  end

  def select_date
    render :layout => 'menu'
  end
  
  def set_appointments
    @select_date = params[:user_selected_date].to_date
    @patients = Report.set_appointments(@select_date)
    render :layout => 'menu'
  end
  
  def malaria_report_menu
    render :layout => "application"
  end
  def la_report_menu
    render :layout => "application"
  end
  def process_malaria_report
    @report_name = "Malaria Report"
    @logo = CoreService.get_global_property_value('logo').to_s
    @current_location_name =Location.current_health_center.name

    @start_date = (params[:start_year] + "-" + params[:start_month] + "-" + params[:start_day]).to_date
    @end_date = (params[:end_year] + "-" + params[:end_month] + "-" + params[:end_day]).to_date

    @formated_start_date = @start_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.strftime('%A, %d, %b, %Y')

    if @start_date > @end_date
      flash[:notice] = 'Start date is greater that end date'
      redirect_to :action => 'malaria_report_menu' and return
    end

    outpatient_encounter_type_id = EncounterType.find_by_name("OUTPATIENT DIAGNOSIS").encounter_type_id
    lab_orders_encounter_type_id = EncounterType.find_by_name("LAB ORDERS").encounter_type_id
    lab_result_encounter_type_id = EncounterType.find_by_name("LAB RESULTS").encounter_type_id

    tests_ordered_concept_id = Concept.find_by_name("BLOOD").concept_id
    malaria_concept_id = Concept.find_by_name("MALARIA").concept_id
    malaria_test_result_concept_id = Concept.find_by_name("MALARIA TEST RESULT").concept_id
    unknown_concept_id = Concept.find_by_name("UNKNOWN").concept_id
    diagnosis_concept_ids = ["PRIMARY DIAGNOSIS", "SECONDARY DIAGNOSIS", "ADDITIONAL DIAGNOSIS"].collect do |concept_name|
      Concept.find_by_name(concept_name).concept_id
    end

    malaria_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{outpatient_encounter_type_id}
        AND o.concept_id IN (#{diagnosis_concept_ids.join(', ')}) AND o.value_coded = #{malaria_concept_id}
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @malaria_cases_count = malaria_observations.count

    microscopy_order_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_orders_encounter_type_id}
        AND o.concept_id = #{tests_ordered_concept_id} AND UPPER(o.value_text) = 'MALARIA (MICROSCOPY)'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>MICROSCOPY QUERIES START>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    @microscopy_total_orders = microscopy_order_observations.count
    microscopy_order_accession_numbers = microscopy_order_observations.map(&:accession_number).compact
    microscopy_order_accession_numbers = [0] if microscopy_order_accession_numbers.blank?

    microscopy_positive_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{microscopy_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = 'THICK SMEAR POSITIVE'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @microscopy_positive_results_count = microscopy_positive_results_observations.count

    microscopy_negative_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{microscopy_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = 'THICK SMEAR NEGATIVE'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @microscopy_negative_results_count = microscopy_negative_results_observations.count

    microscopy_uknown_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{microscopy_order_accession_numbers.join(', ')})
        AND o.value_coded = #{unknown_concept_id}
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @microscopy_uknown_results_count = microscopy_uknown_results_observations.count
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>mRDT QUERIES>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


    mrdt_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_orders_encounter_type_id}
        AND o.concept_id = #{tests_ordered_concept_id} AND UPPER(o.value_text) = 'MALARIA (MRDT)'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @mrdt_total_orders = mrdt_observations.count
    mrdt_order_accession_numbers = mrdt_observations.map(&:accession_number).compact
    mrdt_order_accession_numbers = [0] if mrdt_order_accession_numbers.blank?

    mrdt_positive_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{mrdt_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = 'MALARIA RDT POSITIVE'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @mrdt_positive_results_count = mrdt_positive_results_observations.count

    mrdt_negative_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{mrdt_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = 'MALARIA RDT NEGATIVE'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    @mrdt_negative_results_count = mrdt_negative_results_observations.count

    mrdt_unknown_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{mrdt_order_accession_numbers.join(', ')})
        AND o.value_coded = #{unknown_concept_id}
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
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
        o.order_type_id = #{drug_order_type_id}
        AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        AND e.voided=0 GROUP BY do.drug_inventory_id"
    ).last.total_prescribed_drugs rescue 0

    @total_la_one_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
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
        AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        AND do.drug_inventory_id = #{la_two_drug_id} AND
        o.order_type_id = #{drug_order_type_id} AND e.encounter_datetime <= \"#{Date.today} 23:59:59\"
        AND e.voided=0 GROUP BY do.drug_inventory_id"
    ).last.total_prescribed_drugs rescue 0

    @total_la_two_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} 
        AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        AND o.order_type_id = #{drug_order_type_id}
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
        AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        AND do.drug_inventory_id = #{la_three_drug_id} AND
        o.order_type_id = #{drug_order_type_id} AND e.encounter_datetime <= \"#{Date.today} 23:59:59\"
        AND e.voided=0 GROUP BY do.drug_inventory_id"
    ).last.total_prescribed_drugs rescue 0

    @total_la_three_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
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
        AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        AND do.drug_inventory_id = #{la_four_drug_id} AND
        o.order_type_id = #{drug_order_type_id} AND e.encounter_datetime <= \"#{Date.today} 23:59:59\"
        AND e.voided=0 GROUP BY do.drug_inventory_id"
    ).last.total_prescribed_drugs rescue 0

    @total_la_four_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND DATE(e.encounter_datetime) >= '#{@start_date}' AND DATE(e.encounter_datetime) <= '#{@end_date}'
        AND do.drug_inventory_id = #{la_four_drug_id}
        AND obs.concept_id = #{amount_dispensed_concept} AND e.voided=0 GROUP BY d.drug_id"
    ).last.total_dispensed_drugs rescue 0

    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    render :layout => "report"
  end
  def process_la_report
    @report_name = "LA Report"
    @logo = CoreService.get_global_property_value('logo').to_s
    @current_location_name =Location.current_health_center.name

    @start_date = (params[:start_year] + "-" + params[:start_month] + "-" + params[:start_day]).to_date
    @end_date = (params[:end_year] + "-" + params[:end_month] + "-" + params[:end_day]).to_date

    @formated_start_date = @start_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.strftime('%A, %d, %b, %Y')

    if @start_date > @end_date
      flash[:notice] = 'Start date is greater that end date'
      redirect_to :action => 'la_report_menu' and return
    end

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
    start_date = @start_date.strftime("%Y-%m-%d").to_s
    end_date = @end_date.strftime("%Y-%m-%d").to_s
    @total_la_one_prescribed_drugs = Order.find_by_sql("
        SELECT SUM((ABS(DATEDIFF(o.auto_expire_date, o.start_date)) * do.equivalent_daily_dose)) as total_prescribed_drugs
        FROM encounter e INNER JOIN encounter_type et
        ON e.encounter_type = et.encounter_type_id INNER JOIN orders o
        ON e.encounter_id = o.encounter_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{treatment_encounter_type_id}
        AND do.drug_inventory_id = #{la_one_drug_id} AND
        o.order_type_id = #{drug_order_type_id} AND DATE(e.encounter_datetime) >= \"#{start_date}\"
        AND DATE(e.encounter_datetime) <= \"#{end_date}\" 
        AND e.voided=0 GROUP BY do.drug_inventory_id" 
    ).last.total_prescribed_drugs rescue 0

    @total_la_one_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e 
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND do.drug_inventory_id = #{la_one_drug_id}
        AND DATE(e.encounter_datetime) >= \"#{start_date}\"
        AND DATE(e.encounter_datetime) <= \"#{end_date}\"
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
        o.order_type_id = #{drug_order_type_id} 
        AND DATE(e.encounter_datetime) >= \"#{start_date}\"
        AND DATE(e.encounter_datetime) <= \"#{end_date}\"
        AND e.voided=0 GROUP BY do.drug_inventory_id"
    ).last.total_prescribed_drugs rescue 0

    @total_la_two_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND do.drug_inventory_id = #{la_two_drug_id}
        AND obs.concept_id = #{amount_dispensed_concept} 
        AND DATE(e.encounter_datetime) >= \"#{start_date}\"
        AND DATE(e.encounter_datetime) <= \"#{end_date}\"
        AND e.voided=0 GROUP BY d.drug_id"
    ).last.total_dispensed_drugs rescue 0

    @total_la_three_prescribed_drugs = Order.find_by_sql("
        SELECT SUM((ABS(DATEDIFF(o.auto_expire_date, o.start_date)) * do.equivalent_daily_dose)) as total_prescribed_drugs
        FROM encounter e INNER JOIN encounter_type et
        ON e.encounter_type = et.encounter_type_id INNER JOIN orders o
        ON e.encounter_id = o.encounter_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{treatment_encounter_type_id}
        AND do.drug_inventory_id = #{la_three_drug_id} AND
        o.order_type_id = #{drug_order_type_id} 
        AND DATE(e.encounter_datetime) >= \"#{start_date}\"
        AND DATE(e.encounter_datetime) <= \"#{end_date}\"
        AND e.voided=0 GROUP BY do.drug_inventory_id"
    ).last.total_prescribed_drugs rescue 0

    @total_la_three_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND do.drug_inventory_id = #{la_three_drug_id}
        AND obs.concept_id = #{amount_dispensed_concept}
        AND DATE(e.encounter_datetime) >= \"#{start_date}\"
        AND DATE(e.encounter_datetime) <= \"#{end_date}\"
        AND e.voided=0 GROUP BY d.drug_id"
    ).last.total_dispensed_drugs rescue 0
    
    @total_la_four_prescribed_drugs = Order.find_by_sql("
        SELECT SUM((ABS(DATEDIFF(o.auto_expire_date, o.start_date)) * do.equivalent_daily_dose)) as total_prescribed_drugs
        FROM encounter e INNER JOIN encounter_type et
        ON e.encounter_type = et.encounter_type_id INNER JOIN orders o
        ON e.encounter_id = o.encounter_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{treatment_encounter_type_id}
        AND do.drug_inventory_id = #{la_four_drug_id} AND
        o.order_type_id = #{drug_order_type_id} 
        AND DATE(e.encounter_datetime) >= \"#{start_date}\"
        AND DATE(e.encounter_datetime) <= \"#{end_date}\"
        AND e.voided=0 GROUP BY do.drug_inventory_id"
    ).last.total_prescribed_drugs rescue 0

    @total_la_four_dispensed_drugs = Order.find_by_sql("SELECT SUM(obs.value_numeric) as total_dispensed_drugs FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND do.drug_inventory_id = #{la_four_drug_id}
        AND obs.concept_id = #{amount_dispensed_concept} 
        AND DATE(e.encounter_datetime) >= \"#{start_date}\"
        AND DATE(e.encounter_datetime) <= \"#{end_date}\"
        AND e.voided=0 GROUP BY d.drug_id"
    ).last.total_dispensed_drugs rescue 0

    render :layout => "report"
  end
  def update_dhis
  	@dhis_reports = ["ANC Monthly Facility Report", "HMIS-15", "IDSR Monthly"]
	render :layout => "application"
  end
  
  def generate_dhis_report
  	@logo = CoreService.get_global_property_value('logo') rescue nil
  	@report = params[:report]
  	@report_name = ""
  	@idsr_mothly = {}
  	if @report == "IDSR Monthly"
  		@report_name = @report
  		
		coc_death = "urZWwWW5FU9"
		coc_out_patient_cases = "qqg5qsADtHX"
		coc_inpatient_deaths = "dAObMfCg8zn"
		coc_inpatient_cases = "q4r3uBRqJaf"
		coc_in_patient_cases = "RxoQpVgSQq6"
		coc_in_patient_deaths = "OFdC9ug92YH"
		coc_default = "fiC1VMp5zq6"
		
		
  		@idsr_mothly = {
			"IDSR Male Urethral Discharge".upcase=>
			{ 
					"Out-patient cases"=>
					{
						:dataElement=>"DTZU9thFC85",
						:value=>0,
						:categoryOptionCombo=>coc_out_patient_cases
					 }
			},
			
			"IDSR Viral Hemorrhagic Fever".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"Pj67s6ApYb2",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"Pj67s6ApYb2",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"Pj67s6ApYb2",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Meningitis".upcase=> 
			{
				"Out-patient cases"=>
				{
					:dataElement=>"CRArwtJppcy",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"CRArwtJppcy",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"CRArwtJppcy",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Pneumonia <5 Years".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"jPH2HL1zlTU",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				}
			},
			
			"IDSR Schistosomiasis Intestinal".upcase=> 
			{
				"Out-patient cases"=>
				{
					:dataElement=>"p494BDUSEUz",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"p494BDUSEUz",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"p494BDUSEUz",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Uncomplicated Malaria <5y, Lab-Confirmed".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"WDQ9DoNW1gI",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
		  	},
			
			"IDSR Male Non-Vesicular Genital Ulcer".upcase => 
			{
				"Out-patient cases"=>
				{
					:dataElement=>"gMQn2Hgv3ud",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
			},
			
			"IDSR Malaria < 5 Years Severe".upcase=>
			{									
				"In-patient cases"=>
				{
					:dataElement=>"wsOnpRZtp3t",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"wsOnpRZtp3t",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR New AIDS Cases".upcase=> 
			{
				"Out-patient cases"=>
				{
					:dataElement=>"fYpGGzLiVbe",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"fYpGGzLiVbe",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"fYpGGzLiVbe",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Measles".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"BnbLe0vUHIM",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"BnbLe0vUHIM",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"BnbLe0vUHIM",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Neonatal Tetanus".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"YXnx3FepHlE",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"YXnx3FepHlE",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"YXnx3FepHlE",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Diarrhoea With Dehydration".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"GERSeo2EiaP",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"GERSeo2EiaP",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"GERSeo2EiaP",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Malaria >= 5 Years Uncomplicated".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"sUmQaUBzNy3",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				}
			},
			
			"IDSR Malaria With Severe Anemia <5years".upcase=>
			{
				"In-patient cases"=>
				{
					:dataElement=>"spfnMEG1wl0",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"spfnMEG1wl0",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Female Non-Vesicular Genital Ulcer".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"TxPvgF64DZB",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				}
		    },
			
			"IDSR AFP".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"aZmJTJpj4Xa",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"aZmJTJpj4Xa",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"aZmJTJpj4Xa",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Malaria In Pregnant Women Uncomplicated".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"cLEvPveMGfq",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
			},
			
			"IDSR Schistosomiasis Urinary".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"wA7sDe6Jshb",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"wA7sDe6Jshb",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"wA7sDe6Jshb",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Cholera".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"xRmq6560gDJ",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"xRmq6560gDJ",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"xRmq6560gDJ",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Uncomplicated Malaria 5+Y, Lab-Confirmed".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"tvp6Blay8Yc",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				}
		  	},
			
			"IDSR Malaria >= 5 Years Severe".upcase=>
			{
				"In-patient cases"=>
				{
					:dataElement=>"hHXHbQQVm4O",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"hHXHbQQVm4O",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
		   	},
			
			"IDSR Malaria < 5 Years Uncomplicated".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"DpRXVfxBy1m",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				}
			},
			
			"IDSR Plague".upcase=>
			{					
				"Out-patient cases"=>
				{
					:dataElement=>"Zs6Bjgfyrct",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"Zs6Bjgfyrct",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"Zs6Bjgfyrct",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Malaria In Pregnant Women Severe".upcase=>
			{
				"In-patient cases"=>
				{
					:dataElement=>"HiFlLTvDG0l",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"HiFlLTvDG0l",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
		  	},
			
			"IDSR Diarrhoea With Blood".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"XVNCLVde2Eu",
					:value=>0,
					:categoryOptionCombo=>coc_out_patient_cases
				},
				"In-patient cases"=>
				{
					:dataElement=>"XVNCLVde2Eu",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"XVNCLVde2Eu",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
		  	},
			
			"IDSR Severe Pneumonia <5 Years".upcase=>
			{
				"In-patient cases"=>
				{
					:dataElement=>"tLk5ymzkutq",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"tLk5ymzkutq",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},
			
			"IDSR Diarrhoea With Bloody".upcase=>
			{
				"Out-patient cases"=>
				{
					:dataElement=>"wDCBO0oRE18",
					:value=>0,
					:categoryOptionCombo=>coc_default
				},
				"In-patient cases"=>
				{
					:dataElement=>"XVNCLVde2Eu",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"XVNCLVde2Eu",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			},

			
			"IDSR Very Severe Pneumonia <5 Years".upcase=>
			{

				"In-patient cases"=>
				{
					:dataElement=>"kLWOyuVuvoW",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_cases
				},
				"In-patient deaths"=>
				{
					:dataElement=>"kLWOyuVuvoW",
					:value=>0,
					:categoryOptionCombo=>coc_in_patient_deaths
				}
			 }																		
  		}

		header="<dataValueSet dataSet=\"wmO5qvufx5b\" completeDate=\"2014-03-25\" period=\"201403\" orgUnit=\"rERxz2TtA3i\">\n"
		c = header
  		@idsr_mothly.each do |key, data|
  			data.each do |k,d|
  				c += "	<dataValue dataElement=\""+d[:dataElement].to_s + "\" categoryOptionCombo=\""+d[:categoryOptionCombo].to_s + "\" value=\""+d[:value].to_s + "\" />\n"
  			end
  		end
  		
  		c+="</dataValueSet>"
  		`touch dhis2/datavalueset.xml`
  		f = File.open("dhis2/datavalueset.xml", 'w')
  		f.print c
  		f.close()
  		
  		@report = @report + " (#{Date::MONTHNAMES[params[:month].to_i]} - #{params[:year]}) Report Preview"
  		render :template => 'report/dhis_idsr', :layout => 'dhis2'
  	else
  		redirect_to "/report/update_dhis" and return
  	end
  end
  
  def update_dhis2_report
		result = `curl -d @dhis2/datavalueset.xml "http://localhost:8080/api/dataValueSets" -H "Content-Type:application/xml" -u admin:district -v`
		puts result
		result = result.scan(/<status>(.*)<\/status>/).to_s
		
		if result.empty?
			result = "failed"
		end
		redirect_to "/clinic?dhis_status=#{result}" and return
  end

end
