class ProgramEcounter < ActiveRecord::Base
  set_table_name "program_ecounters"
  set_primary_key "program_encounter_id"

  belongs_to :encounter, :foreign_key => :encounter_id
  
end
