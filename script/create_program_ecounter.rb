def program_encounter
  puts "Checking if program_encounters table exists"
  check_program_encounter_table_existence = ActiveRecord::Base.connection.table_exists? 'program_ecounters'
  
  if check_program_encounter_table_existence
    puts "program_encounters table already exists"
  else
    puts "program_encounters table not found. Creating...."
    #migration file: 20160503085616_create_program_ecounters.rb
    `bundle exec rake db:migrate:up VERSION=20160503085616`
  end
  
  puts "Done"
end

program_encounter