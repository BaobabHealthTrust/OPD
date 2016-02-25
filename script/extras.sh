#!/bin/bash

usage(){
  echo "Usage: $0 ENVIRONMENT"
  echo
  echo "ENVIRONMENT should be: development|test|production"
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
HOST=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['host']"`

mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/extras/drop_villages.sql

mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/extras/countries.sql

mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/extras/villages.sql
