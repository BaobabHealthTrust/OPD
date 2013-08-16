#!/bin/bash

usage(){
  echo "Usage: $0 ENVIRONMENT"
  echo
  echo "ENVIRONMENT should be: development|test|production"
  #echo "Available SITES:"
  ls -1 db/data
} 

ENV=$1
#SITE=$2

if [ -z "$ENV" ] ; then
  usage
  exit
fi

set -x # turns on stacktrace mode which gives useful debug information

if [ ! -x config/database.yml ] ; then
  cp config/database.yml.example config/database.yml
fi

USERNAME=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['username']"`
PASSWORD=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['password']"`
DATABASE=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['database']"`

echo "DROP TABLE IF EXISTS location_tag_map;" | mysql --user=$USERNAME --password=$PASSWORD $DATABASE
echo "DROP TABLE IF EXISTS location_tag;" | mysql --user=$USERNAME --password=$PASSWORD $DATABASE

mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/create_and_alter_tables_before_openmrs_migration.sql
echo "After completing database setup, you are advised to run the following:"
echo "rake test"
echo "rake cucumber"
