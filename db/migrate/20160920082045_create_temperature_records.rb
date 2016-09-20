class CreateTemperatureRecords < ActiveRecord::Migration
  def self.up
    create_table :temperature_records do |t|
      t.column :patient_identifier, :string, :limit => 35
      t.column :temperature, :decimal
      t.timestamps
    end
  end

  def self.down
    drop_table :temperature_records
  end
end
