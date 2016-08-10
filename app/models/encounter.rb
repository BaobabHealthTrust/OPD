class Encounter < ActiveRecord::Base
  set_table_name :encounter
  set_primary_key :encounter_id
  include Openmrs
  has_many :observations, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :drug_orders,  :through   => :orders,  :foreign_key => 'order_id'
  has_many :orders, :dependent => :destroy, :conditions => {:voided => 0}
  belongs_to :type, :class_name => "EncounterType", :foreign_key => :encounter_type, :conditions => {:retired => 0}
  belongs_to :provider, :class_name => "Person", :foreign_key => :provider_id, :conditions => {:voided => 0}
  belongs_to :patient, :conditions => {:voided => 0}

  has_one :program_encounter, :foreign_key => :encounter_id

  # TODO, this needs to account for current visit, which needs to account for possible retrospective entry
  named_scope :current, :conditions => 'DATE(encounter.encounter_datetime) = CURRENT_DATE()'

  after_create :create_encounter_program

  def before_save
    self.provider = User.current.person if self.provider.blank?
    # TODO, this needs to account for current visit, which needs to account for possible retrospective entry
    self.encounter_datetime = Time.now if self.encounter_datetime.blank?
  end

  def after_save
    self.add_location_obs
  end

  def after_void(reason = nil)
    self.observations.each do |row|
      if not row.order_id.blank?
        ActiveRecord::Base.connection.execute <<EOF
UPDATE drug_order SET quantity = NULL WHERE order_id = #{row.order_id};
EOF
      end rescue nil
      row.void(reason)
    end rescue []

    self.orders.each do |order|
      order.void(reason)
    end

    void_encounter_program
  end

  def name
    self.type.name rescue "N/A"
  end

  def encounter_type_name=(encounter_type_name)
    self.type = EncounterType.find_by_name(encounter_type_name)
    raise "#{encounter_type_name} not a valid encounter_type" if self.type.nil?
  end

  def to_s
    if name == 'REGISTRATION'
      "Patient was seen at the registration desk at #{encounter_datetime.strftime('%I:%M')}"
    elsif name == 'TREATMENT'
      o = orders.collect{|order| order.to_s}.join("\n")
      o = "No prescriptions have been made" if o.blank?
      o
    elsif name == 'VITALS'
      temp = observations.select {|obs| obs.concept.concept_names.map(&:name).include?("TEMPERATURE (C)") && "#{obs.answer_string}".upcase != 'UNKNOWN' }
      weight = observations.select {|obs| obs.concept.concept_names.map(&:name).include?("WEIGHT (KG)") || obs.concept.concept_names.map(&:name).include?("Weight (kg)") && "#{obs.answer_string}".upcase != '0.0' }
      height = observations.select {|obs| obs.concept.concept_names.map(&:name).include?("HEIGHT (CM)") || obs.concept.concept_names.map(&:name).include?("Height (cm)") && "#{obs.answer_string}".upcase != '0.0' }
      vitals = [weight_str = weight.first.answer_string + 'KG' rescue 'UNKNOWN WEIGHT',
        height_str = height.first.answer_string + 'CM' rescue 'UNKNOWN HEIGHT']
      temp_str = temp.first.answer_string + '°C' rescue nil
      vitals << temp_str if temp_str
      vitals.join(', ')
    else
      observations.collect{|observation| "<b>#{(observation.concept.concept_names.last.name) rescue ""}</b>: #{observation.answer_string}"}.join(", ")
    end
  end

  def self.statistics(encounter_types, opts={})

    encounter_types = EncounterType.all(:conditions => ['name IN (?)', encounter_types])
    encounter_types_hash = encounter_types.inject({}) {|result, row| result[row.encounter_type_id] = row.name; result }
    database_sharing = CoreService.get_global_property_value("database.sharing").to_s == "true"
    opd_program_id = Program.find_by_name("OPD Program").program_id

    if (database_sharing)
      with_scope(:find => opts) do
        rows = self.all(
          :select => 'count(*) as number, encounter_type',
          :joins => [:program_encounter],
          :group => 'encounter.encounter_type',
          :conditions => ['encounter_type IN (?) AND program_id =?', encounter_types.map(&:encounter_type_id), opd_program_id])
        return rows.inject({}) {|result, row| result[encounter_types_hash[row['encounter_type']]] = row['number']; result }
      end
    else
      with_scope(:find => opts) do
        rows = self.all(
          :select => 'count(*) as number, encounter_type',
          :group => 'encounter.encounter_type',
          :conditions => ['encounter_type IN (?)', encounter_types.map(&:encounter_type_id)])
        return rows.inject({}) {|result, row| result[encounter_types_hash[row['encounter_type']]] = row['number']; result }
      end
    end

  end

  def create_encounter_program
    database_sharing = CoreService.get_global_property_value("database.sharing").to_s == "true"
    if (database_sharing)
      program_encounter = ProgramEncounter.new
      program_encounter.encounter_id = self.encounter_id
      program_encounter.program_id = Program.find_by_name("OPD Program").program_id
      program_encounter.save
    end
  end

  def void_encounter_program
    database_sharing = CoreService.get_global_property_value("database.sharing").to_s == "true"
    if (database_sharing)
      program_encounter = ProgramEncounter.find_by_encounter_id(self.encounter_id)
      unless program_encounter.blank?
        program_encounter.voided = 1
        program_encounter.save
      end
    end
  end

#  def self.underline_diseases(patient_id)
#  find_by_sql("SELECT C.name cname, O.* FROM concept_name C, obs O
#              where O.value_coded = C.concept_id
#              and C.concept_id = 5
#              and C.concept_name_type = 'fully_specified'
#              and person_id = #{patient_id}")
#  rescue nils
#end

  def self.previous_body_weight(patient_id)
  find_by_sql("SELECT * FROM obs where obs_id =
             (select max(obs_id) from chintheche.obs
              where concept_id = 5089
              and person_id = #{patient_id})")
  end

  def  self.underline_diseases_set(patient_id)
  concept_set_id = ConceptName.find_by_name('underlined IDSR diseases').concept_id
  concept_ids = ConceptSet.find(:all,:conditions=>["concept_set=?",concept_set_id]).map(&:concept_id)
  underlined_obs = Observation.find(:all,:conditions=>["value_coded IN (?) and person_id = ?",concept_ids,patient_id]).map(&:answer_string)
  end
end
