class BillingController < ApplicationController
  def index
  end

  def create_billing

  end

  def list_billing
      billing_database = YAML::load(IO.read('config/database.yml'))['billing']['database']
      connection = ActiveRecord::Base.connection
      insurances = connection.select_all("SELECT c.insurance_id, h.name h_name,
                    c.name cover_name, c.insurance_plan_id
                    FROM #{billing_database}.health_insurances h
                    INNER JOIN #{billing_database}.health_insurance_plans c
                    USING(insurance_id) WHERE c.voided = 0 AND h.voided = 0")
      @insurances = {}
      (insurances || []).each do |i|
          @insurances[i['insurance_id']] = [] if @insurances[i['insurance_id']].blank?
          @insurances[i['insurance_id']] << {
              :cover_name     => i['cover_name'],
              :cover_id       => i['insurance_plan_id'],
              :insurance_id   => i['insurance_id'],
              :insurance_name => i['h_name']
          }
      end
  end

end
