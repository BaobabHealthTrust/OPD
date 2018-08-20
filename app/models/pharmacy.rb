class Pharmacy < ActiveRecord::Base
  set_table_name "pharmacy_obs"
  set_primary_key "pharmacy_module_id"
  include Openmrs
  #before_create :update_stock_record

  named_scope :active, :conditions => ['voided = 0']

  def self.total_removed(drug_id , start_date = Date.today , end_date = Date.today)
    pharmacy_encounter_type = PharmacyEncounterType.find_by_name('Tins removed')

    self.active.find(:first,:select => "SUM(value_numeric) total_removed",
      :conditions => ["pharmacy_encounter_type = ? AND drug_id = ?
                      AND encounter_date >= ? AND encounter_date <= ?",
        pharmacy_encounter_type.id , drug_id , start_date , end_date],
      :group => "drug_id").total_removed.to_f rescue 0
  end

  def self.drug_dispensed_stock_adjustment(drug_id,quantity,encounter_date,reason = nil, expiring_units = nil)
    encounter_type = PharmacyEncounterType.find_by_name("Tins removed").id if encounter_type.blank?
    encounter =  self.new()
    encounter.pharmacy_encounter_type = encounter_type
    encounter.drug_id = drug_id
    encounter.encounter_date = encounter_date
    encounter.value_numeric = quantity.to_f
    encounter.expiring_units = expiring_units unless expiring_units.blank?
    encounter.value_text = reason unless reason.blank?
    encounter.save
    self.update_stock_record(drug_id, encounter_date)
    self.update_average_drug_consumption(drug_id)
  end

  def self.date_ranges(date)
    current_range =[]
    current_range << Report.cohort_range(date).last
    end_date = Report.cohort_range(Date.today).last
    while current_range.last < end_date
      current_range << Report.cohort_range(current_range.last + 1.day).last
    end
    current_range[1..-1] rescue nil
  end

  def Pharmacy.dispensed_drugs_since(drug_id, start_date = Date.today , end_date = Date.today)
    return 0 if start_date.blank? or end_date.blank?
    dispensed_encounter = EncounterType.find_by_name('DISPENSING')
    amount_dispensed_concept_id = ConceptName.find_by_name('AMOUNT DISPENSED').concept_id
    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00') rescue nil
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59') rescue nil

    Encounter.find(:first,:joins => "INNER JOIN obs USING(encounter_id)",
      :select => "SUM(value_numeric) total_dispensed" ,
      :conditions => ["concept_id = ? AND encounter_type = ?
                   AND obs_datetime >= ? AND obs_datetime <= ? AND value_drug = ? AND obs.voided=0",
        amount_dispensed_concept_id,dispensed_encounter.id,
        start_date,end_date,drug_id],
      :group => "value_drug").total_dispensed.to_f rescue 0
  end

  def Pharmacy.dispensed_drugs_to_date(drug_id)
    dispensed_encounter = EncounterType.find_by_name('DISPENSING')
    amount_dispensed_concept_id = ConceptName.find_by_name('AMOUNT DISPENSED').concept_id

    Encounter.find(:first,:joins => "INNER JOIN obs USING(encounter_id)",
      :select => "SUM(value_numeric) total_dispensed" ,
      :conditions => ["concept_id = ? AND encounter_type = ? AND value_drug = ? AND obs.voided=0",
        amount_dispensed_concept_id,dispensed_encounter.id,drug_id],
      :group => "value_drug").total_dispensed.to_f rescue 0
  end

  def self.current_stock(drug_id)
    self.current_stock_as_from(drug_id, self.first_delivery_date(drug_id), Date.today)
  end

  def self.current_stock_as_from(drug_id, start_date = Date.today, end_date = Date.today)
    total_delivered = self.total_delivered(drug_id, start_date, end_date)
    total_dispensed = self.dispensed_drugs_since(drug_id, start_date, end_date)
    total_removed = self.total_removed(drug_id, start_date, end_date)
    (total_delivered - (total_dispensed + total_removed))
  end

  def self.delivered(drug_id, start_date = Date.today, end_date = Date.today)

    return [] if drug_id.blank? || start_date.blank? || end_date.blank?

    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    return Pharmacy.all(
      :select => ["value_numeric, value_text, encounter_date AS value_date"],
      :conditions => ["pharmacy_encounter_type = ? AND (DATE(encounter_date) BETWEEN (?) AND (?)) AND drug_id = ?",
        encounter_type, start_date.to_date, end_date.to_date, drug_id
      ]).collect{|del| [del.value_numeric, del.value_date, del.value_text]}
  end

  def self.new_delivery(drug_id,pills,date = Date.today,encounter_type = nil,expiry_date = nil, barcode = nil, expiring_units = nil, pack_size = 60)
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id if encounter_type.blank?
    delivery =  self.new()
    delivery.pharmacy_encounter_type = encounter_type
    delivery.drug_id = drug_id
    delivery.encounter_date = date
    delivery.value_text = barcode
    delivery.pack_size = pack_size
    delivery.expiry_date = expiry_date unless expiry_date.blank?
    delivery.value_numeric = pills.to_f
    if expiring_units
      delivery.expiring_units = expiring_units
    end
    if expiry_date
      if expiry_date.to_date < Date.today
        delivery.voided = 1
        return delivery.save
      end
    end

    encounter_type = PharmacyEncounterType.find_by_name('Tins currently in stock').id
    auto_verified_encounter =  self.new()
    auto_verified_encounter.pharmacy_encounter_type = encounter_type
    auto_verified_encounter.drug_id = drug_id
    auto_verified_encounter.encounter_date = date
    auto_verified_encounter.pack_size = pack_size
    auto_verified_encounter.value_numeric = Pharmacy.latest_drug_stock(drug_id).to_f + pills.to_f
    auto_verified_encounter.value_text = 'Clinic'

    if expiring_units
      auto_verified_encounter.expiring_units = expiring_units
    end
    if expiry_date
      auto_verified_encounter.expiry_date = expiry_date
    end

    delivery.save
    auto_verified_encounter.save

    self.update_stock_record(drug_id, date) #Update stock record
    self.update_average_drug_consumption(drug_id)
    # raise delivery.to_yaml
  end

  def self.total_delivered(drug_id, start_date = Date.today ,end_date = Date.today)
    pharmacy_encounter_type = PharmacyEncounterType.find_by_name('New deliveries')

    self.active.find(:first,:select => "SUM(value_numeric) total_delivered",
      :conditions => ["pharmacy_encounter_type = ? AND drug_id = ?
                      AND encounter_date >= ? AND encounter_date <= ?",
        pharmacy_encounter_type.id , drug_id , start_date , end_date],
      :group => "drug_id").total_delivered.to_f rescue 0
  end

  def self.first_delivery_date(drug_id)
    encounter_type = PharmacyEncounterType.find_by_name("New deliveries").id
    Pharmacy.active.find(:first,:conditions => ["drug_id=? AND pharmacy_encounter_type=?",drug_id,encounter_type],
      :order => "encounter_date ASC,date_created ASC").encounter_date rescue nil
  end

  def self.expiring_drugs(start_date , end_date)
    pharmacy_encounter_type = PharmacyEncounterType.find_by_name('New deliveries')

    expiring_drugs = self.active.find(:all,
      :conditions => ["pharmacy_encounter_type = ?
                     AND expiry_date >= ? AND expiry_date <= ?",
        pharmacy_encounter_type.id , start_date , end_date])

    expiring_drugs_hash = {}
    (expiring_drugs || []).each do | expiring |
      current_stock = self.current_stock_as_from(expiring.drug_id , self.first_delivery_date(expiring.drug_id),expiring.encounter_date)
      next if current_stock <= 0
      expiring_drugs_hash["#{expiring.pharmacy_module_id}:#{Drug.find(expiring.drug_id).name}"] = {
        'delivered_stock' => expiring.value_numeric ,
        'date_delivered' => expiring.encounter_date ,
        'expiry_date' => expiring.expiry_date ,
        'current_stock' => current_stock
      }
    end
    expiring_drugs_hash
  end

  def self.currently_expiring_drugs(start_date, drug_id)
    pharmacy_encounter_type = PharmacyEncounterType.find_by_name('New deliveries')

    end_date = start_date + 3.months
    expiring_drugs = self.active.find(:all,
      :conditions => ["pharmacy_encounter_type = ?
                     AND expiry_date >= ? AND expiry_date <= ? AND drug_id = ?",
        pharmacy_encounter_type.id , start_date , end_date, drug_id])

    expiring_drugs_hash = {}
    (expiring_drugs || []).each do | expiring |
      current_stock = self.current_stock_as_from(expiring.drug_id , self.first_delivery_date(expiring.drug_id),expiring.encounter_date)
      next if current_stock <= 0
      expiring_drugs_hash["#{expiring.pharmacy_module_id}:#{Drug.find(expiring.drug_id).name}"] = {
        'delivered_stock' => expiring.value_numeric ,
        'date_delivered' => expiring.encounter_date ,
        'expiry_date' => expiring.expiry_date ,
        'current_stock' => current_stock
      }
    end
    expiring_drugs_hash
  end

  def self.removed_from_shelves(start_date , end_date)
    pharmacy_encounter_type = PharmacyEncounterType.find_by_name('Tins removed')

    removed_from_shelves = self.active.find(:all,
      :conditions => ["pharmacy_encounter_type = ?
                     AND encounter_date >= ? AND encounter_date <= ?",
        pharmacy_encounter_type.id , start_date , end_date])

    removed_from_shelves_hash = {}
    (removed_from_shelves || []).each do | removed |
      current_stock = self.current_stock_as_from(removed.drug_id , self.first_delivery_date(removed.drug_id),end_date)
      removed_from_shelves_hash["#{removed.pharmacy_module_id}:#{Drug.find(removed.drug_id).name}"] = {
        'amount_removed' => removed.value_numeric ,
        'date_removed' => removed.encounter_date ,
        'reason' => removed.value_text ,
        'current_stock' => current_stock
      }
    end
    removed_from_shelves_hash
  end

  def Pharmacy.prescribed_drugs_since(drug_id,start_date,end_date = Date.today)
    treatment_encounter_type = EncounterType.find_by_name('TREATMENT')
    drug_orders = DrugOrder.find(:all,
      :joins => "INNER JOIN orders ON drug_order.order_id = orders.order_id
                                 INNER JOIN encounter e ON e.encounter_id = orders.encounter_id",
      :conditions => ["encounter_type = ? AND drug_inventory_id = ?
                                 AND encounter_datetime >= ? AND encounter_datetime <= ?" ,
        treatment_encounter_type.id , drug_id ,
        start_date.to_date.strftime('%Y-%m-%d 00:00:00') ,
        end_date.to_date.strftime('%Y-%m-%d 23:59:59') ])

    return 0 if drug_orders.blank?
    prescribed_drugs = 0
    (drug_orders).each do | drug_order |
      prescribed_drugs += (drug_order.duration * drug_order.equivalent_daily_dose) rescue prescribed_drugs
    end
    prescribed_drugs
  end

  def self.total_drug_prescription(drug_id,start_date,end_date = Date.today)
    drug_order = OrderType.find_by_name("Drug Order")
    drug_order_type_id = drug_order.id
    treatment_encounter_type = EncounterType.find_by_name("TREATMENT")
    treatment_encounter_type_id = treatment_encounter_type.id

    total_prescribed = ActiveRecord::Base.connection.select_all("SELECT SUM((ABS(DATEDIFF(o.auto_expire_date, o.start_date)) * do.equivalent_daily_dose)) as total,
        d.name as DrugName FROM encounter e INNER JOIN encounter_type et
        ON e.encounter_type = et.encounter_type_id INNER JOIN orders o
        ON e.encounter_id = o.encounter_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{treatment_encounter_type_id} AND do.drug_inventory_id = #{drug_id}
        AND o.order_type_id = #{drug_order_type_id} AND e.encounter_datetime >= \"#{start_date} 00:00:00\"
        AND e.encounter_datetime <= \"#{end_date} 23:59:59\"
        AND e.voided=0 GROUP BY do.drug_inventory_id").first["total"] rescue 0
    return total_prescribed
  end

  #new code from Bart 10.2

  def self.alter(drug, quantity, date = nil , reason = nil, auth_code = nil, receiving_facility=nil)
    encounter_type = PharmacyEncounterType.find_by_name("Tins removed").id
    current_stock =  Pharmacy.new()
    current_stock.pharmacy_encounter_type = encounter_type
    current_stock.drug_id = drug.id
    current_stock.encounter_date = date
    current_stock.value_numeric = quantity.to_f
    current_stock.value_text = reason
    current_stock.void_reason = "auth_code:" + auth_code + (receiving_facility.blank? ? "" : ("|relocated_to:"+receiving_facility))
    current_stock.save
    self.update_stock_record(drug.id, date)
    self.update_average_drug_consumption(drug.id)
  end

  def self.relocated(drug_id,start_date,end_date = Date.today)
    encounter_type = PharmacyEncounterType.find_by_name('Tins removed').id
    result = ActiveRecord::Base.connection.select_value <<EOF
SELECT sum(value_numeric) FROM pharmacy_obs p
INNER JOIN pharmacy_encounter_type t ON t.pharmacy_encounter_type_id = p.pharmacy_encounter_type
AND pharmacy_encounter_type_id = #{encounter_type}
WHERE p.voided=0 AND drug_id=#{drug_id}
AND p.encounter_date >='#{start_date.to_date.strftime('%Y-%m-%d 00:00:00')}'
AND p.encounter_date <='#{end_date.to_date.strftime('%Y-%m-%d 23:59:59')}'
GROUP BY drug_id ORDER BY encounter_date
EOF

    result.to_i rescue 0
  end

  def self.receipts(drug_id,start_date,end_date = Date.today)
    encounter_type = PharmacyEncounterType.find_by_name('New deliveries').id
    result = ActiveRecord::Base.connection.select_value <<EOF
SELECT sum(value_numeric) FROM pharmacy_obs p
INNER JOIN pharmacy_encounter_type t ON t.pharmacy_encounter_type_id = p.pharmacy_encounter_type
AND pharmacy_encounter_type_id = #{encounter_type}
WHERE p.voided=0 AND drug_id=#{drug_id}
AND p.encounter_date >='#{start_date.to_date.strftime('%Y-%m-%d 00:00:00')}'
AND p.encounter_date <='#{end_date.to_date.strftime('%Y-%m-%d 23:59:59')}'
GROUP BY drug_id ORDER BY encounter_date
EOF

    result.to_i rescue 0
  end

  def self.expected(drug_id,start_date,end_date)
    encounter_type_ids = PharmacyEncounterType.find(:all).collect{|e|e.id}
    start_date = Pharmacy.active.find(:first,:conditions =>["pharmacy_encounter_type IN (?)",
        encounter_type_ids],:order =>'encounter_date ASC,date_created ASC').encounter_date rescue start_date

    dispensed_drugs = self.dispensed_drugs_since(drug_id,start_date,end_date)
    relocated = self.relocated(drug_id,start_date,end_date)
    receipts = self.receipts(drug_id,start_date,end_date)

    return (receipts - (dispensed_drugs + relocated))
  end

  def self.verify_closing_stock_count(drug_id,start_date,end_date, type=nil, with_date=false)
    if !type.blank?
      condition = " AND value_text = '#{type}'"
    end
    encounter_type_id = PharmacyEncounterType.find_by_name('Tins currently in stock').id
    stock = Pharmacy.active.find(:first,
      :conditions =>["pharmacy_encounter_type = ? AND  encounter_date > ? AND encounter_date <= ?
                        AND drug_id = ? #{condition}",
        encounter_type_id, start_date, end_date, drug_id],
      :order =>'encounter_date DESC,date_created DESC')

    if with_date
      return [stock.value_numeric, stock.encounter_date] rescue [0, nil]
    else
      return stock.value_numeric rescue 0
    end

  end

  def self.verify_stock_count(drug_id,start_date,end_date, type=nil)
    if !type.blank?
      condition = " AND value_text = '#{type}'"
    end
    encounter_type_id = PharmacyEncounterType.find_by_name('Tins currently in stock').id
    start_date = Pharmacy.active.find(:first,
      :conditions =>["pharmacy_encounter_type = ? AND encounter_date <= ? AND drug_id = ? AND #{condition}",
        encounter_type_id, start_date,drug_id],
      :order =>'encounter_date DESC,date_created DESC').value_numeric rescue 0
    #raise start_date.to_yaml
  end

  def self.verified_stock(drug_id,date,pills, earliest_expiry=nil, units=nil, type=nil, pack_size = nil)
    encounter_type = PharmacyEncounterType.find_by_name('Tins currently in stock').id
    encounter =  self.new()
    encounter.pharmacy_encounter_type = encounter_type
    encounter.drug_id = drug_id
    encounter.encounter_date = date
    encounter.pack_size = pack_size
    encounter.value_numeric = pills.to_f
    if ! earliest_expiry.blank?
      encounter.expiry_date = earliest_expiry
    end
    if ! units.blank?
      encounter.expiring_units = units
    end
    if ! type.blank?
      encounter.value_text = type
    end
    encounter.save
    self.update_stock_record(drug_id, date)
    self.update_average_drug_consumption(drug_id)
  end

  def self.current_stock_after_dispensation(drug_id, start_date, end_date = Date.today)
    total_physical_count = self.latest_physical_counted(drug_id, start_date)#self.total_physically_counted(drug_id, start_date, end_date)
    total_dispensed = self.dispensed_drugs_since(drug_id, start_date, end_date)
    total_removed = self.total_removed(drug_id, start_date, end_date)
    (total_physical_count - (total_dispensed + total_removed))
  end

  def self.total_physically_counted(drug_id, start_date ,end_date = Date.today)
    pharmacy_encounter_type = PharmacyEncounterType.find_by_name('Tins currently in stock')

    latest_supervision_type = Pharmacy.find_by_sql(
      "SELECT * FROM pharmacy_obs p WHERE p.drug_id = #{drug_id}
        AND p.pharmacy_module_id = (
              SELECT MAX(pharmacy_module_id) FROM pharmacy_obs t
              WHERE t.encounter_date = p.encounter_date AND t.drug_id = p.drug_id
              AND t.pharmacy_encounter_type = p.pharmacy_encounter_type
              AND t.encounter_date >= '#{start_date}' AND t.encounter_date <= '#{end_date}'
            )
        AND p.encounter_date = (
            SELECT max(encounter_date) from pharmacy_obs t2
            where t2.encounter_date = p.encounter_date AND t2.drug_id = p.drug_id
            AND t2.pharmacy_encounter_type = p.pharmacy_encounter_type
            AND t2.encounter_date >= '#{start_date}' AND t2.encounter_date <= '#{end_date}'
          ) LIMIT 1;"
    ).last.value_text rescue nil #To avoid double count of clinic and supervision data

    self.active.find(:first,:select => "SUM(value_numeric) total_physical_count",
      :conditions => ["pharmacy_encounter_type = ? AND drug_id = ?
                      AND encounter_date >= ? AND encounter_date <= ? AND value_text = '#{latest_supervision_type}'",
        pharmacy_encounter_type.id , drug_id , start_date , end_date],
      :group => "drug_id").total_physical_count.to_f rescue 0
  end

  def self.latest_physical_counted(drug_id, latest_date)
    pharmacy_encounter_type = PharmacyEncounterType.find_by_name('Tins currently in stock')

    latest_physical_count = Pharmacy.find_by_sql(
      "SELECT * FROM pharmacy_obs p WHERE p.drug_id = #{drug_id}
        AND p.pharmacy_module_id = (
              SELECT MAX(pharmacy_module_id) FROM pharmacy_obs t
              WHERE t.encounter_date = p.encounter_date AND t.drug_id = p.drug_id
              AND t.pharmacy_encounter_type = #{pharmacy_encounter_type.id}
              AND t.encounter_date >= '#{latest_date}' AND t.encounter_date <= '#{latest_date}'
            )
        AND p.encounter_date = (
            SELECT max(encounter_date) from pharmacy_obs t2
            where t2.encounter_date = p.encounter_date AND t2.drug_id = p.drug_id
            AND t2.pharmacy_encounter_type = #{pharmacy_encounter_type.id}
            AND t2.encounter_date >= '#{latest_date}' AND t2.encounter_date <= '#{latest_date}'
          ) LIMIT 1;"
    ).last.value_numeric rescue 0 #To avoid double count of clinic and supervision data

    return latest_physical_count
  end

  def self.last_physical_count(drug_id, value_text='Supervision')
    pharmacy_encounter_type = PharmacyEncounterType.find_by_name('Tins currently in stock')
    last_physical_count = Pharmacy.find_by_sql(
      "SELECT * FROM pharmacy_obs p WHERE p.drug_id = #{drug_id}
        AND p.pharmacy_encounter_type = #{pharmacy_encounter_type.id} AND
        p.value_text = '#{value_text}' AND
      DATE(p.encounter_date) = (
              SELECT MAX(DATE(t.encounter_date)) FROM pharmacy_obs t
              WHERE t.encounter_date = p.encounter_date AND t.drug_id = p.drug_id
              AND t.pharmacy_encounter_type = #{pharmacy_encounter_type.id}
              AND t.value_text = '#{value_text}'
            )"
    ).last.value_numeric rescue 0

    return last_physical_count
  end

  def self.current_drug_stock(drug_id)
    #This method gives the current drug stock after latest date of physical count
    # and all dispensation of that particular drug from the latest date of physical count

    pharmacy_encounter_type = PharmacyEncounterType.find_by_name('Tins currently in stock')

    last_physical_count_enc_date = Pharmacy.find_by_sql(
      "SELECT * from pharmacy_obs WHERE
           drug_id = #{drug_id} AND pharmacy_encounter_type = #{pharmacy_encounter_type.id} AND
           DATE(encounter_date) = (
            SELECT MAX(DATE(encounter_date)) FROM pharmacy_obs
            WHERE drug_id =#{drug_id} AND pharmacy_encounter_type = #{pharmacy_encounter_type.id}
          ) LIMIT 1;"
    ).last.encounter_date rescue nil
    #total_physical_count = self.total_physically_counted(drug_id, last_physical_count_enc_date)
    total_physical_count = self.latest_physical_counted(drug_id, last_physical_count_enc_date) #Created a method for pulling latest drug total supervised
    total_dispensed = self.dispensed_drugs_since(drug_id, last_physical_count_enc_date)
    total_removed = self.total_removed(drug_id, last_physical_count_enc_date)
    (total_physical_count - (total_dispensed + total_removed))
  end

  def self.pack_size(drug_id)
    return DrugCms.find(drug_id).pack_size rescue 60
    pharmacy_encounter_type = PharmacyEncounterType.find_by_name('Tins currently in stock')
    drug_pack_size = Pharmacy.find_by_sql(
      "SELECT * from pharmacy_obs WHERE drug_id = #{drug_id} AND
          pharmacy_encounter_type = #{pharmacy_encounter_type.id} AND
           DATE(encounter_date) = (
            SELECT MAX(DATE(encounter_date)) FROM pharmacy_obs
            WHERE drug_id =#{drug_id} AND pharmacy_encounter_type = #{pharmacy_encounter_type.id}
          ) LIMIT 1;"
    ).last.pack_size rescue 60 #if the pack size is not recorded then assume 60 is the pack size. Most drugs come in 60s
    drug_pack_size = 60 if drug_pack_size.blank?
    return drug_pack_size
  end

  def self.update_stock_record(drug_id, encounter_date)
    #Added these methods for the purpose of speed
    edited_stock_encounter_id = PharmacyEncounterType.find_by_name('Edited stock').pharmacy_encounter_type_id
    current_drug_stock = Pharmacy.current_drug_stock(drug_id)

    pharmacy_obs = Pharmacy.find(:last, :conditions => ["pharmacy_encounter_type =? AND drug_id =? AND
        value_text = ?", edited_stock_encounter_id, drug_id, 'Current Stock'])

    if pharmacy_obs.blank?
      pharmacy_obs =  Pharmacy.new()
      pharmacy_obs.pharmacy_encounter_type = edited_stock_encounter_id
      pharmacy_obs.drug_id = drug_id
      pharmacy_obs.value_text = 'Current Stock'
    end

    pharmacy_obs.encounter_date = encounter_date
    pharmacy_obs.value_numeric = current_drug_stock.to_i
    pharmacy_obs.save

  end

  def self.update_average_drug_consumption(drug_id)
    #Added these methods for the purpose of speed
    past_ninety_days_date = (Date.today - 90.days)
    total_drug_dispensations_within_ninety_days = Pharmacy.dispensed_drugs_since(drug_id, past_ninety_days_date) #within 90 days
    total_days = (Date.today - past_ninety_days_date).to_i #Difference in days between two dates.
    consumption_rate = (total_drug_dispensations_within_ninety_days/total_days)#Three months average consumption

    edited_stock_encounter_id = PharmacyEncounterType.find_by_name('Edited stock').pharmacy_encounter_type_id
    pharmacy_obs = Pharmacy.find(:last, :conditions => ["pharmacy_encounter_type =? AND drug_id =? AND
        value_text = ?", edited_stock_encounter_id, drug_id, 'Drug Rate'])

    if pharmacy_obs.blank?
      pharmacy_obs =  Pharmacy.new()
      pharmacy_obs.pharmacy_encounter_type = edited_stock_encounter_id
      pharmacy_obs.drug_id = drug_id
      pharmacy_obs.value_text = 'Drug Rate'
    end

    pharmacy_obs.encounter_date = Date.today
    pharmacy_obs.value_numeric = consumption_rate
    pharmacy_obs.save
  end

  def self.average_drug_consumption(drug_id)
    #Added these methods for the purpose of speed
    edited_stock_encounter_id = PharmacyEncounterType.find_by_name('Edited stock').pharmacy_encounter_type_id
    pharmacy_obs = Pharmacy.find(:last, :conditions => ["pharmacy_encounter_type =? AND drug_id =? AND
        value_text = ?", edited_stock_encounter_id, drug_id, 'Drug Rate'])
    return pharmacy_obs.value_numeric unless pharmacy_obs.blank?
    return 0
  end

  def self.latest_drug_stock(drug_id, date=Date.today)
    #Added these methods for the purpose of speed
    edited_stock_encounter_id = PharmacyEncounterType.find_by_name('Edited stock').pharmacy_encounter_type_id
    pharmacy_obs = Pharmacy.find(:last, :conditions => ["pharmacy_encounter_type =? AND drug_id =? AND
        value_text = ? AND encounter_date <= ?", edited_stock_encounter_id, drug_id, 'Current Stock', date.to_date])
    return pharmacy_obs.value_numeric unless pharmacy_obs.blank?
    return 0
  end

  def self.latest_drug_rate(drug_id, date=Date.today)
    #Added these methods for the purpose of speed
    edited_stock_encounter_id = PharmacyEncounterType.find_by_name('Edited stock').pharmacy_encounter_type_id
    pharmacy_obs = Pharmacy.find(:last, :conditions => ["pharmacy_encounter_type =? AND drug_id =? AND
        value_text = ? AND encounter_date <= ?", edited_stock_encounter_id, drug_id, 'Drug Rate', date.to_date])
    return pharmacy_obs.value_numeric unless pharmacy_obs.blank?
    return 0
  end

  def self.physical_verified_stock(drug_id,date)
    encounter_type = PharmacyEncounterType.find_by_name('Tins currently in stock').id
    verified_stock = self.find_by_sql("SELECT * FROM pharmacy_obs t
      WHERE t.encounter_date = '#{date}' AND drug_id = #{drug_id} AND t.value_text = 'Supervision'
      AND pharmacy_encounter_type = #{encounter_type} AND t.voided = 0
      AND date_created = (SELECT MAX(t2.date_created) FROM pharmacy_obs t2
      WHERE t2.encounter_date = '#{date}' AND t2.drug_id = #{drug_id} AND t2.value_text = 'Supervision'
      AND t2.pharmacy_encounter_type = #{encounter_type} AND t2.voided = 0) LIMIT 1").first

    return [] if verified_stock.blank?


    previous_verified_stock = 0

    unless verified_stock.date_created.blank?
      previous_verified_stock = self.find_by_sql("SELECT t.value_numeric FROM pharmacy_obs t
      WHERE t.encounter_date = '#{date}' AND drug_id = #{drug_id} AND t.value_text = 'Supervision'
      AND pharmacy_encounter_type = #{encounter_type} AND t.voided = 0
      AND date_created = (SELECT MAX(t2.date_created) FROM pharmacy_obs t2
      WHERE t2.encounter_date = '#{date}' AND t2.drug_id = #{drug_id} AND t2.value_text = 'Supervision'
      AND t2.pharmacy_encounter_type = #{encounter_type} AND t2.voided = 0
      AND t2.date_created < '#{verified_stock.date_created.to_time.strftime('%Y-%m-%d %H:%M:%S')}')")

      previous_verified_stock = previous_verified_stock.value_numeric.to_f rescue 0
    end

    return {:verified_stock => verified_stock.value_numeric,
      :expiring_units => verified_stock.expiring_units,
      :earliest_expiry_date => verified_stock.expiry_date,
      :previous_verified_stock => previous_verified_stock}
  end

  def self.drug_stock_on(drug_id, date = Date.today)
    #This method gives the current drug stock after latest date of physical count
    # and all dispensation of that particular drug from the latest date of physical count

    #total_physical_count = self.total_physically_counted(drug_id, last_physical_count_enc_date)
    physical_count = self.latest_physical_count(drug_id) #Created a method for pulling latest drug total supervised
    return 0 if physical_count.blank?
    total_physical_count = physical_count.first
    start_date = physical_count.last
    return 0 if start_date > date
    total_dispensed = self.dispensed_drugs_since(drug_id, start_date, date)
    total_removed = self.total_removed(drug_id, start_date, date)
    count = (total_physical_count - (total_dispensed + total_removed))
    return count if count >= 0
    return 0
  end

  # ............................... New code to cal latest_physical_counted (meant for ART stock management app).................................#
  def self.latest_physical_count(drug_id)
    encounter_type = PharmacyEncounterType.find_by_name('Tins currently in stock').id
=begin
    verified_stock = self.find_by_sql("SELECT * FROM pharmacy_obs t
      WHERE t.encounter_date <= current_date() AND drug_id = #{drug_id} AND t.value_text IN('Supervision', 'Clinic')
      AND pharmacy_encounter_type = #{encounter_type} AND t.voided = 0
      AND encounter_date = (SELECT MAX(t2.encounter_date) FROM pharmacy_obs t2
      WHERE t2.encounter_date <= current_date() AND t2.drug_id = #{drug_id} AND t2.value_text IN('Supervision', 'Clinic')
      AND t2.pharmacy_encounter_type = #{encounter_type} AND t2.voided = 0) LIMIT 1").first
=end

    latest_date = Pharmacy.find_by_sql(
      "SELECT * from pharmacy_obs WHERE
           drug_id = #{drug_id} AND pharmacy_encounter_type = #{encounter_type} AND
           DATE(encounter_date) = (
            SELECT MAX(DATE(encounter_date)) FROM pharmacy_obs
            WHERE drug_id =#{drug_id} AND pharmacy_encounter_type = #{encounter_type}
          ) LIMIT 1;"
    ).last.encounter_date rescue nil

    verified_stock = Pharmacy.find_by_sql(
      "SELECT * FROM pharmacy_obs p WHERE p.drug_id = #{drug_id}
        AND p.pharmacy_module_id = (
              SELECT MAX(pharmacy_module_id) FROM pharmacy_obs t
              WHERE t.encounter_date = p.encounter_date AND t.drug_id = p.drug_id
              AND t.pharmacy_encounter_type = #{encounter_type}
              AND t.encounter_date >= '#{latest_date}' AND t.encounter_date <= '#{latest_date}'
            )
        AND p.encounter_date = (
            SELECT max(encounter_date) from pharmacy_obs t2
            where t2.encounter_date = p.encounter_date AND t2.drug_id = p.drug_id
            AND t2.pharmacy_encounter_type = #{encounter_type}
            AND t2.encounter_date >= '#{latest_date}' AND t2.encounter_date <= '#{latest_date}'
          ) LIMIT 1;"
    ).last

    return [] if verified_stock.blank?
    return [verified_stock.value_numeric, verified_stock.encounter_date]
  end
  # ............................... New code to cal latest_physical_counted (meant for ART stock management app) ends .................................#
end
