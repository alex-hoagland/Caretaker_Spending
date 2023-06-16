/*
*========================================================================*
* Program:   Identifying family risk from diagnosis (HCC_161)             *
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
 * 0. Identify all HCC_161 claims in 2006				  *
 * 1. Identify all *new* HCC_161 claims in (2007-2010)			  *
 * 2. Keep all those who are enrolled at least 5 years post (2012-2015)   *
 * 3. Randomly sample families						  *
 * 4. Calculate rate of new diagnoses and time until dx			  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Diabetics in 2006 -----------------------------------------*/; 
data out.pe_161; 
   set in.ms_o_2006(keep=enrolid dx1 dx2) in.ms_s_2006(keep=enrolid dx1 dx2);
   
   if dx1 in: ('49300', '49301', '49302', '49310', '49311', '49312', '49381', '49382', '49390', '49391', '49392', 'J4520', 'J4521', 'J4522', 'J4530', 'J4531', 'J4532', 'J4540', 'J4541', 'J4542', 'J4550', 'J4551', 'J4552', 'J45901', 'J45902', 'J45909', 'J45990', 'J45991', 'J45998') or 
      dx2 in: ('49300', '49301', '49302', '49310', '49311', '49312', '49381', '49382', '49390', '49391', '49392', 'J4520', 'J4521', 'J4522', 'J4530', 'J4531', 'J4532', 'J4540', 'J4541', 'J4542', 'J4550', 'J4551', 'J4552', 'J45901', 'J45902', 'J45909', 'J45990', 'J45991', 'J45998'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.pe_161 as 
   select enrolid from out.pe_161
   group by enrolid; 
quit; 


/* --- 1. All NEW Diabetics in 2007-2010 -----------------------------------------*/; 
data out.new_161; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_161");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_o_2007(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2007(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2008(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2008(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2009(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2009(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2010(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2010(keep=enrolid age year dx1 dx2 svcdate fachdid);
   if ids.find()^=0;
   
   if dx1 in: ('49300', '49301', '49302', '49310', '49311', '49312', '49381', '49382', '49390', '49391', '49392', 'J4520', 'J4521', 'J4522', 'J4530', 'J4531', 'J4532', 'J4540', 'J4541', 'J4542', 'J4550', 'J4551', 'J4552', 'J45901', 'J45902', 'J45909', 'J45990', 'J45991', 'J45998') or 
      dx2 in: ('49300', '49301', '49302', '49310', '49311', '49312', '49381', '49382', '49390', '49391', '49392', 'J4520', 'J4521', 'J4522', 'J4530', 'J4531', 'J4532', 'J4540', 'J4541', 'J4542', 'J4550', 'J4551', 'J4552', 'J45901', 'J45902', 'J45909', 'J45990', 'J45991', 'J45998'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.new_161 as 
   select enrolid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.new_161
   group by enrolid; 
quit; 

* Make sure these new diabetics have at least a year of non-dx time before hand; 
data out.check_161;
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_161");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_a_2006(keep=enrolid year) in.ms_a_2007(keep=enrolid year) in.ms_a_2008(keep=enrolid year) in.ms_a_2009(keep=enrolid year);
   if ids.find()^=0 then delete;
run; 

proc sql; 
   create table out.check_161 as 
   select enrolid, min(year) as fyear from out.check_161
   group by enrolid; 
quit;

data out.new_161; 
   merge out.new_161 out.check_161; 
   by enrolid;

   if dx_year - fyear < 1 then delete; 
run; 

proc delete data=out.check_161; 
run; 


/* --- 2. Keep all new diabetics enrolled at least 5 years post -----------------------------------------*/;
data out.tomerge_161; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_161");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set in.ms_a_2012(keep=enrolid year) in.ms_a_2013(keep=enrolid year) in.ms_a_2014(keep=enrolid year) in.ms_a_2015(keep=enrolid year); 
   if ids.find()^=0 then delete; 
run; 

* Collapse to enrollee level; 
proc sql;
   create table out.tomerge_161 as 
   select enrolid, max(year) as lyear from out.tomerge_161
   group by enrolid; 
quit; 

* Merge in with out.new_161, keep those with 5 years enrollment;
data out.new_161; 
   merge out.new_161 out.tomerge_161; 

   if lyear - dx_year < 5 then delete; 
   famid = floor(enrolid/100); 
run; 

* Collapse to family ids; 
proc sql; 
   create table out.fams_161 as
   select famid from out.new_161
   group by famid; 
quit; 


/* --- 3. Draw a random sample of these families? -----------------------------------------*/;
* No need for this; 


/* --- 4. Look for secondary diagnoses within these families -----------------------------------------*/;
data out.subsequent_161; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.fams_161");
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

   if dx1 in: ('49300', '49301', '49302', '49310', '49311', '49312', '49381', '49382', '49390', '49391', '49392', 'J4520', 'J4521', 'J4522', 'J4530', 'J4531', 'J4532', 'J4540', 'J4541', 'J4542', 'J4550', 'J4551', 'J4552', 'J45901', 'J45902', 'J45909', 'J45990', 'J45991', 'J45998') or 
      dx2 in: ('49300', '49301', '49302', '49310', '49311', '49312', '49381', '49382', '49390', '49391', '49392', 'J4520', 'J4521', 'J4522', 'J4530', 'J4531', 'J4532', 'J4540', 'J4541', 'J4542', 'J4550', 'J4551', 'J4552', 'J45901', 'J45902', 'J45909', 'J45990', 'J45991', 'J45998'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 

* Remove principal diagnoses;
data out.subsequent_161; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_161");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set out.subsequent_161; 
   if ids.find()^=0;  
run; 

* Collapse to enrollee level; 
proc sql; 
   create table out.subsequent_161 as 
   select enrolid, famid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.subsequent_161
   group by enrolid; 
quit; 


/* --- 5. Merge the two data sets -----------------------------------------*/;   


/* --- N. Delete some superfluous data sets -----------------------------------------*/;
proc delete data=out.tomerge_161; 
run; 

proc delete data=out.fams_161; 
run; 

