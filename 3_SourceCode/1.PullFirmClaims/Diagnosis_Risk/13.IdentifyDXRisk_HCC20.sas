/*
*========================================================================*
* Program:   Identifying family risk from diagnosis (HCC_20)             *
*                                                                        *
* Purpose:   This code identifies non-sample individuals diagnosed 	 *
* 		with an HCC in 2007. Then, calculates the rate at which  *
*		other family members are diagnosed in next 10 years.     *
*                                                                        *
* Note: This file							 *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*									 *
* Created:   October, 2020		                                 *
* Updated:  		                                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/*------------------------------------------------------------------------*
 * 		ORDER OF OPERATIONS					  *
 * 0. Identify all HCC_20 claims in 2006				  *
 * 1. Identify all *new* HCC_20 claims in (2007-2010)			  *
 * 2. Keep all those who are enrolled at least 5 years post (2012-2015)   *
 * 3. Randomly sample families						  *
 * 4. Calculate rate of new diagnoses and time until dx			  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Diabetics in 2006 -----------------------------------------*/; 
data out.pe_20; 
   set in.ms_o_2006(keep=enrolid dx1 dx2) in.ms_s_2006(keep=enrolid dx1 dx2);
   
    if dx1 in: ('24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25040', '25041', '25042', '25043', '25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', '25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36207', '36641', 'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E08329', 'E08331', 'E08339', 'E08341', 'E08349', 'E08351', 'E08359', 'E0836', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08649', 'E0865', 'E0869', 'E088', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E09329', 'E09331', 'E09339', 'E09341', 'E09349', 'E09351', 'E09359', 'E0936', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09649', 'E0965', 'E0969', 'E098', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E10329', 'E10331', 'E10339', 'E10341', 'E10349', 'E10351', 'E10359', 'E1036', 'E1039', 'E1040', 'E1041', 'E1042', 'E1043', 'E1044', 'E1049', 'E1051', 'E1052', 'E1059', 'E10610', 'E10618', 'E10620', 'E10621', 'E10622', 'E10628', 'E10630', 'E10638', 'E10649', 'E1065', 'E1069', 'E108', 'E1121', 'E1122', 'E1129', 'E11311', 'E11319', 'E11321', 'E11329', 'E11331', 'E11339', 'E11341', 'E11349', 'E11351', 'E11359', 'E1136', 'E1139', 'E1140', 'E1141', 'E1142', 'E1143', 'E1144', 'E1149', 'E1151', 'E1152', 'E1159', 'E11610', 'E11618', 'E11620', 'E11621', 'E11622', 'E11628', 'E11630', 'E11638', 'E11649', 'E1165', 'E1169', 'E118', 'E1321', 'E1322', 'E1329', 'E13311', 'E13319', 'E13321', 'E13329', 'E13331', 'E13339', 'E13341', 'E13349', 'E13351', 'E13359', 'E1336', 'E1339', 'E1340', 'E1341', 'E1342', 'E1343', 'E1344', 'E1349', 'E1351', 'E1352', 'E1359', 'E13610', 'E13618', 'E13620', 'E13621', 'E13622', 'E13628', 'E13630', 'E13638', 'E13649', 'E1365', 'E1369', 'E138') or 
      dx2 in: ('24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25040', '25041', '25042', '25043', '25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', '25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36207', '36641', 'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E08329', 'E08331', 'E08339', 'E08341', 'E08349', 'E08351', 'E08359', 'E0836', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08649', 'E0865', 'E0869', 'E088', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E09329', 'E09331', 'E09339', 'E09341', 'E09349', 'E09351', 'E09359', 'E0936', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09649', 'E0965', 'E0969', 'E098', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E10329', 'E10331', 'E10339', 'E10341', 'E10349', 'E10351', 'E10359', 'E1036', 'E1039', 'E1040', 'E1041', 'E1042', 'E1043', 'E1044', 'E1049', 'E1051', 'E1052', 'E1059', 'E10610', 'E10618', 'E10620', 'E10621', 'E10622', 'E10628', 'E10630', 'E10638', 'E10649', 'E1065', 'E1069', 'E108', 'E1121', 'E1122', 'E1129', 'E11311', 'E11319', 'E11321', 'E11329', 'E11331', 'E11339', 'E11341', 'E11349', 'E11351', 'E11359', 'E1136', 'E1139', 'E1140', 'E1141', 'E1142', 'E1143', 'E1144', 'E1149', 'E1151', 'E1152', 'E1159', 'E11610', 'E11618', 'E11620', 'E11621', 'E11622', 'E11628', 'E11630', 'E11638', 'E11649', 'E1165', 'E1169', 'E118', 'E1321', 'E1322', 'E1329', 'E13311', 'E13319', 'E13321', 'E13329', 'E13331', 'E13339', 'E13341', 'E13349', 'E13351', 'E13359', 'E1336', 'E1339', 'E1340', 'E1341', 'E1342', 'E1343', 'E1344', 'E1349', 'E1351', 'E1352', 'E1359', 'E13610', 'E13618', 'E13620', 'E13621', 'E13622', 'E13628', 'E13630', 'E13638', 'E13649', 'E1365', 'E1369', 'E138'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.pe_20 as 
   select enrolid from out.pe_20
   group by enrolid; 
quit; 


/* --- 1. All NEW Diabetics in 2007-2010 -----------------------------------------*/; 
data out.new_20; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_20");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_o_2007(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2007(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2008(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2008(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2009(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2009(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2010(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2010(keep=enrolid age year dx1 dx2 svcdate fachdid);
   if ids.find()^=0;
   
    if dx1 in: ('24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25040', '25041', '25042', '25043', '25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', '25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36207', '36641', 'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E08329', 'E08331', 'E08339', 'E08341', 'E08349', 'E08351', 'E08359', 'E0836', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08649', 'E0865', 'E0869', 'E088', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E09329', 'E09331', 'E09339', 'E09341', 'E09349', 'E09351', 'E09359', 'E0936', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09649', 'E0965', 'E0969', 'E098', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E10329', 'E10331', 'E10339', 'E10341', 'E10349', 'E10351', 'E10359', 'E1036', 'E1039', 'E1040', 'E1041', 'E1042', 'E1043', 'E1044', 'E1049', 'E1051', 'E1052', 'E1059', 'E10610', 'E10618', 'E10620', 'E10621', 'E10622', 'E10628', 'E10630', 'E10638', 'E10649', 'E1065', 'E1069', 'E108', 'E1121', 'E1122', 'E1129', 'E11311', 'E11319', 'E11321', 'E11329', 'E11331', 'E11339', 'E11341', 'E11349', 'E11351', 'E11359', 'E1136', 'E1139', 'E1140', 'E1141', 'E1142', 'E1143', 'E1144', 'E1149', 'E1151', 'E1152', 'E1159', 'E11610', 'E11618', 'E11620', 'E11621', 'E11622', 'E11628', 'E11630', 'E11638', 'E11649', 'E1165', 'E1169', 'E118', 'E1321', 'E1322', 'E1329', 'E13311', 'E13319', 'E13321', 'E13329', 'E13331', 'E13339', 'E13341', 'E13349', 'E13351', 'E13359', 'E1336', 'E1339', 'E1340', 'E1341', 'E1342', 'E1343', 'E1344', 'E1349', 'E1351', 'E1352', 'E1359', 'E13610', 'E13618', 'E13620', 'E13621', 'E13622', 'E13628', 'E13630', 'E13638', 'E13649', 'E1365', 'E1369', 'E138') or 
      dx2 in: ('24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25040', '25041', '25042', '25043', '25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', '25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36207', '36641', 'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E08329', 'E08331', 'E08339', 'E08341', 'E08349', 'E08351', 'E08359', 'E0836', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08649', 'E0865', 'E0869', 'E088', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E09329', 'E09331', 'E09339', 'E09341', 'E09349', 'E09351', 'E09359', 'E0936', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09649', 'E0965', 'E0969', 'E098', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E10329', 'E10331', 'E10339', 'E10341', 'E10349', 'E10351', 'E10359', 'E1036', 'E1039', 'E1040', 'E1041', 'E1042', 'E1043', 'E1044', 'E1049', 'E1051', 'E1052', 'E1059', 'E10610', 'E10618', 'E10620', 'E10621', 'E10622', 'E10628', 'E10630', 'E10638', 'E10649', 'E1065', 'E1069', 'E108', 'E1121', 'E1122', 'E1129', 'E11311', 'E11319', 'E11321', 'E11329', 'E11331', 'E11339', 'E11341', 'E11349', 'E11351', 'E11359', 'E1136', 'E1139', 'E1140', 'E1141', 'E1142', 'E1143', 'E1144', 'E1149', 'E1151', 'E1152', 'E1159', 'E11610', 'E11618', 'E11620', 'E11621', 'E11622', 'E11628', 'E11630', 'E11638', 'E11649', 'E1165', 'E1169', 'E118', 'E1321', 'E1322', 'E1329', 'E13311', 'E13319', 'E13321', 'E13329', 'E13331', 'E13339', 'E13341', 'E13349', 'E13351', 'E13359', 'E1336', 'E1339', 'E1340', 'E1341', 'E1342', 'E1343', 'E1344', 'E1349', 'E1351', 'E1352', 'E1359', 'E13610', 'E13618', 'E13620', 'E13621', 'E13622', 'E13628', 'E13630', 'E13638', 'E13649', 'E1365', 'E1369', 'E138'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.new_20 as 
   select enrolid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.new_20
   group by enrolid; 
quit; 

* Make sure these new diabetics have at least a year of non-dx time before hand; 
data out.check_20;
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_20");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_a_2006(keep=enrolid year) in.ms_a_2007(keep=enrolid year) in.ms_a_2008(keep=enrolid year) in.ms_a_2009(keep=enrolid year);
   if ids.find()^=0 then delete;
run; 

proc sql; 
   create table out.check_20 as 
   select enrolid, min(year) as fyear from out.check_20
   group by enrolid; 
quit;

data out.new_20; 
   merge out.new_20 out.check_20; 
   by enrolid;

   if dx_year - fyear < 1 then delete; 
run; 

proc delete data=out.check_20; 
run; 


/* --- 2. Keep all new diabetics enrolled at least 5 years post -----------------------------------------*/;
data out.tomerge_20; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_20");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set in.ms_a_2012(keep=enrolid year) in.ms_a_2013(keep=enrolid year) in.ms_a_2014(keep=enrolid year) in.ms_a_2015(keep=enrolid year); 
   if ids.find()^=0 then delete; 
run; 

* Collapse to enrollee level; 
proc sql;
   create table out.tomerge_20 as 
   select enrolid, max(year) as lyear from out.tomerge_20
   group by enrolid; 
quit; 

* Merge in with out.new_20, keep those with 5 years enrollment;
data out.new_20; 
   merge out.new_20 out.tomerge_20; 

   if lyear - dx_year < 5 then delete; 
   famid = floor(enrolid/100); 
run; 

* Collapse to family ids; 
proc sql; 
   create table out.fams_20 as
   select famid from out.new_20
   group by famid; 
quit; 


/* --- 3. Draw a random sample of these families? -----------------------------------------*/;
* No need for this; 


/* --- 4. Look for secondary diagnoses within these families -----------------------------------------*/;
data out.subsequent_20; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.fams_20");
   ids.definekey('famid');
   ids.definedone();
   end; 

   set in.ms_o_2008(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2008(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2009(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2009(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2010(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2010(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2011(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2011(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2012(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2012(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2013(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2013(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2014(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2014(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2015(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2015(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2016(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2016(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2017(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2017(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2018(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2018(keep=enrolid age year dx1 dx2 svcdate fachdid);
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

    if dx1 in: ('24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25040', '25041', '25042', '25043', '25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', '25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36207', '36641', 'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E08329', 'E08331', 'E08339', 'E08341', 'E08349', 'E08351', 'E08359', 'E0836', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08649', 'E0865', 'E0869', 'E088', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E09329', 'E09331', 'E09339', 'E09341', 'E09349', 'E09351', 'E09359', 'E0936', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09649', 'E0965', 'E0969', 'E098', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E10329', 'E10331', 'E10339', 'E10341', 'E10349', 'E10351', 'E10359', 'E1036', 'E1039', 'E1040', 'E1041', 'E1042', 'E1043', 'E1044', 'E1049', 'E1051', 'E1052', 'E1059', 'E10610', 'E10618', 'E10620', 'E10621', 'E10622', 'E10628', 'E10630', 'E10638', 'E10649', 'E1065', 'E1069', 'E108', 'E1121', 'E1122', 'E1129', 'E11311', 'E11319', 'E11321', 'E11329', 'E11331', 'E11339', 'E11341', 'E11349', 'E11351', 'E11359', 'E1136', 'E1139', 'E1140', 'E1141', 'E1142', 'E1143', 'E1144', 'E1149', 'E1151', 'E1152', 'E1159', 'E11610', 'E11618', 'E11620', 'E11621', 'E11622', 'E11628', 'E11630', 'E11638', 'E11649', 'E1165', 'E1169', 'E118', 'E1321', 'E1322', 'E1329', 'E13311', 'E13319', 'E13321', 'E13329', 'E13331', 'E13339', 'E13341', 'E13349', 'E13351', 'E13359', 'E1336', 'E1339', 'E1340', 'E1341', 'E1342', 'E1343', 'E1344', 'E1349', 'E1351', 'E1352', 'E1359', 'E13610', 'E13618', 'E13620', 'E13621', 'E13622', 'E13628', 'E13630', 'E13638', 'E13649', 'E1365', 'E1369', 'E138') or 
      dx2 in: ('24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25040', '25041', '25042', '25043', '25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', '25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36207', '36641', 'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E08329', 'E08331', 'E08339', 'E08341', 'E08349', 'E08351', 'E08359', 'E0836', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08649', 'E0865', 'E0869', 'E088', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E09329', 'E09331', 'E09339', 'E09341', 'E09349', 'E09351', 'E09359', 'E0936', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09649', 'E0965', 'E0969', 'E098', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E10329', 'E10331', 'E10339', 'E10341', 'E10349', 'E10351', 'E10359', 'E1036', 'E1039', 'E1040', 'E1041', 'E1042', 'E1043', 'E1044', 'E1049', 'E1051', 'E1052', 'E1059', 'E10610', 'E10618', 'E10620', 'E10621', 'E10622', 'E10628', 'E10630', 'E10638', 'E10649', 'E1065', 'E1069', 'E108', 'E1121', 'E1122', 'E1129', 'E11311', 'E11319', 'E11321', 'E11329', 'E11331', 'E11339', 'E11341', 'E11349', 'E11351', 'E11359', 'E1136', 'E1139', 'E1140', 'E1141', 'E1142', 'E1143', 'E1144', 'E1149', 'E1151', 'E1152', 'E1159', 'E11610', 'E11618', 'E11620', 'E11621', 'E11622', 'E11628', 'E11630', 'E11638', 'E11649', 'E1165', 'E1169', 'E118', 'E1321', 'E1322', 'E1329', 'E13311', 'E13319', 'E13321', 'E13329', 'E13331', 'E13339', 'E13341', 'E13349', 'E13351', 'E13359', 'E1336', 'E1339', 'E1340', 'E1341', 'E1342', 'E1343', 'E1344', 'E1349', 'E1351', 'E1352', 'E1359', 'E13610', 'E13618', 'E13620', 'E13621', 'E13622', 'E13628', 'E13630', 'E13638', 'E13649', 'E1365', 'E1369', 'E138'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 

* Remove principal diagnoses;
data out.subsequent_20; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_20");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set out.subsequent_20; 
   if ids.find()^=0;  
run; 

* Collapse to enrollee level; 
proc sql; 
   create table out.subsequent_20 as 
   select enrolid, famid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.subsequent_20
   group by enrolid; 
quit; 


/* --- 5. Merge the two data sets -----------------------------------------*/;   


/* --- N. Delete some superfluous data sets -----------------------------------------*/;
proc delete data=out.tomerge_20; 
run; 

proc delete data=out.fams_20; 
run; 
