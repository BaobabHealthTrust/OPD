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
        save = false
        #TODO: Handle the saving more intricately.
        if temperature > 37.8 && temperature < 38.0
          puts "/**********Saving Fever Temperature to OPD database********"
          puts "Temp=> #{temperature.to_s} AND  Patient Identifier => "
          save = true
        elsif temperature > 38.0
          puts "/**********Saving High Fever to OPD database***********" #save in opd
          puts "Temp=> #{temperature.to_s} AND Patient Identifier => "
          save = true
        else
          puts "No Fever"
        end

        if save
          # Save Using ActiveRecord
        end
      end
      @notifier.run
    rescue Exception => e
      puts "An error occured whilst executing"
      @mysql_service.close_conection
      puts e.message
      puts e.backtrace.inspect
    end
  end
end
