class LocationController < GenericLocationController

  def disease_surveillance_api

    diagnosis_set = CoreService.get_global_property_value("application_diagnosis_concept")
    diagnosis_set = "Qech outpatient diagnosis list" if diagnosis_set.blank?
    diagnosis_concept_set = ConceptName.find_by_name(diagnosis_set).concept
    diagnosis_concepts = Concept.find(:all, :joins => :concept_sets, :conditions => ['concept_set = ?', diagnosis_concept_set.id])

    hash = {}
    hash["diagnosis_concepts"] = {}
    hash["presenting_complaints_concepts"] = {}
    
    (diagnosis_concepts || []).each do |diagnosis_concept|
      concept_id = diagnosis_concept.concept_id
      concept_short_name = diagnosis_concept.short_name
      concept_full_name = diagnosis_concept.full_name
      hash["diagnosis_concepts"][concept_id] = {}
      hash["diagnosis_concepts"][concept_id]["short_name"] = concept_short_name
      hash["diagnosis_concepts"][concept_id]["full_name"] = concept_full_name
    end

    presenting_complaints_set = "PRESENTING COMPLAINT"
		presenting_complaints_concept_set = ConceptName.find_by_name(presenting_complaints_set).concept
		presenting_complaints_concepts = Concept.find(:all, :joins => :concept_sets,
      :conditions => ['concept_set = ?', presenting_complaints_concept_set.id])
    
    (presenting_complaints_concepts || []).each do |presenting_complaint_concept|
      concept_id = presenting_complaint_concept.concept_id
      concept_short_name = presenting_complaint_concept.short_name
      concept_full_name = presenting_complaint_concept.full_name
      hash["presenting_complaints_concepts"][concept_id] = {}
      hash["presenting_complaints_concepts"][concept_id]["short_name"] = concept_short_name
      hash["presenting_complaints_concepts"][concept_id]["full_name"] = concept_full_name
    end
    
    render :text => hash.to_json and return
  end
  
end
