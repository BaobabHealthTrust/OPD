class UserActivation < ActiveRecord::Base
  set_table_name :user_activation
  belongs_to :user
end
