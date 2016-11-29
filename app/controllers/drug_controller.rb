class DrugController < GenericDrugController

  def new_create_new_products_delivery
    params[:obs].each { |ob_variations|

      drug_id = Drug.find_by_name(ob_variations[0]).id #rescue (raise "Missing drug #{ob_variations[0]}".to_s)

      ob_variations[1].each { |delivered|

        delivery_date = params[:delivery_date].to_date
        barcode = params[:identifier]

        number_of_tins = delivered["expire_amount"].to_f
        number_of_pills_per_tin = delivered["amount"].to_f

        expiry_date = delivered["date"].sub(/^\d+/, "01").to_date.end_of_month rescue
        (raise "Invalid Date #{delivered["date"]}".to_s) rescue Date.today
        number_of_pills = (number_of_tins * number_of_pills_per_tin)
        next if number_of_pills == 0

        Pharmacy.new_delivery(drug_id, number_of_pills, delivery_date, nil, expiry_date, barcode, nil, number_of_pills_per_tin)
      }
    }

    redirect_to "/clinic"
  end
  
end
