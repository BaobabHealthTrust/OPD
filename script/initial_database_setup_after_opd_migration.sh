#!/bin/bash

usage(){
  echo "Usage: $0 ENVIRONMENT"
  echo
  echo "ENVIRONMENT should be: development|test|production"
  #echo "Available SITES:"
  ls -1 db/data
} 

ENV=$1
SITE=$2

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

mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/schema_opd_additions.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/opd_after_migration_defaults.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/openmrs_metadata_1_7.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/malawi_regions.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/moh_regimens_only.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/user_schema_modifications.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/missing_tables.sql

echo "After completing database setup, you are advised to run the following:"
echo "script/runner -e development|production|test script/update_diagnosis_observations.rb"
echo "rake test"
echo "rake cucumber"
