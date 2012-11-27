class EncountersController < GenericEncountersController

	def new
		@patient = Patient.find(params[:patient_id] || session[:patient_id])
		@patient_bean = PatientService.get_patient(@patient.person)
		session_date = session[:datetime].to_date rescue Date.today
		@session_date = session[:datetime].to_date rescue Date.today

		if session[:datetime]
			@retrospective = true 
		else
			@retrospective = false
		end
		
		@procedures = []
		@proc =  GlobalProperty.find_by_property("facility.procedures").property_value.split(",") rescue []

		@proc.each{|proc|
		  proc_concept = ConceptName.find_by_name(proc, :conditions => ["voided = 0"]).concept_id rescue nil
		  @procedures << [proc, proc_concept] if !proc_concept.nil?
		}

		@diagnosis_type = params[:diagnosis_type]

		@current_height = PatientService.get_patient_attribute_value(@patient, "current_height")
		@min_weight = PatientService.get_patient_attribute_value(@patient, "min_weight")
		@max_weight = PatientService.get_patient_attribute_value(@patient, "max_weight")
		@min_height = PatientService.get_patient_attribute_value(@patient, "min_height")
		@max_height = PatientService.get_patient_attribute_value(@patient, "max_height")
		@select_options = select_options

		@select_options = select_options

    if  ['INPATIENT_DIAGNOSIS', 'OUTPATIENT_DIAGNOSIS', 'ADMISSION_DIAGNOSIS', 'DISCHARGE_DIAGNOSIS'].include?((params[:encounter_type].upcase rescue ''))
			diagnosis_concept_set_id = ConceptName.find_by_name("Diagnoses requiring specification").concept.id
			diagnosis_concepts = Concept.find(:all, :joins => :concept_sets, :conditions => ['concept_set = ?', diagnosis_concept_set_id])	
			@diagnoses_requiring_specification = diagnosis_concepts.map{|concept| concept.fullname.upcase}.join(';')

			diagnosis_concept_set_id = ConceptName.find_by_name("Diagnoses requiring details").concept.id
			diagnosis_concepts = Concept.find(:all, :joins => :concept_sets, :conditions => ['concept_set = ?', diagnosis_concept_set_id])	
			@diagnoses_requiring_details = diagnosis_concepts.map{|concept| concept.fullname.upcase}.join(';')
    end
        
    if (params[:encounter_type].upcase rescue '') == 'PRESENTING_COMPLAINTS'
			complaint_concept_set_id = ConceptName.find_by_name("Presenting complaints requiring specification").concept.id
			complaint_concepts = Concept.find(:all, :joins => :concept_sets, :conditions => ['concept_set = ?', complaint_concept_set_id])
			@complaints_requiring_specification = complaint_concepts.map{|concept| concept.fullname.upcase}.join(';')

			complaint_concept_set_id = ConceptName.find_by_name("Presenting complaints requiring details").concept.id
			complaint_concepts = Concept.find(:all, :joins => :concept_sets, :conditions => ['concept_set = ?', complaint_concept_set_id])	
			@complaints_requiring_details = complaint_concepts.map{|concept| concept.fullname.upcase}.join(';')
    end

    if (params[:encounter_type].upcase rescue '') == 'SOCIAL_HISTORY'
			religions = ["Jehovahs Witness",  
			  "Roman Catholic", 
			  "Presbyterian (C.C.A.P.)",
			  "Seventh Day Adventist", 
			  "Baptist", 
			  "Moslem"]

			@religions = Observation.find(:all, :joins => [:concept, :encounter], 
			  :conditions => ["obs.concept_id = ? AND NOT value_text IN (?) AND " + 
            "encounter_type = ?",
          ConceptName.find_by_name("Other").concept_id, religions,
          EncounterType.find_by_name("SOCIAL HISTORY").id]).collect{|o| o.value_text}

			@religions = religions + @religions

			@religions = @religions.sort

			@religions << "Other"
    end

    if (params[:encounter_type].upcase rescue '') == 'DISCHARGE_PATIENT'
			@discharge_outcomes = [
        ['',''],
        ['Alive (Discharged home)', 'Alive'],
        ['Dead', 'Dead'],
        ['Referred (Within facility)', 'Referred'],
        ['Transferred (Another health facility)', 'Transferred'],
        ['Absconded', 'Absconded'],
        ['Discharged (Home based care)', 'Home based care']]
    end


		if (params[:encounter_type].upcase rescue '') == "ADMIT_PATIENT"
			ipd_wards_tag = CoreService.get_global_property_value('ipd.wards.tag')
			@ipd_wards = []
			@ipd_wards = LocationTagMap.all.collect { | ltm |
				[ltm.location.name] if ltm.location_tag.name == ipd_wards_tag
			}
			@ipd_wards = @ipd_wards.compact.sort		  
		end
		
		redirect_to "/" and return unless @patient

		redirect_to next_task(@patient) and return unless params[:encounter_type]


		if params[:encounter_type].upcase == 'ADMISSION DIAGNOSIS' || params[:encounter_type].upcase == 'DISCHARGE DIAGNOSIS' || params[:encounter_type].upcase == 'OUTPATIENT_DIAGNOSIS'
			if !is_encounter_available(@patient, 'VITALS', session_date) && @patient_bean.age <= 14
				session[:original_encounter] = params[:encounter_type]
				params[:encounter_type] = 'vitals'					
			else
				#if !is_encounter_available(@patient, 'PRESENTING COMPLAINTS', session_date)
				#	session[:original_encounter] = params[:encounter_type]
				#	params[:encounter_type] = 'presenting_complaints'					
				#end
			end
		end
		
		if (params[:encounter_type].upcase rescue '') == 'HIV_STAGING' and  (CoreService.get_global_property_value('use.extended.staging.questions').to_s == "true" rescue false)
			render :template => 'encounters/extended_hiv_staging'
		else
      if params[:encounter_type].upcase == "INFLUENZA"
        render :layout => "multi_touch", :action => params[:encounter_type]
      else
        render :action => params[:encounter_type] if params[:encounter_type]
      end
			 	
		end

	end

	def select_options
		select_options = {
      'reason_for_tb_clinic_visit' => [
        ['',''],
        ['Clinical review (Children, Smear-, HIV+)','CLINICAL REVIEW'],
        ['Smear Positive (HIV-)','SMEAR POSITIVE'],
        ['X-ray result interpretation','X-RAY RESULT INTERPRETATION']
		  ],
      'tb_clinic_visit_type' => [
        ['',''],
        ['Lab analysis','Lab follow-up'],
        ['Follow-up','Follow-up'],
        ['Clinical review (Clinician visit)','Clinical review']
		  ],
      'family_planning_methods' => [
        ['',''],
        ['Oral contraceptive pills', 'ORAL CONTRACEPTIVE PILLS'],
        ['Depo-Provera', 'DEPO-PROVERA'],
        ['IUD-Intrauterine device/loop', 'INTRAUTERINE CONTRACEPTION'],
        ['Contraceptive implant', 'CONTRACEPTIVE IMPLANT'],
        ['Male condoms', 'MALE CONDOMS'],
        ['Female condoms', 'FEMALE CONDOMS'],
        ['Rhythm method', 'RYTHM METHOD'],
        ['Withdrawal', 'WITHDRAWAL'],
        ['Abstinence', 'ABSTINENCE'],
        ['Tubal ligation', 'TUBAL LIGATION'],
        ['Vasectomy', 'VASECTOMY']
		  ],
      'male_family_planning_methods' => [
        ['',''],
        ['Male condoms', 'MALE CONDOMS'],
        ['Withdrawal', 'WITHDRAWAL'],
        ['Rhythm method', 'RYTHM METHOD'],
        ['Abstinence', 'ABSTINENCE'],
        ['Vasectomy', 'VASECTOMY'],
        ['Other','OTHER']
		  ],
      'female_family_planning_methods' => [
        ['',''],
        ['Oral contraceptive pills', 'ORAL CONTRACEPTIVE PILLS'],
        ['Depo-Provera', 'DEPO-PROVERA'],
        ['IUD-Intrauterine device/loop', 'INTRAUTERINE CONTRACEPTION'],
        ['Contraceptive implant', 'CONTRACEPTIVE IMPLANT'],
        ['Female condoms', 'FEMALE CONDOMS'],
        ['Withdrawal', 'WITHDRAWAL'],
        ['Rhythm method', 'RYTHM METHOD'],
        ['Abstinence', 'ABSTINENCE'],
        ['Tubal ligation', 'TUBAL LIGATION'],
        ['Emergency contraception', 'EMERGENCY CONTRACEPTION'],
        ['Other','OTHER']
		  ],
      'drug_list' => [
			  ['',''],
			  ["Rifampicin Isoniazid Pyrazinamide and Ethambutol", "RHEZ (RIF, INH, Ethambutol and Pyrazinamide tab)"],
			  ["Rifampicin Isoniazid and Ethambutol", "RHE (Rifampicin Isoniazid and Ethambutol -1-1-mg t"],
			  ["Rifampicin and Isoniazid", "RH (Rifampin and Isoniazid tablet)"],
			  ["Stavudine Lamivudine and Nevirapine", "D4T+3TC+NVP"],
			  ["Stavudine Lamivudine + Stavudine Lamivudine and Nevirapine", "D4T+3TC/D4T+3TC+NVP"],
			  ["Zidovudine Lamivudine and Nevirapine", "AZT+3TC+NVP"]
		  ],
			'presc_time_period' => [
			  ["",""],
			  ["1 month", "30"],
			  ["2 months", "60"],
			  ["3 months", "90"],
			  ["4 months", "120"],
			  ["5 months", "150"],
			  ["6 months", "180"],
			  ["7 months", "210"],
			  ["8 months", "240"]
		  ],
			'continue_treatment' => [
			  ["",""],
			  ["Yes", "YES"],
			  ["DHO DOT site","DHO DOT SITE"],
			  ["Transfer Out", "TRANSFER OUT"]
		  ],
			'hiv_status' => [
			  ['',''],
			  ['Negative','NEGATIVE'],
			  ['Positive','POSITIVE'],
			  ['Unknown','UNKNOWN']
		  ],
		  'who_stage1' => [
        ['',''],
        ['Asymptomatic','ASYMPTOMATIC'],
        ['Persistent generalised lymphadenopathy','PERSISTENT GENERALISED LYMPHADENOPATHY'],
        ['Unspecified stage 1 condition','UNSPECIFIED STAGE 1 CONDITION']
		  ],
		  'who_stage2' => [
        ['',''],
        ['Unspecified stage 2 condition','UNSPECIFIED STAGE 2 CONDITION'],
        ['Angular cheilitis','ANGULAR CHEILITIS'],
        ['Popular pruritic eruptions / Fungal nail infections','POPULAR PRURITIC ERUPTIONS / FUNGAL NAIL INFECTIONS']
		  ],
		  'who_stage3' => [
        ['',''],
        ['Oral candidiasis','ORAL CANDIDIASIS'],
        ['Oral hairly leukoplakia','ORAL HAIRLY LEUKOPLAKIA'],
        ['Pulmonary tuberculosis','PULMONARY TUBERCULOSIS'],
        ['Unspecified stage 3 condition','UNSPECIFIED STAGE 3 CONDITION']
		  ],
		  'who_stage4' => [
        ['',''],
        ['Toxaplasmosis of the brain','TOXAPLASMOSIS OF THE BRAIN'],
        ["Kaposi's Sarcoma","KAPOSI'S SARCOMA"],
        ['Unspecified stage 4 condition','UNSPECIFIED STAGE 4 CONDITION'],
        ['HIV encephalopathy','HIV ENCEPHALOPATHY']
		  ],
		  'tb_xray_interpretation' => [
        ['',''],
        ['Consistent of TB','Consistent of TB'],
        ['Not Consistent of TB','Not Consistent of TB']
		  ],
		  'lab_orders' =>{
        "Blood" => ["Full blood count", "Malaria parasite", "Group & cross match", "Urea & Electrolytes", "CD4 count", "Resistance",
          "Viral Load", "Cryptococcal Antigen", "Lactate", "Fasting blood sugar", "Random blood sugar", "Sugar profile",
          "Liver function test", "Hepatitis test", "Sickling test", "ESR", "Culture & sensitivity", "Widal test", "ELISA",
          "ASO titre", "Rheumatoid factor", "Cholesterol", "Triglycerides", "Calcium", "Creatinine", "VDRL", "Direct Coombs",
          "Indirect Coombs", "Blood Test NOS"],
        "CSF" => ["Full CSF analysis", "Indian ink", "Protein & sugar", "White cell count", "Culture & sensitivity"],
        "Urine" => ["Urine microscopy", "Urinanalysis", "Culture & sensitivity"],
        "Aspirate" => ["Full aspirate analysis"],
        "Stool" => ["Full stool analysis", "Culture & sensitivity"],
        "Sputum-AAFB" => ["AAFB(1st)", "AAFB(2nd)", "AAFB(3rd)"],
        "Sputum-Culture" => ["Culture(1st)", "Culture(2nd)"],
        "Swab" => ["Microscopy", "Culture & sensitivity"]
		  },
		  'tb_symptoms_short' => [
        ['',''],
        ["Bloody cough", "Hemoptysis"],
        ["Chest pain", "Chest pain"],
        ["Cough", "Cough lasting more than three weeks"],
        ["Fatigue", "Fatigue"],
        ["Fever", "Relapsing fever"],
        ["Loss of appetite", "Loss of appetite"],
        ["Night sweats","Night sweats"],
        ["Shortness of breath", "Shortness of breath"],
        ["Weight loss", "Weight loss"],
        ["Other", "Other"]
		  ],
		  'tb_symptoms_all' => [
        ['',''],
        ["Bloody cough", "Hemoptysis"],
        ["Bronchial breathing", "Bronchial breathing"],
        ["Crackles", "Crackles"],
        ["Cough", "Cough lasting more than three weeks"],
        ["Failure to thrive", "Failure to thrive"],
        ["Fatigue", "Fatigue"],
        ["Fever", "Relapsing fever"],
        ["Loss of appetite", "Loss of appetite"],
        ["Meningitis", "Meningitis"],
        ["Night sweats","Night sweats"],
        ["Peripheral neuropathy", "Peripheral neuropathy"],
        ["Shortness of breath", "Shortness of breath"],
        ["Weight loss", "Weight loss"],
        ["Other", "Other"]
		  ],
		  'drug_related_side_effects' => [
        ['',''],
        ["Confusion", "Confusion"],
        ["Deafness", "Deafness"],
        ["Dizziness", "Dizziness"],
        ["Peripheral neuropathy","Peripheral neuropathy"],
        ["Skin itching/purpura", "Skin itching"],
        ["Visual impairment", "Visual impairment"],
        ["Vomiting", "Vomiting"],
        ["Yellow eyes", "Jaundice"],
        ["Other", "Other"]
		  ],
		  'tb_patient_categories' => [
        ['',''],
        ["New", "New patient"],
        ["Failure", "Failed - TB"],
        ["Relapse", "Relapse MDR-TB patient"],
        ["Treatment after default", "Treatment after default MDR-TB patient"],
        ["Other", "Other"]
		  ],
		  'duration_of_current_cough' => [
        ['',''],
        ["Less than 1 week", "Less than one week"],
        ["1 Week", "1 week"],
        ["2 Weeks", "2 weeks"],
        ["3 Weeks", "3 weeks"],
        ["4 Weeks", "4 weeks"],
        ["More than 4 Weeks", "More than 4 weeks"],
        ["Unknown", "Unknown"]
		  ],
		  'eptb_classification'=> [
        ['',''],
        ['Pulmonary effusion', 'Pulmonary effusion'],
        ['Lymphadenopathy', 'Lymphadenopathy'],
        ['Pericardial effusion', 'Pericardial effusion'],
        ['Ascites', 'Ascites'],
        ['Spinal disease', 'Spinal disease'],
        ['Meningitis','Meningitis'],
        ['Other', 'Other']
		  ],
		  'tb_types' => [
        ['',''],
        ['Susceptible', 'Susceptible to tuberculosis drug'],
        ['Multi-drug resistant (MDR)', 'Multi-drug resistant tuberculosis'],
        ['Extreme drug resistant (XDR)', 'Extreme drug resistant tuberculosis']
		  ],
		  'tb_classification' => [
        ['',''],
        ['Pulmonary tuberculosis (PTB)', 'Pulmonary tuberculosis'],
        ['Extrapulmonary tuberculosis (EPTB)', 'Extrapulmonary tuberculosis (EPTB)']
		  ],
		  'source_of_referral' => [
        ['',''],
        ['Walk in', 'Walk in'],
        ['Healthy Facility', 'Healthy Facility'],
        ['Index Patient', 'Index Patient'],
        ['HTC', 'HTC clinic'],
        ['ART', 'ART'],
        ['PMTCT', 'PMTCT'],
        ['Private practitioner', 'Private practitioner'],
        ['Sputum collection point', 'Sputum collection point'],
        ['Other','Other']
		  ]
		}
	end

	def create_adult_influenza_entry
		create_influenza_data
	end
  
	def create_influenza_data
		# raise params.to_yaml

		encounter = Encounter.new(params[:encounter])
		encounter.encounter_datetime = session[:datetime] unless session[:datetime].blank? or encounter.name == 'DIABETES TEST'
		encounter.save

		(params[:observations] || []).each { | observation |
			# Check to see if any values are part of this observation
			# This keeps us from saving empty observations
			values = "coded_or_text group_id boolean coded drug datetime numeric modifier text".split(" ").map { | value_name |
				observation["value_#{value_name}"] unless observation["value_#{value_name}"].blank? rescue nil
			}.compact

			next if values.length == 0
			observation.delete(:value_text) unless observation[:value_coded_or_text].blank?
			observation[:encounter_id] = encounter.id
			observation[:obs_datetime] = encounter.encounter_datetime ||= (session[:datetime] ||= Time.now())
			observation[:person_id] ||= encounter.patient_id
			observation[:concept_name] ||= "OUTPATIENT DIAGNOSIS" if encounter.type.name == "OUTPATIENT DIAGNOSIS"

			if(observation[:measurement_unit])
				observation[:value_numeric] = observation[:value_numeric].to_f * 18 if ( observation[:measurement_unit] == "mmol/l")
				observation.delete(:measurement_unit)
			end

			if(observation[:parent_concept_name])
				concept_id = Concept.find_by_name(observation[:parent_concept_name]).id rescue nil
				observation[:obs_group_id] = Observation.find(:first, :conditions=> ['concept_id = ? AND encounter_id = ?',concept_id, encounter.id]).id rescue ""
				observation.delete(:parent_concept_name)
			end

			extracted_value_numerics = observation[:value_numeric]
			if (extracted_value_numerics.class == Array)
				extracted_value_numerics.each do |value_numeric|
					observation[:value_numeric] = value_numeric
					Observation.create(observation)
				end
			else
				Observation.create(observation)
			end
		}
		@patient = Patient.find(params[:encounter][:patient_id])

		# redirect to a custom destination page 'next_url'
		if(params[:next_url])
			redirect_to params[:next_url] and return
		else
			redirect_to next_task(@patient)
		end
	end

	def create_influenza_recruitment
		create_influenza_data
	end
  
	# create_chronics is a method to save the results of an influenza
	# Chronic Conditions question set
	def create_chronics
		create_influenza_data
	end

	def presenting_complaints
		search_string = (params[:search_string] || '').upcase
		filter_list = params[:filter_list].split(/, */) rescue []
		
		presenting_complaint = ConceptName.find_by_name("PRESENTING COMPLAINT").concept
		

		complaint_set = CoreService.get_global_property_value("application_presenting_complaint")
		complaint_set = "PRESENTING COMPLAINT" if complaint_set.blank?
		complaint_concept_set = ConceptName.find_by_name(complaint_set).concept
		complaint_concepts = Concept.find(:all, :joins => :concept_sets, :conditions => ['concept_set = ?', complaint_concept_set.id])

		valid_answers = complaint_concepts.map{|concept| 
			name = concept.fullname rescue nil
			name.upcase.include?(search_string) ? name : nil rescue nil
		}.compact

		previous_answers = []

		# TODO Need to check global property to find out if we want previous answers or not (right now we)
		previous_answers = Observation.find_most_common(presenting_complaint, search_string)

		@suggested_answers = (previous_answers + valid_answers.sort!).reject{|answer| filter_list.include?(answer) }.uniq[0..10] 
		@suggested_answers = @suggested_answers - params[:search_filter].split(',') rescue @suggested_answers
		render :text => "<li></li>" + "<li>" + @suggested_answers.join("</li><li>") + "</li>"
	end

	#added this to ensure that we are able to get the detailed diagnosis set
	def diagnosis_details
		concept_name = params[:diagnosis_string]
		options = concept_set(concept_name).flatten.uniq
		render :text => "<li></li><li>" + options.join("</li><li>") + "</li>"
	end

	#added this to ensure that we are able to get the detailed concept set
	def concept_options
		concept_name = params[:search_string]
		options = concept_set(concept_name).flatten.uniq

		render :text => "<li></li><li>" + options.join("</li><li>") + "</li>"
	end

