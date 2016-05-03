class CreateProgramEcounters < ActiveRecord::Migration
  def self.up
    create_table :program_ecounters, :primary_key => :program_encounter_id do |t|
      t.integer :encounter_id
      t.integer :program_id
      t.timestamps
    end
  end

  def self.down
    drop_table :program_ecounters
  end
end
