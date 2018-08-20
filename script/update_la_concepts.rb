

def update_la_concepts
  la_drug_concept = "LA (Lumefantrine + arthemether)"
  la_drug_names = ["Lumefantrine + arthemether (30x12)",
    "Lumefantrine + arthemether (30x18)", "Lumefantrine + arthemether (30x24)",
    "Lumefantrine + arthemether (30x6)"
  ]

  la_drug = Drug.find_by_name(la_drug_concept)
  unless la_drug.blank?
    la_drug.name = 'Lumefantrine + Arthemether 1 x 6'
    la_drug.save
  end

  la_drug_names.each do |drug_name|
    drug = Drug.find_by_name(drug_name)
    next if drug.blank?
    drug.retired = 1
    drug.retired_by = 1
    drug.retire_reason = 'Duplicate Drug'
    drug.date_retired = Date.today
    drug.save
    puts "Retired #{drug_name}"
  end
  
  puts "Done"
end

update_la_concepts