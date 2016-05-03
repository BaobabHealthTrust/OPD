class ProgramEncounter < ActiveRecord::Base
  set_table_name "program_encounters"
  set_primary_key "program_encounter_id"

  include Openmrs
  belongs_to :encounter, :foreign_key => :encounter_id
  
end