=begin
	def is_first_art_visit(patient_id)
		     session_date = session[:datetime].to_date rescue Date.today
		     art_encounter = Encounter.find(:first,:conditions =>["voided = 0 AND patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) < ?",
		                     patient_id, EncounterType.find_by_name('ART_INITIAL').id, session_date ]) rescue nil
		    return true if art_encounter.nil?
		     return false
	end
=end


  def life_threatening_condition  
    search_string = (params[:search_string] || '').upcase
    
    aconcept_set = []
        
    common_answers = Observation.find_most_common(ConceptName.find_by_name("Life threatening condition").concept, search_string)
    concept_set("Life threatening condition").each{|concept| aconcept_set << concept.uniq.to_s rescue "test"}  
    set = (common_answers + aconcept_set.sort).uniq             
    set.map!{|cc| cc.upcase.include?(search_string)? cc : nil}        
    
    set = set.sort rescue []
           
    render :text => "<li></li>" + "<li>" + set.join("</li><li>") + "</li>"

  end

  def triage_category

    search_string = (params[:search_string] || '').upcase   
    aconcept_set = []        

    common_answers = Observation.find_most_common(ConceptName.find_by_name("Triage category").concept, search_string)
    concept_set("Triage category").each{|concept| aconcept_set << concept.uniq.to_s rescue "test"}  
    set = (common_answers + aconcept_set.sort).uniq
    set.map!{|cc| cc.upcase.include?(search_string)? cc : nil}
             
    set = set.sort rescue []
           
    render :text => "<li></li>" + "<li>" + set.join("</li><li>") + "</li>"
  end


  def create_complaints
      encounter = Encounter.new()
      encounter.encounter_type = EncounterType.find_by_name("VITALS").id
      encounter.patient_id = params['encounter']['patient_id']
      encounter.encounter_datetime = session[:datetime]
      if params[:filter] and !params[:filter][:provider].blank?
        user_person_id = User.find_by_username(params[:filter][:provider]).person_id
      else
        user_person_id = User.find_by_user_id(params['encounter']['provider_id']).person_id
      end
      encounter.provider_id = user_person_id
      encounter.save

      params[:complaints].each do |complaint|
      encounter_id = Encounter.find(:last, :order => 'encounter_id ASC').id
		  if !complaint.blank?
        multiple = complaint.match(/[:]/)
        unless multiple.nil?
          multiple_array = complaint.split(":")
          concept_name = ConceptName.find_by_name(multiple_array[0]).name
          parent_obs = {
            "encounter_id" => "#{encounter_id}",
            "patient_id" => params['encounter']['patient_id'],
            "concept_name" => "#{concept_name}".upcase,
            "value_text" => "#{multiple_array[0]}",
            "obs_datetime" => params['encounter']['encounter_datetime']
          }

          b = Observation.create(parent_obs)
          encounter_id = b.encounter_id
          parent_concept_id = b.concept_id
          obs_group = Observation.find(:first, :order => "obs_id DESC", :conditions => ["encounter_id =? AND concept_id =?", \
                    encounter_id, parent_concept_id])
          obs_group_id = obs_group.id if obs_group
          child_obs = {
            "encounter_id" => "#{encounter_id}",
            "patient_id" => params['encounter']['patient_id'],
            "concept_name" => "#{multiple_array[0]}",
            "value_text" => "#{multiple_array[1]}",
            "obs_group_id" => "#{obs_group_id}",
            "obs_datetime" => params['encounter']['encounter_datetime']
          }
         Observation.create(child_obs)
        else
          obs = {
            "encounter_id" => "#{encounter.id}",
            "patient_id" => params['encounter']['patient_id'],
						"concept_name" => "#{complaint}".upcase,
						"value_text" => complaint,
						"obs_datetime" => params['encounter']['encounter_datetime']
          }
          Observation.create(obs)
        end
		  end
    end
   create_obs(encounter, params)
   @patient_id = params[:encounter][:patient_id]
   redirect_to("/patients/show/#{@patient_id}")
  end


end
