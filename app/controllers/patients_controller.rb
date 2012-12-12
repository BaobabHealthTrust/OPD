class PatientsController < GenericPatientsController

	def tab_social_history
		@alcohol = nil
		@smoke = nil
		@nutrition = nil

		@patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil

		@alcohol = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
			@patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
			ConceptName.find_by_name('Patient currently consumes alcohol').concept_id]).answer_string rescue nil

		@smokes = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
			@patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
			ConceptName.find_by_name('Patient currently smokes').concept_id]).answer_string rescue nil

		@nutrition = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
			@patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
			ConceptName.find_by_name('Nutrition status').concept_id]).answer_string rescue nil

		@civil = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
			@patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
			ConceptName.find_by_name('Civil status').concept_id]).answer_string.titleize rescue nil

		@civil_other = (Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
			  @patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
			  ConceptName.find_by_name('Other Civil Status Comment').concept_id]).answer_string rescue nil) if @civil == "Other"

		@religion = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
			@patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
			ConceptName.find_by_name('Religion').concept_id]).answer_string.titleize rescue nil

		@religion_other = (Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
			  @patient.id, Encounter.find(:all, :conditions => ["patient_id = ? AND encounter_type = ?", 
				  @patient.id, EncounterType.find_by_name("SOCIAL HISTORY").id]).collect{|e| e.encounter_id},
			  ConceptName.find_by_name('Other').concept_id]).answer_string rescue nil) if @religion == "Other"

		render :layout => false
	end
  
	def show
		session[:mastercard_ids] = []
		session_date = session[:datetime].to_date rescue Date.today
		@patient_bean = PatientService.get_patient(@patient.person)
		@encounters = @patient.encounters.find_by_date(session_date)
		@diabetes_number = DiabetesService.diabetes_number(@patient)
		@prescriptions = @patient.orders.unfinished.prescriptions.all
		@programs = @patient.patient_programs.all
		@alerts = alerts(@patient, session_date) rescue nil

		if !session[:location].blank?
			session["category"] = (session[:location] == "Paeds A and E" ? "paeds" : "adults")
		end

		#find the user priviledges
		@super_user = false
		@clinician  = false
		@doctor     = false
		@regstration_clerk  = false

		@category = session["category"] rescue ""


		@user = current_user

		user_roles = UserRole.find(:all,:conditions =>["user_id = ?", current_user.id]).collect{|r|r.role.downcase}
		inherited_roles = RoleRole.find(:all,:conditions => ["child_role IN (?)", user_roles]).collect{|r|r.parent_role.downcase}
		user_roles = user_roles + inherited_roles
		user_roles = user_roles.uniq

		if user_roles.include?("superuser")
			@super_user = true
		end

		if user_roles.include?("clinician")
			@clinician  = true
		end

		if user_roles.include?("doctor")
			@doctor = true
		end

		if user_roles.include?("regstration_clerk")
			@regstration_clerk  = true
		end

		if user_roles.include?("adults")
			@adults  = true
		end

		if user_roles.include?("paediatrics")
			@paediatrics  = true
		end

		if user_roles.include?("hmis lab order")
			@hmis_lab_order  = true
		end

		if user_roles.include?("spine clinician")
			@spine_clinician  = true
		end

		if user_roles.include?("lab")
			@lab  = true
		end

		if ! allowed_hiv_viewer
		@show_hiv_tab = false
		else
		@show_hiv_tab = true
		end

		@restricted = ProgramLocationRestriction.all(:conditions => {:location_id => Location.current_health_center.id })

		@restricted.each do |restriction|
			@encounters = restriction.filter_encounters(@encounters)
			@prescriptions = restriction.filter_orders(@prescriptions)
			@programs = restriction.filter_programs(@programs)
		end

		@date = (session[:datetime].to_date rescue Date.today).strftime("%Y-%m-%d")

		@location = Location.find(session[:location_id]).name rescue ""

		@task = main_next_task(Location.current_location,@patient,session_date)
		@hiv_status = PatientService.patient_hiv_status(@patient)
		@reason_for_art_eligibility = PatientService.reason_for_art_eligibility(@patient)
		@arv_number = PatientService.get_patient_identifier(@patient, 'ARV Number')

		render :template => 'patients/index', :layout => false
	end

	def personal
		@links = []
		patient = Patient.find(params[:id])

		@links << ["Visit Summary (Print)","/patients/dashboard_print_opd_visit/#{patient.id}"]
		@links << ["National ID (Print)","/patients/dashboard_print_national_id/#{patient.id}"]
		@links << ["Demographics (Edit)","/patients/edit_demographics?patient_id=#{patient.id}"]
		@links << ["Patient past visits (View)","/patients/past_visits_summary?patient_id=#{patient.id}"]
		@links << ["Medical History (View)","/patients/past_diagnoses?patient_id=#{patient.id}"]

		if use_filing_number and not PatientService.get_patient_identifier(patient, 'Filing Number').blank?
		  @links << ["Filing Number (Print)","/patients/print_filing_number/#{patient.id}"]
		end 

		if use_filing_number and PatientService.get_patient_identifier(patient, 'Filing Number').blank?
		  @links << ["Filing Number (Create)","/patients/set_filing_number/#{patient.id}"]
		end 

		if use_user_selected_activities
		  @links << ["Change User Activities","/user/activities/#{current_user.id}?patient_id=#{patient.id}"]
		end

		@links << ["Recent Lab Orders Label","/patients/recent_lab_orders?patient_id=#{patient.id}"]

		render :template => 'dashboards/personal_tab', :layout => false
	end
  
	def dashboard_print_opd_visit
		print_and_redirect("/patients/opd_visit_label/?patient_id=#{params[:id]}", "/patients/show/#{params[:id]}")
	end
 
	def opd_visit_label
		session_date = session[:datetime].to_date rescue Date.today
		print_string = opd_patient_visit_label(@patient, session_date) rescue (raise "Unable to find patient (#{params[:patient_id]}) or generate a visit label for that patient")
		send_data(print_string,:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{params[:patient_id]}#{rand(10000)}.lbl", :disposition => "inline")
	end
	
	def mastercard
		@type = params[:type]

		#the parameter are used to re-construct the url when the mastercard is called from a Data cleaning report
		@quarter = params[:quarter]
		@arv_start_number = params[:arv_start_number]
		@arv_end_number = params[:arv_end_number]
		@show_mastercard_counter = false

		if params[:patient_id].blank?

		  @patient_id = session[:mastercard_ids][session[:mastercard_counter]]
		   
		elsif session[:mastercard_ids].length.to_i != 0
		  @patient_id = params[:patient_id]
		else
		  @patient_id = params[:patient_id]
		end

		unless params.include?("source")
		  @source = params[:source] rescue nil
		else
		  @source = nil
		end

		render :layout => false
	end

  def opd_patient_visit_label(patient, date = Date.today)
      label = ZebraPrinter::StandardLabel.new
      label.font_size = 3
      label.font_horizontal_multiplier = 1
      label.font_vertical_multiplier = 1
      label.left_margin = 50
      title_header_font = {:font_reverse => false,:font_size => 4, :font_horizontal_multiplier => 1, :font_vertical_multiplier => 1}
      concepts_font = {:font_reverse => false, :font_size => 3, :font_horizontal_multiplier => 1, :font_vertical_multiplier => 1 }
      title_font_top_bottom = {:font_reverse => false, :font_size => 4, :font_horizontal_multiplier => 1, :font_vertical_multiplier => 1}
      title_font_bottom = {:font_reverse => false, :font_size => 2, :font_horizontal_multiplier => 1, :font_vertical_multiplier => 1}
      units = {"WEIGHT"=>"kg", "HT"=>"cm"}
      encs = patient.encounters.find(:all, :order => 'encounter_datetime ASC', :conditions =>["DATE(encounter_datetime) = ?",date])
      return nil if encs.blank?
      label.draw_multi_text("Visit: #{encs.first.encounter_datetime.strftime("%d/%b/%Y %H:%M")}" +
    " - #{encs.last.encounter_datetime.strftime("%d/%b/%Y %H:%M")}", title_font_top_bottom)
      label.draw_line(20,60,800,2,0)
      outcomes = []
      vitals = []
      notes = []
      check_vitals = encs.map(&:name).include?('VITALS')
      check_notes = encs.map(&:name).include?('NOTES')
      encs.each {|encounter|
          if encounter.name.upcase.include?('TREATMENT')
            encounter_datetime = encounter.encounter_datetime.strftime('%H:%M')
            o = encounter.orders.collect{|order| order.to_s if order.order_type_id == OrderType.find_by_name('Drug Order').order_type_id}.join("\n")
            o = "No prescriptions have been made" if o.blank?
            o = "TREATMENT NOT DONE" if treatment_not_done(encounter.patient, date)
            label.draw_multi_text("Prescriptions at #{encounter_datetime}", title_header_font)
            label.draw_multi_text("#{o}", concepts_font)

          elsif encounter.name.upcase.include?("PROCEDURES DONE")
            procs = ["Procedures - "]
            procs << encounter.observations.collect{|observation| 
              observation.answer_string.squish if !observation.concept.fullname.match(/Workstation location/i)
            }.compact.join("; ")
            label.draw_multi_text("#{procs}", concepts_font)

          elsif encounter.name.upcase.include?('UPDATE HIV STATUS')            
            label.draw_multi_text("#{ 'HIV Status - ' + PatientService.patient_hiv_status(patient).to_s }", :font_reverse => false)

          elsif encounter.name.upcase.include?('DIAGNOSIS')
            encounter_datetime = encounter.encounter_datetime.strftime('%H:%M')
            obs = []
            encounter.observations.each{|observation|
            concept_name = observation.concept.fullname
            next if concept_name.match(/Workstation location/i)
            next if !observation.obs_group_id.blank?

              child_obs = Observation.find(:all, :conditions => ["obs_group_id = ?", observation.obs_id])

              if !child_obs.empty?
                text = observation.answer_string.to_s + " - "
                count = 0
                child_obs.each { | child_observation |
                  text = text + ", " if count > 0
                  text = text + child_observation.answer_string.to_s
                  count = count + 1
                }
                obs << text
              else
                obs << observation.answer_string.to_s
              end
            }
              #"#{observe.answer_string}".squish rescue nil if observe.concept.fullname.upcase.include?('DIAGNOSIS')
            #.compact.join("; ")
            label.draw_multi_text("Diagnoses at #{encounter_datetime}",title_header_font )
            obs.each { | observation |
                label.draw_multi_text("#{observation}", concepts_font)
            }
          elsif encounter.name.upcase.include?('TRANSFER OUT')
            obs = ["Referred to facility - "]
            obs << encounter.observations.collect{|observe|
              Location.find("#{observe.answer_string}".squish).name if observe.concept.fullname.upcase.include?('TRANSFER')}.compact.join("; ")
            obs
            label.draw_multi_text("Transfer Out", :font_reverse => true)
            label.draw_multi_text("#{obs}", concepts_font)
          
          elsif encounter.name.upcase.include?("NOTES")
            encounter_datetime = encounter.encounter_datetime.strftime('%H:%M')
            obs = []
            encounter.observations.each { | observation |

              concept_name = observation.concept.concept_names.last.name
							next if concept_name.match(/Workstation location/i)
              next if concept_name.match(/Life threatening condition/i)
              next if concept_name.match(/Triage category/i)
              next if concept_name.match(/specific presenting complaint/i)
              next if !observation.obs_group_id.blank?

              child_obs = Observation.find(:all, :conditions => ["obs_group_id = ?", observation.obs_id])

              if !child_obs.empty?
                text = observation.answer_string.to_s + " - "
                count = 0
                child_obs.each { | child_observation |
                  text = text + ", " if count > 0
                  text = text + child_observation.answer_string.to_s
                  count = count + 1
                }
                obs << text
              else
                obs << observation.answer_string.to_s
              end
              notes << obs
            }
            notes
            if (check_vitals == false)
              label.draw_multi_text("Notes at #{encounter_datetime}",title_header_font)
              label.draw_multi_text("#{obs.join(',')}",concepts_font)
            end

          elsif encounter.name.upcase.include?("ADMIT PATIENT")
            encounter_datetime = encounter.encounter_datetime.strftime('%H:%M')
            obs = []
            encounter.observations.each do |observation|
              concept_name = observation.concept.concept_names.last.name
              next if concept_name.match(/Workstation location/i)
                obs << observation.answer_string
            end
            label.draw_multi_text("Patient admission at #{encounter_datetime}", title_header_font)
            label.draw_multi_text("#{obs}", concepts_font)
          elsif encounter.name.upcase.include?("PATIENT SENT HOME")
              outcomes << "Sent home"
          elsif encounter.name.upcase.include?("REFERRAL")
            outcomes << "Referred"
            encounter_datetime = encounter.encounter_datetime.strftime('%H:%M')
            obs = []
            encounter.observations.each do |observation|
              concept_name = observation.concept.fullname
              next if concept_name.match(/Workstation location/i)
              obs << observation.answer_string 
            end
            string = []
            string << 'Referred to : ' + obs.first
            string << 'Specialist clinic : ' + obs.last
            label.draw_multi_text("Referral at #{encounter_datetime}", title_header_font)
            string.each { | observation |
               label.draw_multi_text("#{observation}", concepts_font)
            }

					elsif encounter.name.upcase.include?("VITALS")
            vital_signs = ["HT","Weight","Heart rate","Temperature","RR","SAO2"]
            #blood_pressure = ["TA", "Diastolic"]
              #SAO2 for oxygen saturation;
              #TA for Systolic blood pressure
            encounter_datetime = encounter.encounter_datetime.strftime('%H:%M')
						string = []
            obs = []
            complaints = [] #to hold life threatening condition and triage category
                            #so that they should be printed in different lines
            bp = []
            encounter.observations.each { | observation |

             # if (observation.concept_id == 8578)
              concept_name = observation.concept.concept_names.last.name
              #next if concept_name.match(/Detailed presenting complaint/i)
							next if concept_name.match(/Workstation location/i)
              next if !observation.obs_group_id.blank?

              child_obs = Observation.find(:all, :conditions => ["obs_group_id = ?", observation.obs_id])

              if !child_obs.empty?
                text = observation.answer_string.to_s + " : "
                count = 0
                child_obs.each { | child_observation |
                  text = text + ", " if count > 0
                  text = text + child_observation.answer_string.to_s
                  count = count + 1
                }
                obs << text
              else
                string << observation.concept.fullname + ':' + observation.answer_string if vital_signs.include?(concept_name)
                bp << observation.answer_string if concept_name.match(/TA/i)
                bp << observation.answer_string if concept_name.match(/DIASTOLIC/i)
                if !vital_signs.include?(concept_name)
                  if !concept_name.match(/TA/i)
                    if !concept_name.match(/DIASTOLIC/i)
                      if !concept_name.match(/LIFE THREATENING CONDITION/i)
                        if !concept_name.match(/TRIAGE CATEGORY/i)
                          obs << observation.answer_string.to_s 
                        end
                      end
                      complaints << concept_name + ':' + observation.answer_string if concept_name.match(/LIFE THREATENING CONDITION/i)
                      complaints << concept_name + ':' + observation.answer_string if concept_name.match(/TRIAGE CATEGORY/i)
                    end
                  end
                end
              end
              vitals << obs << string
            }

            unless bp.blank?
              sbp = bp[0]
              dbp = bp[1]
              string << ('BP: ' + sbp.to_s.squish + '/' + dbp.to_s.squish )
            end
            
            vitals
            if (check_notes == false)
              label.draw_multi_text("Vitals at #{encounter_datetime}", title_header_font)
              label.draw_multi_text("#{string.join(',')}", concepts_font)
              #label.draw_multi_text("Presenting complaints", title_header_font)
              label.draw_multi_text("Presenting complaints\n #{obs.join(',')}", concepts_font) if !obs.blank?

              unless complaints.blank?
                complaints.each { | complaint |
                  label.draw_multi_text("#{complaint}", concepts_font)
                }
              end
              
            end
        end

      }
      if ((check_notes == true) && (check_vitals == true))
          combined = (vitals + notes).flatten.sort.uniq #Trying to remove the duplicate entries
          label.draw_multi_text("NOTES AND VITALS", title_header_font)
          label.draw_multi_text("#{combined.join(',')}", concepts_font)
          #combined.each { | value |
            #label.draw_multi_text("#{value}", concepts_font)
          #}
      end
			['OPD PROGRAM','IPD PROGRAM'].each do |program_name|		
					program_id = Program.find_by_name(program_name).id
					state = patient.patient_programs.local.select{|p| 
            p.program_id == program_id
          }.last.patient_states.last rescue nil

					next if state.nil?
					
					state_start_date = state.start_date.to_date	
					state_name = state.program_workflow_state.concept.fullname
					
					if ((state_start_date == session[:datetime]) || (state_start_date.to_date == Date.today)) && (state_name.upcase != 'FOLLOWING')
            outcomes << state_name
      		  #label.draw_multi_text("Outcome : #{state_name}", concepts_font)
      		end
          unless outcomes.blank?
            label.draw_multi_text("Outcomes : #{outcomes.uniq.join(',')}", concepts_font)
          end
			end
      initial = current_user.person.names.last.given_name.first + "."
      last_name = current_user.person.names.last.family_name
      label.draw_multi_text("___________________________________________________", concepts_font)
      label.draw_multi_text("Seen by: #{initial + last_name} at " +
        " #{Location.current_location.name}", title_font_bottom)
      
      label.print(1)
  end

  def past_diagnoses
    @patient_ID = params[:patient_id]  #--removedas I am only passing the patient_id  || params[:id] || session[:patient_id]
    @patient = Patient.find(@patient_ID) rescue nil 
    #@remote_visit_diagnoses = @patient.remote_visit_diagnoses rescue nil
    #@remote_visit_treatments = @patient.remote_visit_treatments rescue nil
   # @local_diagnoses = PatientService.visit_diagnoses(@patient.id)
   # @local_treatments = @patient.visit_treatments
	 
	 patient_encounters = @patient.encounters
	
	 if !allowed_hiv_viewer
	   patient_encounters = remove_art_encounters(patient_encounters, 'encounter')
	 end
   
    @past_local_cases = {} 
    patient_encounters.each{|e| 
      @past_local_cases[e.encounter_datetime.strftime("%Y-%m-%d")] = {} if e.encounter_datetime.to_date < (session[:datetime].to_date rescue Date.today.to_date)   
      } 
    
    patient_encounters.each{|e| 
      @past_local_cases[e.encounter_datetime.strftime("%Y-%m-%d")][e.name] = encounter_summary(e)  if e.encounter_datetime.to_date < (session[:datetime].to_date rescue Date.today.to_date)   
      } rescue nil
   
    @patient_bean = PatientService.get_patient(Person.find(@patient_ID)) 
    @past_local_cases = @past_local_cases.sort.reverse!
    render :layout => "menu"
  end
  
	def diagnosis_summary(encounter)
      diagnosis_array = []
      encounter.observations.each{|observation|
        next if observation.obs_group_id != nil || observation.concept.fullname.upcase != 'DIAGNOSIS'
        observation_string =  observation.answer_string
        child_ob = child_observation(observation)
        while child_ob != nil
          observation_string += " #{child_ob.answer_string}"
          child_ob = child_observation(child_ob)
        end
        diagnosis_array << observation_string
        diagnosis_array << " : "
      }
      
      my_hash = []
      encounter.observations.each{|observation|
        my_hash << observation.concept.fullname 
      }
 			#raise my_hash.to_yaml           
      diagnosis_array.compact.to_s.gsub(/ : $/, "")
	end
	
	def encounter_summary(encounter)
		name = encounter.type.name
    if name == 'TREATMENT'
      if !allowed_hiv_viewer
         arv_drugs = []
         concept_set("antiretroviral drugs").each{|concept| arv_drugs << concept.uniq.to_s}
         o = []
         encounter.orders.each{|order|
           if ! arv_drugs.include? Concept.find(order.concept_id).fullname
             o << order.to_s 
           end
         }
         o.join("\n")
      else
         o = encounter.orders.collect{|order| order.to_s}.join("\n")
      end
      
      o = "TREATMENT NOT DONE" if encounter.type.name == 'X'
      o = "No prescriptions have been made" if o.blank?
      o
    elsif name.upcase.include?('DIAGNOSIS')
      diagnosis_array = []
      encounter.observations.each{|observation|
        next if observation.obs_group_id != nil || !observation.concept.fullname.upcase.include?('DIAGNOSIS')
        observation_string =  observation.answer_string
        child_ob = child_observation(observation)
        while child_ob != nil
          observation_string += " #{child_ob.answer_string}"
          child_ob = child_observation(child_ob)
        end
        diagnosis_array << observation_string
        diagnosis_array << " : "
      }
      
         
      diagnosis_array.compact.to_s.gsub(/ : $/, "")

    elsif name == 'LAB ORDERS'

     x = encounter.observations.collect{|observation|
     	 next if observation.concept.fullname.upcase == "WORKSTATION LOCATION"
       lab_obs_lab_results_string(observation).gsub("LAB TEST SERIAL NUMBER: ", "LAB ID: ")
      }.compact.join(",<br /> ")
		end
	end		

  def child_observation(obs)
    Observation.find(:first, :conditions => ["obs_group_id =?", obs.id])
  end
  
  # Added to filter Chronic Conditions and Influenza Data
  def lab_obs_lab_results_string(observation)
    if observation.answer_concept
      if !observation.answer_concept.fullname.include?("NO")
        "#{(observation.concept.fullname == "LAB TEST RESULT" ? "<b>#{observation.answer_concept.fullname rescue nil}</b>" : 
        "#{observation.concept.fullname}: #{observation.answer_concept.fullname rescue nil}#{observation.value_text rescue nil}#{observation.value_numeric rescue nil}") rescue nil}"
      end
    else
      "#{observation.concept.fullname rescue nil}: #{observation.value_text rescue 1 }#{observation.value_numeric rescue 2 }"
    end
  end
  
  def modify_demographics
    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil
    @field = params[:field]
    render :partial => "edit_demographics", :field =>@field, :layout => true and return
  end
  
  def update_demographics
   update_demo_graphics(params)
   redirect_to :action => 'edit_demographics', :patient_id => params['person_id'] and return
  end
  
  def update_demo_graphics(params)
    person = Person.find(params['person_id'])
    
    if params.has_key?('person')
      params = params['person']
    end
    
    address_params = params["addresses"]
    names_params = params["names"]
    patient_params = params["patient"]
    person_attribute_params = params["attributes"]

    params_to_process = params.reject{|key,value| key.match(/addresses|patient|names|attributes/) }
    birthday_params = params_to_process.reject{|key,value| key.match(/gender/) }

    person_params = params_to_process.reject{|key,value| key.match(/birth_|age_estimate/) }
   
    if !birthday_params.empty?
    
      if birthday_params["birth_year"] == "Unknown"
        PatientService.set_birthdate_by_age(person, birthday_params["age_estimate"])
      else
        PatientService.set_birthdate(person, birthday_params["birth_year"], birthday_params["birth_month"], birthday_params["birth_day"])
      end
      
      person.birthdate_estimated = 1 if params["birthdate_estimated"] == 'true'
      person.save
    end
    
    person.update_attributes(person_params) if !person_params.empty?
    person.names.first.update_attributes(names_params) if names_params
    person.addresses.first.update_attributes(address_params) if address_params

    #update or add new person attribute
    person_attribute_params.each{|attribute_type_name, attribute|
        attribute_type = PersonAttributeType.find_by_name(attribute_type_name.humanize.titleize) || PersonAttributeType.find_by_name("Unknown id")
        #find if attribute already exists
        exists_person_attribute = PersonAttribute.find(:first, :conditions => ["person_id = ? AND person_attribute_type_id = ?", person.id, attribute_type.person_attribute_type_id]) rescue nil 
        if exists_person_attribute
          exists_person_attribute.update_attributes({'value' => attribute})
        else
          person.person_attributes.create("value" => attribute, "person_attribute_type_id" => attribute_type.person_attribute_type_id)
        end
      } if person_attribute_params

  end
  
  # Influenza method for accessing the influenza view
  def influenza
    
    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil
    @person = Person.find(@patient.patient_id)
		
		@patient_bean = PatientService.get_patient(@person)
    @gender = @patient_bean.sex
    
    if @patient_bean.age > 15
    	session["category"] = 'adults'
    else
    	session["category"] = 'peads'    
    end
    render :layout => "multi_touch"
    
  end

  def influenza_recruitment

    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil
    @influenza_data = Array.new()
    @influenza_concepts = Array.new()

    excluded_concepts = ["INFLUENZA VACCINE IN THE LAST 1 YEAR",
                         "CURRENTLY (OR IN THE LAST WEEK) TAKING ANTIBIOTICS",
                         "CURRENT SMOKER","WERE YOU A SMOKER 3 MONTHS AGO",
                         "PREGNANT?","RDT OR BLOOD SMEAR POSITIVE FOR MALARIA",
                         "PNEUMOCOCCAL VACCINE","MEASLES VACCINE",
                         "MUAC LESS THAN 11.5 (CM)","WEIGHT",
                         "PATIENT CURRENTLY SMOKES","IS PATIENT PREGNANT?"]
        
    influenza_data = @patient.encounters.current.all(
                                        :conditions => ["encounter.encounter_type = ?",EncounterType.find_by_name('INFLUENZA DATA').encounter_type_id],
                                        :include => [:observations]
                                      ).map{|encounter| encounter.observations.all}.flatten.compact.map{|obs|
                                        @influenza_data.push("#{obs.concept.fullname}: #{obs.answer_string}") if !excluded_concepts.include?(obs.to_s.split(':')[0])
                                      }

    if @influenza_data.length == 0
     redirect_to :action => 'show', :patient_id => @patient.id and return
    end
    render :layout => "multi_touch"
  end
  
  # Influenza method for accessing the influenza view
  def chronic_conditions

    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil
    @person = Person.find(@patient.patient_id)

    @gender = @person.gender

  end

  def treatment_not_done(patient, date)
    self.current_treatment_encounter(patient, date).first.observations.all(
      :conditions => ["obs.concept_id = ?", ConceptName.find_by_name("TREATMENT").concept_id]).last rescue false
  end

  def current_treatment_encounter(patient, date, force = false)
    type = EncounterType.find_by_name('TREATMENT')

    encounter = patient.encounters.find(:all,:conditions =>["encounter_type = ? AND
                                  DATE(encounter_datetime) = ?", type,date])
    return encounter
  end
  
  def influenza_info
    @patient_id = params[:patient_id]  #--removed as I am only passing the patient_id  || params[:id] || session[:patient_id]
    @patient = Patient.find(@patient_id) rescue nil
    @influenza_data = Array.new()
    excluded_concepts = Array.new()
    @opd_influenza_data = Array.new()

    excluded_concepts = ["INFLUENZA VACCINE IN THE LAST 1 YEAR",
                         "CURRENTLY (OR IN THE LAST WEEK) TAKING ANTIBIOTICS",
                         "CURRENT SMOKER","WERE YOU A SMOKER 3 MONTHS AGO",
                         "PREGNANT?","RDT OR BLOOD SMEAR POSITIVE FOR MALARIA",
                         "PNEUMOCOCCAL VACCINE","MEASLES VACCINE",
                         "MUAC LESS THAN 11.5 (CM)","WEIGHT",
                         "PATIENT CURRENTLY SMOKES","IS PATIENT PREGNANT?"]

   @influenza_data = @patient.encounters.all(
                                        :conditions => ["encounter.encounter_type = ?",EncounterType.find_by_name('INFLUENZA DATA').encounter_type_id],
                                        :include => [:observations]
                                      ).map{|encounter| encounter.observations.all}.flatten.compact.map{|obs|
                                        @influenza_data.push("#{obs.concept.fullname.humanize}: #{obs.answer_string} ") if !excluded_concepts.include?(obs.to_s.split(':')[0])
                                      }
    if @influenza_data.length == 0
      @opd_influenza_data << "None"
    else
      @opd_influenza_data = @influenza_data.last
    end
    @ipd_influenza_data = remote_influenza_info(@patient)
    
    render :layout => false
  end
  
  def remote_influenza_info(patient)

		patient_bean = PatientService.get_patient(patient.person)
		
    #this gets the influenza info from IPD
      given_params = {:person => {:patient => { :identifiers => {"National id" => patient_bean.national_id }}}}
      national_id_params = CGI.unescape(given_params.to_param).split('&').map{|elem| elem.split('=')}
      mechanize_browser = Mechanize.new
      demographic_servers = JSON.parse(GlobalProperty.find_by_property("demographic_server_ips_and_local_port").property_value)   rescue []

      result = demographic_servers.map{|demographic_server, local_port|
       begin
             
          output = mechanize_browser.post("http://localhost:local_port/patients/retrieve_	", national_id_params).body

        rescue Timeout::Error
         return []
         rescue
         return []
       end
       output if output and output.match(/person/)
       }.sort{|a,b|b.length <=> a.length}.first

     # result ? JSON.parse(result) : nil
     
     result = JSON.parse(output) rescue nil

  end
  
  def chronic_conditions_info
    @patient_id = params[:patient_id]
    @patient = Patient.find(@patient_id) rescue nil
    @ipd_chronic_conditions = Array.new()

    @ipd_chronic_conditions = get_remote_chronic_conditions(@patient)
    #Add None element if no conditions are returned from remote

    if @ipd_chronic_conditions.length == 0
      @ipd_chronic_conditions << "None"
    end
   # raise @ipd_chronic_conditions.to_yaml
    @opd_chronic_conditions = local_chronic_conditions(@patient_id)
    if @opd_chronic_conditions.length == 0
      @opd_chronic_conditions << "None"
    end
    render :layout => false
  end
  
  def get_remote_chronic_conditions(patient)
  
		patient_bean = PatientService.get_patient(patient.person)
  
    #this gets the influenza info from IPD
      given_params = {:person => {:patient => { :identifiers => {"National id" => patient_bean.national_id }}}}
      national_id_params = CGI.unescape(given_params.to_param).split('&').map{|elem| elem.split('=')}
      mechanize_browser = Mechanize.new
      demographic_servers = JSON.parse(GlobalProperty.find_by_property("demographic_server_ips_and_local_port").property_value)   rescue []

      result = demographic_servers.map{|demographic_server, local_port|
      begin
          output = mechanize_browser.post("http://localhost:local_port/patients/remote_chronic_conditions", national_id_params).body

      rescue Timeout::Error
         return []
         rescue
         return []
      end
       output if output and output.match(/person/)
      }.sort{|a,b|b.length <=> a.length}.first

     #result ? JSON.parse(result) : nil

     result = JSON.parse(output) rescue []

  end
  
  def local_chronic_conditions(patient_id)

    @patient = Patient.find(patient_id) rescue nil
    @chronic_conditions = @patient.encounters.all(
                                        :conditions => ["encounter.encounter_type = ?",EncounterType.find_by_name('CHRONIC CONDITIONS').encounter_type_id],
                                        :include => [:observations]
                                      ) rescue []
   
    chronic_conditions_array = Array.new
    
    if @chronic_conditions.length == 0
      chronic_conditions_array << "None"
    else
      @chronic_conditions.each do |encounter|
          chronic_conditions_array << encounter.to_s
      end
    end
    return chronic_conditions_array
    
  end
  
  def print_opd_visit_summary
     print_and_redirect("/patients/dashboard_print_opd_visit/#{params[:id]}","/patients/show/#{params[:id]}") and return
 	end

  def social_history
    @alcohol = nil
    @smoke = nil
    @nutrition = nil
    
    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil
    
    @alcohol = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('Patient currently consumes alcohol').concept_id]).answer_string rescue nil

    @smokes = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('Patient currently smokes').concept_id]).answer_string rescue nil

    @nutrition = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('Nutrition status').concept_id]).answer_string rescue nil
  
    @civil = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('Civil status').concept_id]).answer_string.titleize rescue nil
  
    @civil_other = (Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
          @patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
          ConceptName.find_by_name('Other Civil Status Comment').concept_id]).answer_string rescue nil) if @civil == "Other"
  
    @religion = Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
        @patient.id, Encounter.find(:all, :conditions => ["patient_id = ?", @patient.id]).collect{|e| e.encounter_id},
        ConceptName.find_by_name('Religion').concept_id]).answer_string.titleize rescue nil
  
    @religion_other = (Observation.find(:last, :conditions => ["person_id = ? AND encounter_id IN (?) AND concept_id = ?",
          @patient.id, Encounter.find(:all, :conditions => ["patient_id = ? AND encounter_type = ?", 
              @patient.id, EncounterType.find_by_name("SOCIAL HISTORY").id]).collect{|e| e.encounter_id},
          ConceptName.find_by_name('Other').concept_id]).answer_string rescue nil) if @religion == "Other"
  
    render :layout => false
  end
end
