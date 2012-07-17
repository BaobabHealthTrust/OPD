
UPDATE global_property SET property_value = 'UPDATE HIV STATUS,LAB ORDERS,SPUTUM SUBMISSION,LAB RESULTS,TB REGISTRATION,TB RECEPTION,HIV CLINIC REGISTRATION,HIV RECEPTION,VITALS,HIV STAGING, HIV CLINIC CONSULTATION,ART ADHERENCE,TREATMENT,DISPENSING' WHERE property = 'list.of.clinical.encounters.sequentially';
UPDATE global_property SET property_value = 'Source of referral:Manage Source of Referral,Give lab results:Give Lab Results,Tb clinic visit:Manage TB Clinic Visits,Tb visit:Manage TB Treatment Visits,Hiv clinic consultation:Manage HIV clinic consultations,Hiv staging:Manage HIV staging visits,Update hiv status:Manage HIV Status Visits,Art adherence:Manage ART adherence,Tb reception:Manage TB Reception Visits,Hiv clinic registration:Manage HIV first visits,Lab results:Manage Lab Results,Vitals:Manage Vitals,Sputum submission:Manage Sputum Submissions,Hiv reception:Manage HIV reception visits,Tb registration:Manage TB Registration Visits,Tb clinic visit:Manage TB Clinic Visits,Give drugs:Manage Give Drugs,Lab orders:Manage Lab Orders,Tb initial:Manage TB initial visits,Tb adherence:Manage TB adherence' WHERE property = 'encounter_privilege_map';