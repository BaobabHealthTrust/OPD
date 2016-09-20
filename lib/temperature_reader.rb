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
        #TODO: Get/Set patient_identifier for this reading
        if temperature > 37.8 && temperature < 38.0
          puts "/**********Saving Fever Temperature to OPD database********"
          puts "Temp=> #{temperature.to_s} AND Patient Identifier =>#{patient_identifier}"
        elsif temperature > 38.0
          puts "/**********Saving High Fever to OPD database***********" #save in opd
          puts "Temp=> #{temperature.to_s} AND Patient Identifier =>#{patient_identifier}"
        else
          puts "No Fever"
        end

        temperature_record = TemperatureRecord.new()
        temperature_record.patient_identifier = patient_identifier
        temperature_record.temperature = temperature
        temperature_record.save #save temperature
      end
      @notifier.run
    rescue Exception => e
      puts "An error occured whilst executing"
      puts e.message
      #puts e.backtrace.inspect
    end
  end
end
