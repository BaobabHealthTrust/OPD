class CreateDdeApplicationUsers < ActiveRecord::Migration
  def self.up
    create_table :dde_application_users, :id => false do |t|
      t.integer         :application_id,  :null =>  false
      t.integer         :program_id,      :null =>  false
      t.integer         :creator,         :null =>  false
      t.string          :username,        :null =>  false
      t.string          :password,        :null =>  false
      t.string          :ipaddress,       :null =>  false
      t.integer         :port,            :null =>  false
               
      t.timestamps
    end
		execute "ALTER TABLE `dde_application_users` CHANGE COLUMN `application_id` `application_id` INT(11) NOT NULL AUTO_INCREMENT, ADD PRIMARY KEY (`application_id`);"
  end

  def self.down
    drop_table :dde_application_users
  end
end
