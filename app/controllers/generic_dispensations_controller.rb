class GenericDispensationsController < ApplicationController
	def new
		@patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil

		#@prescriptions = @patient.orders.current.prescriptions.all
		type = EncounterType.find_by_name('TREATMENT')
		session_date = session[:datetime].to_date rescue Date.today
		@prescriptions = Order.find(:all,
      :joins => "INNER JOIN encounter e USING (encounter_id)",
      :conditions => ["encounter_type = ? AND e.patient_id = ? AND DATE(encounter_datetime) = ?",
        type.id,@patient.id,session_date])
		@options = @prescriptions.map{|presc| [presc.drug_order.drug.name, presc.drug_order.drug_inventory_id]}

    @drug_order_hash = {}
    @prescriptions.each do |presc|
      drug_id =  presc.drug_order.drug_inventory_id
      @drug_order_hash[drug_id] = presc.order_id
    end

    la_concept_id = Concept.find_by_name("LA(Lumefantrine + arthemether)").concept_id
    @quinine_drug_names = Drug.find(:all, :conditions => ["concept_id =?", la_concept_id]).collect{|d|d.name.squish}

	end

  def change_amount_dispensed
    @patient = Patient.find(params[:patient_id])
    @order = Order.find(params[:order_id])
    @order_id = @order.order_id
    @drug_name = @order.drug_order.drug.name
    @drug_value = @order.drug_order.drug.drug_id
    session_date = session[:datetime] || Time.now()
    
    if params[:filter] and !params[:filter][:provider].blank?
      user_person_id = User.find_by_username(params[:filter][:provider]).person_id
    elsif params[:location]
      user_person_id = params[:provider_id]
    else
      user_person_id = current_user.person_id
    end

    @encounter = current_dispensation_encounter(@patient, session_date, user_person_id)

    if request.post?
      ActiveRecord::Base.transaction do
        drug_order = @order.drug_order
        drug_order.quantity = nil #Reset the quantity 
        drug_order.save
        
        obs_orders = Observation.find(:all, :conditions => ["order_id =?", @order.order_id])
        obs_orders.each do |obs_order|
          obs_order.void #void all related observations of this order
        end

        obs = Observation.new(
          :concept_name => "AMOUNT DISPENSED",
          :order_id => @order_id,
          :person_id => @patient.person.person_id,
          :encounter_id => @encounter.id,
          :value_drug => @drug_value,
          :value_numeric => params[:quantity],
          :obs_datetime => session_date || Time.now()
        )

        obs.save

      end

      redirect_to "/patients/treatment_dashboard?id=#{@patient.patient_id}&dispensed_order_id=#{@order_id}"
    end
  end

  def create
    if (params[:identifier])
      params[:drug_id] = params[:identifier].match(/^\d+/).to_s
      params[:quantity] = params[:identifier].match(/\d+$/).to_s
    end
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    unless params[:location]
      session_date = session[:datetime] || Time.now()
    else
      session_date = params[:encounter_datetime] #Use date_created passed during import
    end

    @drug = Drug.find(params[:drug_id]) rescue nil
    #TODO look for another place to put this block of code
    if @drug.blank? or params[:quantity].blank?
      flash[:error] = "There is no drug with barcode: #{params[:identifier]}"
      redirect_to "/patients/treatment_dashboard/#{@patient.patient_id}" and return
    end if (params[:identifier])

    # set current location via params if given
    Location.current_location = Location.find(params[:location]) if params[:location]

    if params[:filter] and !params[:filter][:provider].blank?
      user_person_id = User.find_by_username(params[:filter][:provider]).person_id
    elsif params[:location]
      user_person_id = params[:provider_id]
    else
      user_person_id = current_user.person_id
    end

    @encounter = current_dispensation_encounter(@patient, session_date, user_person_id)

    @order = PatientService.current_treatment_encounter( @patient, session_date, user_person_id).drug_orders.find(:first,:conditions => ['drug_order.drug_inventory_id = ?', 
        params[:drug_id]]).order rescue []

    # Do we have an order for the specified drug?
		if @order.blank?
			if params[:location]
				obs = nil

				treatment_encounter = PatientService.current_treatment_encounter(@patient, session_date, user_person_id)
				current_weight = PatientService.get_patient_attribute_value(@patient, "current_weight")

				estimate = false				
				if current_weight.blank?
					estimate = true
				end

				drug = Drug.find(params[:drug_id])

        dose = 1
        frequency = 'TWICE A DAY (BD)'
        prn = 0
        instructions = "#{drug.name}"
        equivalent_daily_dose = 2
				start_date = session_date
				duration = 0

				if !estimate
          regimen = Regimen.find(:first, :select => "regimen.*, regimen_drug_order.*", :joins => 'LEFT JOIN regimen_drug_order ON regimen.regimen_id = regimen_drug_order.regimen_id' ,
            :conditions => ['min_weight <= ? AND max_weight > ?
													AND program_id = 1 AND drug_inventory_id = ?', current_weight, current_weight, params[:drug_id]])
          if !regimen.blank?
            dose = regimen.dose
            frequency = regimen.frequency
            prn = regimen.prn
            instructions = "#{drug.name}: #{regimen.instructions}"
            equivalent_daily_dose = regimen.equivalent_daily_dose
          end
							
				end

				duration = params[:quantity].to_i / equivalent_daily_dose.to_i

				auto_expire_date = start_date + duration.to_i.days rescue start_date.to_date + duration.to_i.days

				DrugOrder.write_order(
					treatment_encounter, 
					@patient, 
					obs, 
					drug, 
					start_date, 
					auto_expire_date, 
					dose, 
					frequency, 
					prn, 
					instructions,
					equivalent_daily_dose)   

				@order = PatientService.current_treatment_encounter( @patient, session_date, user_person_id).drug_orders.find(:first,:conditions => ['drug_order.drug_inventory_id = ?', 
            params[:drug_id]]).order rescue []
				
				@order_id = @order.order_id
				@drug_value = params[:drug_id]
			else
				flash[:error] = "There is no prescription for #{@drug.name}"
				redirect_to "/patients/treatment_dashboard/#{@patient.patient_id}" and return
			end
		else
			@order_id = @order.order_id
			@drug_value = @order.drug_order.drug_inventory_id
		end

    #assign the order_id and  drug_inventory_id
    # Try to dispense the drug
      
    obs = Observation.new(
      :concept_name => "AMOUNT DISPENSED",
      :order_id => @order_id,
      :person_id => @patient.person.person_id,
      :encounter_id => @encounter.id,
      :value_drug => @drug_value,
      :value_numeric => params[:quantity],
      :obs_datetime => session_date || Time.now())

    obs.save

    if !params[:encounter].blank?
      if params[:encounter][:voided]
        obs.voided = params[:encounter][:voided]
        obs.voided_by = params[:encounter][:voided_by]
        obs.date_voided = params[:encounter][:date_voided]
        obs.void_reason = params[:encounter][:void_reason]
        obs.save
      end
    end

    @patient.patient_programs.find_last_by_program_id(Program.find_by_name("HIV PROGRAM")).transition(
      :state => "On antiretrovirals",:start_date => session_date || Time.now()) if MedicationService.arv(@drug) rescue nil

    @patient.patient_programs.find_last_by_program_id(Program.find_by_name("DIABETES PROGRAM")).transition(
      :state => "On treatment",:start_date => session_date || Time.now()) if MedicationService.diabetes_medication(@drug) rescue nil

    @tb_programs = @patient.patient_programs.in_uncompleted_programs(['TB PROGRAM', 'MDR-TB PROGRAM'])

    if !@tb_programs.blank?
      @patient.patient_programs.find_last_by_program_id(Program.find_by_name("TB PROGRAM")).transition(
        :state => "Currently in treatment",:start_date => session_date || Time.now()) if   MedicationService.tb_medication(@drug)
    end

    @order.drug_order.total_drug_supply(@patient, @encounter, session_date.to_date)
    
    #checks if the prescription is satisfied
    complete = dispensation_complete(@patient, @encounter, PatientService.current_treatment_encounter(@patient, session_date, user_person_id))
    if complete
      unless params[:location]
        if (CoreService.get_global_property_value('auto_set_appointment') rescue false)
          start_date, end_date = DrugOrder.prescription_dates(@patient,session_date.to_date)
          redirect_to :controller => 'encounters',:action => 'new',
            :patient_id => @patient.id,:id =>"show",:encounter_type => "appointment" ,
            :select_date => 'NO'
        else
          redirect_to "/patients/treatment_dashboard?id=#{@patient.patient_id}&dispensed_order_id=#{@order_id}"
        end
      else
        render :text => 'complete' and return
      end
    else
      unless params[:location]
        redirect_to "/patients/treatment_dashboard?id=#{@patient.patient_id}&dispensed_order_id=#{@order_id}"
      else
        render :text => 'complete' and return
      end
    end
  end  
  
  def quantities 
    drug = Drug.find(params[:formulation])
    # Most common quantity should be for the generic, not the specific
    # But for now, the value_drug shortcut is significant enough that we 
    # Should just use it. Also, we are using the AMOUNT DISPENSED obs
    # and not the drug_order.quantity because the quantity contains number
    # of pills brought to clinic and we should assume that the AMOUNT DISPENSED
    # observations more accurately represent pack sizes
    amounts = []
    Observation.question("AMOUNT DISPENSED").all(
      :conditions => {:value_drug => drug.drug_id},
      :group => 'value_drug, value_numeric',
      :order => 'count(*)',
      :limit => '10').each do |obs|
      amounts << "#{obs.value_numeric.to_f}" unless obs.value_numeric.blank?
    end
    amounts = amounts.flatten.compact.uniq
    render :text => "<li>" + amounts.join("</li><li>") + "</li>"
  end

  def current_dispensation_encounter(patient, date = Time.now(), provider = user_person_id)
    type = EncounterType.find_by_name("DISPENSING")
    encounter = patient.encounters.find(:first,:conditions =>["DATE(encounter_datetime) = ? AND encounter_type = ?",date.to_date,type.id])
    encounter ||= patient.encounters.create(:encounter_type => type.id,:encounter_datetime => date, :provider_id => provider)
  end

  def create_drug_stock_out_obs
    patient_id = params[:patient_id]
    #drug_name = params[:drug_name]
    drug_id = params[:drug_id]
    order_id = params[:order_id]
    session_date = session[:datetime].to_date rescue Time.now
    
    patient = Patient.find(patient_id)
    dispensation_encounter = current_dispensation_encounter(patient, session_date, current_user.person_id)
    concept_id = Concept.find_by_name("DRUG OUT OF STOCK").concept_id
    dispensation_encounter.observations.create({
        :person_id => patient_id,
        :concept_id => concept_id,
        :order_id => order_id,
        :value_drug => drug_id,
        :value_text => 'Stocked Out',
        :obs_datetime => Time.now
      })

    redirect_to("/dispensations/dispense_non_prescribed_drugs?patient_id=#{patient_id}&order_id=#{order_id}") and return if params[:dispense_new_drug]
    redirect_to("/patients/treatment_dashboard/#{patient_id}") and return
  end

  def dispense_non_prescribed_drugs
    @patient = Patient.find(params[:patient_id])
    concept_id = Concept.find_by_name("LA(Lumefantrine + arthemether)").concept_id
		type = EncounterType.find_by_name('TREATMENT')
		session_date = session[:datetime].to_date rescue Date.today
		prescriptions = Order.find(:all,
      :joins => "INNER JOIN encounter e USING (encounter_id)",
      :conditions => ["encounter_type = ? AND e.patient_id = ? AND DATE(encounter_datetime) = ?",
        type.id,@patient.id,session_date])

    prescribed_drug_ids = prescriptions.map{|presc| presc.drug_order.drug_inventory_id}
    prescribed_drug_ids = [0] if prescribed_drug_ids.blank?

    non_prescribed_drugs = Drug.find(:all, :conditions => ["concept_id =? AND drug_id NOT IN (?)",
        concept_id, prescribed_drug_ids])
    
		@options = non_prescribed_drugs.map{|drug| [drug.name, drug.drug_id]}

  end

  def create_non_prescribed_drug_dispensation
    session_date = session[:datetime].to_date rescue Time.now()
    order = Order.find(params[:order_id])
    new_order = order.clone
    new_drug_order = order.drug_order.clone
    instructions = new_order.instructions.split(":")[1]
    drug_name = Drug.find(params[:drug_id]).name
    new_order_instructions = "#{drug_name} : #{instructions.squish}"

    if params[:filter] and !params[:filter][:provider].blank?
      user_person_id = User.find_by_username(params[:filter][:provider]).person_id
    elsif params[:location]
      user_person_id = params[:provider_id]
    else
      user_person_id = current_user.person_id
    end

    patient = Patient.find(params[:patient_id])
    encounter = current_dispensation_encounter(patient, session_date, user_person_id)

    ActiveRecord::Base.transaction do
      new_order.instructions = new_order_instructions
      new_order.save

      new_drug_order.order_id = new_order.order_id
      new_drug_order.drug_inventory_id = params[:drug_id]
      new_drug_order.save

      obs = Observation.new(
        :concept_name => "AMOUNT DISPENSED",
        :order_id => new_order.order_id,
        :person_id => params[:patient_id],
        :encounter_id => encounter.encounter_id,
        :value_drug => params[:drug_id],
        :value_numeric => params[:quantity],
        :obs_datetime => session_date
      )
      obs.save
      
      new_order.drug_order.total_drug_supply(patient, encounter, session_date.to_date)
    end

    redirect_to("/patients/treatment_dashboard/#{params[:patient_id]}")
  end

  def set_received_regimen(patient, encounter,prescription)
    dispense_finish = true ; dispensed_drugs_inventory_ids = []

    prescription.orders.each do | order |
      next if not MedicationService.arv(order.drug_order.drug)
		  
      if order.drug_order.quantity and order.drug_order.quantity > 0
        dispensed_drugs_inventory_ids << order.drug_order.drug.id
      end
=begin		
		  if (order.drug_order.amount_needed > 0)
			dispense_finish = false
		  end
=end
    end

    #return unless dispense_finish
    #return if dispensed_drugs_inventory_ids.blank?

    return_text = ''
    if !dispensed_drugs_inventory_ids.blank?
      regimen_drug_order = ActiveRecord::Base.connection.select_all <<EOF
SELECT r.regimen_id , r.concept_id ,
(SELECT COUNT(t3.regimen_id) FROM regimen_drug_order t3
WHERE t3.regimen_id = t.regimen_id GROUP BY t3.regimen_id) as c
FROM regimen_drug_order t, regimen r
WHERE t.drug_inventory_id IN (#{dispensed_drugs_inventory_ids.join(',')})
AND r.regimen_id = t.regimen_id
GROUP BY r.concept_id
HAVING c = #{dispensed_drugs_inventory_ids.length}
AND r.regimen_id = (
SELECT x.regimen_id FROM regimen_drug_order x 
WHERE x.drug_inventory_id IN (#{dispensed_drugs_inventory_ids.join(',')}) 
GROUP BY x.regimen_id 
HAVING count(x.drug_inventory_id) = c
LIMIT 1)
EOF

      regimen_prescribed = regimen_drug_order.first['concept_id'].to_i rescue ConceptName.find_by_name('UNKNOWN ANTIRETROVIRAL DRUG').concept_id


      #			if (Observation.find(:first,:conditions => ["person_id = ? AND encounter_id = ? AND concept_id = ?",
      #					patient.id,encounter.id,ConceptName.find_by_name('ARV REGIMENS RECEIVED ABSTRACTED CONSTRUCT').concept_id])).blank?

      regimen_value_text = Concept.find(regimen_prescribed).shortname rescue nil
      if regimen_value_text.blank?
        regimen_value_text = ConceptName.find_by_concept_id(regimen_prescribed).name rescue nil
      end
	
      return if regimen_value_text.blank?
      return_text = regimen_value_text

      selected_regimen = Regimen.find(regimen_drug_order.first['regimen_id'].to_i) rescue nil

      regimen_category_id = ConceptName.find_by_name('REGIMEN CATEGORY').concept_id
      if encounter.observations.find_by_concept_id(regimen_category_id).blank?
        obs = Observation.create(
          :concept_name => "REGIMEN CATEGORY",
          :person_id => patient.id,
          :encounter_id => encounter.id,
          :value_text => selected_regimen.regimen_index,
          :obs_datetime => encounter.encounter_datetime) if !selected_regimen.blank?
      end
			
      regimens_received_id = ConceptName.find_by_name('ARV REGIMENS RECEIVED ABSTRACTED CONSTRUCT').concept_id
      if encounter.observations.find_by_concept_id(regimens_received_id).blank?
        obs = Observation.new(
          :concept_name => "ARV REGIMENS RECEIVED ABSTRACTED CONSTRUCT",
          :person_id => patient.id,
          :encounter_id => encounter.id,
          :value_coded => regimen_prescribed,
          :obs_datetime => encounter.encounter_datetime)

        obs.save
      end
			
    end
    return return_text
  end

  private

  def dispensation_complete(patient,encounter,prescription)
    complete = all_orders_complete(patient, encounter.encounter_datetime.to_date)
    if complete
      dispensation_completed = set_received_regimen(patient, encounter,prescription)
    end
    return complete
  end

  def all_orders_complete(patient, encounter_date)
    type = EncounterType.find_by_name('TREATMENT').id

    current_treatment_encounters = Encounter.find(:all,
      :conditions =>["patient_id = ? AND encounter_datetime BETWEEN ? AND ?
				AND encounter_type = ?",patient.id , 
        encounter_date.to_date.strftime('%Y-%m-%d 00:00:00'),
        encounter_date.to_date.strftime('%Y-%m-%d 23:59:59'),
        type])
							                                                            
    complete = true
    (current_treatment_encounters || []).each do | encounter |
      encounter.drug_orders.each do | drug_order |
        if drug_order.amount_needed > 0
          complete = false
        end
        break if complete == false
      end
      break if complete == false
    end
    return complete
  end
end
