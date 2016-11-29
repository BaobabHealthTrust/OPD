class GenericDrugController < ApplicationController

  def name
    @names = Drug.find(:all,:conditions =>["name LIKE ?","%" + params[:search_string] + "%"]).collect{|drug| drug.name}
    render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"
  end

  def delivery
    @drugs = Drug.find(:all).map{|d|d.name}.compact.sort rescue []
  end

  def create_stock
    obs = params[:observations]
    delivery_date = obs[0]['value_datetime']
    expiry_date = obs[1]['value_datetime']
    drug_id = Drug.find_by_name(params[:drug_name]).id
    number_of_tins = params[:number_of_tins].to_f
    number_of_pills_per_tin = params[:number_of_pills_per_tin].to_f
    number_of_pills = (number_of_tins * number_of_pills_per_tin)
    barcode = params[:identifier]
    Pharmacy.new_delivery(drug_id,number_of_pills,delivery_date,nil,expiry_date,barcode)
    #add a notice
    #flash[:notice] = "#{params[:drug_name]} successfully entered"
    redirect_to "/clinic"   # /management"
  end

  def edit_stock
    if request.method == :post
      obs = params[:observations]
      edit_reason = obs[0]['value_coded_or_text']
      encounter_datetime = obs[1]['value_datetime']
      drug_id = Drug.find_by_name(params[:drug_name]).id
      pills = (params[:number_of_pills_per_tin].to_i * params[:number_of_tins].to_i)
      date = encounter_datetime || Date.today 

      if edit_reason == 'Receipts'
        expiry_date = obs[2]['value_datetime'].to_date
        Pharmacy.new_delivery(drug_id,pills,date,nil,expiry_date,edit_reason)
      else
        Pharmacy.drug_dispensed_stock_adjustment(drug_id,pills,date,edit_reason)
      end
      #flash[:notice] = "#{params[:drug_name]} successfully edited"
      redirect_to "/clinic"   # /management"
    end
  end

  def verification
    obs = params[:observations]
    edit_reason = obs[0]['value_coded_or_text']
    encounter_datetime = obs[0]['value_datetime']
    drug_id = Drug.find_by_name(params[:drug_name]).id
    pills = (params[:number_of_pills_per_tin].to_i * params[:number_of_tins].to_i)
    date = encounter_datetime || Date.today
    Pharmacy.verified_stock(drug_id,date,pills) 
    redirect_to "/clinic"   # /management"
  end

  def stock_report
    @start_date = params[:start_date].to_date
    @end_date = params[:end_date].to_date
    
    #TODO
