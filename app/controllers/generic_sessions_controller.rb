class GenericSessionsController < ApplicationController
	skip_before_filter :authenticate_user!, :except => [:location, :update]
	skip_before_filter :location_required


	def new
	end


	def create
		if !params[:login_barcode].empty?

			begin
				user = User.decode_user_barcode(params[:login_barcode]) 
			rescue Exception => e

				flash[:notice] = "Invalid login barcode"
				redirect_to "/" and return
			end

				if user
					params[:login]		= user[0].username
					params[:password]	= user[0].password
					user = User.check(params[:login], params[:password])
					sign_in(:user, user) if user && user.status == 'active'
					authenticate_user! if user && user.status == 'active'
					session[:return_uri] = nil
				else
					redirect_to "/" and return
				end
		else
				#raise params[:password].inspect
				user = User.authenticate(params[:login], params[:password])
				sign_in(:user, user) if user && user.status == 'active'
				authenticate_user! if user && user.status == 'active' 
				session[:return_uri] = nil
				
		end


    if params[:passwordless]
		  user = User.find_by_username(SimpleEncryption.decrypt(params[:passwordless])) 
    else
		  user = User.authenticate(params[:login], params[:password])
    end
		sign_in(:user, user) if user && user.status == 'active'
		authenticate_user! if user && user.status == 'active' 
		session[:return_uri] = nil

		if user_signed_in?

		     	session[:username] = params[:login]
		      	session[:password] = params[:password]
				redirect_to '/clinic'
		else
				note_failed_signin
				@login = params[:login]
				render :action => 'new'
		end
	end

	# Form for entering the location information
	def location
		@login_wards = (CoreService.get_global_property_value('facility.login_wards')).split(',') rescue []
		if (CoreService.get_global_property_value('select_login_location').to_s == "true" rescue false)
			render :template => 'sessions/select_location'
		end
	end

	# Update the session with the location information
	def update    
		# First try by id, then by name
		location = Location.find(params[:location]) rescue nil
		location ||= Location.find_by_name(params[:location]) rescue nil
		#raise generic_locations.inspect

		valid_location = (generic_locations.include?(location.name)) rescue false
		
		unless location and valid_location

			flash[:error] = "Invalid workstation location"

			@login_wards = (CoreService.get_global_property_value('facility.login_wards')).split(',') rescue []
			if (CoreService.get_global_property_value('select_login_location').to_s == "true" rescue false)
				render :template => 'sessions/select_location'
			else
				render :action => 'location'
			end
			return    
		end
		self.current_location = location
		if use_user_selected_activities and not location.name.match(/Outpatient/i)
			redirect_to "/user/activities/#{current_user.id}"
		else
			redirect_to '/clinic'
		end
	end

	def destroy
		sign_out(current_user) if !current_user.blank?
		self.current_location = nil
    reset_session #Remove every session
		flash[:notice] = "You have been logged out."
		redirect_back_or_default('/')
	end



	protected
		# Track failed login attempts
		def note_failed_signin
			flash[:error] = "Invalid user name or password"
			logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
		end
end
