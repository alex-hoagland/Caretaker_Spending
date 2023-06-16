/*
*========================================================================*
* Program:   Identifying family risk from diagnosis (HCC_48)             *
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
 * 0. Identify all HCC_48 claims in 2006				  *
 * 1. Identify all *new* HCC_48 claims in (2007-2010)			  *
 * 2. Keep all those who are enrolled at least 5 years post (2012-2015)   *
 * 3. Randomly sample families						  *
 * 4. Calculate rate of new diagnoses and time until dx			  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Diabetics in 2006 -----------------------------------------*/; 
data out.pe_48; 
   set in.ms_o_2006(keep=enrolid dx1 dx2) in.ms_s_2006(keep=enrolid dx1 dx2);
   
   if dx1 in: ('5550', '5551', '5552', '5559', '5560', '5561', '5562', '5563', '5564', '5565', '5566', '5568', '5569', 'K5000', 'K50011', 'K50013', 'K50014', 'K50018', 'K50019', 'K5010', 'K50111', 'K50113', 'K50114', 'K50118', 'K50119', 'K5080', 'K50811', 'K50813', 'K50814', 'K50818', 'K50819', 'K5090', 'K50911', 'K50913', 'K50914', 'K50918', 'K50919', 'K5100', 'K51011', 'K51013', 'K51014', 'K51018', 'K51019', 'K5120', 'K51211', 'K51213', 'K51214', 'K51218', 'K51219', 'K5130', 'K51311', 'K51313', 'K51314', 'K51318', 'K51319', 'K5140', 'K51411', 'K51413', 'K51414', 'K51418', 'K51419', 'K5150', 'K51511', 'K51513', 'K51514', 'K51518', 'K51519', 'K5180', 'K51811', 'K51813', 'K51814', 'K51818', 'K51819', 'K5190', 'K51911', 'K51913', 'K51914', 'K51918', 'K51919', 'K50012', 'K50112', 'K50812', 'K50912', 'K51012', 'K51212', 'K51312', 'K51412', 'K51512', 'K51812', 'K51912') or 
      dx2 in: ('5550', '5551', '5552', '5559', '5560', '5561', '5562', '5563', '5564', '5565', '5566', '5568', '5569', 'K5000', 'K50011', 'K50013', 'K50014', 'K50018', 'K50019', 'K5010', 'K50111', 'K50113', 'K50114', 'K50118', 'K50119', 'K5080', 'K50811', 'K50813', 'K50814', 'K50818', 'K50819', 'K5090', 'K50911', 'K50913', 'K50914', 'K50918', 'K50919', 'K5100', 'K51011', 'K51013', 'K51014', 'K51018', 'K51019', 'K5120', 'K51211', 'K51213', 'K51214', 'K51218', 'K51219', 'K5130', 'K51311', 'K51313', 'K51314', 'K51318', 'K51319', 'K5140', 'K51411', 'K51413', 'K51414', 'K51418', 'K51419', 'K5150', 'K51511', 'K51513', 'K51514', 'K51518', 'K51519', 'K5180', 'K51811', 'K51813', 'K51814', 'K51818', 'K51819', 'K5190', 'K51911', 'K51913', 'K51914', 'K51918', 'K51919', 'K50012', 'K50112', 'K50812', 'K50912', 'K51012', 'K51212', 'K51312', 'K51412', 'K51512', 'K51812', 'K51912'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.pe_48 as 
   select enrolid from out.pe_48
   group by enrolid; 
quit; 


/* --- 1. All NEW Diabetics in 2007-2010 -----------------------------------------*/; 
data out.new_48; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_48");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_o_2007(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2007(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2008(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2008(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2009(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2009(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2010(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2010(keep=enrolid age year dx1 dx2 svcdate fachdid);
   if ids.find()^=0;
   
   if dx1 in: ('5550', '5551', '5552', '5559', '5560', '5561', '5562', '5563', '5564', '5565', '5566', '5568', '5569', 'K5000', 'K50011', 'K50013', 'K50014', 'K50018', 'K50019', 'K5010', 'K50111', 'K50113', 'K50114', 'K50118', 'K50119', 'K5080', 'K50811', 'K50813', 'K50814', 'K50818', 'K50819', 'K5090', 'K50911', 'K50913', 'K50914', 'K50918', 'K50919', 'K5100', 'K51011', 'K51013', 'K51014', 'K51018', 'K51019', 'K5120', 'K51211', 'K51213', 'K51214', 'K51218', 'K51219', 'K5130', 'K51311', 'K51313', 'K51314', 'K51318', 'K51319', 'K5140', 'K51411', 'K51413', 'K51414', 'K51418', 'K51419', 'K5150', 'K51511', 'K51513', 'K51514', 'K51518', 'K51519', 'K5180', 'K51811', 'K51813', 'K51814', 'K51818', 'K51819', 'K5190', 'K51911', 'K51913', 'K51914', 'K51918', 'K51919', 'K50012', 'K50112', 'K50812', 'K50912', 'K51012', 'K51212', 'K51312', 'K51412', 'K51512', 'K51812', 'K51912') or 
      dx2 in: ('5550', '5551', '5552', '5559', '5560', '5561', '5562', '5563', '5564', '5565', '5566', '5568', '5569', 'K5000', 'K50011', 'K50013', 'K50014', 'K50018', 'K50019', 'K5010', 'K50111', 'K50113', 'K50114', 'K50118', 'K50119', 'K5080', 'K50811', 'K50813', 'K50814', 'K50818', 'K50819', 'K5090', 'K50911', 'K50913', 'K50914', 'K50918', 'K50919', 'K5100', 'K51011', 'K51013', 'K51014', 'K51018', 'K51019', 'K5120', 'K51211', 'K51213', 'K51214', 'K51218', 'K51219', 'K5130', 'K51311', 'K51313', 'K51314', 'K51318', 'K51319', 'K5140', 'K51411', 'K51413', 'K51414', 'K51418', 'K51419', 'K5150', 'K51511', 'K51513', 'K51514', 'K51518', 'K51519', 'K5180', 'K51811', 'K51813', 'K51814', 'K51818', 'K51819', 'K5190', 'K51911', 'K51913', 'K51914', 'K51918', 'K51919', 'K50012', 'K50112', 'K50812', 'K50912', 'K51012', 'K51212', 'K51312', 'K51412', 'K51512', 'K51812', 'K51912'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.new_48 as 
   select enrolid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.new_48
   group by enrolid; 
quit; 

* Make sure these new diabetics have at least a year of non-dx time before hand; 
data out.check_48;
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_48");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_a_2006(keep=enrolid year) in.ms_a_2007(keep=enrolid year) in.ms_a_2008(keep=enrolid year) in.ms_a_2009(keep=enrolid year);
   if ids.find()^=0 then delete;
run; 

proc sql; 
   create table out.check_48 as 
   select enrolid, min(year) as fyear from out.check_48
   group by enrolid; 
quit;

data out.new_48; 
   merge out.new_48 out.check_48; 
   by enrolid;

   if dx_year - fyear < 1 then delete; 
run; 

proc delete data=out.check_48; 
run; 


/* --- 2. Keep all new diabetics enrolled at least 5 years post -----------------------------------------*/;
data out.tomerge_48; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_48");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set in.ms_a_2012(keep=enrolid year) in.ms_a_2013(keep=enrolid year) in.ms_a_2014(keep=enrolid year) in.ms_a_2015(keep=enrolid year); 
   if ids.find()^=0 then delete; 
run; 

* Collapse to enrollee level; 
proc sql;
   create table out.tomerge_48 as 
   select enrolid, max(year) as lyear from out.tomerge_48
   group by enrolid; 
quit; 

* Merge in with out.new_48, keep those with 5 years enrollment;
data out.new_48; 
   merge out.new_48 out.tomerge_48; 

   if lyear - dx_year < 5 then delete; 
   famid = floor(enrolid/100); 
run; 

* Collapse to family ids; 
proc sql; 
   create table out.fams_48 as
   select famid from out.new_48
   group by famid; 
quit; 


/* --- 3. Draw a random sample of these families? -----------------------------------------*/;
* No need for this; 


/* --- 4. Look for secondary diagnoses within these families -----------------------------------------*/;
data out.subsequent_48; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.fams_48");
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

   if dx1 in: ('5550', '5551', '5552', '5559', '5560', '5561', '5562', '5563', '5564', '5565', '5566', '5568', '5569', 'K5000', 'K50011', 'K50013', 'K50014', 'K50018', 'K50019', 'K5010', 'K50111', 'K50113', 'K50114', 'K50118', 'K50119', 'K5080', 'K50811', 'K50813', 'K50814', 'K50818', 'K50819', 'K5090', 'K50911', 'K50913', 'K50914', 'K50918', 'K50919', 'K5100', 'K51011', 'K51013', 'K51014', 'K51018', 'K51019', 'K5120', 'K51211', 'K51213', 'K51214', 'K51218', 'K51219', 'K5130', 'K51311', 'K51313', 'K51314', 'K51318', 'K51319', 'K5140', 'K51411', 'K51413', 'K51414', 'K51418', 'K51419', 'K5150', 'K51511', 'K51513', 'K51514', 'K51518', 'K51519', 'K5180', 'K51811', 'K51813', 'K51814', 'K51818', 'K51819', 'K5190', 'K51911', 'K51913', 'K51914', 'K51918', 'K51919', 'K50012', 'K50112', 'K50812', 'K50912', 'K51012', 'K51212', 'K51312', 'K51412', 'K51512', 'K51812', 'K51912') or 
      dx2 in: ('5550', '5551', '5552', '5559', '5560', '5561', '5562', '5563', '5564', '5565', '5566', '5568', '5569', 'K5000', 'K50011', 'K50013', 'K50014', 'K50018', 'K50019', 'K5010', 'K50111', 'K50113', 'K50114', 'K50118', 'K50119', 'K5080', 'K50811', 'K50813', 'K50814', 'K50818', 'K50819', 'K5090', 'K50911', 'K50913', 'K50914', 'K50918', 'K50919', 'K5100', 'K51011', 'K51013', 'K51014', 'K51018', 'K51019', 'K5120', 'K51211', 'K51213', 'K51214', 'K51218', 'K51219', 'K5130', 'K51311', 'K51313', 'K51314', 'K51318', 'K51319', 'K5140', 'K51411', 'K51413', 'K51414', 'K51418', 'K51419', 'K5150', 'K51511', 'K51513', 'K51514', 'K51518', 'K51519', 'K5180', 'K51811', 'K51813', 'K51814', 'K51818', 'K51819', 'K5190', 'K51911', 'K51913', 'K51914', 'K51918', 'K51919', 'K50012', 'K50112', 'K50812', 'K50912', 'K51012', 'K51212', 'K51312', 'K51412', 'K51512', 'K51812', 'K51912'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 

* Remove principal diagnoses;
data out.subsequent_48; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_48");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set out.subsequent_48; 
   if ids.find()^=0;  
run; 

* Collapse to enrollee level; 
proc sql; 
   create table out.subsequent_48 as 
   select enrolid, famid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.subsequent_48
   group by enrolid; 
quit; 


/* --- 5. Merge the two data sets -----------------------------------------*/;   


/* --- N. Delete some superfluous data sets -----------------------------------------*/;
proc delete data=out.tomerge_48; 
run; 

proc delete data=out.fams_48; 
run; 