#need to redo the SQL query
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    new_deliveries = Pharmacy.active.find(:all,
      :conditions =>["pharmacy_encounter_type=?",encounter_type],
      :order => "encounter_date DESC,date_created DESC")
    
    current_stock = {}
    new_deliveries.each{|delivery|
      current_stock[delivery.drug_id] = delivery if current_stock[delivery.drug_id].blank?
    }

    @stock = {}
    current_stock.each{|delivery_id , delivery|
      first_date = Pharmacy.active.find(:first,:conditions =>["drug_id =?",
                   delivery.drug_id],:order => "encounter_date").encounter_date.to_date rescue nil
      next if first_date.blank?
      next if first_date > @end_date

      start_date = @start_date
      end_date = @end_date
                   
      drug = Drug.find(delivery.drug_id)
      drug_name = drug.name
      @stock[drug_name] = {"confirmed_closing" => 0,"dispensed" => 0,"current_stock" => 0 ,
        "confirmed_opening" => 0, "start_date" => start_date , "end_date" => end_date,
        "relocated" => 0, "receipts" => 0,"expected" => 0}
      @stock[drug_name]["dispensed"] = Pharmacy.dispensed_drugs_since(drug.id,start_date,end_date)
      @stock[drug_name]["confirmed_opening"] = Pharmacy.verify_stock_count(drug.id,start_date,start_date)
      @stock[drug_name]["confirmed_closing"] = Pharmacy.verify_stock_count(drug.id,start_date,end_date)
      @stock[drug_name]["current_stock"] = Pharmacy.current_stock_as_from(drug.id,start_date,end_date)
      @stock[drug_name]["relocated"] = Pharmacy.relocated(drug.id,start_date,end_date)
      @stock[drug_name]["receipts"] = Pharmacy.receipts(drug.id,start_date,end_date)
      @stock[drug_name]["expected"] = Pharmacy.expected(drug.id,start_date,end_date)
    }    

  end

  def date_select
    @goto = params[:goto]
    @goto = 'stock_report' if @goto.blank?
  end

  def print_barcode
    if request.post?
      print_and_redirect("/drug/print?drug_id=#{params[:drug_id]}&quantity=#{params[:pill_count]}", "/drug/print_barcode")
    else
      @drugs = Drug.find(:all,:conditions =>["name IS NOT NULL"])
    end
  end
  
  def print
      pill_count = params[:quantity]
      drug = Drug.find(params[:drug_id])
      drug_name = drug.name
      drug_name1=""
      drug_name2=""
      drug_quantity = pill_count
      drug_barcode = "#{drug.id}-#{drug_quantity}"
      drug_string_length =drug_name.length

      if drug_name.length > 27
        drug_name1 = drug_name[0..25]
        drug_name2 = drug_name[26..-1]
      end

      if drug_string_length <= 27
        label = ZebraPrinter::StandardLabel.new
        label.draw_text("#{drug_name}", 40, 30, 0, 2, 2, 2, false)
        label.draw_text("Quantity: #{drug_quantity}", 40, 80, 0, 2, 2, 2,false)
        label.draw_barcode(40, 130, 0, 1, 5, 15, 120,true, "#{drug_barcode}")
      else
        label = ZebraPrinter::StandardLabel.new
        label.draw_text("#{drug_name1}", 40, 30, 0, 2, 2, 2, false)
        label.draw_text("#{drug_name2}", 40, 80, 0, 2, 2, 2, false)
        label.draw_text("Quantity: #{drug_quantity}", 40, 130, 0, 2, 2, 2,false)
        label.draw_barcode(40, 180, 0, 1, 5, 15, 100,true, "#{drug_barcode}")
      end
      send_data(label.print(1),:type=>"application/label; charset=utf-8", :stream=> false, :filename=>"#{drug_barcode}.lbl", :disposition => "inline")
  end

  def expiring
    @start_date = params[:start_date].to_date
    @end_date = params[:end_date].to_date
    @expiring_drugs = Pharmacy.expiring_drugs(@start_date,@end_date)
    render :layout => "menu"
  end
  
  def removed_from_shelves
    @start_date = params[:start_date].to_date
    @end_date = params[:end_date].to_date
    @drugs_removed = Pharmacy.removed_from_shelves(@start_date,@end_date)
    render :layout => "menu"
  end

  def available_name    
    ids = Pharmacy.active.find(:all).collect{|p|p.drug_id} rescue []
    @names = Drug.find(:all,:conditions =>["name LIKE ? AND drug_id IN (?)","%" + 
          params[:search_string] + "%", ids]).collect{|drug| drug.name}
    render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"
  end

  def receive_products
    @drugs = [""]

    drugs = opd_drugs
    drugs.each do |drug|
      @drugs << drug.name.squish
    end
    @drugs = [""] + opd_drugs.collect{|d|d.name}.sort
    #@drugs = ["", "Triomune-40", "d4T (Stavudine 30mg tablet)", "d4T (Stavudine 40mg tablet)", "DDI (Didanosine 125mg tablet)"]
  end

  def receive_products_main
    #raise params.inspect
    @delivery_date = params[:observations].first["value_datetime"]
    @drugs = params[:drug_name]
    drugs = opd_drugs
    @formatted = drugs.map(&:name)
    @drug_short_names = {} #regimen_name_map
    @drug_cms_names = {}
    @drug_cms_packsizes = {}

    drugs.each do |drug|
      drug_name = drug.name
      @drug_cms_names[drug_name] = drug.name
      @drug_cms_packsizes[drug_name] = ""#drug.pack_size
      @drug_short_names[drug_name] = "#{drug_name} #{drug.dose_strength} #{drug.units}"
    end

    @list = []
    @expiring = {}
    @formatted.each { |drug|
      @drugs.each { |received|
        if drug == received
          @list << drug
          @expiring["#{drug}"] = calculate_dispensed("#{drug}", @delivery_date)
        end
      }
    }
  end

  def relocate_products

  end

  def mark_loss_damage_of_products
    
  end

  def pull_receipt_drugs

    data = {}

    Pharmacy.active.find_all_by_value_text(params[:barcode]).each { |entry|

      drug = Drug.find(entry.drug_id).name
      qty_size = entry.pack_size.blank? ? 60 : entry.pack_size.to_i

      data[drug] = {} if data[drug].blank?
      data[drug][qty_size] = {} if data[drug][qty_size].blank?
      data[drug][qty_size]["tins"] = (entry.value_numeric.to_i/qty_size).round
      data[drug][qty_size]["pack_size"] = qty_size
      data[drug][qty_size]["id"] = entry.id
    }

    render :text => data.to_json
  end

  def void

    user_id = current_user.user_id
    delivery = Pharmacy.find(params[:id])
    delivery.voided = 1
    delivery.void_reason = params[:reason]
    delivery.date_voided = (session[:datetime].to_date rescue Date.today)
    delivery.changed_by = user_id
    delivery.save
    render :text => "Done".to_json
  end

  def opd_drugs
    arv_concept_ids = MedicationService.arv_drugs.map(&:concept_id)
    non_art_drugs = Drug.find(:all, :conditions => ["concept_id NOT IN (?)", arv_concept_ids], :limit => 20)
    return non_art_drugs
  end

  def calculate_dispensed(drug_name, delivery_date)

    drug_id = Drug.find_by_name(drug_name).id
    current_stock = Pharmacy.current_stock_as_from(drug_id, Pharmacy.first_delivery_date(drug_id), delivery_date.to_date)

    expiry = 0
    Pharmacy.currently_expiring_drugs(delivery_date.to_date, drug_id).each { |stock|
      #raise stock[1].to_yaml
      expiry += stock[1]["delivered_stock"]

    }
    if current_stock > 0 and current_stock <= expiry
      expiry = current_stock
    elsif current_stock > expiry
      expiry = expiry
    else
      expiry = 0
    end

    return expiry
  end
end
