class PrescriptionsController < GenericPrescriptionsController

  def load_frequencies_and_dosages
    drugs = MedicationService.dosages(params[:concept_id])
    render :text => drugs.to_json
  end
  
  def generic_advanced_prescription
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    @generics = MedicationService.generic
    @frequencies = MedicationService.frequencies
    @diagnosis = @patient.current_diagnoses["DIAGNOSIS"] rescue []
    render :layout => 'application'
  end
 
  def advanced_drug_details(drug_info)
    
    insulin = false
    if (drug_info[0].downcase.include? "insulin") && ((drug_info[0].downcase.include? "lente") ||
          (drug_info[0].downcase.include? "soluble")) || ((drug_info[0].downcase.include? "glibenclamide") && (drug_info[1] == ""))

      if(drug_info[0].downcase == "insulin, lente")     # due to error noticed when searching for drugs
        drug_info[0] = "LENTE INSULIN"
      end

      if(drug_info[0].downcase == "insulin, soluble")     # due to error noticed when searching for drugs
        drug_info[0] = "SOLUBLE INSULIN"
      end

      name = "%"+drug_info[0]+"%"
      insulin = true

    else

      # do not remove the '(' in the following string
      name = "%"+drug_info[0]+"%"+drug_info[1]+"%"

    end

    drug_details = Array.new

    concept_name_id = ConceptName.find_by_name("DRUG FREQUENCY CODED").concept_id

    drugs = Drug.find(:all, :select => "concept.concept_id AS concept_id, concept_name.name AS name,
        drug.dose_strength AS strength, drug.name AS formulation",
      :joins => "INNER JOIN concept       ON drug.concept_id = concept.concept_id
               INNER JOIN concept_name  ON concept_name.concept_id = concept.concept_id",
      :conditions => ["drug.name LIKE ? OR (concept_name.name LIKE ? AND COALESCE(drug.dose_strength, 0) = ? " +
          "AND COALESCE(drug.units, '') = ?)", name, "%" + drug_info[0] + "%", drug_info[3], drug_info[4]],
      :group => "concept.concept_id, drug.name, drug.dose_strength")

    # raise drugs.to_yaml
    
    unless(insulin)

      drug_frequency = drug_info[2].upcase rescue nil

      preferred_concept_name_id = Concept.find_by_name(drug_frequency).concept_id
      preferred_dmht_tag_id = ConceptNameTag.find_by_tag("preferred_dmht").concept_name_tag_id

      drug_frequency = ConceptName.find(:first, :select => "concept_name.name",
        :joins => "INNER JOIN concept_answer ON concept_name.concept_id = concept_answer.answer_concept
                                INNER JOIN concept_name_tag_map cnmp
                                  ON  cnmp.concept_name_id = concept_name.concept_name_id",
        :conditions => ["concept_answer.concept_id = ? AND concept_name.concept_id = ? AND voided = 0
                                  AND cnmp.concept_name_tag_id = ?", concept_name_id, preferred_concept_name_id, preferred_dmht_tag_id])

      drugs.each do |drug|

        drug_details += [:drug_concept_id => drug.concept_id,
          :drug_name => drug.name, :drug_strength => drug.strength,
          :drug_formulation => drug.formulation, :drug_prn => 0, :drug_frequency => drug_frequency.name]

      end

    else

      drugs.each do |drug|

        drug_details += [:drug_concept_id => drug.concept_id,
          :drug_name => drug.name, :drug_strength => drug.strength,
          :drug_formulation => drug.formulation, :drug_prn => 0, :drug_frequency => ""]

      end rescue []

    end

    drug_details

  end

end
