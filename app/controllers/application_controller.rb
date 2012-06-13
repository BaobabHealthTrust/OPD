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
	
end
