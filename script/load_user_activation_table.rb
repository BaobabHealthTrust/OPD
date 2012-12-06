
  def load_users
    ActiveRecord::Base.connection.execute <<EOF
      DROP TABLE IF EXISTS `user_activation`;
EOF

    ActiveRecord::Base.connection.execute <<EOF
      CREATE TABLE `user_activation` (                                                
        `id` int(11) NOT NULL AUTO_INCREMENT,                                         
        `user_id` int(11) NOT NULL,                                                   
        `system_id` varchar(45) NOT NULL,                                             
        `status` varchar(45) NOT NULL,                                                
        PRIMARY KEY (`id`),                                                           
        UNIQUE KEY `id_UNIQUE` (`id`)                                                 
      ) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=latin1; 
EOF


    (User.all || []).each do |user|
      activation = UserActivation.new()
      activation.user_id = user.id
      activation.system_id = "OPD"
      activation.status = "active"
      activation.save
      puts "................. #{user.username}"
    end
  end

  load_users
