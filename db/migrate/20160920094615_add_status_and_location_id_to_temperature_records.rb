class AddStatusAndLocationIdToTemperatureRecords < ActiveRecord::Migration
  def self.up
    add_column :temperature_records, :status, :string,:after => :temperature,
               :limit => 10
    add_column :temperature_records,:location_id,:string,:after => :status,
               :lmit => 20
  end

  def self.down
    remove_column :temperature_records, :status
    remove_column :temperature_records, :location_id
  end
end
