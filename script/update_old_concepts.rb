start_time = Time.now
puts "Start Time: #{start_time}\n\n"
logger = Logger.new(Rails.root.join("log",'update_diagnosis_observations.log')) #,3,5*1024*1024)
logger.info "Start Time: #{start_time}"
total_saved = 0
total_unsaved = 0

concept_ids = {10001 => 3057,10002 => 6833,10003 => 63,10004 => 3058,10005 => 6436,10006 => 58,10007 => 891,10008 => 106,
        10009 => 43,10010 => 5,10011 => 3059,10012 =>198,10013 => 7637,10014 => 3060,10015 => 3,10016 => 7383,10017 => 903,
        10018 => 7384,10019 => 3061,10020 => 155,10021 => 3692,10022 => 70,10023 => 131,10024 => 7385,10025 => 890,
        10026 => 140,10027 => 3064,10028 => 894,10029 => 3065,10030 => 123,10031 => 363,10032 => 892,10033 => 6866,10034 => 7386,
        10035 => 60,10036 => 6867,10037 => 141,10038 => 57,10039 => 6437,10040 => 7389,10041 => 7392,10042 => 3740,10043 => 7393,
        10044 => 6901,10045 => 1175,10046 => 3056,10047 => 7382,10048 => 3713,10049 => 6865,10050 => 199,10051 => 7387,
        10052 => 7388,10053 => 6874,10054 => 7156,10055 => 7390,10056 => 3066,10057 => 7391,10058 => 7392,10059 => 86,10060 => 7410,10061 => 7394,10062 => 7380}



old_obs = Observation.find_by_sql("SELECT * FROM obs WHERE value_coded BETWEEN 10001 AND 10062)")

old_obs.each do |ob|
 found = concept_ids[ob.value_coded]
 unless found.nil?
   ob.value_coded = found
   ob.save
   total_saved += 1
   logger.info "Total saved => #{total_saved} concept => #{ob[:concept_id]} value_coded => #{ob[:value_coded]} encounter => #{ob[:encounter_id]}"

 else
   total_unsaved += 1
   logger.info "Total unsaved => #{total_unsaved} concept => #{ob[:concept_id]} value_coded => #{ob[:value_coded]} encounter => #{ob[:encounter_id]}"
 end
end


end_time = Time.now

logger.info "End Time: #{end_time}"
puts "Start Time: #{end_time}\n\n"
logger.info "Total saved: #{total_saved}"
logger.info "It took : #{end_time - start_time}"
logger.info "Completed successfully !!\n\n"


