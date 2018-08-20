=begin
NOTE: This class does not handle below the normal temperature
It only handles the range of our threshold
=end
class TemperatureReader

  def initialize(filepath)
    @filepath = filepath  #constructor injection
    @notifier = INotify::Notifier.new
  end
  #reads the temperature a from a given file and records it into opd
  def read_temperature
    begin
      temperature_array = []
      @notifier.watch(@filepath,:modify) do
        temperature_array = FasterCSV.read(@filepath) #TODO:read on the last line of the csv
        temperature = temperature_array.last[1].to_f
        patient_identifier= temperature_array.last[0]
        location = temperature_array.last[3]
        save_in_openmrs =  false
        #TODO: Get/Set patient_identifier for this reading
        if temperature > 37.8 && temperature < 38.0
          puts "/**********Saving Fever Temperature to OPD database********"
          puts "Temp=> #{temperature.to_s} AND Patient Identifier =>#{patient_identifier}"
          save_in_openmrs = true
        elsif temperature > 38.0
          puts "/**********Saving High Fever to OPD database***********" #save in opd
          puts "Temp=> #{temperature.to_s} AND Patient Identifier =>#{patient_identifier}"
          save_in_openmrs = true
        else
          puts "No Fever"
        end

        if(save_in_openmrs)
          openmrs_save(location, temperature) #store the values in OpenMRS
        end

        temperature_record = TemperatureRecord.new()
        temperature_record.patient_identifier = patient_identifier
        temperature_record.temperature = temperature
        temperature_record.status = 'open'
        temperature_record.location_id = location #assuming the machine will provide location information
        temperature_record.save #save temperature
      end
      @notifier.run
    rescue Exception => e
      puts "An error occured whilst executing"
      puts e.message
      #puts e.backtrace.inspect
    end
  end
  def openmrs_save(location, temperature)
    #create a record in OpenMRS if Fever is detected or high fever
    #create person
    person =  Person.create(:creator => 1)
    patient = Patient.create(:id=>person.id, :creator=>1)
    encounter_type = EncounterType.find_by_name('VITALs').id
    concept_id =  ConceptName.find_by_name('Temperature (c)').id
    encounter = Encounter.create(:encounter_type=> encounter_type,
                                 :patient_id=>patient.id,
                                 :provider_id=>person.id,
                                 :location_id=>location,:creator=>1)
    obs = Observation.create(:person_id=>person.id,
                             :encounter_id=>encounter.id,
                             :concept_id => concept_id,
                             :obs_datetime=> Time.now,
                             :location_id=>location,:value_text=> temperature.to_s,
                             :creator => 1)
  end
end
