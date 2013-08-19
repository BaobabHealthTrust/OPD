#adding programs to migrated patients with hiv staging


Encounter.find_by_sql("
				SELECT * FROM encounter e
				WHERE encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'REGISTRATION')
				AND patient_id not IN (SELECT DISTINCT(patient_id) FROM patient_program WHERE program_id = 14)").each {|patient |

  current = Patient.find(patient.patient_id)
				
				if current.patient_programs.in_programs("OPD PROGRAM").blank?
					current = current.patient_programs.create(
							  :program_id => 14,
                :creator => 1,
                :location_id => patient.location_id,
							  :date_enrolled => patient.encounter_datetime)
          puts "working program for patient #{patient.patient_id}"
        end
         
				}

 concept_name = ConceptName.find_all_by_name("Following")

  state = ProgramWorkflowState.find(:first, :conditions => ["concept_id IN (?)",concept_name.map{|c|c.concept_id}] ).program_workflow_state_id

PatientProgram.find_by_sql("
        SELECT * FROM patient_program
        WHERE patient_program_id NOT IN (SELECT patient_program_id FROM patient_state)").each {|pg|
        states = PatientState.new(
          :patient_program_id => pg.patient_program_id,
          :start_date => pg.date_enrolled,
          :state => state,
          :creator => 1
          )
        states.save!

       
          puts "working states for patient #{pg.patient_id}"
  
        }
