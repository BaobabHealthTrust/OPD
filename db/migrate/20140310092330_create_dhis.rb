class CreateDhis < ActiveRecord::Migration
  def self.up
    create_table :dhis do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :dhis
  end
end
