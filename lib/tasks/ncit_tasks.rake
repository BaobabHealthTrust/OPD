require 'temperature_reader'
require 'rb-inotify'
require 'fastercsv'

namespace :ncit  do
  namespace :temperature do
    desc "Taks to read temperature from file"
    task :read => :environment do
      path = File.expand_path(File.join(File.dirname(__FILE__),'../../../sample.csv'))
      if File.exist?(path)
        temperature_reader = TemperatureReader.new(File.expand_path(File.join(
        File.dirname(__FILE__),'../../../sample.csv')))
        temperature_reader.read_temperature
      else
        puts "File to read from doesn't exist"
        puts "Make sure the NCIT scanner has created the required file"
      end
    end
  end
end
