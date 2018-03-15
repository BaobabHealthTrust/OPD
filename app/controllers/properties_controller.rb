class PropertiesController < GenericPropertiesController
  
  def dde_properties_menu
    @dde_status = GlobalProperty.find_by_property('dde.status').property_value rescue ""
    @dde_status = 'Yes' if @dde_status.match(/ON/i)
    @dde_status = 'No' if @dde_status.match(/OFF/i)
    @dde_address = GlobalProperty.find_by_property('dde.address').property_value rescue ""
    @dde_port = GlobalProperty.find_by_property('dde.port').property_value rescue ""
    @dde_username = GlobalProperty.find_by_property('dde.username').property_value rescue ""
    @dde_password = GlobalProperty.find_by_property('dde.password').property_value rescue ""
  end

  def portal_properties_menu
    @portal_status = GlobalProperty.find_by_property('use_portal').property_value rescue ""
    @portal_status = "Yes" if !@portal_status.blank? && @portal_status == "true"
    @portal_status = "No" if @portal_status.blank? ||  @portal_status == "false"

    @portal_address = GlobalProperty.find_by_property('portal_address').property_value rescue ""
    @portal_port = GlobalProperty.find_by_property('portal_port').property_value rescue ""
  end

  def create_portal_properties

    portal_status = GlobalProperty.find_by_property('use_portal') || GlobalProperty.new()
    portal_status.property = 'use_portal'
    portal_status.property_value = params[:portal_status] == "Yes" ? "true" : "false"
    portal_status.save

    portal_address = GlobalProperty.find_by_property('portal_address') || GlobalProperty.new()
    portal_address.property = 'portal_address'
    portal_address.property_value = params[:portal_address]
    portal_address.save

    portal_port = GlobalProperty.find_by_property('portal_port') || GlobalProperty.new()
    portal_port.property = 'portal_port'
    portal_port.property_value = params[:portal_port]
    portal_port.save

    flash[:notice] = "Portal configurations updated successfully"
    redirect_to("/clinic") and return
  end

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
        flash[:notice] = "DDE user already exists."
        redirect_to("/properties/dde_properties_menu") and return
      end
      session[:dde_token] = dde_token unless dde_token.blank?
    end

    redirect_to("/clinic") and return
  end
end
