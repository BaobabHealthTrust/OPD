class Lab < ActiveRecord::Base
  set_table_name "map_lab_panel"

  def self.results(patient, patient_ids)
    results = self.find_by_sql(["
SELECT * FROM Lab_Sample s
INNER JOIN Lab_Parameter p ON p.sample_id = s.sample_id
INNER JOIN codes_TestType c ON p.testtype = c.testtype
INNER JOIN (SELECT DISTINCT rec_id, short_name FROM map_lab_panel) m ON c.panel_id = m.rec_id
WHERE s.patientid IN (?)
AND s.deleteyn = 0
AND s.attribute = 'pass'
GROUP BY short_name ORDER BY m.short_name",patient_ids
    ]).collect do | result |
      [
        result.short_name,
        result.TestName,
        result.Range,
        result.TESTVALUE,
        result.TESTDATE
      ]
    end

    return if results.blank?
    results
  end

  def self.results_by_type(patient, type, patient_ids)
    results_hash = {}
    results = self.find_by_sql(["
SELECT * FROM Lab_Sample s
INNER JOIN Lab_Parameter p ON p.sample_id = s.sample_id
INNER JOIN codes_TestType c ON p.testtype = c.testtype
INNER JOIN (SELECT DISTINCT rec_id, short_name FROM map_lab_panel) m ON c.panel_id = m.rec_id
WHERE s.patientid IN (?)
AND short_name = ?
AND s.deleteyn = 0
AND s.attribute = 'pass'
ORDER BY DATE(TESTDATE) DESC",patient_ids,type
    ]).collect do | result |
      test_date = result.TESTDATE.to_date rescue ''
      if results_hash[result.TestName].blank?
        results_hash["#{test_date}::#{result.TestName}"] = { "Range" => nil , "TestValue" => nil }
      end
      results_hash["#{test_date}::#{result.TestName}"] = { "Range" => result.Range , "TestValue" => result.TESTVALUE }
    end

    return if results_hash.blank?
    results_hash
  end


  def self.malaria_test_result(patient)
    lab_orders_encounter_type_id = EncounterType.find_by_name("LAB ORDERS").encounter_type_id
    tests_ordered_concept_id = Concept.find_by_name("TESTS ORDERED").concept_id

    malaria_order_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.patient_id = #{patient.id} AND e.encounter_type = #{lab_orders_encounter_type_id}
        AND o.concept_id = #{tests_ordered_concept_id} AND UPPER(o.value_text) IN ('MICROSCOPY', 'MRDT')
        AND e.voided=0 AND DATE(e.encounter_datetime) = '#{Date.today}'")

    return "no_orders" if malaria_order_observations.blank?

    lab_result_encounter_type_id = EncounterType.find_by_name("LAB RESULTS").encounter_type_id
    malaria_test_result_concept_id = Concept.find_by_name("MALARIA TEST RESULT").concept_id

    malaria_positive_results_observations = Observation.find_by_sql("SELECT o.* FROM encounter e INNER JOIN obs o
        ON e.encounter_id = o.encounter_id AND e.patient_id = #{patient.id} AND e.encounter_type = #{lab_result_encounter_type_id}
        AND o.concept_id = #{malaria_test_result_concept_id} AND o.accession_number IS NOT NULL
        AND UPPER(o.value_text) IN ('THICK SMEAR POSITIVE', 'MALARIA RDT POSITIVE')
        AND e.voided=0 AND DATE(e.encounter_datetime) = '#{Date.today}'")

    return "positive" unless malaria_positive_results_observations.blank?
    
  end

end
