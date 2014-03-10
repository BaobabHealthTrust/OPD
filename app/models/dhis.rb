class Dhis < ActiveRecord::Base
	attr_accessor :start_date, :end_date
	
	def initialize(start_date, end_date)
		@start_date = start_date
		@end_date = "#{end_date} 23:59:59"
	end
	
end
