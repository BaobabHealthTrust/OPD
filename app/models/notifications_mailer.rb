class NotificationsMailer < ActionMailer::Base
  def send_email
		recipients 'bartbaobab@gmail.com'
		from 'bartbaobab@gmail.com' 
		subject "OPD Test Email" 
		sent_on Time.now 
		body 'OPD is cool!!!'
  end    
end
