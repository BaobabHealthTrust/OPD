require 'temperature_reader'
require 'rb-inotify'
require 'fastercsv'

namespace :ncit  do
  namespace :temperature do
    desc "Taks to read temperature from file"
    task :read do
      temperature_reader = TemperatureReader.new('../sample.csv')
      temperature_reader.read_temperature
    end
  end
end
