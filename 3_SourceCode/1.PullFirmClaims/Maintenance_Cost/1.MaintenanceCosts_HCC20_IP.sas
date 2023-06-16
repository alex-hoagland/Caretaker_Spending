/*
*========================================================================*
* Program:   HCCClaimsIP.sas     		                         *
*                                                                        *
* Purpose:   This program pulls all IP claims for specific chronic HCCs  *
*		in the MarketScan data. 				 * 
*                                                                        *
* Author:    Alex Hoagland						 *
*            Boston University				                 *
*                                                                        *
* Created:   Sep 30, 2020	                                         *
* Updated:  				                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/*------------------------------------------------------------------------*
 * 		ORDER OF OPERATIONS					  *
 * 0. Identify all those with HCCs in 2006				  *
 * 1. Identify all claims based for specific individual/dx's ('07-'18)    *
 * 2. Collapse to yearly spending level for individual-dx		  *
 *------------------------------------------------------------------------*/;

*** Pull all INPATIENT maintenance costs for these enrollees (2007-2018); 
data out.maintenance_costs_hcc20_ip; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_maintenancesample_hcc20");
   ids.definekey('enrolid');
   ids.definedone();
   end;
    set in.ms_s_2007(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2008(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2009(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2010(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2011(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2012(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2013(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2014(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2015(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2016(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2017(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2018(keep=enrolid year pay cob copay coins deduct dx: ); 
   if ids.find()^=0 then delete;

   hcc = 0; 
    
    *20     "Diabetes w/ Comp.";
    if (dx1 in: ('24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25040', '25041', '25042', '25043', '25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', '25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36207', '36641', 'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E08329', 'E08331', 'E08339', 'E08341', 'E08349', 'E08351', 'E08359', 'E0836', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08649', 'E0865', 'E0869', 'E088', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E09329', 'E09331', 'E09339', 'E09341', 'E09349', 'E09351', 'E09359', 'E0936', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09649', 'E0965', 'E0969', 'E098', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E10329', 'E10331', 'E10339', 'E10341', 'E10349', 'E10351', 'E10359', 'E1036', 'E1039', 'E1040', 'E1041', 'E1042', 'E1043', 'E1044', 'E1049', 'E1051', 'E1052', 'E1059', 'E10610', 'E10618', 'E10620', 'E10621', 'E10622', 'E10628', 'E10630', 'E10638', 'E10649', 'E1065', 'E1069', 'E108', 'E1121', 'E1122', 'E1129', 'E11311', 'E11319', 'E11321', 'E11329', 'E11331', 'E11339', 'E11341', 'E11349', 'E11351', 'E11359', 'E1136', 'E1139', 'E1140', 'E1141', 'E1142', 'E1143', 'E1144', 'E1149', 'E1151', 'E1152', 'E1159', 'E11610', 'E11618', 'E11620', 'E11621', 'E11622', 'E11628', 'E11630', 'E11638', 'E11649', 'E1165', 'E1169', 'E118', 'E1321', 'E1322', 'E1329', 'E13311', 'E13319', 'E13321', 'E13329', 'E13331', 'E13339', 'E13341', 'E13349', 'E13351', 'E13359', 'E1336', 'E1339', 'E1340', 'E1341', 'E1342', 'E1343', 'E1344', 'E1349', 'E1351', 'E1352', 'E1359', 'E13610', 'E13618', 'E13620', 'E13621', 'E13622', 'E13628', 'E13630', 'E13638', 'E13649', 'E1365', 'E1369', 'E138') or 
        dx2 in: ('24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25040', '25041', '25042', '25043', '25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', '25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36207', '36641', 'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E08329', 'E08331', 'E08339', 'E08341', 'E08349', 'E08351', 'E08359', 'E0836', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08649', 'E0865', 'E0869', 'E088', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E09329', 'E09331', 'E09339', 'E09341', 'E09349', 'E09351', 'E09359', 'E0936', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09649', 'E0965', 'E0969', 'E098', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E10329', 'E10331', 'E10339', 'E10341', 'E10349', 'E10351', 'E10359', 'E1036', 'E1039', 'E1040', 'E1041', 'E1042', 'E1043', 'E1044', 'E1049', 'E1051', 'E1052', 'E1059', 'E10610', 'E10618', 'E10620', 'E10621', 'E10622', 'E10628', 'E10630', 'E10638', 'E10649', 'E1065', 'E1069', 'E108', 'E1121', 'E1122', 'E1129', 'E11311', 'E11319', 'E11321', 'E11329', 'E11331', 'E11339', 'E11341', 'E11349', 'E11351', 'E11359', 'E1136', 'E1139', 'E1140', 'E1141', 'E1142', 'E1143', 'E1144', 'E1149', 'E1151', 'E1152', 'E1159', 'E11610', 'E11618', 'E11620', 'E11621', 'E11622', 'E11628', 'E11630', 'E11638', 'E11649', 'E1165', 'E1169', 'E118', 'E1321', 'E1322', 'E1329', 'E13311', 'E13319', 'E13321', 'E13329', 'E13331', 'E13339', 'E13341', 'E13349', 'E13351', 'E13359', 'E1336', 'E1339', 'E1340', 'E1341', 'E1342', 'E1343', 'E1344', 'E1349', 'E1351', 'E1352', 'E1359', 'E13610', 'E13618', 'E13620', 'E13621', 'E13622', 'E13628', 'E13630', 'E13638', 'E13649', 'E1365', 'E1369', 'E138')) 
        then hcc=20; 

   if hcc = 0 then delete;   
  
   oop = copay + cob + coins + deduct;
run; 


*** Collapse to yearly spending by enrollee-hcc pairing (eventually need to merge this back into main sample);  
proc sql; 
   create table out.maintenance_costs_hcc20_ip as 
   select enrolid, hcc, year, sum(oop) as ip_oop, sum(pay) as ip_pay from out.maintenance_costs_hcc20_ip
   group by enrolid, hcc, year; 
quit;


*** Adjust for inflation; 
data out.maintenance_costs_hcc20_ip; 
   set out.maintenance_costs_hcc20_ip;

   * Change all spending to 2020 dollars;
   if year = 2006 then oop = oop * 1.2788;
   if year = 2006 then pay = pay * 1.2788 ;
   if year = 2007 then oop = oop * 1.2449;
   if year = 2007 then pay = pay * 1.2449;
   if year = 2008 then oop = oop * 1.1988;
   if year = 2008 then pay = pay * 1.1988 ;
   if year = 2009 then oop = oop * 1.2031 ;
   if year = 2009 then pay = pay * 1.2031 ;
   if year = 2010 then oop = oop * 1.1837 ;
   if year = 2010 then pay = pay * 1.1837 ;
   if year = 2011 then oop = oop * 1.1475 ;
   if year = 2011 then pay = pay * 1.1475 ;
   if year = 2012 then oop = oop * 1.1242 ;
   if year = 2012 then pay = pay * 1.1242  ;
   if year = 2013 then oop = oop * 1.1080 ;
   if year = 2013 then pay = pay * 1.1080 ;
   if year = 2014 then oop = oop * 1.0903 ;
   if year = 2014 then pay = pay * 1.0903 ;
   if year = 2015 then oop = oop * 1.0890 ;
   if year = 2015 then pay = pay * 1.0890 ;
   if year = 2016 then oop = oop * 1.0754 ;
   if year = 2016 then pay = pay * 1.0754 ;
   if year = 2017 then oop = oop * 1.0530 ;
   if year = 2017 then pay = pay * 1.0530 ;
   if year = 2018 then oop = oop * 1.0261 ;
   if year = 2018 then pay = pay * 1.0261 ;
run; 
