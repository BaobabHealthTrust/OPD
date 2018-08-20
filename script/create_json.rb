
def create_json
  
  syndrome_hash = {
    "syndrome_g1" => ["fever","Influenza like illness","respiratory"],
    "syndrome_g2" => ["Gastrointestinal","Haema"],
    "syndrome_g3" => ["Nephro","Trauma","Cardiovascular"],
    "syndrome_g4" => ["General","Other"]
  }
  hash = {}
  syndrome_hash.each do |key, values|
    hash[key] = {}
    values.each do |concept_name|
      concept_sets = MedicationService.concept_set(concept_name)
      hash[key][concept_name] = concept_sets
    end
  end

  File.open("#{Rails.root.to_s}/public/json/idsr_complaints.json", 'w') { |file| file.write(hash.to_json) }
  return hash.to_json
end

create_json