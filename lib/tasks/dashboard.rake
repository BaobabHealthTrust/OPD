require "rest-client"
namespace :dashboard do
  desc "Pull data from openmrs and save to couch database"
  task :pull_data => :environment do
    configs = YAML.load_file("#{RAILS_ROOT}/config/couchdb.yml")[RAILS_ENV] rescue nil

    if configs.present?
      database = configs["database"]
      username = configs["username"]
      password = configs["password"]
      port = configs["port"]
      host = configs["host"]

      url = "http://#{username}:#{password}@#{host}:#{port}/#{database}"
      `curl -X PUT #{url}`
      `cd #{RAILS_ROOT}/db && curl -X PUT -d @couchdb_views.json #{url}/_design/query`

      cur_date = params[:date].to_date rescue Date.today

      #Usage:
      #{"key" => "api method to call"}
      data_sources = {
          "reported_cases" => "malaria_observations",
          "microscopy_orders" => "microscopy_orders",
          "microscopy_positives" => "microscopy_positives",
          "microscopy_negatives" => "microscopy_negatives",
          "microscopy_unknown" => "microscopy_unknown",
          "mRDT_orders" => "mRDT_orders",
          "mRDT_positives" => "mRDT_positives",
          "mRDT_negatives" => "mRDT_negatives",
          "mRDT_unknown" => "mRDT_unknown",
          "presumed_and_confirmed" => 'presumed_and_confirmed',
          "under_five_males" => "under_five_malaria_cases_male",
          "under_five_females" => "under_five_malaria_cases_female",
          "treated_negatives" => "treated_negatives",
          "all_dispensations" => "all_dispensations",
          "first_line_dispensations" => "first_line_dispensations",
          "malaria_in_pregnancy" => "malaria_in_pregnancy"
      }

      date_ranges = {
          "Today" => [cur_date, cur_date],
          "This Month" => [cur_date.beginning_of_month, cur_date.end_of_month],
          "This Quarter" => [cur_date.beginning_of_quarter, cur_date.end_of_quarter],
          "This Year" => [cur_date.beginning_of_year, cur_date.end_of_year]
      }

      results = {}

      date_ranges.each do |category, date_range|

        results[category] = {}
        treated_negatives = eval("API.treated_negatives('#{date_range[0].to_s}', '#{date_range[1].to_s}')")

        rptd = []
        total_reported = []
        total_treated_negatives = []
        rptd += eval("API.microscopy_positives('#{date_range[0].to_s}', '#{date_range[1].to_s}')")
        rptd += eval("API.mRDT_positives('#{date_range[0].to_s}', '#{date_range[1].to_s}')")
        rptd += eval("API.all_dispensations('#{date_range[0].to_s}', '#{date_range[1].to_s}')")
        rptd += eval("API.malaria_observations('#{date_range[0].to_s}', '#{date_range[1].to_s}')")

        counted = {}
        rptd.each do |m|
          id = m.person_id rescue m.patient_id
          i_date = m.obs_datetime rescue m.encounter_datetime
          counted[id] = {} if counted[id].blank?
          next if !counted[id][i_date.to_date].blank? #case already counted
          counted[id][i_date.to_date] = 1
          total_reported << (id.to_s + "_" + i_date.to_date.to_s)
        end

        if rptd.length > 0 && treated_negatives.length > 0
          treated_negatives.each do |m|
            id = m.person_id rescue m.patient_id
            i_date = m.obs_datetime rescue m.encounter_datetime
            counted[id] = {} if counted[id].blank?
            next if !counted[id][i_date.to_date].blank? #case already counted
            counted[id][i_date.to_date] = 1
            total_treated_negatives << (id.to_s + "_" + i_date.to_date.to_s)
          end
        end

        data_sources.each do |indicator, query|
          start = Time.now

					if indicator == "reported_cases"
              total_reported = total_reported - total_treated_negatives
							results[category][indicator] = total_reported.count
          elsif indicator == 'treated_negatives'
            results[category][indicator] =  total_treated_negatives.count
          elsif indicator == 'presumed_and_confirmed'
            results[category][indicator] == (total_reported - total_treated_negatives).count
					else
          		results[category][indicator] = eval("API.#{query}('#{date_range[0].to_s}', '#{date_range[1].to_s}').count")
					end
        end
      end

      results['dispensation_trends'] = API.dispensation_trends((cur_date - 1.year), cur_date)

      date = cur_date.to_date.strftime("%Y%m%d")
      data = {
          "type" => "PullTracker",
          "date" => date,
          "district_code" => configs['district_code'],
          "district_name" => configs['district_name'],
          "site_code" => configs['site_code'],
          "site_name" => configs['site_name'],
          "data" => results
      }

      info = JSON.parse(`curl -X GET http://#{username}:#{password}@#{host}:#{port}/#{database}/_design/query/_view/by_date?key=\\\"#{date}\\\"`)
      uuid = info['rows'].first['id'] rescue nil
      doc = JSON.parse(`curl -X GET http://#{username}:#{password}@#{host}:#{port}/#{database}/#{uuid}`) rescue nil

      if doc && !doc['date'].blank?
        doc['data'] = results
        RestClient.post("http://#{username}:#{password}@#{host}:#{port}/#{database}", doc.to_json, :content_type => "application/json")
      else
        url = "http://#{username}:#{password}@#{host}:#{port}/#{database}/"
        RestClient.post(url, data.to_json, :content_type => "application/json")
      end

      `curl -X POST  http://127.0.0.1:5984/_replicate -d '{"source":"#{url}","target":"#{configs['sync_url']}", "continuous":true}' -H "Content-Type: application/json"`

    end
  end
end
