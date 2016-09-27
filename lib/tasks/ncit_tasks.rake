require 'temperature_reader'
require 'rb-inotify'
require 'fastercsv'

namespace :ncit  do
  namespace :temperature do
    desc "Taks to read temperature from file"
    task :read => :environment do
      temperature_reader = TemperatureReader.new(File.expand_path(File.join(
      File.dirname(__FILE__),'../../../sample.csv')))
      temperature_reader.read_temperature
    end
  end
end
