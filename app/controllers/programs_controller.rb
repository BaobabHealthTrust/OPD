class ProgramsController < GenericProgramsController
  def update
    flash[:error] = nil

    if request.method == :post
      patient_program = PatientProgram.find(params[:patient_program_id])
      #we don't want to have more than one open states - so we have to close the current active on before opening/creating a new one

      current_active_state = patient_program.patient_states.last
      current_active_state.end_date = params[:current_date].to_date

       # set current location via params if given
      Location.current_location = Location.find(params[:location]) if params[:location]

      patient_state = patient_program.patient_states.build(
        :state => params[:current_state],
        :start_date => params[:current_date])
      if patient_state.save
		    # Close and save current_active_state if a new state has been created
		   current_active_state.save
			 
        if patient_state.program_workflow_state.concept.fullname.upcase == 'PATIENT DIED' ||
					 patient_state.program_workflow_state.concept.fullname.upcase == 'PATIENT TRANSFERRED OUT' ||
        	 patient_state.program_workflow_state.concept.fullname.upcase == 'REFERRED TO ANOTHER FACILITY'
					 
					encounter = Encounter.new(params[:encounter])
          encounter.encounter_datetime = session[:datetime] unless session[:datetime].blank?
          encounter.save

          (params[:observations] || [] ).each do |observation|
            #for now i do this
            obs = {}
            obs[:concept_name] = observation[:concept_name] 
            obs[:value_coded_or_text] = observation[:value_coded_or_text] 
            obs[:encounter_id] = encounter.id
            obs[:obs_datetime] = encounter.encounter_datetime || Time.now()
            obs[:person_id] ||= encounter.patient_id  
            Observation.create(obs)
          end

          observation = {} 
          #observation[:concept_name] = 'TRANSFER OUT TO'
					observation[:concept_name] = 'TRANSFER OUT TO'
          observation[:encounter_id] = encounter.id
          observation[:obs_datetime] = encounter.encounter_datetime || Time.now()
          observation[:person_id] ||= encounter.patient_id
          observation[:value_text] = params[:transfer_out_location_id]
          Observation.create(observation)
        end  

        updated_state = patient_state.program_workflow_state.concept.fullname

		#disabled redirection during import in the code below
		# Changed the terminal state conditions from hardcoded ones to terminal indicator from the updated state object
        if patient_state.program_workflow_state.terminal == 1
          #the following code updates the person table to died yes if the state is Died/Death
          if updated_state.match(/DIED/i)
            person = patient_program.patient.person
            person.dead = 1
            unless params[:current_date].blank?
              person.death_date = params[:current_date].to_date
            end
            person.save

            #updates the state of all patient_programs to patient died and save the
            #end_date of the last active state.
            current_programs = PatientProgram.find(:all,:conditions => ["patient_id = ?",@patient.id])
            current_programs.each do |program|
              if patient_program.to_s != program.to_s
                current_active_state = program.patient_states.last
                current_active_state.end_date = params[:current_date].to_date

                Location.current_location = Location.find(params[:location]) if params[:location]

                patient_state = program.patient_states.build(
                    :state => params[:current_state],
                    :start_date => params[:current_date])
                if patient_state.save
		              current_active_state.save

		          # date_completed = session[:datetime].to_time rescue Time.now()
                date_completed = params[:current_date].to_date rescue Time.now()
                PatientProgram.update_all "date_completed = '#{date_completed.strftime('%Y-%m-%d %H:%M:%S')}'",
                                       "patient_program_id = #{program.patient_program_id}"
                end
             end
            end
          end

          # date_completed = session[:datetime].to_time rescue Time.now()
          date_completed = params[:current_date].to_date rescue Time.now()
          PatientProgram.update_all "date_completed = '#{date_completed.strftime('%Y-%m-%d %H:%M:%S')}'",
                                     "patient_program_id = #{patient_program.patient_program_id}"
        else
          person = patient_program.patient.person
          person.dead = 0
          person.save
          date_completed = nil
          PatientProgram.update_all "date_completed = NULL",
                                     "patient_program_id = #{patient_program.patient_program_id}"
        end
        #for import
         unless params[:location]
            redirect_to :controller => :patients, :action => :programs_dashboard, :patient_id => params[:patient_id]
         else
            render :text => "import suceeded" and return
         end
        
      else
        #for import
        unless params[:location]
          redirect_to :controller => :patients, :action => :programs_dashboard, :patient_id => params[:patient_id],:error => "Unable to update state"
        else
            render :text => "import suceeded" and return
        end
      end
    else
      patient_program = PatientProgram.find(params[:id])
      unless patient_program.date_completed.blank?
        unless params[:location]
            flash[:error] = "The patient has already completed this program!"
       else
          render :text => "import suceeded" and return
       end   
      end
      @patient = patient_program.patient
      @patient_program_id = patient_program.patient_program_id
      program_workflow = ProgramWorkflow.all(:conditions => ['program_id = ?', patient_program.program_id], :include => :concept)
      @program_workflow_id = program_workflow.first.program_workflow_id
      @states = ProgramWorkflowState.all(:conditions => ['program_workflow_id = ?', @program_workflow_id], :include => :concept)
      @names = @states.map{|state|
        concept = state.concept
        next if concept.blank?
        concept.fullname 
      }

      @names = @names.compact unless @names.blank?
      @program_date_completed = patient_program.date_completed.to_date rescue nil
      @program_name = patient_program.program.name
      @current_state = patient_program.patient_states.last.program_workflow_state.concept.fullname if patient_program.patient_states.last.end_date.blank?

      closed_states = []
      current_programs = PatientProgram.find(:all,:conditions => ["patient_id = ?",@patient.id])
      current_programs.each do | patient_program |
        patient_program.patient_states.each do | state |
          next if state.end_date.blank?
          closed_states << "#{state.start_date.to_date}:#{state.end_date.to_date}"
        end
        @invalid_date_ranges = closed_states.join(',')
      end
    end
  end
end
