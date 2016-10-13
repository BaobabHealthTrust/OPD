Outpatient is a simple patient registration application written in Ruby on Rails and is intended as a web front end for OpenMRS.

OpenMRS® is a community-developed, open-source, enterprise electronic medical record system framework. We've come together to specifically respond to those actively building and managing health systems in the developing world, where AIDS, tuberculosis, and malaria afflict the lives of millions. Our mission is to foster self-sustaining health information technology implementations in these environments through peer mentorship, proactive collaboration, and a code base that equals or surpasses proprietary equivalents. You are welcome to come participate in the community, whether by implementing our software, or contributing your efforts to our mission!

Outpatient was built by Baobab Health and Partners in Health in Malawi, Africa. It is licensed under the Mozilla Public License.

===================================================================================================================
OPD SYSTEM CONFIGURATION
===================================================================================================================
Below are some simple steps to follow when you want to setup ADT.

Open your terminal
Get a source code from github by typing "git clone git@github.com:BaobabHealthTrust/OPD.git"
Enter into the root of your application by typing "cd OPD"
Type "cp config/application.yml.example config/application.yml"
Type "cp config/database.yml.example config/database.yml"
Type "cp config/dashboard.yml.example config/dashboard.yml"
Note: Open config/database.yml and edit the file. Provide any database name to be used in your application. Do not forget to provide mysql password in the same file.
Note: Open dashboard.yml and change the username and password to match the one active on the surveillance dashboard system.
Type "script/initial_database_setup.sh development mpc". Please be patient while the script is running. This may take some time.
Type "script/runner script/load_user_activation_table.rb" This script is for activating users.
Type "sudo bundle install"
After completing the above steps, you may now run the application by typing "script/server"

Open your browser on the following address"http://0.0.0.0:3000"
Username : admin
password : test
Workstation Location : 721
Note: You can change the default port of the application by passing -p option
e.g "script/server -p 3001"

===================================================================================================================
