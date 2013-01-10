class CohortToolController < ApplicationController
  require 'bean'
  require 'will_paginate'
  def select
    @cohort_quarters  = [""]
    @report_type      = params[:report_type]
    @header 	        = params[:report_type] rescue ""
    @page_destination = ("/" + params[:dashboard].gsub("_", "/")) rescue ""

    if @report_type == "in_arv_number_range"
      @arv_number_start = params[:arv_number_start]
      @arv_number_end   = params[:arv_number_end]
    end

    start_date  = PatientService.initial_encounter.encounter_datetime rescue Date.today

    end_date    = Date.today

    @cohort_quarters  += Report.generate_cohort_quarters(start_date, end_date)
  end

  def reports
    session[:list_of_patients] = nil
    if params[:report]
      case  params[:report_type]
      when "visits_by_day"
        redirect_to :action   => "visits_by_day",
          :name     => params[:report],
          :pat_name => "Visits by day",
          :quarter  => params[:report].gsub("_"," ")
        return

      when "non_eligible_patients_in_cohort"
        date = Report.generate_cohort_date_range(params[:report])

        redirect_to :action       => "non_eligible_patients_in_art",
          :controller   => "report",
          :start_date   => date.first.to_s,
          :end_date     => date.last.to_s,
          :id           => "start_reason_other",
          :report_type  => "non_eligible patients in: #{params[:report]}"
        return

      when "out_of_range_arv_number"
        redirect_to :action           => "out_of_range_arv_number",
          :arv_end_number   => params[:arv_end_number],
          :arv_start_number => params[:arv_start_number],
          :quarter          => params[:report].gsub("_"," "),
          :report_type      => params[:report_type]
        return

      when "data_consistency_check"
        redirect_to :action       => "data_consistency_check",
          :quarter      => params[:report],
          :report_type  => params[:report_type]
        return

      when "summary_of_records_that_were_updated"
        redirect_to :action   => "records_that_were_updated",
          :quarter  => params[:report].gsub("_"," ")
        return

      when "adherence_histogram_for_all_patients_in_the_quarter"
        redirect_to :action   => "adherence",
          :quarter  => params[:report].gsub("_"," ")
        return

      when "patients_with_adherence_greater_than_hundred"
        redirect_to :action  => "patients_with_adherence_greater_than_hundred",
          :quarter => params[:report].gsub("_"," ")
        return

      when "patients_with_multiple_start_reasons"
        redirect_to :action       => "patients_with_multiple_start_reasons",
          :quarter      => params[:report],
          :report_type  => params[:report_type]
        return

      when "dispensations_without_prescriptions"
        redirect_to :action       => "dispensations_without_prescriptions",
          :quarter      => params[:report],
          :report_type  => params[:report_type]
        return

      when "prescriptions_without_dispensations"
        redirect_to :action       => "prescriptions_without_dispensations",
          :quarter      => params[:report],
          :report_type  => params[:report_type]
        return

      when "drug_stock_report"
        start_date  = "#{params[:start_year]}-#{params[:start_month]}-#{params[:start_day]}"
        end_date    = "#{params[:end_year]}-#{params[:end_month]}-#{params[:end_day]}"

        if end_date.to_date < start_date.to_date
          redirect_to :controller   => "cohort_tool",
            :action       => "select",
            :report_type  =>"drug_stock_report" and return
        end rescue nil

        redirect_to :controller => "drug",
          :action     => "report",
          :start_date => start_date,
          :end_date   => end_date,
          :quarter    => params[:report].gsub("_"," ")
        return
      end
    end
  end

  def records_that_were_updated
    @quarter    = params[:quarter]

    date_range  = Report.generate_cohort_date_range(@quarter)
    @start_date = date_range.first
    @end_date   = date_range.last

    @encounters = records_that_were_corrected(@quarter)

    render :layout => false
  end

  def records_that_were_corrected(quarter)

    date        = Report.generate_cohort_date_range(quarter)
    start_date  = (date.first.to_s  + " 00:00:00")
    end_date    = (date.last.to_s   + " 23:59:59")

    voided_records = {}

    other_encounters = Encounter.find_by_sql("SELECT encounter.* FROM encounter
                        INNER JOIN obs ON encounter.encounter_id = obs.encounter_id
                        WHERE ((encounter.encounter_datetime BETWEEN '#{start_date}' AND '#{end_date}'))
                        GROUP BY encounter.encounter_id
                        ORDER BY encounter.encounter_type, encounter.patient_id")

    drug_encounters = Encounter.find_by_sql("SELECT encounter.* as duration FROM encounter
                        INNER JOIN orders ON encounter.encounter_id = orders.encounter_id
                        WHERE ((encounter.encounter_datetime BETWEEN '#{start_date}' AND '#{end_date}'))
                        ORDER BY encounter.encounter_type")

    voided_encounters = []
    other_encounters.delete_if { |encounter| voided_encounters << encounter if (encounter.voided == 1)}

    voided_encounters.map do |encounter|
      patient           = Patient.find(encounter.patient_id)
      patient_bean = PatientService.get_patient(patient.person)

      new_encounter  = other_encounters.reduce([])do |result, e|
        result << e if( e.encounter_datetime.strftime("%d-%m-%Y") == encounter.encounter_datetime.strftime("%d-%m-%Y")&&
            e.patient_id      == encounter.patient_id &&
            e.encounter_type  == encounter. encounter_type)
        result
      end

      new_encounter = new_encounter.last

      next if new_encounter.nil?

      voided_observations = voided_observations(encounter)
      changed_to    = changed_to(new_encounter)
      changed_from  = changed_from(voided_observations)

      if( voided_observations && !voided_observations.empty?)
        voided_records[encounter.id] = {
          "id"              => patient.patient_id,
          "arv_number"      => patient_bean.arv_number,
          "name"            => patient_bean.name,
          "national_id"     => patient_bean.national_id,
          "encounter_name"  => encounter.name,
          "voided_date"     => encounter.date_voided,
          "reason"          => encounter.void_reason,
          "change_from"     => changed_from,
          "change_to"       => changed_to
        }
      end
    end

    voided_treatments = []
    drug_encounters.delete_if { |encounter| voided_treatments << encounter if (encounter.voided == 1)}

    voided_treatments.each do |encounter|

      patient           = Patient.find(encounter.patient_id)
      patient_bean = PatientService.get_patient(patient.person)

      orders            = encounter.orders
      changed_from      = ''
      changed_to        = ''

      new_encounter  =  drug_encounters.reduce([])do |result, e|
        result << e if( e.encounter_datetime.strftime("%d-%m-%Y") == encounter.encounter_datetime.strftime("%d-%m-%Y")&&
            e.patient_id      == encounter.patient_id &&
            e.encounter_type  == encounter. encounter_type)
        result
      end

      new_encounter = new_encounter.last

      next if new_encounter.nil?
      changed_from  += "Treatment: #{voided_orders(new_encounter).to_s.gsub!(":", " =>")}</br>"
      changed_to    += "Treatment: #{encounter.to_s.gsub!(":", " =>") }</br>"

      if( orders && !orders.empty?)
        voided_records[encounter.id]= {
          "id"              => patient.patient_id,
          "arv_number"      => patient_bean.arv_number,
          "name"            => patient_bean.name,
          "national_id"     => patient_bean.national_id,
          "encounter_name"  => encounter.name,
          "voided_date"     => encounter.date_voided,
          "reason"          => encounter.void_reason,
          "change_from"     => changed_from,
          "change_to"       => changed_to
        }
      end

    end

    show_tabuler_format(voided_records)
  end

  def show_tabuler_format(records)

    patients = {}

    records.each do |key,value|

      sorted_values = sort(value)

      patients["#{key},#{value['id']}"] = sorted_values
    end

    patients
  end

  def sort(values)
    name              = ''
    patient_id        = ''
    arv_number        = ''
    national_id       = ''
    encounter_name    = ''
    voided_date       = ''
    reason            = ''
    obs_names         = ''
    changed_from_obs  = {}
    changed_to_obs    = {}
    changed_data      = {}

    values.each do |value|
      value_name =  value.first
      value_data =  value.last

      case value_name
      when "id"
        patient_id = value_data
      when "arv_number"
        arv_number = value_data
      when "name"
        name = value_data
      when "national_id"
        national_id = value_data
      when "encounter_name"
        encounter_name = value_data
      when "voided_date"
        voided_date = value_data
      when "reason"
        reason = value_data
      when "change_from"
        value_data.split("</br>").each do |obs|
          obs_name  = obs.split(':')[0].strip
          obs_value = obs.split(':')[1].strip rescue ''

          changed_from_obs[obs_name] = obs_value
        end unless value_data.blank?
      when "change_to"

        value_data.split("</br>").each do |obs|
          obs_name  = obs.split(':')[0].strip
          obs_value = obs.split(':')[1].strip rescue ''

          changed_to_obs[obs_name] = obs_value
        end unless value_data.blank?
      end
    end

    changed_from_obs.each do |a,b|
      changed_to_obs.each do |x,y|

        if (a == x)
          next if b == y
          changed_data[a] = "#{b} to #{y}"

          changed_from_obs.delete(a)
          changed_to_obs.delete(x)
        end
      end
    end

    changed_to_obs.each do |a,b|
      changed_from_obs.each do |x,y|
        if (a == x)
          next if b == y
          changed_data[a] = "#{b} to #{y}"

          changed_to_obs.delete(a)
          changed_from_obs.delete(x)
        end
      end
    end

    changed_data.each do |k,v|
      from  = v.split("to")[0].strip rescue ''
      to    = v.split("to")[1].strip rescue ''

      if obs_names.blank?
        obs_names = "#{k}||#{from}||#{to}||#{voided_date}||#{reason}"
      else
        obs_names += "</br>#{k}||#{from}||#{to}||#{voided_date}||#{reason}"
      end
    end

    results = {
      "id"              => patient_id,
      "arv_number"      => arv_number,
      "name"            => name,
      "national_id"     => national_id,
      "encounter_name"  => encounter_name,
      "voided_date"     => voided_date,
      "obs_name"        => obs_names,
      "reason"          => reason
    }

    results
  end

  def changed_from(observations)
    changed_obs = ''

    observations.collect do |obs|
      ["value_coded","value_datetime","value_modifier","value_numeric","value_text"].each do |value|
        case value
        when "value_coded"
          next if obs.value_coded.blank?
          changed_obs += "#{obs.to_s}</br>"
        when "value_datetime"
          next if obs.value_datetime.blank?
          changed_obs += "#{obs.to_s}</br>"
        when "value_numeric"
          next if obs.value_numeric.blank?
          changed_obs += "#{obs.to_s}</br>"
        when "value_text"
          next if obs.value_text.blank?
          changed_obs += "#{obs.to_s}</br>"
        when "value_modifier"
          next if obs.value_modifier.blank?
          changed_obs += "#{obs.to_s}</br>"
        end
      end
    end

    changed_obs.gsub("00:00:00 +0200","")[0..-6]
  end

  def changed_to(enc)
    encounter_type = enc.encounter_type

    encounter = Encounter.find(:first,
      :joins       => "INNER JOIN obs ON encounter.encounter_id=obs.encounter_id",
      :conditions  => ["encounter_type=? AND encounter.patient_id=? AND Date(encounter.encounter_datetime)=?",
        encounter_type,enc.patient_id, enc.encounter_datetime.to_date],
      :group       => "encounter.encounter_type",
      :order       => "encounter.encounter_datetime DESC")

    observations = encounter.observations rescue nil
    return if observations.blank?

    changed_obs = ''
    observations.collect do |obs|
      ["value_coded","value_datetime","value_modifier","value_numeric","value_text"].each do |value|
        case value
        when "value_coded"
          next if obs.value_coded.blank?
          changed_obs += "#{obs.to_s}</br>"
        when "value_datetime"
          next if obs.value_datetime.blank?
          changed_obs += "#{obs.to_s}</br>"
        when "value_numeric"
          next if obs.value_numeric.blank?
          changed_obs += "#{obs.to_s}</br>"
        when "value_text"
          next if obs.value_text.blank?
          changed_obs += "#{obs.to_s}</br>"
        when "value_modifier"
          next if obs.value_modifier.blank?
          changed_obs += "#{obs.to_s}</br>"
        end
      end
    end

    changed_obs.gsub("00:00:00 +0200","")[0..-6]
  end

  def visits_by_day
    @quarter    = params[:quarter]

    date_range          = Report.generate_cohort_date_range(@quarter)
    @start_date         = date_range.first
    @end_date           = date_range.last
    visits              = get_visits_by_day(@start_date.beginning_of_day, @end_date.end_of_day)
    @patients           = visiting_patients_by_day(visits)
    @visits_by_day      = visits_by_week(visits)
    @visits_by_week_day = visits_by_week_day(visits)

    render :layout => false
  end

  def visits_by_week(visits)

    visits_by_week = visits.inject({}) do |week, visit|

      day       = visit.encounter_datetime.strftime("%a")
      beginning = visit.encounter_datetime.beginning_of_week.to_date

      # add a new week
      week[beginning] = {day => []} if week[beginning].nil?

      #add a new visit to the week
      (week[beginning][day].nil?) ? week[beginning][day] = [visit] : week[beginning][day].push(visit)

      week
    end

    return visits_by_week
  end

  def visits_by_week_day(visits)
    week_day_visits = {}
    visits          = visits_by_week(visits)
    weeks           = visits.keys.sort
    week_days       = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    week_days.each_with_index do |day, index|
      weeks.map do  |week|
        visits_number = 0
        visit_date    = week.to_date.strftime("%d-%b-%Y")
        js_date       = week.to_time.to_i * 1000
        this_day      = visits[week][day]


        unless this_day.nil?
          visits_number = this_day.count
          visit_date    = this_day.first.encounter_datetime.to_date.strftime("%d-%b-%Y")
          js_date       = this_day.first.encounter_datetime.to_time.to_i * 1000
        else
          this_day      = (week.to_date + index.days)
          visit_date    = this_day.strftime("%d-%b-%Y")
          js_date       = this_day.to_time.to_i * 1000
        end

        (week_day_visits[day].nil?) ? week_day_visits[day] = [[js_date, visits_number, visit_date]] : week_day_visits[day].push([js_date, visits_number, visit_date])
      end
    end
    week_day_visits
  end

  def visiting_patients_by_day(visits)

    patients = visits.inject({}) do |patient, visit|

      visit_date = visit.encounter_datetime.strftime("%d-%b-%Y")

      patient_bean = PatientService.get_patient(visit.patient.person)

      # get a patient of a given visit
      new_patient   = { :patient_id   => (visit.patient.patient_id || ""),
        :arv_number   => (patient_bean.arv_number || ""),
        :name         => (patient_bean.name || ""),
        :national_id  => (patient_bean.national_id || ""),
        :gender       => (patient_bean.sex || ""),
        :age          => (patient_bean.age || ""),
        :birthdate    => (patient_bean.birth_date || ""),
        :phone_number => (PatientService.phone_numbers(visit.patient) || ""),
        :start_date   => (visit.patient.encounters.last.encounter_datetime.strftime("%d-%b-%Y") || "")
      }

      #add a patient to the day
      (patient[visit_date].nil?) ? patient[visit_date] = [new_patient] : patient[visit_date].push(new_patient)

      patient
    end

    patients
  end

  def get_visits_by_day(start_date,end_date)
    required_encounters = ["ART ADHERENCE", "ART_FOLLOWUP",   "ART_INITIAL",
      "ART VISIT",     "HIV RECEPTION",  "HIV STAGING",
      "PART_FOLLOWUP", "PART_INITIAL",   "VITALS"]

    required_encounters_ids = required_encounters.inject([]) do |encounters_ids, encounter_type|
      encounters_ids << EncounterType.find_by_name(encounter_type).id rescue nil
      encounters_ids
    end

    required_encounters_ids.sort!

    Encounter.find(:all,
      :joins      => ["INNER JOIN obs     ON obs.encounter_id    = encounter.encounter_id",
        "INNER JOIN patient ON patient.patient_id  = encounter.patient_id"],
      :conditions => ["obs.voided = 0 AND encounter_type IN (?) AND encounter_datetime >=? AND encounter_datetime <=?",required_encounters_ids,start_date,end_date],
      :group      => "encounter.patient_id,DATE(encounter_datetime)",
      :order      => "encounter.encounter_datetime ASC")
  end

  def prescriptions_without_dispensations
    include_url_params_for_back_button

    date_range  = Report.generate_cohort_date_range(params[:quarter])
    start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    @report     = report_prescriptions_without_dispensations_data(start_date , end_date)

    render :layout => 'report'
  end

  def  dispensations_without_prescriptions
    include_url_params_for_back_button

    date_range  = Report.generate_cohort_date_range(params[:quarter])
    start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    @report     = report_dispensations_without_prescriptions_data(start_date , end_date)

    render :layout => 'report'
  end

  def  patients_with_multiple_start_reasons
    include_url_params_for_back_button

    date_range  = Report.generate_cohort_date_range(params[:quarter])
    start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    @report     = report_patients_with_multiple_start_reasons(start_date , end_date)

    render :layout => 'report'
  end

  def out_of_range_arv_number

    include_url_params_for_back_button

    date_range        = Report.generate_cohort_date_range(params[:quarter])
    start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    arv_number_range  = [params[:arv_start_number].to_i, params[:arv_end_number].to_i]

    @report = report_out_of_range_arv_numbers(arv_number_range, start_date, end_date)

    render :layout => 'report'
  end

  def data_consistency_check
    include_url_params_for_back_button
    date_range  = Report.generate_cohort_date_range(params[:quarter])
    start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")

    @dead_patients_with_visits       = report_dead_with_visits(start_date, end_date)
    @males_allegedly_pregnant        = report_males_allegedly_pregnant(start_date, end_date)
    @move_from_second_line_to_first =  report_patients_who_moved_from_second_to_first_line_drugs(start_date, end_date)
    @patients_with_wrong_start_dates = report_with_drug_start_dates_less_than_program_enrollment_dates(start_date, end_date)
    session[:data_consistency_check] = { :dead_patients_with_visits => @dead_patients_with_visits,
      :males_allegedly_pregnant  => @males_allegedly_pregnant,
      :patients_with_wrong_start_dates => @patients_with_wrong_start_dates,
      :move_from_second_line_to_first =>  @move_from_second_line_to_first
    }
    @checks = [['Dead patients with Visits', @dead_patients_with_visits.length],
      ['Male patients with a pregnant observation', @males_allegedly_pregnant.length],
      ['Patients who moved from 2nd to 1st line drugs', @move_from_second_line_to_first.length],
      ['patients with start dates > first receive drug dates', @patients_with_wrong_start_dates.length]]
    render :layout => 'report'
  end

  def list
    @report = []
    include_url_params_for_back_button

    case params[:check_type]
    when 'Dead patients with Visits' then
      @report  =  session[:data_consistency_check][:dead_patients_with_visits]
    when 'Patients who moved from 2nd to 1st line drugs'then
      @report =  session[:data_consistency_check][:move_from_second_line_to_first]
    when 'Male patients with a pregnant observation' then
      @report =  session[:data_consistency_check][:males_allegedly_pregnant]
    when 'patients with start dates > first receive drug dates' then
      @report =  session[:data_consistency_check][:patients_with_wrong_start_dates]
    else

    end

    render :layout => 'report'
  end

  def include_url_params_for_back_button
    @report_quarter = params[:quarter]
    @report_type = params[:report_type]
  end

  def cohort
    @quarter = params[:quarter]
    start_date,end_date = Report.generate_cohort_date_range(@quarter)
    cohort = Cohort.new(start_date,end_date)
    @cohort = cohort.report
    @survival_analysis = SurvivalAnalysis.report(cohort)
    render :layout => 'cohort'
  end

  def cohort_menu
  end

  def adherence
    adherences = get_adherence(params[:quarter])
    @quarter = params[:quarter]
    type = "patients_with_adherence_greater_than_hundred"
    @report_type = "Adherence Histogram for all patients"
    @adherence_summary = "&nbsp;&nbsp;<button onclick='adhSummary();'>Summary</button>" unless adherences.blank?
    @adherence_summary+="<input class='test_name' type=\"button\" onmousedown=\"document.location='/cohort_tool/reports?report=#{@quarter}&report_type=#{type}';\" value=\"Over 100% Adherence\"/>"  unless adherences.blank?
    @adherence_summary_hash = Hash.new(0)
    adherences.each{|adherence,value|
      adh_value = value.to_i
      current_adh = adherence.to_i
      if current_adh <= 94
        @adherence_summary_hash["0 - 94"]+= adh_value
      elsif current_adh >= 95 and current_adh <= 100
        @adherence_summary_hash["95 - 100"]+= adh_value
      else current_adh > 100
        @adherence_summary_hash["> 100"]+= adh_value
      end
    }
    @adherence_summary_hash['missing'] = CohortTool.missing_adherence(@quarter).length rescue 0
    @adherence_summary_hash.values.each{|n|@adherence_summary_hash["total"]+=n}

    data = ""
    adherences.each{|x,y|data+="#{x}:#{y}:"}
    @id = data[0..-2] || ''

    @results = @id
    @results = @results.split(':').enum_slice(2).map
    @results = @results.each {|result| result[0] = result[0]}.sort_by{|result| result[0]}
    @results.each{|result| @graph_max = result[1].to_f if result[1].to_f > (@graph_max || 0)}
    @graph_max ||= 0
    render :layout => false
  end

  def patients_with_adherence_greater_than_hundred

    min_range = params[:min_range]
    max_range = params[:max_range]
    missing_adherence = false
    missing_adherence = true if params[:show_missing_adherence] == "yes"
    session[:list_of_patients] = nil

    @patients = adherence_over_hundred(params[:quarter],min_range,max_range,missing_adherence)

    @quarter = params[:quarter] + ": (#{@patients.length})" rescue  params[:quarter]
    if missing_adherence
      @report_type = "Patient(s) with missing adherence"
    elsif max_range.blank? and min_range.blank?
      @report_type = "Patient(s) with adherence greater than 100%"
    else
      @report_type = "Patient(s) with adherence starting from  #{min_range}% to #{max_range}%"
    end
    render :layout => 'report'
    return
  end

  def report_patients_with_multiple_start_reasons(start_date , end_date)

    art_eligibility_id = ConceptName.find_by_name('REASON FOR ART ELIGIBILITY').concept_id
    patients = Observation.find_by_sql(
      ["SELECT person_id, concept_id, date_created, obs_datetime, value_coded_name_id
                 FROM obs
                 WHERE (SELECT COUNT(*)
                        FROM obs observation
                        WHERE   observation.concept_id = ?
                                AND observation.person_id = obs.person_id) > 1
                                AND date_created >= ? AND date_created <= ?
                                AND obs.concept_id = ?
                                AND obs.voided = 0", art_eligibility_id, start_date, end_date, art_eligibility_id])

    patients_data = []

    patients.each do |reason|
      patient = Patient.find(reason[:person_id])
      patient_bean = PatientService.get_patient(patient.person)
      patients_data << {'person_id' => patient.id,
        'arv_number' => patient_bean.arv_number,
        'national_id' => patient_bean.national_id,
        'date_created' => reason[:date_created].strftime("%Y-%m-%d %H:%M:%S"),
        'start_reason' => ConceptName.find(reason[:value_coded_name_id]).name
      }
    end
    patients_data
  end

  def voided_observations(encounter)
    voided_obs = Observation.find_by_sql("SELECT * FROM obs WHERE obs.encounter_id = #{encounter.encounter_id} AND obs.voided = 1")
    (!voided_obs.empty?) ? voided_obs : nil
  end

  def voided_orders(new_encounter)
    voided_orders = Order.find_by_sql("SELECT * FROM orders WHERE orders.encounter_id = #{new_encounter.encounter_id} AND orders.voided = 1")
    (!voided_orders.empty?) ? voided_orders : nil
  end

  def report_out_of_range_arv_numbers(arv_number_range, start_date , end_date)
    arv_number_id             = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
    arv_start_number          = arv_number_range.first
    arv_end_number            = arv_number_range.last

    out_of_range_arv_numbers  = PatientIdentifier.find_by_sql(["SELECT patient_id, identifier, date_created FROM patient_identifier
                                   WHERE identifier_type = ? AND REPLACE(identifier, 'MPC-ARV-', '') >= ?
                                   AND REPLACE(identifier, 'MPC-ARV-', '') <= ?
                                   AND voided = 0
                                   AND (NOT EXISTS(SELECT * FROM patient_identifier
                                   WHERE identifier_type = ? AND date_created >= ? AND date_created <= ?))",
        arv_number_id,  arv_start_number,  arv_end_number, arv_number_id, start_date, end_date])

    out_of_range_arv_numbers_data = []
    out_of_range_arv_numbers.each do |arv_num_data|
      patient     = Person.find(arv_num_data[:patient_id].to_i)
      patient_bean = PatientService.get_patient(patient.person)

      out_of_range_arv_numbers_data <<{'person_id' => patient.id,
        'arv_number' => patient_bean.arv_number,
        'name' => patient_bean.name,
        'national_id' => patient_bean.national_id,
        'gender' => patient_bean.sex,
        'age' => patient_bean.age,
        'birthdate' => patient_bean.birth_date,
        'date_created' => arv_num_data[:date_created].strftime("%Y-%m-%d %H:%M:%S")
      }
    end
    out_of_range_arv_numbers_data
  end

  def report_dispensations_without_prescriptions_data(start_date , end_date)
    pills_dispensed_id      = ConceptName.find_by_name('PILLS DISPENSED').concept_id

    missed_prescriptions_data = Observation.find(:all, :select =>  "person_id, value_drug, date_created",
      :conditions =>["order_id IS NULL
                                                AND date_created >= ? AND date_created <= ? AND
                                                    concept_id = ? AND voided = 0" ,start_date , end_date, pills_dispensed_id])
    dispensations_without_prescriptions = []

    missed_prescriptions_data.each do |dispensation|
      patient = Patient.find(dispensation[:person_id])
      patient_bean = PatientService.get_patient(patient.person)
      drug_name    = Drug.find(dispensation[:value_drug]).name

      dispensations_without_prescriptions << { 'person_id' => patient.id,
        'arv_number' => patient_bean.arv_number,
        'national_id' => patient_bean.national_id,
        'date_created' => dispensation[:date_created].strftime("%Y-%m-%d %H:%M:%S"),
        'drug_name' => drug_name
      }
    end

    dispensations_without_prescriptions
  end

  def report_prescriptions_without_dispensations_data(start_date , end_date)
    pills_dispensed_id      = ConceptName.find_by_name('PILLS DISPENSED').concept_id

    missed_dispensations_data = Observation.find_by_sql(["SELECT order_id, patient_id, date_created from orders
              WHERE NOT EXISTS (SELECT * FROM obs
               WHERE orders.order_id = obs.order_id AND obs.concept_id = ?)
                AND date_created >= ? AND date_created <= ? AND orders.voided = 0", pills_dispensed_id, start_date , end_date ])

    prescriptions_without_dispensations = []

    missed_dispensations_data.each do |prescription|
      patient      = Patient.find(prescription[:patient_id])
      drug_id      = DrugOrder.find(prescription[:order_id]).drug_inventory_id
      drug_name    = Drug.find(drug_id).name

      prescriptions_without_dispensations << {'person_id' => patient.id,
        'arv_number' => PatientService.get_patient_identifier(patient, 'ARV Number'),
        'national_id' => PatientService.get_national_id(patient),
        'date_created' => prescription[:date_created].strftime("%Y-%m-%d %H:%M:%S"),
        'drug_name' => drug_name
      }
    end
    prescriptions_without_dispensations
  end

  def report_dead_with_visits(start_date, end_date)
    patient_died_concept    = ConceptName.find_by_name('PATIENT DIED').concept_id

    all_dead_patients_with_visits = "SELECT *
    FROM (SELECT observation.person_id AS patient_id, DATE(p.death_date) AS date_of_death, DATE(observation.date_created) AS date_started
          FROM person p right join obs observation ON p.person_id = observation.person_id
          WHERE p.dead = 1 AND DATE(p.death_date) < DATE(observation.date_created) AND observation.voided = 0
          ORDER BY observation.date_created ASC) AS dead_patients_visits
    WHERE DATE(date_of_death) >= DATE('#{start_date}') AND DATE(date_of_death) <= DATE('#{end_date}')
    GROUP BY patient_id"
    patients = Patient.find_by_sql([all_dead_patients_with_visits])

    patients_data  = []
    patients.each do |patient_data_row|
      person = Person.find(patient_data_row[:patient_id].to_i)
      patient_bean = PatientService.get_patient(person)
      patients_data <<{ 'person_id' => person.id,
        'arv_number' => patient_bean.arv_number,
        'name' => patient_bean.name,
        'national_id' => patient_bean.national_id,
        'gender' => patient_bean.sex,
        'age' => patient_bean.age,
        'birthdate' => patient_bean.birth_date,
        'phone' => PatientService.phone_numbers(person),
        'date_created' => patient_data_row[:date_started]
      }
    end
    patients_data
  end

  def report_males_allegedly_pregnant(start_date, end_date)
    pregnant_patient_concept_id = ConceptName.find_by_name('IS PATIENT PREGNANT?').concept_id
    patients = PatientIdentifier.find_by_sql(["
                                   SELECT person.person_id,obs.obs_datetime
                                       FROM obs INNER JOIN person ON obs.person_id = person.person_id
                                           WHERE person.gender = 'M' AND
                                           obs.concept_id = ? AND obs.obs_datetime >= ? AND obs.obs_datetime <= ? AND obs.voided = 0",
        pregnant_patient_concept_id, '2008-12-23 00:00:00', end_date])

    patients_data  = []
    patients.each do |patient_data_row|
      person = Person.find(patient_data_row[:person_id].to_i)
		  patient_bean = PatientService.get_patient(person)
      patients_data <<{ 'person_id' => person.id,
        'arv_number' => patient_bean.arv_number,
        'name' => patient_bean.name,
        'national_id' => patient_bean.national_id,
        'gender' => patient_bean.sex,
        'age' => patient_bean.age,
        'birthdate' => patient_bean.birth_date,
        'phone' => PatientService.phone_numbers(person),
        'date_created' => patient_data_row[:obs_datetime]
      }
    end
    patients_data
  end

  def report_patients_who_moved_from_second_to_first_line_drugs(start_date, end_date)

    first_line_regimen = "('D4T+3TC+NVP', 'd4T 3TC + d4T 3TC NVP')"
    second_line_regimen = "('AZT+3TC+NVP', 'D4T+3TC+EFV', 'AZT+3TC+EFV', 'TDF+3TC+EFV', 'TDF+3TC+NVP', 'TDF/3TC+LPV/r', 'AZT+3TC+LPV/R', 'ABC/3TC+LPV/r')"

    patients_who_moved_from_nd_to_st_line_drugs = "SELECT * FROM (
        SELECT patient_on_second_line_drugs.* , DATE(patient_on_first_line_drugs.date_created) AS date_started FROM (
        SELECT person_id, date_created
        FROM obs
        WHERE value_drug IN (
        SELECT drug_id
        FROM drug
        WHERE concept_id IN (SELECT concept_id FROM concept_name
        WHERE name IN #{second_line_regimen}))
        ) AS patient_on_second_line_drugs inner join

        (SELECT person_id, date_created
        FROM obs
        WHERE value_drug IN (
        SELECT drug_id
        FROM drug
        WHERE concept_id IN (SELECT concept_id FROM concept_name
        WHERE name IN #{first_line_regimen}))
        ) AS patient_on_first_line_drugs
        ON patient_on_first_line_drugs.person_id = patient_on_second_line_drugs.person_id
        WHERE DATE(patient_on_first_line_drugs.date_created) > DATE(patient_on_second_line_drugs.date_created) AND
              DATE(patient_on_first_line_drugs.date_created) >= DATE('#{start_date}') AND DATE(patient_on_first_line_drugs.date_created) <= DATE('#{end_date}')
        ORDER BY patient_on_first_line_drugs.date_created ASC) AS patients
        GROUP BY person_id"

    patients = Patient.find_by_sql([patients_who_moved_from_nd_to_st_line_drugs])

    patients_data  = []
    patients.each do |patient_data_row|
      person = Person.find(patient_data_row[:person_id].to_i)
      patient_bean = PatientService.get_patient(person)
      patients_data <<{ 'person_id' => person.id,
        'arv_number' => patient_bean.arv_number,
        'name' => patient_bean.name,
        'national_id' => patient_bean.national_id,
        'gender' => patient_bean.sex,
        'age' => patient_bean.age,
        'birthdate' => patient_bean.birth_date,
        'phone' => PatientService.phone_numbers(person),
        'date_created' => patient_data_row[:date_started]
      }
    end
    patients_data
  end

  def report_with_drug_start_dates_less_than_program_enrollment_dates(start_date, end_date)

    arv_drugs_concepts      = MedicationService.arv_drugs.inject([]) {|result, drug| result << drug.concept_id}
    on_arv_concept_id       = ConceptName.find_by_name('ON ANTIRETROVIRALS').concept_id
    hvi_program_id          = Program.find_by_name('HIV PROGRAM').program_id
    national_identifier_id  = PatientIdentifierType.find_by_name('National id').patient_identifier_type_id
    arv_number_id           = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id

    patients_on_antiretrovirals_sql = "
         (SELECT p.patient_id, s.date_created as Date_Started_ARV
          FROM patient_program p INNER JOIN patient_state s
          ON  p.patient_program_id = s.patient_program_id
          WHERE s.state IN (SELECT program_workflow_state_id
                            FROM program_workflow_state g
                            WHERE g.concept_id = #{on_arv_concept_id})
                            AND p.program_id = #{hvi_program_id}
         ) patients_on_antiretrovirals"

    antiretrovirals_obs_sql = "
         (SELECT * FROM obs
          WHERE  value_drug IN (SELECT drug_id FROM drug
          WHERE concept_id IN ( #{arv_drugs_concepts.join(', ')} ) )
         ) antiretrovirals_obs"

    drug_start_dates_less_than_program_enrollment_dates_sql= "
      SELECT * FROM (
                  SELECT patients_on_antiretrovirals.patient_id, DATE(patients_on_antiretrovirals.date_started_ARV) AS date_started_ARV,
                         antiretrovirals_obs.obs_datetime, antiretrovirals_obs.value_drug
                  FROM #{patients_on_antiretrovirals_sql}, #{antiretrovirals_obs_sql}
                  WHERE patients_on_antiretrovirals.Date_Started_ARV > antiretrovirals_obs.obs_datetime
                        AND patients_on_antiretrovirals.patient_id = antiretrovirals_obs.person_id
                        AND patients_on_antiretrovirals.Date_Started_ARV >='#{start_date}' AND patients_on_antiretrovirals.Date_Started_ARV <= '#{end_date}'
                  ORDER BY patients_on_antiretrovirals.date_started_ARV ASC) AS patient_select
      GROUP BY patient_id"


    patients       = Patient.find_by_sql(drug_start_dates_less_than_program_enrollment_dates_sql)
    patients_data  = []
    patients.each do |patient_data_row|
      person = Person.find(patient_data_row[:patient_id])
      patient_bean = PatientService.get_patient(person)
      patients_data <<{ 'person_id' => person.id,
        'arv_number' => patient_bean.arv_number,
        'name' => patient_bean.name,
        'national_id' => patient_bean.national_id,
        'gender' => patient_bean.sex,
        'age' => patient_bean.age,
        'birthdate' => patient_bean.birth_date,
        'phone' => PatientService.phone_numbers(person),
        'date_created' => patient_data_row[:date_started_ARV]
      }
    end
    patients_data
  end

  def get_adherence(quarter="Q1 2009")
    date = Report.generate_cohort_date_range(quarter)

    start_date  = date.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    end_date    = date.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    adherences  = Hash.new(0)
    adherence_concept_id = ConceptName.find_by_name("WHAT WAS THE PATIENTS ADHERENCE FOR THIS DRUG ORDER").concept_id

    adherence_sql_statement= " SELECT worse_adherence_dif, pat_ad.person_id as patient_id, pat_ad.value_numeric AS adherence_rate_worse
                            FROM (SELECT ABS(100 - Abs(value_numeric)) as worse_adherence_dif, obs_id, person_id, concept_id, encounter_id, order_id, obs_datetime, location_id, value_numeric
                                  FROM obs q
                                  WHERE concept_id = #{adherence_concept_id} AND order_id IS NOT NULL
                                  ORDER BY q.obs_datetime DESC, worse_adherence_dif DESC, person_id ASC)pat_ad
                            WHERE pat_ad.obs_datetime >= '#{start_date}' AND pat_ad.obs_datetime<= '#{end_date}'
                            GROUP BY patient_id "

    adherence_rates = Observation.find_by_sql(adherence_sql_statement)

    adherence_rates.each{|adherence|

      rate = adherence.adherence_rate_worse.to_i

      if rate >= 91 and rate <= 94
        cal_adherence = 94
      elsif  rate >= 95 and rate <= 100
        cal_adherence = 100
      else
        cal_adherence = rate + (5- rate%5)%5
      end
      adherences[cal_adherence]+=1
    }
    adherences
  end

  def adherence_over_hundred(quarter="Q1 2009",min_range = nil,max_range=nil,missing_adherence=false)
    date_range                 = Report.generate_cohort_date_range(quarter)
    start_date                 = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
    end_date                   = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
    adherence_range_filter     = " (adherence_rate_worse >= #{min_range} AND adherence_rate_worse <= #{max_range}) "
    adherence_concept_id       = ConceptName.find_by_name("WHAT WAS THE PATIENTS ADHERENCE FOR THIS DRUG ORDER").concept_id
    brought_drug_concept_id    = ConceptName.find_by_name("AMOUNT OF DRUG BROUGHT TO CLINIC").concept_id

    patients = {}

    if (min_range.blank? or max_range.blank?) and !missing_adherence
      adherence_range_filter = " (adherence_rate_worse > 100) "
    elsif missing_adherence

      adherence_range_filter = " (adherence_rate_worse IS NULL) "

    end

    patients_with_adherences =  " (SELECT   oders.start_date, obs_inner_order.obs_datetime, obs_inner_order.adherence_rate AS adherence_rate,
                                        obs_inner_order.id, obs_inner_order.patient_id, obs_inner_order.drug_inventory_id AS drug_id,
                                        ROUND(DATEDIFF(obs_inner_order.obs_datetime, oders.start_date)* obs_inner_order.equivalent_daily_dose, 0) AS expected_remaining,
                                        obs_inner_order.quantity AS quantity, obs_inner_order.encounter_id, obs_inner_order.order_id
                               FROM (SELECT latest_adherence.obs_datetime, latest_adherence.adherence_rate, latest_adherence.id, latest_adherence.patient_id, latest_adherence.order_id, drugOrder.drug_inventory_id, drugOrder.equivalent_daily_dose, drugOrder.quantity, latest_adherence.encounter_id
                                    FROM (SELECT all_adherences.obs_datetime, all_adherences.value_numeric AS adherence_rate, all_adherences.obs_id as id, all_adherences.person_id as patient_id,all_adherences.order_id, all_adherences.encounter_id
                                          FROM (SELECT obs_id, person_id, concept_id, encounter_id, order_id, obs_datetime, location_id, value_numeric
                                                FROM obs Observations
                                                WHERE concept_id = #{adherence_concept_id}
                                                ORDER BY person_id ASC , Observations.obs_datetime DESC )all_adherences
                                          WHERE all_adherences.obs_datetime >= '#{start_date}' AND all_adherences.obs_datetime<= '#{end_date}'
                                          GROUP BY order_id, patient_id) latest_adherence
                                    INNER JOIN
                                          drug_order drugOrder
                                    On    drugOrder.order_id = latest_adherence.order_id) obs_inner_order
                               INNER JOIN
                                    orders oders
                               On     oders.order_id = obs_inner_order.order_id) patients_with_adherence  "

    worse_adherence_per_patient =" (SELECT worse_adherence_dif, pat_ad.person_id as patient_id, pat_ad.value_numeric AS adherence_rate_worse
                                FROM (SELECT ABS(100 - Abs(value_numeric)) as worse_adherence_dif, obs_id, person_id, concept_id, encounter_id, order_id, obs_datetime, location_id, value_numeric
                                      FROM obs q
                                      WHERE concept_id = #{adherence_concept_id} AND order_id IS NOT NULL
                                      ORDER BY q.obs_datetime DESC, worse_adherence_dif DESC, person_id ASC)pat_ad
                                WHERE pat_ad.obs_datetime >= '#{start_date}' AND pat_ad.obs_datetime<= '#{end_date}'
                                GROUP BY patient_id ) worse_adherence_per_patient   "

    patient_adherences_sql =  " SELECT *
                                 FROM   #{patients_with_adherences} INNER JOIN #{worse_adherence_per_patient}
                                 ON patients_with_adherence.patient_id = worse_adherence_per_patient.patient_id
                                 WHERE  #{adherence_range_filter} "

    rates = Observation.find_by_sql(patient_adherences_sql)

    patients_rates = []
    rates.each{|rate|
      patients_rates << rate
    }
    adherence_rates = patients_rates

    arv_number_id = PatientIdentifierType.find_by_name('ARV Number').patient_identifier_type_id
    adherence_rates.each{|rate|

      patient    = Patient.find(rate.patient_id)
      person     = patient.person
      patient_bean = PatientService.get_patient(person)
      drug       = Drug.find(rate.drug_id)
      pill_count = Observation.find(:first, :conditions => "order_id = #{rate.order_id} AND encounter_id = #{rate.encounter_id} AND concept_id = #{brought_drug_concept_id} ").value_numeric rescue ""
      if !patients[patient.patient_id] then

        patients[patient.patient_id]={"id" =>patient.id,
          "arv_number" => patient_bean.arv_number,
          "name" => patient_bean.name,
          "national_id" => patient_bean.national_id,
          "visit_date" =>rate.obs_datetime,
          "gender" =>patient_bean.sex,
          "age" => PatientService.patient_age_at_initiation(patient, rate.start_date.to_date),
          "birthdate" => patient_bean.birth_date,
          "pill_count" => pill_count.to_i.to_s,
          "adherence" => rate. adherence_rate_worse,
          "start_date" => rate.start_date.to_date,
          "expected_count" =>rate.expected_remaining,
          "drug" => drug.name}
      elsif  patients[patient.patient_id] then

        patients[patient.patient_id]["age"].to_i < PatientService.patient_age_at_initiation(patient, rate.start_date.to_date).to_i ? patients[patient.patient_id]["age"] = patient.age_at_initiation(rate.start_date.to_date).to_s : ""

        patients[patient.patient_id]["drug"] = patients[patient.patient_id]["drug"].to_s + "<br>#{drug.name}"

        patients[patient.patient_id]["pill_count"] << "<br>#{pill_count.to_i.to_s}"

        patients[patient.patient_id]["expected_count"] << "<br>#{rate.expected_remaining.to_i.to_s}"

        patients[patient.patient_id]["start_date"].to_date > rate.start_date.to_date ?
          patients[patient.patient_id]["start_date"] = rate.start_date.to_date : ""

      end
    }

    patients.sort { |a,b| a[1]['adherence'].to_i <=> b[1]['adherence'].to_i }
  end

  def opd_report_index
  end
  def opd_report_index_graph
  end


  def opd_cohort
  	@report_type = params[:selType]
    @start_date = nil
    @end_date = nil
    @start_age = params[:startAge]
    @end_age = params[:endAge]
    @type = params[:selType]

    case params[:selSelect]
    when "day"
      @start_date = params[:day]
      @end_date = params[:day]

    when "week"
      if params[:selWeek] != ""
        if params[:selWeek] == "mon"
          @start_date = "#{params[:selYear]}-#{Date.today.month.to_s}-01".to_date
          @end_date = Date.today
        elsif params[:selWeek] == "lmon"
          lmon = Date.today.month - 1
          lmon_days = days_in_month(lmon).to_s
          @start_date = "#{params[:selYear]}-#{lmon}-01".to_date
          @end_date = "#{params[:selYear]}-#{lmon}-#{lmon_days}".to_date
        elsif params[:selWeek] == "all"
          mon = Date.today.month
          mon_days = days_in_month(mon).to_s
          @start_date = ("#{params[:selYear]}-01-01").to_date.strftime("%Y-%m-%d")
      	  @end_date = Date.today
        else
          @start_date = (("#{params[:selYear]}-01-01".to_date) + (params[:selWeek].to_i * 7)) -
            ("#{params[:selYear]}-01-01".to_date.strftime("%w").to_i)
          @end_date = (("#{params[:selYear]}-01-01".to_date) + (params[:selWeek].to_i * 7)) +
            6 - ("#{params[:selYear]}-01-01".to_date.strftime("%w").to_i)
        end
      else
        @start_date = ("#{params[:selYear]}-01-01").to_date.strftime("%Y-%m-%d")
        @end_date = ("#{params[:selYear]}-12-31").to_date.strftime("%Y-%m-%d")
      end
    when "month"
      @start_date = ("#{params[:selYear]}-#{params[:selMonth]}-01").to_date.strftime("%Y-%m-%d")

      @end_date = ("#{params[:selYear]}-#{params[:selMonth]}-#{ (params[:selMonth].to_i != 12 ?
        ("#{params[:selYear]}-#{params[:selMonth].to_i + 1}-01".to_date - 1).strftime("%d") : "31") }").to_date.strftime("%Y-%m-%d")

    when "year"
      @start_date = ("#{params[:selYear]}-01-01").to_date.strftime("%Y-%m-%d")
      @end_date = ("#{params[:selYear]}-12-31").to_date.strftime("%Y-%m-%d")

    when "quarter"
      day = params[:selQtr].to_s.match(/^min=(.+)&max=(.+)$/)

      @start_date = (day ? day[1] : Date.today.strftime("%Y-%m-%d"))
      @end_date = (day ? day[2] : Date.today.strftime("%Y-%m-%d"))

    when "range"
      @start_date = params[:start_date]
      @end_date = params[:end_date]

    end

    report = Reports::CohortOpd.new(@start_date, @end_date, @start_age, @end_age, @type)

    @specified_period = report.specified_period

    # raise @specified_period.to_yaml
    @diag = Hash.new()

    @diag['hiv_positive'] = report.hiv_positive

    @attendance = report.attendance

    @measles_u_5 = report.measles_u_5

    @measles = report.measles

    @tb = report.tb

    @upper_respiratory_infections = report.upper_respiratory_infections

    @pneumonia = report.pneumonia

    @pneumonia_u_5 = report.pneumonia_u_5

    @asthma = report.asthma

    @lower_respiratory_infection = report.lower_respiratory_infection

    @cholera = report.cholera

    @cholera_u_5 = report.cholera_u_5

    @dysentery = report.dysentery

    @dysentery_u_5 = report.dysentery_u_5

    @diarrhoea = report.diarrhoea

    @diarrhoea_u_5 = report.diarrhoea_u_5

    @anaemia = report.anaemia

    @malnutrition = report.malnutrition

    @goitre = report.goitre

    @hypertension = report.hypertension

    @heart = report.heart

    @acute_eye_infection = report.acute_eye_infection

    @epilepsy = report.epilepsy

    @dental_decay = report.dental_decay

    @other_dental_conditions = report.other_dental_conditions

    @scabies = report.scabies

    @skin = report.skin

    @malaria = report.malaria

    @sti = report.sti

    @bilharzia = report.bilharzia

    @chicken_pox = report.chicken_pox

    @intestinal_worms = report.intestinal_worms

    @jaundice = report.jaundice

    @meningitis = report.meningitis

    @typhoid = report.typhoid

    @rabies = report.rabies

    @communicable_diseases = report.communicable_diseases

    @gynaecological_disorders = report.gynaecological_disorders

    @genito_urinary_infections = report.genito_urinary_infections

    @musculoskeletal_pains = report.musculoskeletal_pains

    @traumatic_conditions = report.traumatic_conditions

    @ear_infections = report.ear_infections

    @non_communicable_diseases = report.non_communicable_diseases

    @accident = report.accident

    @diabetes = report.diabetes

    @surgicals = report.surgicals

    @opd_deaths = report.opd_deaths

    @pud = report.pud

    @gastritis = report.gastritis
    @current_location_name = Location.current_health_center.name
    if @type == "diagnoses" || @type == "diagnoses_adults" || @type == "diagnoses_paeds"
      @general = report.general
    end

    if params[:selType]
      case params[:selType]
      when "adults"
        render :layout => "report", :action => "adults_cohort" and return
      when "paeds"
        render :layout => "report", :action => "paeds_cohort" and return
      else
        render :layout => "report", :action => "general_cohort" and return
      end
    end
    render :layout => "opd_cohort"
  end
  

  def opd_general_graph
  	@report_type = params[:selType]
    @start_date = nil
    @end_date = nil
    @logo = CoreService.get_global_property_value('logo').to_s
    @start_age = params[:startAge]
    @end_age = params[:endAge]
    @type = params[:selType]

    case params[:selSelect]
    when "day"
      @start_date = params[:day]
      @end_date = params[:day]

    when "week"
      if params[:selWeek] != ""
        if params[:selWeek] == "mon"
          @start_date = "#{params[:selYear]}-#{Date.today.month.to_s}-01".to_date
          @end_date = Date.today
        elsif params[:selWeek] == "lmon"
          lmon = Date.today.month - 1
          lmon_days = days_in_month(lmon).to_s
          @start_date = "#{params[:selYear]}-#{lmon}-01".to_date
          @end_date = "#{params[:selYear]}-#{lmon}-#{lmon_days}".to_date
        elsif params[:selWeek] == "all"
          mon = Date.today.month
          mon_days = days_in_month(mon).to_s
          @start_date = ("#{params[:selYear]}-01-01").to_date.strftime("%Y-%m-%d")
      	  @end_date = Date.today
        else
          @start_date = (("#{params[:selYear]}-01-01".to_date) + (params[:selWeek].to_i * 7)) -
            ("#{params[:selYear]}-01-01".to_date.strftime("%w").to_i)
          @end_date = (("#{params[:selYear]}-01-01".to_date) + (params[:selWeek].to_i * 7)) +
            6 - ("#{params[:selYear]}-01-01".to_date.strftime("%w").to_i)
        end
      else
        @start_date = ("#{params[:selYear]}-01-01").to_date.strftime("%Y-%m-%d")
        @end_date = ("#{params[:selYear]}-12-31").to_date.strftime("%Y-%m-%d")
      end
    when "month"
      @start_date = ("#{params[:selYear]}-#{params[:selMonth]}-01").to_date.strftime("%Y-%m-%d")

      @end_date = ("#{params[:selYear]}-#{params[:selMonth]}-#{ (params[:selMonth].to_i != 12 ?
        ("#{params[:selYear]}-#{params[:selMonth].to_i + 1}-01".to_date - 1).strftime("%d") : "31") }").to_date.strftime("%Y-%m-%d")

    when "year"
      @start_date = ("#{params[:selYear]}-01-01").to_date.strftime("%Y-%m-%d")
      @end_date = ("#{params[:selYear]}-12-31").to_date.strftime("%Y-%m-%d")

    when "quarter"
      day = params[:selQtr].to_s.match(/^min=(.+)&max=(.+)$/)

      @start_date = (day ? day[1] : Date.today.strftime("%Y-%m-%d"))
      @end_date = (day ? day[2] : Date.today.strftime("%Y-%m-%d"))

    when "range"
      @start_date = params[:start_date]
      @end_date = params[:end_date]

    end
    @formated_start_date = @start_date.to_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.to_date.strftime('%A, %d, %b, %Y')
    report = Reports::CohortOpd.new(@start_date, @end_date, @start_age, @end_age, @type)

    @specified_period = report.specified_period
		@details = []
    # raise @specified_period.to_yaml

		@details << ["Hiv Positive",report.hiv_positive]
		@details << ["Attendance",report.attendance]
		@details << ["Measles Under 5" ,report.measles_u_5]

 		@details << ["Measles", report.measles]

 		@details << ["Tuberculosis", report.tb]

 		@details << ["Upper Respiratory Infections", report.upper_respiratory_infections]

 		@details << [ "Pnuemonia", report.pneumonia]

		@details << ["Pnuemonia Under 5", report.pneumonia_u_5]

		@details << ["Asthma", report.asthma]

		@details << ["Lower Respiratory Infection", report.lower_respiratory_infection]

		@details << ["Cholera", report.cholera]

		@details << ["Cholera Under 5",report.cholera_u_5]

		@details << ["Dysentery", report.dysentery]

		@details << ["Dysentery Under 5",report.dysentery_u_5]

		@details << ["Diarrhoea",report.diarrhoea]

		@details << ["Diarrhoea Under 5",report.diarrhoea_u_5]

		@details << ["Anaemia", report.anaemia]

		@details << ["Malnutrition", report.malnutrition]

		@details << ["Goitre",report.goitre]

		@details << ["Hypertension",report.hypertension]

		@details << ["Heart",report.heart]

		@details << ["Acute Eye Infection", report.acute_eye_infection]

		@details << ["Epilepsy",report.epilepsy]

		@details << ["Dental Decay",report.dental_decay]

		@details << ["Other Dental Conditions", report.other_dental_conditions]

		@details << ["Scabies",report.scabies]

		@details << ["Skin",report.skin]

		@details << ["Malaria",report.malaria]

		@details << ["STI",report.sti]

		@details << ["Bilharzia",report.bilharzia]

		@details << ["Chicken Pox",report.chicken_pox]

		@details << ["Intestinal Worms" , report.intestinal_worms]

 		@details << ["Jaundice",report.jaundice]

		@details << ["Meningitis",report.meningitis]

		@details << ["Typhoid",report.typhoid]

 		@details << ["Rabies",report.rabies]

 		@details << ["Communicable Diseases" , report.communicable_diseases]

		@details << ["Gynaecological Disorders",report.gynaecological_disorders]

 		@details << ["Genito Urinary Infections",report.genito_urinary_infections]

 		@details << ["Musculosketal Pains", report.musculoskeletal_pains]

 		@details << ["Traumatic Conditions",report.traumatic_conditions]

 		@details << ["Ear Infection", report.ear_infections]

 		@details << ["Non-Communicable Diseases",report.non_communicable_diseases]

 		@details << ["Accident", report.accident]

		@details << ["Diabetes", report.diabetes]

 		@details << ["Surgicals", report.surgicals]

 		@details << ["OPD Deaths",report.opd_deaths]

 		@details << ["Pud", report.pud]

 		@details << ["Gastritis",report.gastritis]
    
    @current_location_name = Location.current_health_center.name
    if @type == "diagnoses" || @type == "diagnoses_adults" || @type == "diagnoses_paeds"
      @general = report.general
    end
    
    render :layout => "menu"		
  end

  def opd_menu
	@shifts =[
			["Day","day"],
			["Night","night"],
			["24 Hours","24_hour"],
			["Specific","specific"]
		]
		@report_name = params[:report_name]
  end

	def shift_report
		@report_name = params[:report_name]
		@shift_type = params[:shift_type]
		@shift_date = params[:shift_date]
    #raise params.inspect
		if params[:start_time] == ""
			 if @shift_type == "day"
				 @start_time = Time.parse(@shift_date + " 7:30:00")
				 @end_time = Time.parse(@shift_date + " 16:59:59")
       end

			 if @shift_type == "night"
				 @start_time = Time.parse(@shift_date + " 17:00:00")
				 @end_time= (Time.parse(@shift_date + " 7:30:00")).tomorrow
       end

       if @shift_type == "24_hour"
				 @start_time = Time.parse(@shift_date + " 17:00:00")
				 @end_time= (Time.parse(@shift_date + " 7:29:59")).tomorrow
			 end
		else
					@start_time = Time.parse(@shift_date + " " + params[:start_time])
					@end_time = Time.parse(@shift_date + " " + params[:end_time])
		end

		@logo = CoreService.get_global_property_value('logo').to_s
    @current_location_name =Location.current_health_center.name
    @admission = []


    @outpatient_diagnosis_id = EncounterType.find_by_name("OUTPATIENT DIAGNOSIS").encounter_type_id
    trauma_concepts = ['trauma','traumatic conditions'] #to find total patients with diagnosis like trauma
    @total_trauma_patients = 0
    trauma_concepts.each { |concept|
      condition_string = "name LIKE \"#{concept}\" "
      trauma_concept_ids = ConceptName.find_by_sql("SELECT * FROM concept_name WHERE \
      #{condition_string} AND voided = 0" ).map{|c| c.concept_id}
      total_trauma_patients = Encounter.find(:all,
			:joins => [:type, :observations, [:patient => :person]],\
        :conditions => ["encounter_type = ? AND encounter.voided = 0 AND\
					value_coded IN (?) AND encounter_datetime >= ? AND encounter_datetime <= ?",\
          @outpatient_diagnosis_id, trauma_concept_ids, @start_time, @end_time]).map{|e| e.patient_id}.uniq.size
      @total_trauma_patients+=total_trauma_patients
    }


    surgical_concepts = ['abdomical pain, surgical', 'acute abdomen surgical problem',
      'all other surgical conditions']
    @total_surgical_patients = 0
    surgical_concepts.each { |concept|
      condition_string = "name LIKE \"#{concept}\" "
      surgical_concept_ids = ConceptName.find_by_sql("SELECT * FROM concept_name WHERE \
      #{condition_string} AND voided = 0" ).map{|c| c.concept_id}
      total_surgical_patients = Encounter.find(:all,
        :joins => [:type, :observations, [:patient => :person]],\
        :conditions => ["encounter_type = ? AND encounter.voided = 0 AND\
				 value_coded IN (?) AND encounter_datetime >= ? AND encounter_datetime <= ?",\
         @outpatient_diagnosis_id, surgical_concept_ids, @start_time, @end_time]).map{|e| e.patient_id}.uniq.size
      @total_surgical_patients+=total_surgical_patients
    }

    pyschiatric_concepts = ['chronic psychiatric disease', 'psychiatric disorder']
    @total_psychiatric_patients = 0
    pyschiatric_concepts.each { |concept|
      condition_string = "name LIKE \"#{concept}\" "
      psychiatric_concept_ids = ConceptName.find_by_sql("SELECT * FROM concept_name WHERE \
      #{condition_string} AND voided = 0" ).map{|c| c.concept_id}
      total_psychiatric_patients = Encounter.find(:all,
        :joins => [:type, :observations, [:patient => :person]],\
        :conditions => ["encounter_type = ? AND encounter.voided = 0 AND\
				 value_coded IN (?) AND encounter_datetime >= ? AND encounter_datetime <= ?",\
         @outpatient_diagnosis_id, psychiatric_concept_ids, @start_time, @end_time]).map{|e| e.patient_id}.uniq.size
      @total_psychiatric_patients+=total_psychiatric_patients
    }

    #As of now there is no diagnosis to categorize a patient as an orthropaedic so we will use ward
    #Orthropaedic patients are patients admitted in ward 6A.
    admission_encounter_id = EncounterType.find_by_name("ADMIT PATIENT").encounter_type_id
    orthro_paedic_ward = 'Ward 6A'
    @orthro_patients = Encounter.find(:all, :joins => [:type, :observations],\
        :conditions => ['encounter_type = ? AND encounter_datetime >= ? AND
        encounter_datetime <= ? AND value_text = ?', admission_encounter_id, @start_time, @end_time,
        orthro_paedic_ward]).map{|e| e.patient_id}.uniq.size


    wards = ['Ward 3A', 'Ward 4B', 'Ward 5A', 'Ward 5B', 'Ward 6A', 'Labour Ward','Post-natal Ward',
      'Ante-natal Ward', 'Ward 1A', 'Ward 2A', 'Gynaecology Ward'
    ]
    @admitted = {}
    wards.each { |ward|
     total_patients = Encounter.find(:all, :joins => [:type, :observations],\
        :conditions => ['encounter_type = ? AND encounter_datetime >= ? AND
        encounter_datetime <= ? AND value_text = ?', admission_encounter_id, @start_time, @end_time,
        ward.to_s]).map{|e| e.patient_id}.uniq.size
        @admitted[ward] = total_patients
    }

    @total_medical_admissions = 0
    medical_wards = ['Ward 3A', 'Ward 4B', 'Ward 2A','Lepra']
    medical_wards.each { |ward|
     total_patients = Encounter.find(:all, :joins => [:type, :observations],\
        :conditions => ['encounter_type = ? AND encounter_datetime >= ? AND
        encounter_datetime <= ? AND value_text = ?', admission_encounter_id, @start_time, @end_time,
        ward.to_s]).map{|e| e.patient_id}.uniq.size
        @total_medical_admissions+=total_patients
    }
 
    surgical_wards = ['Ward 5A', 'Ward 5B', 'Ward 6A', 'Burns']
    @total_surgical_admissions = 0
    surgical_wards.each { |ward|
     total_patients = Encounter.find(:all, :joins => [:type, :observations],\
        :conditions => ['encounter_type = ? AND encounter_datetime >= ? AND
        encounter_datetime <= ? AND value_text = ?', admission_encounter_id, @start_time, @end_time,
        ward.to_s]).map{|e| e.patient_id}.uniq.size
        @total_surgical_admissions+=total_patients
    }

    obs_and_gynae_wards = ['Gynaecology ward', 'Ante-natal ward', 'Post-natal ward', 'Labour ward', 'Ward 1A']
    @obs_gynae_admissions = 0
    obs_and_gynae_wards.each { |ward|
     total_patients = Encounter.find(:all, :joins => [:type, :observations],\
        :conditions => ['encounter_type = ? AND encounter_datetime >= ? AND
        encounter_datetime <= ? AND value_text = ?', admission_encounter_id, @start_time, @end_time,
        ward.to_s]).map{|e| e.patient_id}.uniq.size
        @obs_gynae_admissions+=total_patients
    }


    #icu_wards = ['ICU']
    #raise @admitted['Ward 4B'].inspect
		render :layout => "report"
  end

  def count_patient_with_concept(concept, start_date, end_date)

			condition_string = "name LIKE \"#{concept}\" "
      @outpatient_diagnosis_id = EncounterType.find_by_name("OUTPATIENT DIAGNOSIS").encounter_type_id
			@concept_ids = ConceptName.find_by_sql("SELECT * FROM concept_name WHERE \
        #{condition_string} AND voided = 0" ).map{|c| c.concept_id}

			Encounter.find(:all,
										 :joins => [:type, :observations, [:patient => :person]],\
										 :conditions => ["encounter_type = ? AND encounter.voided = 0 AND\
																		value_coded IN (?) AND encounter_datetime >= ?\
																		AND encounter_datetime <= ?",\
																		@outpatient_diagnosis_id, @concept_ids, start_date, end_date]\
										).map{|e| e. patient_id}.uniq.size
	end

	
	def total_registration

    @report_name = params[:report_name]
    @logo = CoreService.get_global_property_value('logo').to_s
    @current_location_name =Location.current_health_center.name
    start_year = params[:start_year]
    start_month = params[:start_month]
    start_day = params[:start_day]
    end_year = params[:end_year]
    end_month = params[:end_month]
    end_day = params[:end_day]
    @age_groups = params[:age_groups].map{|g|g.upcase}
    @start_date = (start_year + "-" + start_month + "-" + start_day).to_date
    @end_date = (end_year + "-" + end_month + "-" + end_day).to_date
    @total_registered = []
    @formated_start_date = @start_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.strftime('%A, %d, %b, %Y')

    people = Person.find(:all,:include =>{:patient=>{:encounters=>{:type=>{}}}},
        :conditions => ["patient.patient_id IS NOT NULL AND encounter_type.name IN (?)
        AND person.date_created >= TIMESTAMP(?)
        AND person.date_created  <= TIMESTAMP(?)", ["TREATMENT","OUTPATIENT DIAGNOSIS"],
        @start_date.strftime('%Y-%m-%d 00:00:00'),
        @end_date.strftime('%Y-%m-%d 23:59:59')])
        peoples = []
        people.each do  |person|
          if (@age_groups.include?("< 6 MONTHS"))
            if (PatientService.age_in_months(person).to_i < 6 )
                peoples << person
            end
          end

          if (@age_groups.include?("6 MONTHS TO < 1 YR"))
            if (PatientService.age_in_months(person).to_i >= 6 && PatientService.age(person).to_i < 1)
                peoples << person
            end
          end

          if (@age_groups.include?("1 TO < 5"))
            if (PatientService.age(person).to_i >= 1 && PatientService.age(person).to_i < 5)
                peoples << person
            end
          end

          if (@age_groups.include?("5 TO 14"))
            if (PatientService.age(person).to_i >= 5 && PatientService.age(person).to_i < 14)
                peoples << person
            end
          end

          if (@age_groups.include?("> 14 TO < 20"))
            if (PatientService.age(person).to_i >= 14 && PatientService.age(person).to_i < 20)
                peoples << person
            end
          end

          if (@age_groups.include?("20 TO 30"))
            if (PatientService.age(person).to_i >= 20 && PatientService.age(person).to_i < 30)
                peoples << person
            end
          end

          if (@age_groups.include?("30 TO < 40"))
            if (PatientService.age(person).to_i >= 30 && PatientService.age(person).to_i < 40)
                peoples << person
            end
          end

          if (@age_groups.include?("40 TO < 50"))
            if (PatientService.age(person).to_i >= 40 && PatientService.age(person).to_i < 50)
                peoples << person
            end
          end

          if (@age_groups.include?("ALL"))
                peoples << person
          end

        end
    @total_registered = peoples
      @registered = []
      peoples.each do | person_id |
        person = Person.find(person_id)
        name = person.names.first.given_name + ' ' + person.names.first.family_name rescue nil
        @registered << [name, person.birthdate, person.gender,
        person.date_created.to_date,
        person.addresses.first.city_village,
        person.addresses.first.county_district]
      end

    render :layout => "report"
  end

	def total_registration_graph

    @report_name = params[:report_name]
    @logo = CoreService.get_global_property_value('logo').to_s
    @current_location_name =Location.current_health_center.name
    start_year = params[:start_year]
    start_month = params[:start_month]
    start_day = params[:start_day]
    end_year = params[:end_year]
    end_month = params[:end_month]
    end_day = params[:end_day]

    @start_date = (start_year + "-" + start_month + "-" + start_day).to_date
    @end_date = (end_year + "-" + end_month + "-" + end_day).to_date
    @total_registered = 0
    @formated_start_date = @start_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.strftime('%A, %d, %b, %Y')

    people = Person.find(:all,:include =>{:patient=>{:encounters=>{:type=>{}}}},
        :conditions => ["patient.patient_id IS NOT NULL AND encounter_type.name IN (?)
        AND person.date_created >= TIMESTAMP(?)
        AND person.date_created  <= TIMESTAMP(?)", ["TREATMENT","OUTPATIENT DIAGNOSIS"],
        @start_date.strftime('%Y-%m-%d 00:00:00'),
        @end_date.strftime('%Y-%m-%d 23:59:59')])
        @peoples = Hash.new(0)
        people.each do  |person|


            if (PatientService.age_in_months(person).to_i < 6 )
                if(PatientService.sex(person) == 'Male')
                	@peoples['Under6M'] +=1
                else
	                @peoples['Under6F'] +=1
                end

            end

            if (PatientService.age_in_months(person).to_i >= 6 && PatientService.age(person).to_i < 1)
                if(PatientService.sex(person) == 'Male')
                	@peoples['Under12MM'] +=1
                else
	                @peoples['Under12MF'] +=1
                end

            end

            if (PatientService.age(person).to_i >= 1 && PatientService.age(person).to_i < 5)
                if(PatientService.sex(person) == 'Male')
                	@peoples['Under5YM'] +=1
                else
	                @peoples['Under5YF'] +=1
                end

            end

            if (PatientService.age(person).to_i >= 5 && PatientService.age(person).to_i < 14)
                if(PatientService.sex(person) == 'Male')
                	@peoples['Under14YM'] +=1
                else
	                @peoples['Under14YF'] +=1
                end

            end

            if (PatientService.age(person).to_i >= 14 && PatientService.age(person).to_i < 20)
                if(PatientService.sex(person) == 'Male')
                	@peoples['Under20YM'] +=1
                else
	                @peoples['Under20YF'] +=1
                end

            end

            if (PatientService.age(person).to_i >= 20 && PatientService.age(person).to_i < 30)
                if(PatientService.sex(person) == 'Male')
                	@peoples['Under30YM'] +=1
                else
	                @peoples['Under30YF'] +=1
                end

            end

            if (PatientService.age(person).to_i >= 30 && PatientService.age(person).to_i < 40)
                if(PatientService.sex(person) == 'Male')
                	@peoples['Under40YM'] +=1
                else
	                @peoples['Under40YF'] +=1
                end

            end

            if (PatientService.age(person).to_i >= 40 && PatientService.age(person).to_i < 50)
                if(PatientService.sex(person) == 'Male')
                	@peoples['Under50YM'] +=1
                else
	                @peoples['Under50YF'] +=1
                end

            end
						
						if (PatientService.age(person).to_i >= 50)
                if(PatientService.sex(person) == 'Male')
                	@peoples['Over50YM'] +=1
                else
	                @peoples['Over50YF'] +=1
                end

            end
    		@total_registered +=1
        end    

    render :layout => "report"
  end


  def diagnosis_report

    @report_name = params[:report_name]
    @logo = CoreService.get_global_property_value('logo').to_s
    @current_location_name =Location.current_health_center.name
    age_groups = params[:age_groups]
    start_year = params[:start_year]
    start_month = params[:start_month]
    start_day = params[:start_day]
    end_year = params[:end_year]
    end_month = params[:end_month]
    end_day = params[:end_day]

    @age_groups = age_groups.map{|g|g.upcase}
    @required = ["TREATMENT","OUTPATIENT DIAGNOSIS"]
    @start_date = (start_year + "-" + start_month + "-" + start_day).to_date
    @end_date = (end_year + "-" + end_month + "-" + end_day).to_date
    @disaggregated_diagnosis = {}
    @diagnosis_by_address = {}
    @diagnosis_name = {}
    @diagnosis_report = Hash.new(0)
    @formated_start_date = @start_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.strftime('%A, %d, %b, %Y')
    concept_ids = ConceptName.find(:all,
    :conditions => ["name IN (?)",["Additional diagnosis","Diagnosis",
    "primary diagnosis","secondary diagnosis"]]).map(&:concept_id)

      observation = Observation.find(:all, :include => {:person =>{}},
        :conditions => ["obs.obs_datetime >= TIMESTAMP(?) AND obs.obs_datetime
        <= TIMESTAMP(?) AND obs.concept_id IN (?)",
        @start_date.strftime('%Y-%m-%d 00:00:00'),
        @end_date.strftime('%Y-%m-%d 23:59:59'),concept_ids])

        observation.each do |obs|
          next if obs.answer_concept.blank?
          diagnosis_name = obs.answer_concept.fullname rescue ''
           if (PatientService.age_in_months(obs.person).to_i < 6 )
              @diagnosis_report[diagnosis_name]+=1
           end

          if (@age_groups.include?("6 MONTHS TO < 1 YR"))
            if (PatientService.age_in_months(obs.person).to_i >= 6 && PatientService.age(obs.person).to_i < 1)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("1 TO < 5"))
            if (PatientService.age(obs.person).to_i >= 1 && PatientService.age(obs.person).to_i < 5)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("5 TO 14"))
            if (PatientService.age(obs.person).to_i >= 5 && PatientService.age(obs.person).to_i < 14)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("> 14 TO < 20"))
            if (PatientService.age(obs.person).to_i >= 14 && PatientService.age(obs.person).to_i < 20)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("20 TO 30"))
            if (PatientService.age(obs.person).to_i >= 20 && PatientService.age(obs.person).to_i < 30)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("30 TO < 40"))
            if (PatientService.age(obs.person).to_i >= 30 && PatientService.age(obs.person).to_i < 40)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("40 TO < 50"))
            if (PatientService.age(obs.person).to_i >= 40 && PatientService.age(obs.person).to_i < 50)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("ALL"))
            @diagnosis_report[diagnosis_name]+=1
          end
        end

      @diagnosis_report_paginated = []
      @diagnosis_report.each { | diag, value |
        @diagnosis_report_paginated << [diag, value]
      }
    render :layout => "report"
  end

def diagnosis_report_graph


    @report_name = params[:report_name]
    @logo = CoreService.get_global_property_value('logo').to_s
    @current_location_name =Location.current_health_center.name
    age_groups = params[:age_groups]
    start_year = params[:start_year]
    start_month = params[:start_month]
    start_day = params[:start_day]
    end_year = params[:end_year]
    end_month = params[:end_month]
    end_day = params[:end_day]

    @age_groups = age_groups.map{|g|g.upcase}
    @required = ["TREATMENT","OUTPATIENT DIAGNOSIS"]
    @start_date = (start_year + "-" + start_month + "-" + start_day).to_date
    @end_date = (end_year + "-" + end_month + "-" + end_day).to_date
    @disaggregated_diagnosis = {}
    @diagnosis_by_address = {}
    @diagnosis_name = {}
    @diagnosis_report = Hash.new(0)
    @formated_start_date = @start_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.strftime('%A, %d, %b, %Y')
    concept_ids = ConceptName.find(:all,
    :conditions => ["name IN (?)",["Additional diagnosis","Diagnosis",
    "primary diagnosis","secondary diagnosis"]]).map(&:concept_id)

      observation = Observation.find(:all, :include => {:person =>{}},
        :conditions => ["obs.obs_datetime >= TIMESTAMP(?) AND obs.obs_datetime
        <= TIMESTAMP(?) AND obs.concept_id IN (?)",
        @start_date.strftime('%Y-%m-%d 00:00:00'),
        @end_date.strftime('%Y-%m-%d 23:59:59'),concept_ids])

        observation.each do |obs|
          next if obs.answer_concept.blank?
          diagnosis_name = obs.answer_concept.fullname rescue ''
           if (PatientService.age_in_months(obs.person).to_i < 6 )
              @diagnosis_report[diagnosis_name]+=1
           end

          if (@age_groups.include?("6 MONTHS TO < 1 YR"))
            if (PatientService.age_in_months(obs.person).to_i >= 6 && PatientService.age(obs.person).to_i < 1)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("1 TO < 5"))
            if (PatientService.age(obs.person).to_i >= 1 && PatientService.age(obs.person).to_i < 5)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("5 TO 14"))
            if (PatientService.age(obs.person).to_i >= 5 && PatientService.age(obs.person).to_i < 14)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("> 14 TO < 20"))
            if (PatientService.age(obs.person).to_i >= 14 && PatientService.age(obs.person).to_i < 20)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("20 TO 30"))
            if (PatientService.age(obs.person).to_i >= 20 && PatientService.age(obs.person).to_i < 30)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("30 TO < 40"))
            if (PatientService.age(obs.person).to_i >= 30 && PatientService.age(obs.person).to_i < 40)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("40 TO < 50"))
            if (PatientService.age(obs.person).to_i >= 40 && PatientService.age(obs.person).to_i < 50)
              @diagnosis_report[diagnosis_name]+=1
            end
          end

          if (@age_groups.include?("ALL"))
            @diagnosis_report[diagnosis_name]+=1
          end
        end

      @diagnosis_report_paginated = []
      @diagnosis_report.each { | diag, value |
        @diagnosis_report_paginated << [diag, value]
      }

  	@ara = Array.new
  	@ara = [[0, 3], [4, 8], [8, 5], [9, 13],[2,8],[5,12],[7,15],[1,16]]

    render :layout => 'report'
  end


  def patient_level_data
  
    @report_name = params[:report_name]
    @age_groups = params[:age_groups]
    @logo = CoreService.get_global_property_value('logo').to_s
    session_date = session[:datetime].to_date rescue Date.today
    @current_location_name =Location.current_health_center.name
    if params[:page].blank?
      session[:people] = nil
      session[:observation] = nil
      session[:groups] = params[:age_groups]
      age_groups = params[:age_groups]
      start_year = params[:start_year]
      start_month = params[:start_month]
      start_day = params[:start_day]
      end_year = params[:end_year]
      end_month = params[:end_month]
      end_day = params[:end_day]
      @age_groups = age_groups.map{|g|g.upcase}
      @required = ["TREATMENT","OUTPATIENT DIAGNOSIS"]
      @start_date = (start_year + "-" + start_month + "-" + start_day).to_date
      @end_date = (end_year + "-" + end_month + "-" + end_day).to_date
      @diagnosis_name = {}
    else
      @start_date = params[:start_date].to_date
      @end_date = params[:end_date].to_date
    end
    @formated_start_date = @start_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.strftime('%A, %d, %b, %Y')
    observation = session[:observation]
    if observation.blank?
      observation =Observation.find(:all, :include=>{:encounter=>{:type=>{}},  :person=>{}},
        :conditions => ["encounter_type.name IN (?) AND obs.obs_datetime >= TIMESTAMP(?) AND obs.obs_datetime  <= TIMESTAMP(?)",
          ['outpatient diagnosis','treatment'], @start_date.strftime('%Y-%m-%d 00:00:00'),
          @end_date.strftime('%Y-%m-%d 23:59:59')])
      session[:observation] = observation
    end
    records_per_page = CoreService.get_global_property_value('records_per_page') || 20
    unless observation.nil?
      @page = observation.paginate(:page => params[:page], :per_page => records_per_page.to_i)
      @patient_level_data = {}
      @page.each do |obs|
        diagnosis_type = obs.concept.fullname rescue ''
        prescription = obs.encounter.orders.map{|o| o.instructions }.join(" <br />") if obs.encounter.name.upcase=="TREATMENT"
        person =  obs.person
        gender = person.gender
        visit_date = obs.encounter.encounter_datetime.to_date.to_s
        name = person.names.first.given_name + ' ' + person.names.first.family_name rescue nil
        diagnosis_name = obs.answer_concept.fullname rescue ''
        @patient_level_data[visit_date] = {} if @patient_level_data[visit_date].nil?
        @patient_level_data[visit_date][gender] = {} if @patient_level_data[visit_date][gender].nil?
        @patient_level_data[visit_date][gender][person.id] = {} if @patient_level_data[visit_date][gender][person.id].nil?
        @patient_level_data[visit_date][gender][person.id][name] = {} if @patient_level_data[visit_date][gender][person.id][name].nil?
        @patient_level_data[visit_date][gender][person.id][name][person.birthdate] = {"PRIMARY DIAGNOSIS"=> "",
          "SECONDARY DIAGNOSIS"=> "",
          "TREATMENT"=> "" } if @patient_level_data[visit_date][gender][person.id][name][person.birthdate].nil?

        @patient_level_data[visit_date][gender][person.id][name][person.birthdate][diagnosis_type.upcase] = diagnosis_name
        @patient_level_data[visit_date][gender][person.id][name][person.birthdate]["TREATMENT"] = prescription if (obs.encounter.name.upcase=="TREATMENT" && !prescription.blank?)
      end
    end
    render :layout => "report"
  end

  def diagnosis_by_address

    @report_name = params[:report_name]
    @logo = CoreService.get_global_property_value('logo').to_s
    @current_location_name =Location.current_health_center.name
    age_groups = params[:age_groups]
    start_year = params[:start_year]
    start_month = params[:start_month]
    start_day = params[:start_day]
    end_year = params[:end_year]
    end_month = params[:end_month]
    end_day = params[:end_day]
    @age_groups = age_groups.map{|g|g.upcase}
    @required = ["TREATMENT","OUTPATIENT DIAGNOSIS"]
    @start_date = (start_year + "-" + start_month + "-" + start_day).to_date
    @end_date = (end_year + "-" + end_month + "-" + end_day).to_date
    @diagnosis_by_address = {}
    @formated_start_date = @start_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.strftime('%A, %d, %b, %Y')
    concept_ids = ConceptName.find(:all, :conditions => ["name IN (?)",
      ["Additional diagnosis","Diagnosis", "primary diagnosis",
      "secondary diagnosis"]]).map(&:concept_id)
      observation = Observation.find(:all, :include=>{:person=>{}},
                    :conditions => ["obs.obs_datetime >= TIMESTAMP(?)
                    AND obs.obs_datetime  <= TIMESTAMP(?) AND obs.concept_id IN (?)",
                    @start_date.strftime('%Y-%m-%d 00:00:00'), @end_date.strftime('%Y-%m-%d 23:59:59'),
                    concept_ids])

      observation.each do | obs|
        next if obs.answer_concept.nil?
          if (@age_groups.include?("< 6 MONTHS"))
            if (PatientService.age_in_months(obs.person).to_i < 6 )
              diagnosis_name = obs.answer_concept.fullname rescue ''
              @diagnosis_by_address[diagnosis_name] = {} if @diagnosis_by_address[diagnosis_name].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] = 0 if @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] += 1
            end
          end

          if (@age_groups.include?("6 MONTHS TO < 1 YR"))
            if (PatientService.age_in_months(obs.person).to_i >= 6 && PatientService.age(obs.person).to_i < 1)
              diagnosis_name = obs.answer_concept.fullname rescue ''
              @diagnosis_by_address[diagnosis_name] = {} if @diagnosis_by_address[diagnosis_name].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] = 0 if @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] += 1
            end
          end

          if (@age_groups.include?("1 TO < 5"))
            if (PatientService.age(obs.person).to_i >= 1 && PatientService.age(obs.person).to_i < 5)
              diagnosis_name = obs.answer_concept.fullname rescue ''
              @diagnosis_by_address[diagnosis_name] = {} if @diagnosis_by_address[diagnosis_name].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] = 0 if @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] += 1
            end
          end

          if (@age_groups.include?("5 TO 14"))
            if (PatientService.age(obs.person).to_i >= 5 && PatientService.age(obs.person).to_i < 14)
              diagnosis_name = obs.answer_concept.fullname rescue ''
              @diagnosis_by_address[diagnosis_name] = {} if @diagnosis_by_address[diagnosis_name].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] = 0 if @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] += 1
            end
          end

          if (@age_groups.include?("> 14 TO < 20"))
            if (PatientService.age(obs.person).to_i >= 14 && PatientService.age(obs.person).to_i < 20)
              diagnosis_name = obs.answer_concept.fullname rescue ''
              @diagnosis_by_address[diagnosis_name] = {} if @diagnosis_by_address[diagnosis_name].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] = 0 if @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] += 1
            end
          end

          if (@age_groups.include?("20 TO 30"))
            if (PatientService.age(obs.person).to_i >= 20 && PatientService.age(obs.person).to_i < 30)
              diagnosis_name = obs.answer_concept.fullname rescue ''
              @diagnosis_by_address[diagnosis_name] = {} if @diagnosis_by_address[diagnosis_name].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] = 0 if @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] += 1
            end
          end

          if (@age_groups.include?("30 TO < 40"))
            if (PatientService.age(obs.person).to_i >= 30 && PatientService.age(obs.person).to_i < 40)
              diagnosis_name = obs.answer_concept.fullname rescue ''
              @diagnosis_by_address[diagnosis_name] = {} if @diagnosis_by_address[diagnosis_name].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] = 0 if @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] += 1
            end
          end

          if (@age_groups.include?("40 TO < 50"))
            if (PatientService.age(obs.person).to_i >= 40 && PatientService.age(obs.person).to_i < 50)
              diagnosis_name = obs.answer_concept.fullname rescue ''
              @diagnosis_by_address[diagnosis_name] = {} if @diagnosis_by_address[diagnosis_name].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] = 0 if @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district].nil?
              @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] += 1
            end
          end

          if (@age_groups.include?("ALL"))
            diagnosis_name = obs.answer_concept.fullname rescue ''
            @diagnosis_by_address[diagnosis_name] = {} if @diagnosis_by_address[diagnosis_name].nil?
            @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] = 0 if @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district].nil?
            @diagnosis_by_address[diagnosis_name][obs.person.addresses.first.county_district] += 1
          end
      end
    @diagn_address = []
    @diagnosis_by_address.each { |diagn|
      diagnosis = diagn[0]
      address_total = diagn[1]
      address_total.each { |address,total|
        @diagn_address << [diagnosis,address,total]
      }
    }
    render :layout => "report"
  end

  def referals
    @report_name = params[:report_name]
    @logo = CoreService.get_global_property_value('logo').to_s
    session_date = session[:datetime].to_date rescue Date.today
    @current_location_name =Location.current_health_center.name
    start_year = params[:start_year]
    start_month = params[:start_month]
    start_day = params[:start_day]
    end_year = params[:end_year]
    end_month = params[:end_month]
    end_day = params[:end_day]
    @start_date = (start_year + "-" + start_month + "-" + start_day).to_date
    @end_date = (end_year + "-" + end_month + "-" + end_day).to_date
    @referral_locations = Hash.new(0)
    @formated_start_date = @start_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.strftime('%A, %d, %b, %Y')
    @required = ["TREATMENT","OUTPATIENT DIAGNOSIS"]
    report_trasfer_outs_and_refrerrals(@report_name)
    render :layout => "report"
  end

  def referals_graph
    @report_name = params[:report_name]
    @logo = CoreService.get_global_property_value('logo').to_s
    session_date = session[:datetime].to_date rescue Date.today
    @current_location_name =Location.current_health_center.name
    start_year = params[:start_year]
    start_month = params[:start_month]
    start_day = params[:start_day]
    end_year = params[:end_year]
    end_month = params[:end_month]
    end_day = params[:end_day]
    @start_date = (start_year + "-" + start_month + "-" + start_day).to_date
    @end_date = (end_year + "-" + end_month + "-" + end_day).to_date
    @referral_locations = Hash.new(0)
    @formated_start_date = @start_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.strftime('%A, %d, %b, %Y')
    @required = ["TREATMENT","OUTPATIENT DIAGNOSIS"]
    report_trasfer_outs_and_refrerrals(@report_name)
    render :layout => "report"
  end

	def disaggregated_diagnosis

    @report_name = params[:report_name]
    @logo = CoreService.get_global_property_value('logo').to_s
    @current_location_name =Location.current_health_center.name
    start_year = params[:start_year]
    start_month = params[:start_month]
    start_day = params[:start_day]
    end_year = params[:end_year]
    end_month = params[:end_month]
    end_day = params[:end_day]
    @required = ["TREATMENT","OUTPATIENT DIAGNOSIS"]
    @start_date = (start_year + "-" + start_month + "-" + start_day).to_date
    @end_date = (end_year + "-" + end_month + "-" + end_day).to_date
    @disaggregated_diagnosis = {}
    @formated_start_date = @start_date.strftime('%A, %d, %b, %Y')
    @formated_end_date = @end_date.strftime('%A, %d, %b, %Y')
    concept_ids = ConceptName.find(:all, :conditions => ["name IN (?)",["Additional diagnosis",
      "Diagnosis", "primary diagnosis","secondary diagnosis"]]).map(&:concept_id)
           observation =Observation.find(:all,:include=>{:person=>{}},
              :conditions => ["obs.obs_datetime >= TIMESTAMP(?) AND obs.obs_datetime  <= TIMESTAMP(?) AND obs.concept_id IN (?)",
               @start_date.strftime('%Y-%m-%d 00:00:00'), @end_date.strftime('%Y-%m-%d 23:59:59'),
                concept_ids])
              observation.each do | obs|
                      next if obs.answer_concept.blank?
                      previous_date = obs.obs_datetime.strftime('%Y-%m-%d').to_date
                      sex = obs.person.gender
                      age = PatientService.age(obs.person, previous_date)
                      diagnosis_name = obs.answer_concept.fullname rescue ''
                      @disaggregated_diagnosis[diagnosis_name]={"U5" =>{"M"=> 0, "F"=>0},
                        "5-14" =>{"M"=> 0, "F"=>0},
                        ">14" =>{"M"=> 0, "F"=>0},
                        "< 6 MONTHS" =>{"M"=> 0, "F"=>0}
                      }	if @disaggregated_diagnosis[diagnosis_name].nil?

                      if age.to_i < 1
                        age_in_months = PatientService.age_in_months(obs.person, previous_date)
                        if age_in_months.to_i < 6
                          @disaggregated_diagnosis[diagnosis_name]["< 6 MONTHS"][sex]+=1
                        else age_in_months.to_i >= 6 && age.to_i < 5
                          @disaggregated_diagnosis[diagnosis_name]["U5"][sex]+=1
                        end
                      elsif age.to_i >= 1 and age.to_i <= 14
                        @disaggregated_diagnosis[diagnosis_name]["5-14"][sex]+=1
                      else
                        @disaggregated_diagnosis[diagnosis_name][">14"][sex]+=1
                      end

            end
            @diaggregated_paginated = []
            @disaggregated_diagnosis.each { | diag, value |
              @diaggregated_paginated << [diag, value]
            }
		render :layout => 'report'
	end

	def total_registered(person)
    name = PatientService.name(person)
    sex = PatientService.sex(person)
    address = person.addresses.first.city_village
    traditional_authority = person.addresses.first.county_district
    birthdate = person.birthdate
    @total_registered << [name, birthdate, sex,
      person.patient.encounters.find(:first, :order => "encounter_datetime").encounter_datetime.to_date,
      address, traditional_authority]
	end

	def report_trasfer_outs_and_refrerrals(report_name)
    report_encounter_name = "OUTPATIENT RECEPTION"
    obs_concept_name = "Referral clinic if referred"

    if report_name.upcase == "TRANSFER_OUT"
      report_encounter_name = "TRANSFER OUT"
      obs_concept_name = "Transfer to"
    end

    Observation.find(:all, :include=>{:encounter=>{:type=>{}}, :concept=>{:concept_names=>{}}},
      :conditions => ["encounter_type.name = ? AND concept_name.name = ?
											 									AND encounter.encounter_datetime >= TIMESTAMP(?) AND encounter.encounter_datetime  <= TIMESTAMP(?)",
        report_encounter_name, obs_concept_name, @start_date.strftime('%Y-%m-%d 00:00:00'), @end_date.strftime('%Y-%m-%d 23:59:59')]). each do |obs|
      @referral_locations[Location.find(obs.to_s(["short", "order"]).to_s.split(":")[1].to_i).name]+=1
    end
	end

	def age(person, obs)
    patient_age = (obs.obs_datetime.year - person.birthdate.year) + ((obs.obs_datetime.month - person.birthdate.month) + ((obs.obs_datetime.day - person.birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)
    birth_date = person.birthdate
    estimate=person.birthdate_estimated==1
    patient_age += (estimate && birth_date.month == 7 && birth_date.day == 1  &&
        obs.obs_datetime.month < birth_date.month && person.date_created.year == obs.obs_datetime.year) ? 1 : 0
  end

  def age_in_months(person, obs)
    years = (obs.obs_datetime.year - person.birthdate.year)
    months = (obs.obs_datetime.month - person.birthdate.month)
    (years * 12) + months
  end

  def name(person)
    "#{person.names.first.given_name} #{person.names.first.family_name}".titleize rescue nil
  end

	def report_patient(patient_bean, person, start_date, end_date)
    obs = patient_bean
    diagnosis_name = obs.answer_concept.fullname rescue ''

    if @report_name.upcase == "DISAGGREGATED_DIAGNOSIS"
      age = age(person, obs)
      patient_age_in_months = age_in_months(person, obs)
      gender = person.gender
      if !obs.answer_concept.blank?

        @disaggregated_diagnosis[diagnosis_name]={"U5" =>{"M"=> 0, "F"=>0},
          "5-14" =>{"M"=> 0, "F"=>0},
          ">14" =>{"M"=> 0, "F"=>0},
          "< 6 MONTHS" =>{"M"=> 0, "F"=>0}
        }	if @disaggregated_diagnosis[diagnosis_name].nil?

        if patient_age_in_months.to_i < 6
          @disaggregated_diagnosis[diagnosis_name]["< 6 MONTHS"][gender]+=1
        elsif patient_age_in_months.to_i >= 6 && age.to_i < 5
          @disaggregated_diagnosis[diagnosis_name]["U5"][gender]+=1
        elsif age.to_i <= 14
          @disaggregated_diagnosis[diagnosis_name]["5-14"][gender]+=1
        else
          @disaggregated_diagnosis[diagnosis_name][">14"][gender]+=1
        end
      end
    end
    #Diagnosis Report
    if @report_name.upcase == "DIAGNOSIS_REPORT"
      if !obs.answer_concept.blank?
        @diagnosis_report[diagnosis_name]+=1
      end
    end

    #Diagnosis by Traditional Authority Report
    if @report_name.upcase == "DIAGNOSIS_BY_ADDRESS"

      address = person.addresses.first.county_district

      if !obs.answer_concept.blank?
        @diagnosis_by_address[diagnosis_name] = {} if @diagnosis_by_address[diagnosis_name].nil?
        @diagnosis_by_address[diagnosis_name][address] = 0 if @diagnosis_by_address[diagnosis_name][address].nil?
        @diagnosis_by_address[diagnosis_name][address]+=1
      end
    end
=begin
				Patient Level Data
				if @report_name.upcase == "PATIENT_LEVEL_DATA"
						visit_date = encounter.encounter_datetime.to_date.to_s

						next if !((diagnosis_type.upcase == "PRIMARY DIAGNOSIS") ||
									 (diagnosis_type.upcase == "SECONDARY DIAGNOSIS") || (encounter.name.upcase=="TREATMENT"))

						@patient_level_data[visit_date] = {} if @patient_level_data[visit_date].nil?
						@patient_level_data[visit_date][gender] = {} if @patient_level_data[visit_date][gender].nil?
						@patient_level_data[visit_date][gender][person.id] = {} if @patient_level_data[visit_date][gender][person.id].nil?
						@patient_level_data[visit_date][gender][person.id][patient] = {} if @patient_level_data[visit_date][gender][person.id][patient].nil?
						@patient_level_data[visit_date][gender][person.id][patient][person.birthdate] = {"PRIMARY DIAGNOSIS"=> "",
																																																			 "SECONDARY DIAGNOSIS"=> "",
																																																			 "TREATMENT"=> "" } if @patient_level_data[visit_date][gender][person.id][patient.name][person.birthdate].nil?

						@patient_level_data[visit_date][gender][person.id][patient][person.birthdate][diagnosis_type.upcase] = diagnosis_name
						@patient_level_data[visit_date][gender][person.id][patient][person.birthdate]["TREATMENT"] = prescription if (encounter.name.upcase=="TREATMENT" && !prescription.blank?)
				end
=end
    #end

	end
end
