class CreateTemperatureRecords < ActiveRecord::Migration
  def self.up
    create_table :temperature_records do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :temperature_records
  end
end
