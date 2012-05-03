class EncounterType < ActiveRecord::Base
  set_table_name :encounter_type
  set_primary_key :encounter_type_id
  include Openmrs
  has_many :encounters, :foreign_key => :encounter_type, :conditions => {:voided => 0}
end
