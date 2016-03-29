class GenericPrescriptionsController < ApplicationController
  # Is this used?
  def index
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    @orders = @patient.orders.prescriptions.current.all rescue []
    @history = @patient.orders.prescriptions.historical.all rescue []
    redirect_to "/prescriptions/new?patient_id=#{params[:patient_id] || session[:patient_id]}" and return if @orders.blank?
    render :template => 'prescriptions/index', :layout => 'menu'
  end
  
  def new
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    @patient_diagnoses = PatientService.current_diagnoses(@patient.person.id)
    @current_weight = PatientService.get_patient_attribute_value(@patient, "current_weight")
		@current_height = PatientService.get_patient_attribute_value(@patient, "current_height")
  end
  
  def void	
    @order = Order.find(params[:order_id])
    @order.void
    flash.now[:notice] = "Order was successfully voided"
    if !params[:source].blank? && params[:source].to_s == 'advanced'
      redirect_to "/prescriptions/advanced_prescription?patient_id=#{params[:patient_id]}" and return
    else
    	index and return
   	end
  end
  
  def create
    @suggestions = params[:suggestion] || ['New Prescription']
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    unless params[:location]
      session_date = session[:datetime] || params[:encounter_datetime] || Time.now()
    else
      session_date = params[:encounter_datetime] #Use encounter_datetime passed during import
    end
    # set current location via params if given
    Location.current_location = Location.find(params[:location]) if params[:location]
    
    if params[:filter] and !params[:filter][:provider].blank?
      user_person_id = User.find_by_username(params[:filter][:provider]).person_id
    elsif params[:location] # migration
      user_person_id = params[:provider_id]
    else
      user_person_id = User.find_by_user_id(current_user.user_id).person_id
    end

    @encounter = PatientService.current_treatment_encounter( @patient, session_date, user_person_id)
    @diagnosis = Observation.find(params[:diagnosis]) rescue nil
    @suggestions.each do |suggestion|
      unless (suggestion.blank? || suggestion == '0' || suggestion == 'New Prescription')
        @order = DrugOrder.find(suggestion)
        DrugOrder.clone_order(@encounter, @patient, @diagnosis, @order)
      else
        
        @formulation = (params[:formulation] || '').upcase
        @drug = Drug.find_by_name(@formulation) rescue nil
        unless @drug
          flash[:notice] = "No matching drugs found for formulation #{params[:formulation]}"
          render :new
          return
        end  
        start_date = session_date
        auto_expire_date = session_date.to_date + params[:duration].to_i.days
        prn = params[:prn].to_i
        if params[:type_of_prescription] == "variable"
          DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug, start_date, auto_expire_date, [params[:morning_dose], params[:afternoon_dose], params[:evening_dose], params[:night_dose]], 'VARIABLE', prn)
        else
          DrugOrder.write_order(@encounter, @patient, @diagnosis, @drug, start_date, auto_expire_date, params[:dose_strength], params[:frequency], prn)
        end  
      end  
    end

    unless params[:location]
      redirect_to (params[:auto] == '1' ? "/prescriptions/auto?patient_id=#{@patient.id}" : "/patients/treatment_dashboard/#{@patient.id}")
    else
      render :text => 'import success' and return
    end
    
  end
  
  def auto
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    # Find the next diagnosis that doesn't have a corresponding order
    @diagnoses = PatientService.current_diagnoses(@patient.person.id)
    @prescriptions = @patient.orders.current.prescriptions.all.map(&:obs_id).uniq
    @diagnoses = @diagnoses.reject {|diag| @prescriptions.include?(diag.obs_id) }
    if @diagnoses.empty?
      redirect_to "/prescriptions/new?patient_id=#{@patient.id}"
    else
      redirect_to "/prescriptions/new?patient_id=#{@patient.id}&diagnosis=#{@diagnoses.first.obs_id}&auto=#{@diagnoses.length == 1 ? 0 : 1}"
    end  
  end
  
  # Look up the set of matching generic drugs based on the concepts. We 
  # limit the list to only the list of drugs that are actually in the 
  # drug list so we don't pick something we don't have.
  def generics
    search_string = (params[:search_string] || '').upcase
    filter_list = params[:filter_list].split(/, */) rescue []    
    @drug_concepts = ConceptName.find(:all, 
      :select => "concept_name.name", 
      :joins => "INNER JOIN drug ON drug.concept_id = concept_name.concept_id AND drug.retired = 0", 
      :conditions => ["concept_name.name LIKE ?", '%' + search_string + '%'],:group => 'drug.concept_id')
    render :text => "<li>" + @drug_concepts.map{|drug_concept| drug_concept.name }.uniq.join("</li><li>") + "</li>"
  end
  
  # Look up all of the matching drugs for the given generic drugs
  def formulations
    @generic = (params[:generic] || '')
    @concept_ids = ConceptName.find_all_by_name(@generic).map{|c| c.concept_id}
    render :text => "" and return if @concept_ids.blank?
    search_string = (params[:search_string] || '').upcase
    @drugs = Drug.find(:all, 
      :select => "name", 
      :conditions => ["concept_id IN (?) AND name LIKE ?", @concept_ids, '%' + search_string + '%'])
    render :text => "<li>" + @drugs.map{|drug| drug.name }.join("</li><li>") + "</li>"
  end
  
  # Look up likely durations for the drug
  def durations
    @formulation = (params[:formulation] || '').upcase
    drug = Drug.find_by_name(@formulation) rescue nil
    render :text => "No matching drugs found for #{params[:formulation]}" and return unless drug

    # Grab the 10 most popular durations for this drug
    amounts = []
    orders = DrugOrder.find(:all, 
      :select => 'DATEDIFF(orders.auto_expire_date, orders.start_date) as duration_days',
      :joins => 'LEFT JOIN orders ON orders.order_id = drug_order.order_id AND orders.voided = 0',
      :limit => 10, 
      :group => 'drug_inventory_id, DATEDIFF(orders.auto_expire_date, orders.start_date)', 
      :order => 'count(*)', 
      :conditions => {:drug_inventory_id => drug.id})
      
    orders.each {|order|
      amounts << "#{order.duration_days.to_f}" unless order.duration_days.blank?
    }  
    amounts = amounts.flatten.compact.uniq
    render :text => "<li>" + amounts.join("</li><li>") + "</li>"
  end

  # Look up likely dose_strength for the drug
  def dosages
    @formulation = (params[:formulation] || '')
    drug = Drug.find_by_name(@formulation) rescue nil
    render :text => "No matching drugs found for #{params[:formulation]}" and return unless drug

    @frequency = (params[:frequency] || '')

    # Grab the 10 most popular dosages for this drug
    amounts = []
    amounts << "#{drug.dose_strength}" if drug.dose_strength 
    orders = DrugOrder.find(:all, 
      :limit => 10, 
      :group => 'drug_inventory_id, dose', 
      :order => 'count(*)', 
      :conditions => {:drug_inventory_id => drug.id, :frequency => @frequency})
    orders.each {|order|
      amounts << "#{order.dose}"
    }  
    amounts = amounts.flatten.compact.uniq
    render :text => "<li>" + amounts.join("</li><li>") + "</li>"
  end

	# Look up the units for the first substance in the drug, ideally we should re-activate the units on drug for aggregate units
	def units
		@formulation = (params[:formulation] || '').upcase
		drug = Drug.find_by_name(@formulation) rescue nil
		render :text => "per dose" and return unless drug && !drug.units.blank?
		render :text => drug.units
	end
  
	def suggested
		@diagnosis = Observation.find(params[:diagnosis]) rescue nil
		@options = []
		render :layout => false and return unless @diagnosis && @diagnosis.value_coded
		@orders = DrugOrder.find_common_orders(@diagnosis.value_coded)
		@options = @orders.map{|o| [o.order_id, o.script] } + @options
		render :layout => false
	end
  
	# Look up all of the matching drugs for the given drug name
	def name
		search_string = (params[:search_string] || '').upcase
		@drugs = Drug.find(:all, 
		  :select => "name", 
		  :conditions => ["name LIKE ?", '%' + search_string + '%'])
		render :text => "<li>" + @drugs.map{|drug| drug.name }.join("</li><li>") + "</li>"
	end

	def generic_advanced_prescription
		@use_col_interface = CoreService.get_global_property_value("use.column.interface").to_s
		@patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    la_concept_id = Concept.find_by_name("LA(Lumefantrine + arthemether)").concept_id
		@generics = MedicationService.generic.delete_if{|g| g if g[1] == la_concept_id} #Remove LA drug from list. Dosage + frequency + duration already known
    @preferred_drugs = Drug.preferred_drugs.delete_if{|p| p if p[1] == la_concept_id} #Remove LA drug from list. Dosage + frequency + duration already known
    
		@frequencies = MedicationService.fully_specified_frequencies
		@formulations = {}
    generic_concept_ids = @generics.collect{|generic| generic[1]}
    preferred_drugs_concept_ids = @preferred_drugs.collect{|preferred_drug| preferred_drug[1]}
    @preferred_drugs_concept_ids = preferred_drugs_concept_ids
    
    drug_formulations = {}
    
    Drug.all(:select => ["name, concept_id, dose_strength, units"],
      :conditions => ["concept_id IN (?)", (preferred_drugs_concept_ids + generic_concept_ids).uniq]
    ).each do |record|
      
      if drug_formulations[record.concept_id].blank?
        drug_formulations[record.concept_id] = []
      end
    
      drug_formulations[record.concept_id] << [record.name, record.dose_strength, record.units]
      
    end
   
    (@preferred_drugs + @generics).uniq.each do | name, concept_id |

      #skip non-drug concepts      
      next if drug_formulations[concept_id].blank? 
      formulation = {}    
      drug_formulations[concept_id].each do |drg_name, dose_strength, drg_units|
        formulation[drg_name] = [dose_strength, drg_units]
      end
      
      @formulations[concept_id] = formulation
      
    end
   
    (@preferred_drugs + @generics).uniq.each { | generic |
			drugs = Drug.find(:all,	:conditions => ["concept_id = ?", generic[1]])
			drug_formulations = {}			
			drugs.each { | drug |
				drug_formulations[drug.name] = [drug.dose_strength, drug.units]
			}
			@formulations[generic[1]] = drug_formulations			
		}
    
    session[:formulations] = @formulations
		@diagnosis = @patient.current_diagnoses["DIAGNOSIS"] rescue []

    antimalaria_drugs = CoreService.get_global_property_value("anti_malaria_drugs")
    @antimalarial_drugs_hash = {}
    antimalaria_drugs.each do |key, values|
      drug_id = Drug.find_by_name(key).drug_id rescue nil
      next if drug_id.blank?
      @antimalarial_drugs_hash[drug_id] = {}
      @antimalarial_drugs_hash[drug_id]["duration"] = values["duration"]
      @antimalarial_drugs_hash[drug_id]["frequency"] = values["frequency"]
      @antimalarial_drugs_hash[drug_id]["strength"] = values["strength"]
      @antimalarial_drugs_hash[drug_id]["units"] = values["units"]
      @antimalarial_drugs_hash[drug_id]["drug_name"] = values["drug_name"]
      @antimalarial_drugs_hash[drug_id]["tabs"] = values["tabs"]
    end

    lab_result_encounter_type_id = EncounterType.find_by_name("LAB RESULTS").encounter_type_id
    malaria_test_result_concept_id = Concept.find_by_name("MALARIA TEST RESULT").concept_id
    today =  session[:datetime].to_date rescue Date.today

    malaria_test_result_obs = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
            ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id} AND e.patient_id=#{@patient.id}
            AND o.concept_id = #{malaria_test_result_concept_id} AND e.voided=0
            AND DATE(e.encounter_datetime) = '#{today}'
            ORDER BY e.encounter_datetime DESC LIMIT 1").last

    @malaria_test_result = malaria_test_result_obs.answer_string.squish rescue ""

    if @malaria_test_result.blank?
      malaria_concept_id = Concept.find_by_name("MALARIA").concept_id
      outpatient_encounter_type_id = EncounterType.find_by_name("OUTPATIENT DIAGNOSIS").encounter_type_id

      diagnosis_concept_ids = ["PRIMARY DIAGNOSIS", "SECONDARY DIAGNOSIS", "ADDITIONAL DIAGNOSIS"].collect do |concept_name|
        Concept.find_by_name(concept_name).concept_id
      end

      malaria_observation = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{outpatient_encounter_type_id} AND e.patient_id=#{@patient.id}
        AND o.concept_id IN (#{diagnosis_concept_ids.join(', ')}) AND o.value_coded = #{malaria_concept_id}
        AND e.voided=0 AND DATE(e.encounter_datetime) = '#{today}'").last
      
      @malaria_test_result = 'Positive' unless malaria_observation.blank?
    end

		render :layout => 'application'
	end
  
  def load_frequencies_and_dosages
    concept_id = params[:concept_id]
    drugs = Drug.find(:all,	:conditions => ["concept_id = ?", concept_id])
    drug_formulations = []
    drugs.each { | drug |
      drug_formulations << drug.name + ':' + drug.dose_strength.to_s + ':' + drug.units.to_s + ';'
    }
    render :text => drug_formulations
	end

	def create_advanced_prescription
		@patient    = Patient.find(params[:encounter][:patient_id]  || session[:patient_id]) rescue nil
		encounter  = MedicationService.current_treatment_encounter(@patient)
    if !(params[:prescriptions].blank?)

      (params[:prescriptions] || []).each{ | prescription |
				prescription[:encounter_id]  = encounter.encounter_id
				prescription[:obs_datetime]  = encounter.encounter_datetime || (session[:datetime] ||  Time.now())
				prescription[:person_id]     = encounter.patient_id

				formulation = (prescription[:dosage] || '').upcase

				drug = Drug.find_by_name(formulation) rescue nil

				unless drug
					flash[:notice] = "No matching drugs found for formulation #{prescription[:formulation]}"
					render :new
					return
				end

				start_date = session[:datetime].to_date rescue nil
        start_date = Time.now() if start_date.blank?
        prn = "no"
				auto_expire_date = start_date + prescription[:duration].to_i.days

        DrugOrder.write_order(encounter, @patient, nil, drug, start_date, auto_expire_date, prescription[:strength],
          prescription[:frequency], prn)

			}

      if(@patient)
        #redirect_to "/patients/treatment_dashboard/#{@patient.id}" and return
        flash[:notice] = "Your prescription is successful"
        redirect_to "/patients/show/#{@patient.id}" and return
      else
        #redirect_to "/patients/treatment_dashboard/#{params[:patient_id]}" and return
        redirect_to "/patients/show/#{@patient.id}" and return
      end

    end

    
		if params[:prescription].blank?
			#next if params[:formulation].blank?
      formulation = (params[:formulation] || '').upcase
			drug = Drug.find_by_name(formulation) rescue nil
			unless drug
				flash[:notice] = "No matching drugs found for formulation #{params[:formulation]}"
				render :new
				return
			end
			start_date = session[:datetime].to_date rescue Time.now
			auto_expire_date = session_date.to_date + params[:duration].to_i.days
			prn = params[:prn].to_i

			if prescription[:type_of_prescription] == "variable"
				DrugOrder.write_order(encounter, @patient, nil, drug, start_date, auto_expire_date, [prescription[:morning_dose], 
            prescription[:afternoon_dose], prescription[:evening_dose], prescription[:night_dose]],
					prescription[:type_of_prescription], prn)
			else
				DrugOrder.write_order(encounter, @patient, nil, drug, start_date, auto_expire_date, prescription[:dose_strength], 
					prescription[:frequency], prn)
			end
    end

		unless params[:prescription].blank?
			(params[:prescription] || []).each{ | prescription |      
				prescription[:encounter_id]  = encounter.encounter_id
				prescription[:obs_datetime]  = encounter.encounter_datetime || (session[:datetime] ||  Time.now())
				prescription[:person_id]     = encounter.patient_id

				formulation = (prescription[:formulation] || '').upcase

				drug = Drug.find_by_name(formulation) rescue nil

				unless drug
					flash[:notice] = "No matching drugs found for formulation #{prescription[:formulation]}"
					render :new
					return
				end

				start_date = session[:datetime].to_date rescue nil
        start_date = Time.now() if start_date.blank?

				auto_expire_date = start_date + prescription[:duration].to_i.days
				prn = prescription[:prn]


				if prescription[:type_of_prescription] == "variable"
					DrugOrder.write_order(encounter, @patient, nil, drug, start_date, auto_expire_date, [prescription[:morning_dose], 
              prescription[:afternoon_dose], prescription[:evening_dose], prescription[:night_dose]],
						prescription[:type_of_prescription], prn)
				else
					DrugOrder.write_order(encounter, @patient, nil, drug, start_date, auto_expire_date, prescription[:dose_strength], 
						prescription[:frequency], prn)
				end

			}
		end

		if(@patient)
			#redirect_to "/patients/treatment_dashboard/#{@patient.id}" and return
      flash[:notice] = "Your prescription is successful"
      redirect_to "/patients/show/#{@patient.id}" and return
		else
			#redirect_to "/patients/treatment_dashboard/#{params[:patient_id]}" and return
      redirect_to "/patients/show/#{@patient.id}" and return
		end

	end

  def simple_prescription
    #@generics = MedicationService.generic
    render:layout => "application"
  end

  def drug_formulations
    search_string = params[:search_string]
    unless search_string.blank?
      @drugs = Drug.find(:all,
        :select => "name",
        :conditions => ["name LIKE ?", '%' + search_string + '%'],
        :order => "name ASC")
    else
      @drugs = Drug.find(:all, :select => "name",:order => "name ASC",
        :limit => 10)
    end
    render :text => "<li>" + @drugs.map{|drug| drug.name }.join("</li><li>") + "</li>"
  end

  def create_simple_prescription
    generics = params[:generics].delete_if{|item|item == ""}
    patient_id = params[:patient_id]
    concept_id = Concept.find_by_name('GIVEN DRUGS').id
    encounter = Encounter.new
    encounter.encounter_type = EncounterType.find_by_name('DRUGS GIVEN').id
    encounter.patient_id = patient_id
    encounter.encounter_datetime = session[:datetime]
    encounter.save
    generics.each do |drug|
      obs = Observation.new
      obs.person_id = encounter.patient_id
      obs.concept_id = concept_id
      obs.obs_datetime = Time.now
      obs.encounter_id = encounter.id
      obs.value_drug = Drug.find_by_name(drug).id
      obs.value_text = drug
      obs.save
    end
    redirect_to("/patients/show/#{patient_id}")
  end
end
