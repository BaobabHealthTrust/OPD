class PropertiesController < GenericPropertiesController
  def create_dde_properties
    dde_status = params[:dde_status]
    if dde_status.squish.downcase == 'yes'
      dde_status = 'ON'
    else
      dde_status = 'OFF'
    end

    ActiveRecord::Base.transaction do
      global_property_dde_status = GlobalProperty.find_by_property('dde.status') || GlobalProperty.new()
      global_property_dde_status.property = 'dde.status'
      global_property_dde_status.property_value = dde_status
      global_property_dde_status.save

      if (dde_status == 'ON') #Do this part only when DDE is activated
        global_property_dde_address = GlobalProperty.find_by_property('dde.address') || GlobalProperty.new()
        global_property_dde_address.property = 'dde.address'
        global_property_dde_address.property_value = params[:dde_address]
        global_property_dde_address.save

        global_property_dde_port = GlobalProperty.find_by_property('dde.port') || GlobalProperty.new()
        global_property_dde_port.property = 'dde.port'
        global_property_dde_port.property_value = params[:dde_port]
        global_property_dde_port.save

        global_property_dde_username = GlobalProperty.find_by_property('dde.username') || GlobalProperty.new()
        global_property_dde_username.property = 'dde.username'
        global_property_dde_username.property_value = params[:dde_username]
        global_property_dde_username.save

        global_property_dde_password = GlobalProperty.find_by_property('dde.password') || GlobalProperty.new()
        global_property_dde_password.property = 'dde.password'
        global_property_dde_password.property_value = params[:dde_password]
        global_property_dde_password.save
      end

    end

    if (dde_status == 'ON')
      site_code = PatientIdentifier.site_prefix
      data = {
        "username" => "#{params[:dde_username]}",
        "password"  => "#{params[:dde_password]}",
        "site_code" => site_code,
        "application" =>"ART",
        "description" => "DDE user in an ART app"
      }
      dde_token = PatientService.add_dde_user(data)
      if dde_token.blank?
        flash[:notice] = "Failed to save your user."
        redirect_to("/properties/dde_properties_menu") and return
      end
      session[:dde_token] = dde_token unless dde_token.blank?
    end

    redirect_to("/clinic") and return
  end
end
