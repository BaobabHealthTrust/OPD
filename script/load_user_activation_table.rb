
  def load_users
    UserActivation.delete_all

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
