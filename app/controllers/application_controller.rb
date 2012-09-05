class ApplicationController < GenericApplicationController

  def next_task(patient)
    session_date = session[:datetime].to_date rescue Date.today
    task = main_next_task(Location.current_location, patient,session_date)
    begin
      return task.url if task.present? && task.url.present?
      return "/patients/show/#{patient.id}" 
    rescue
      return "/patients/show/#{patient.id}" 
    end
  end

  # Try to find the next task for the patient at the given location
	def main_next_task(location, patient, session_date = Date.today)
		encounter_available = nil
		task = Task.first rescue Task.new()
		
		task.encounter_type = 'NONE'
		task.url = "/patients/show/#{patient.id}"

		if is_encounter_available(patient, 'DISCHARGE PATIENT', session_date)
			if !is_encounter_available(patient, 'DISCHARGE DIAGNOSIS', session_date)
				task.encounter_type = 'DISCHARGE DIAGNOSIS'
				task.url = "/encounters/new/discharge_diagnosis?patient_id=#{patient.id}"
			end
		end

		if is_encounter_available(patient, 'ADMIT PATIENT', session_date)
			if !is_encounter_available(patient, 'ADMISSION DIAGNOSIS', session_date)
				task.encounter_type = 'ADMISSION DIAGNOSIS'
				task.url = "/encounters/new/admission_diagnosis?patient_id=#{patient.id}"
			end
		end

		if !session[:original_encounter].blank?
			task.encounter_type = session[:original_encounter]
			task.url = "/encounters/new/#{task.encounter_type}?patient_id=#{patient.id}"
			session[:original_encounter] = nil
		end

		if !is_encounter_available(patient, 'OUTPATIENT RECEPTION', session_date) && (CoreService.get_global_property_value("is_referral_centre").to_s == 'true' rescue false) 
			task.encounter_type = 'OUTPATIENT RECEPTION'
			task.url = "/encounters/new/outpatient_reception?patient_id=#{patient.id}"
		end

		return task
	end
  
	def is_encounter_available(patient, encounter_type, session_date)
		is_vailable = false

		encounter_available = Encounter.find(:first,:conditions =>["patient_id = ? AND encounter_type = ? AND DATE(encounter_datetime) = ?",
						                           patient.id,EncounterType.find_by_name(encounter_type).id, session_date],
						                           :order =>'encounter_datetime DESC',:limit => 1)
		if encounter_available.blank?
			is_available = false
		else
			is_available = true
		end

		return is_available	
	end
	def allowed_hiv_viewer
	 allowed = current_user_roles.include?("Doctor" || "Nurse" || "Superuser") rescue nil 
	 return allowed
  end 	
  
  def hiv_program
  	program = PatientProgram.first(:conditions => {:patient_id => @patient.id})
  	if program.program.name == "HIV PROGRAM"
  	return program.program_id
  	else
  	return false
  	end
  end
  
  def remove_art_encounters(all_encounters, type)
    non_art_encounters = []
    hiv_encounters_list = [ "HIV STAGING", "HIV CLINIC REGISTRATION", 
                            "HIV RECEPTION","HIV CLINIC CONSULTATION",
                            "EXIT FROM HIV CARE"
                          ]
    if type.to_s.downcase == 'encounter'
      all_encounters.each{|encounter|
        if ! hiv_encounters_list.include? EncounterType.find(encounter.encounter_type).name.to_s.upcase
          if encounter.encounter_type == EncounterType.find_by_name("Treatment").id || encounter.encounter_type == EncounterType.find_by_name("dispensing").id
            non_art_encounters << encounter if check_for_arvs_presence(encounter) != true       
          else
            non_art_encounters<< encounter
          end
        end
      }
    elsif type.to_s.downcase == 'prescription'
      arv_drugs = []
      concept_set("antiretroviral drugs").each{|concept| arv_drugs << concept.uniq.to_s}
      
      all_encounters.each{|prescription|
        if ! arv_drugs.include? Concept.find(prescription.concept_id).fullname
          non_art_encounters << prescription
        end
      }
    elsif type.to_s.downcase == 'program'
      hiv_program_id = Program.find_by_name('HIV program').id
      all_encounters.each{|program|
        if program.program_id != hiv_program_id
          non_art_encounters << program
        end
      }
    end
    
    return non_art_encounters
    
  end
  
  def check_for_arvs_presence(encounter)
    arv_drugs = []
    concept_set("antiretroviral drugs").each{|concept| arv_drugs << concept.uniq.to_s}
    dispensed_id = Concept.find_by_name('Amount dispensed').concept_id
    arv_regimen_concept_id = Concept.find_by_name('Regimen Category').concept_id
    
    encounter.orders.each{|order|
      if ! arv_drugs.include? Concept.find(order.concept_id).fullname
        return true
      end  
    }
       
    encounter.observations.each {|obs|
      if obs.concept_id == dispensed_id
        return true if arv_drugs.include? Concept.find(Drug.find(obs.value_drug).concept_id).fullname
      elsif obs.concept_id == arv_regimen_concept_id
        return true
      end
    }

    return false
  end
  
end
