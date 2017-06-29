module API
  def self.malaria_observations(start_date, end_date)
    outpatient_encounter_type_id = EncounterType.find_by_name("OUTPATIENT DIAGNOSIS").encounter_type_id
    malaria_concept_id = Concept.find_by_name("MALARIA").concept_id
    diagnosis_concept_ids = ["PRIMARY DIAGNOSIS", "SECONDARY DIAGNOSIS", "ADDITIONAL DIAGNOSIS"].collect do |concept_name|
     Concept.find_by_name(concept_name).concept_id
    end

    Observation.find_by_sql(
        "SELECT o.* FROM encounter e
        INNER JOIN obs o ON e.encounter_id = o.encounter_id AND e.encounter_type = #{outpatient_encounter_type_id}
        AND o.concept_id IN (#{diagnosis_concept_ids.join(', ')}) AND o.value_coded = #{malaria_concept_id}
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")
  end

  def self.microscopy_orders(start_date, end_date)
    lab_orders_encounter_type_id = EncounterType.find_by_name("LAB ORDERS").encounter_type_id
    tests_ordered_concept_id = Concept.find_by_name("BLOOD").concept_id

    Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_orders_encounter_type_id}
        AND o.concept_id = #{tests_ordered_concept_id} AND UPPER(o.value_text) = 'MALARIA (MICROSCOPY)'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")
  end

  def self.microscopy_result(start_date, end_date, value_text)
    malaria_test_result_concept_id = Concept.find_by_name("MALARIA TEST RESULT").concept_id
    lab_result_encounter_type_id = EncounterType.find_by_name("LAB RESULTS").encounter_type_id

    microscopy_order_accession_numbers = self.microscopy_orders(start_date, end_date).map(&:accession_number).compact
    microscopy_order_accession_numbers = [0] if microscopy_order_accession_numbers.blank?

    Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{microscopy_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = '#{value_text}'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")
  end

  def self.microscopy_result_u5(start_date, end_date, gender, value_text)
    malaria_test_result_concept_id = Concept.find_by_name("MALARIA TEST RESULT").concept_id
    lab_result_encounter_type_id = EncounterType.find_by_name("LAB RESULTS").encounter_type_id

    microscopy_order_accession_numbers = self.microscopy_orders(start_date, end_date).map(&:accession_number).compact
    microscopy_order_accession_numbers = [0] if microscopy_order_accession_numbers.blank?

    Observation.find_by_sql("SELECT o.* FROM encounter e
        INNER JOIN person per ON per.person_id = e.patient_id AND per.voided = 0
                AND TIMESTAMPDIFF(DAY, per.birthdate, e.encounter_datetime) < 1800 AND per.gender = '#{gender}'
        INNER JOIN obs o ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{microscopy_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = '#{value_text}'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")
  end

  def self.microscopy_unknown(start_date, end_date)
    malaria_test_result_concept_id = Concept.find_by_name("MALARIA TEST RESULT").concept_id
    lab_result_encounter_type_id = EncounterType.find_by_name("LAB RESULTS").encounter_type_id
    unknown_concept_id = Concept.find_by_name("UNKNOWN").concept_id

    microscopy_order_accession_numbers = self.microscopy_orders(start_date, end_date).map(&:accession_number).compact
    microscopy_order_accession_numbers = [0] if microscopy_order_accession_numbers.blank?

    Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{microscopy_order_accession_numbers.join(', ')})
        AND o.value_coded = #{unknown_concept_id}
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")
  end

  def self.microscopy_positives(start_date, end_date)
    self.microscopy_result(start_date, end_date, 'THICK SMEAR POSITIVE')
  end

  def self.microscopy_negatives(start_date, end_date)
    self.microscopy_result(start_date, end_date, 'THICK SMEAR NEGATIVE')
  end

  def self.mRDT_orders(start_date, end_date)
    lab_orders_encounter_type_id = EncounterType.find_by_name("LAB ORDERS").encounter_type_id
    tests_ordered_concept_id = Concept.find_by_name("BLOOD").concept_id

    Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_orders_encounter_type_id}
        AND o.concept_id = #{tests_ordered_concept_id} AND UPPER(o.value_text) = 'MALARIA (MRDT)'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")
  end

  def self.mRDT_result(start_date, end_date, value_text)
    malaria_test_result_concept_id = Concept.find_by_name("MALARIA TEST RESULT").concept_id
    lab_result_encounter_type_id = EncounterType.find_by_name("LAB RESULTS").encounter_type_id

    mrdt_order_accession_numbers = self.mRDT_orders(start_date, end_date).map(&:accession_number).compact
    mrdt_order_accession_numbers = [0] if mrdt_order_accession_numbers.blank?

    Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{mrdt_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = '#{value_text}'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")
  end

  def self.mRDT_positives(start_date, end_date)
    self.mRDT_result(start_date, end_date, 'MALARIA RDT POSITIVE')
  end

  def self.mRDT_negatives(start_date, end_date)
    self.mRDT_result(start_date, end_date, 'MALARIA RDT NEGATIVE')
  end

  def self.mRDT_unknown(start_date, end_date)
    malaria_test_result_concept_id = Concept.find_by_name("MALARIA TEST RESULT").concept_id
    lab_result_encounter_type_id = EncounterType.find_by_name("LAB RESULTS").encounter_type_id
    unknown_concept_id = Concept.find_by_name("UNKNOWN").concept_id

    mrdt_order_accession_numbers = self.mRDT_orders(start_date, end_date).map(&:accession_number).compact
    mrdt_order_accession_numbers = [0] if mrdt_order_accession_numbers.blank?

    Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{mrdt_order_accession_numbers.join(', ')})
        AND o.value_coded = #{unknown_concept_id}
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")
  end


  def self.mRDT_result_u5(start_date, end_date, gender, value_text)
    malaria_test_result_concept_id = Concept.find_by_name("MALARIA TEST RESULT").concept_id
    lab_result_encounter_type_id = EncounterType.find_by_name("LAB RESULTS").encounter_type_id

    mrdt_order_accession_numbers = self.mRDT_orders(start_date, end_date).map(&:accession_number).compact
    mrdt_order_accession_numbers = [0] if mrdt_order_accession_numbers.blank?

    Observation.find_by_sql("SELECT o.* FROM encounter e
         INNER JOIN person per ON per.person_id = e.patient_id AND per.voided = 0
                AND TIMESTAMPDIFF(DAY, per.birthdate, e.encounter_datetime) < 1800 AND per.gender = '#{gender}'
        INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IN (#{mrdt_order_accession_numbers.join(', ')})
        AND UPPER(o.value_text) = '#{value_text}'
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")
  end

  def self.first_line_dispensations(start_date, end_date)
    dispensing_encounter_type_id = EncounterType.find_by_name("DISPENSING").encounter_type_id
    amount_dispensed_concept = Concept.find_by_name('Amount dispensed').id
    drug_order_type_id = OrderType.find_by_name("Drug Order").order_type_id

    la_one_drug_id = Drug.find_by_name("Lumefantrine + Arthemether 1 x 6").drug_id rescue 0
    #la_two_drug_id = Drug.find_by_name("Lumefantrine + Arthemether 2 x 6").drug_id
    #la_three_drug_id = Drug.find_by_name("Lumefantrine + Arthemether 3 x 6").drug_id
    #la_four_drug_id = Drug.find_by_name("Lumefantrine + Arthemether 4 x 6").drug_id


    Order.find_by_sql("SELECT e.* FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        AND do.drug_inventory_id = #{la_one_drug_id}
        AND obs.concept_id = #{amount_dispensed_concept} AND e.voided=0 GROUP BY e.patient_id, DATE(e.encounter_datetime)"
    )
  end

  def self.all_dispensations(start_date, end_date)
    dispensing_encounter_type_id = EncounterType.find_by_name("DISPENSING").encounter_type_id
    amount_dispensed_concept = Concept.find_by_name('Amount dispensed').id
    drug_order_type_id = OrderType.find_by_name("Drug Order").order_type_id

    drug_ids = [(Drug.find_by_name("Lumefantrine + Arthemether 1 x 6").drug_id rescue 0),
        Drug.find_by_name("Lumefantrine + Arthemether 2 x 6").drug_id,
        Drug.find_by_name("Lumefantrine + Arthemether 3 x 6").drug_id,
        Drug.find_by_name("Lumefantrine + Arthemether 4 x 6").drug_id].join(", ")

    Order.find_by_sql("SELECT e.* FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        AND do.drug_inventory_id IN (#{drug_ids})
        AND obs.concept_id = #{amount_dispensed_concept} AND e.voided=0 GROUP BY e.patient_id, DATE(e.encounter_datetime)"
    )
  end

  def self.all_dispensations_u5(start_date, end_date, gender)
    dispensing_encounter_type_id = EncounterType.find_by_name("DISPENSING").encounter_type_id
    amount_dispensed_concept = Concept.find_by_name('Amount dispensed').id
    drug_order_type_id = OrderType.find_by_name("Drug Order").order_type_id

    drug_ids = [(Drug.find_by_name("Lumefantrine + Arthemether 1 x 6").drug_id rescue 0),
                Drug.find_by_name("Lumefantrine + Arthemether 2 x 6").drug_id,
                Drug.find_by_name("Lumefantrine + Arthemether 3 x 6").drug_id,
                Drug.find_by_name("Lumefantrine + Arthemether 4 x 6").drug_id].join(", ")

    Order.find_by_sql("SELECT e.* FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN person per ON per.person_id = e.patient_id AND per.voided = 0
                AND TIMESTAMPDIFF(DAY, per.birthdate, e.encounter_datetime) < 1800 AND per.gender = '#{gender}'
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        AND do.drug_inventory_id IN (#{drug_ids})
        AND obs.concept_id = #{amount_dispensed_concept} AND e.voided=0 GROUP BY e.patient_id, DATE(e.encounter_datetime)"
    )
  end

  def self.treated_negatives(start_date, end_date)
    accession_numbers = self.mRDT_negatives(start_date, end_date).map(&:accession_number).compact
    accession_numbers = [0] if accession_numbers.blank?

    accession_numbers += self.microscopy_negatives(start_date, end_date).map(&:accession_number).compact

    dispensing_encounter_type_id = EncounterType.find_by_name("DISPENSING").encounter_type_id
    amount_dispensed_concept = Concept.find_by_name('Amount dispensed').id
    drug_order_type_id = OrderType.find_by_name("Drug Order").order_type_id

    drug_ids = [(Drug.find_by_name("Lumefantrine + Arthemether 1 x 6").drug_id rescue 0),
                Drug.find_by_name("Lumefantrine + Arthemether 2 x 6").drug_id,
                Drug.find_by_name("Lumefantrine + Arthemether 3 x 6").drug_id,
                Drug.find_by_name("Lumefantrine + Arthemether 4 x 6").drug_id].join(", ")

    Order.find_by_sql("SELECT e.* FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
        INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN obs o2 ON DATE(o2.obs_datetime) = DATE(e.encounter_datetime) AND o2.person_id = e.patient_id
          AND o2.accession_number IN (#{accession_numbers.join(', ')}) AND UPPER(o2.value_text) IN ('MALARIA RDT NEGATIVE', 'THICK SMEAR NEGATIVE')
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        AND do.drug_inventory_id IN (#{drug_ids})
        AND obs.concept_id = #{amount_dispensed_concept} AND e.voided=0 GROUP BY e.patient_id, DATE(e.encounter_datetime)"
    )
  end

  def self.malaria_in_pregnancy(start_date, end_date)
    [] #Not yet in EMR
  end

  def self.under_five_malaria_cases(start_date, end_date, gender)

    gender = "Female Male" if gender.blank?
    outpatient_encounter_type_id = EncounterType.find_by_name("OUTPATIENT DIAGNOSIS").encounter_type_id
    malaria_concept_id = Concept.find_by_name("MALARIA").concept_id
    diagnosis_concept_ids = ["PRIMARY DIAGNOSIS", "SECONDARY DIAGNOSIS", "ADDITIONAL DIAGNOSIS"].collect do |concept_name|
      Concept.find_by_name(concept_name).concept_id
    end

    # < 1800 days is under five
    observed = Observation.find_by_sql(
        "SELECT o.* FROM encounter e
        INNER JOIN obs o ON e.encounter_id = o.encounter_id AND e.encounter_type = #{outpatient_encounter_type_id}
        INNER JOIN person p ON p.person_id = o.person_id AND TIMESTAMPDIFF(DAY, p.birthdate, o.obs_datetime) < 1800 AND p.gender = '#{gender}'
        AND o.concept_id IN (#{diagnosis_concept_ids.join(', ')}) AND o.value_coded = #{malaria_concept_id}
        AND e.voided=0 AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        GROUP BY o.person_id, DATE(o.obs_datetime)")

    dispensed = self.all_dispensations_u5(start_date, end_date, gender)

    lab_orders = self.mRDT_result_u5(start_date, end_date, gender, 'MALARIA RDT POSITIVE') +
        self.microscopy_result_u5(start_date, end_date, gender, 'MALARIA RDT POSITIVE')

    total_reported = []
    counted = {}
    #(observed + dispensed + lab_orders).each do |m|
    (observed + lab_orders).each do |m|
      id = m.person_id rescue m.patient_id
      i_date = m.obs_datetime rescue m.encounter_datetime

      counted[id] = {} if counted[id].blank?
      next if !counted[id][i_date.to_date].blank?
      counted[id][i_date.to_date] = 1
      total_reported << m
    end

    total_reported
  end

  def self.under_five_malaria_cases_male(start_date, end_date)
    return self.under_five_malaria_cases(start_date, end_date, 'M')
  end

  def self.under_five_malaria_cases_female(start_date, end_date)
    return self.under_five_malaria_cases(start_date, end_date, 'F')
  end

  def self.dispensation_trends(start_date, end_date)
    result = {}
    current_month = "#{end_date.to_date.year}#{end_date.to_date.month.to_s.rjust(2, '0')}".to_i
    start = start_date.to_date
    while start <= end_date
      month = "#{start.year}#{start.month.to_s.rjust(2, '0')}".to_i
      result[month] = 0  if month != current_month
      start = start + 1.month
    end

    dispensing_encounter_type_id = EncounterType.find_by_name("DISPENSING").encounter_type_id
    amount_dispensed_concept = Concept.find_by_name('Amount dispensed').id
    drug_order_type_id = OrderType.find_by_name("Drug Order").order_type_id

    drug_ids = [(Drug.find_by_name("Lumefantrine + Arthemether 1 x 6").drug_id rescue 0),
                Drug.find_by_name("Lumefantrine + Arthemether 2 x 6").drug_id,
                Drug.find_by_name("Lumefantrine + Arthemether 3 x 6").drug_id,
                Drug.find_by_name("Lumefantrine + Arthemether 4 x 6").drug_id].join(", ")

    Order.find_by_sql("SELECT COUNT(*) count, YEAR(e.encounter_datetime) year, MONTH(e.encounter_datetime) month FROM encounter e
        INNER JOIN encounter_type et ON e.encounter_type = et.encounter_type_id INNER JOIN obs ON e.encounter_id=obs.encounter_id
        INNER JOIN orders o ON obs.order_id = o.order_id INNER JOIN drug_order do ON o.order_id = do.order_id
        INNER JOIN drug d ON do.drug_inventory_id = d.drug_id
        WHERE e.encounter_type = #{dispensing_encounter_type_id} AND o.order_type_id = #{drug_order_type_id}
        AND DATE(e.encounter_datetime) >= '#{start_date.to_date.to_s}' AND DATE(e.encounter_datetime) <= '#{end_date.to_date.to_s}'
        AND do.drug_inventory_id IN (#{drug_ids})
        AND obs.concept_id = #{amount_dispensed_concept} AND e.voided=0 GROUP BY year, month"
    ).each do |month|
      m = "#{month.year}#{month.month.to_s.rjust(2, '0')}".to_i
      result[m] = month.count if m != current_month
    end

    result.sort_by { |k, v| k}
  end
end

