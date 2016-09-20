namespace :ncit do
  desc "Read temperature values from file" do
    task :read_file do
      temperature_reader = TemperatureReader.new('sample.csv')
      temperature_reader.read_temperature
    end
  end
end
