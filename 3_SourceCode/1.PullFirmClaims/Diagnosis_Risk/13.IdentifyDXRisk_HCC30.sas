/*
*========================================================================*
* Program:   Identifying family risk from diagnosis (HCC_30)             *
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
 * 0. Identify all HCC_30 claims in 2006				  *
 * 1. Identify all *new* HCC_30 claims in (2007-2010)			  *
 * 2. Keep all those who are enrolled at least 5 years post (2012-2015)   *
 * 3. Randomly sample families						  *
 * 4. Calculate rate of new diagnoses and time until dx			  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Diabetics in 2006 -----------------------------------------*/; 
data out.pe_30; 
   set in.ms_o_2006(keep=enrolid dx1 dx2) in.ms_s_2006(keep=enrolid dx1 dx2);
   
   if dx1 in: ('0363', '2510', '25200', '25201', '25202', '25208', '2521', '2528', '2529', '2530', '2531', '2532', '2533', '2534', '2535', '2536', '2537', '2538', '2539', '2540', '2541', '2548', '2549', '2550', '25510', '25511', '25512', '25513', '25514', '2552', '2553', '25541', '25542', '2555', '2556', '2558', '2559', '25801', '25802', '25803', '2581', '2588', '2589', '5881', '58881', 'A391', 'E035', 'E15', 'E200', 'E208', 'E209', 'E210', 'E211', 'E212', 'E213', 'E214', 'E215', 'E220', 'E221', 'E222', 'E228', 'E229', 'E230', 'E231', 'E232', 'E233', 'E236', 'E237', 'E240', 'E241', 'E242', 'E243', 'E244', 'E248', 'E249', 'E250', 'E258', 'E259', 'E2601', 'E2602', 'E2609', 'E261', 'E2681', 'E2689', 'E269', 'E270', 'E271', 'E272', 'E273', 'E2740', 'E2749', 'E275', 'E278', 'E279', 'E310', 'E311', 'E3120', 'E3121', 'E3122', 'E3123', 'E318', 'E319', 'E320', 'E321', 'E328', 'E329', 'E344', 'E892', 'E893', 'E896', 'N251', 'N2581') or 
      dx2 in: ('0363', '2510', '25200', '25201', '25202', '25208', '2521', '2528', '2529', '2530', '2531', '2532', '2533', '2534', '2535', '2536', '2537', '2538', '2539', '2540', '2541', '2548', '2549', '2550', '25510', '25511', '25512', '25513', '25514', '2552', '2553', '25541', '25542', '2555', '2556', '2558', '2559', '25801', '25802', '25803', '2581', '2588', '2589', '5881', '58881', 'A391', 'E035', 'E15', 'E200', 'E208', 'E209', 'E210', 'E211', 'E212', 'E213', 'E214', 'E215', 'E220', 'E221', 'E222', 'E228', 'E229', 'E230', 'E231', 'E232', 'E233', 'E236', 'E237', 'E240', 'E241', 'E242', 'E243', 'E244', 'E248', 'E249', 'E250', 'E258', 'E259', 'E2601', 'E2602', 'E2609', 'E261', 'E2681', 'E2689', 'E269', 'E270', 'E271', 'E272', 'E273', 'E2740', 'E2749', 'E275', 'E278', 'E279', 'E310', 'E311', 'E3120', 'E3121', 'E3122', 'E3123', 'E318', 'E319', 'E320', 'E321', 'E328', 'E329', 'E344', 'E892', 'E893', 'E896', 'N251', 'N2581'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.pe_30 as 
   select enrolid from out.pe_30
   group by enrolid; 
quit; 


/* --- 1. All NEW Diabetics in 2007-2010 -----------------------------------------*/; 
data out.new_30; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_30");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_o_2007(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2007(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2008(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2008(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2009(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2009(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2010(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2010(keep=enrolid age year dx1 dx2 svcdate fachdid);
   if ids.find()^=0;
   
   if dx1 in: ('0363', '2510', '25200', '25201', '25202', '25208', '2521', '2528', '2529', '2530', '2531', '2532', '2533', '2534', '2535', '2536', '2537', '2538', '2539', '2540', '2541', '2548', '2549', '2550', '25510', '25511', '25512', '25513', '25514', '2552', '2553', '25541', '25542', '2555', '2556', '2558', '2559', '25801', '25802', '25803', '2581', '2588', '2589', '5881', '58881', 'A391', 'E035', 'E15', 'E200', 'E208', 'E209', 'E210', 'E211', 'E212', 'E213', 'E214', 'E215', 'E220', 'E221', 'E222', 'E228', 'E229', 'E230', 'E231', 'E232', 'E233', 'E236', 'E237', 'E240', 'E241', 'E242', 'E243', 'E244', 'E248', 'E249', 'E250', 'E258', 'E259', 'E2601', 'E2602', 'E2609', 'E261', 'E2681', 'E2689', 'E269', 'E270', 'E271', 'E272', 'E273', 'E2740', 'E2749', 'E275', 'E278', 'E279', 'E310', 'E311', 'E3120', 'E3121', 'E3122', 'E3123', 'E318', 'E319', 'E320', 'E321', 'E328', 'E329', 'E344', 'E892', 'E893', 'E896', 'N251', 'N2581') or 
      dx2 in: ('0363', '2510', '25200', '25201', '25202', '25208', '2521', '2528', '2529', '2530', '2531', '2532', '2533', '2534', '2535', '2536', '2537', '2538', '2539', '2540', '2541', '2548', '2549', '2550', '25510', '25511', '25512', '25513', '25514', '2552', '2553', '25541', '25542', '2555', '2556', '2558', '2559', '25801', '25802', '25803', '2581', '2588', '2589', '5881', '58881', 'A391', 'E035', 'E15', 'E200', 'E208', 'E209', 'E210', 'E211', 'E212', 'E213', 'E214', 'E215', 'E220', 'E221', 'E222', 'E228', 'E229', 'E230', 'E231', 'E232', 'E233', 'E236', 'E237', 'E240', 'E241', 'E242', 'E243', 'E244', 'E248', 'E249', 'E250', 'E258', 'E259', 'E2601', 'E2602', 'E2609', 'E261', 'E2681', 'E2689', 'E269', 'E270', 'E271', 'E272', 'E273', 'E2740', 'E2749', 'E275', 'E278', 'E279', 'E310', 'E311', 'E3120', 'E3121', 'E3122', 'E3123', 'E318', 'E319', 'E320', 'E321', 'E328', 'E329', 'E344', 'E892', 'E893', 'E896', 'N251', 'N2581'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.new_30 as 
   select enrolid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.new_30
   group by enrolid; 
quit; 

* Make sure these new diabetics have at least a year of non-dx time before hand; 
data out.check_30;
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_30");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_a_2006(keep=enrolid year) in.ms_a_2007(keep=enrolid year) in.ms_a_2008(keep=enrolid year) in.ms_a_2009(keep=enrolid year);
   if ids.find()^=0 then delete;
run; 

proc sql; 
   create table out.check_30 as 
   select enrolid, min(year) as fyear from out.check_30
   group by enrolid; 
quit;

data out.new_30; 
   merge out.new_30 out.check_30; 
   by enrolid;

   if dx_year - fyear < 1 then delete; 
run; 

proc delete data=out.check_30; 
run; 


/* --- 2. Keep all new diabetics enrolled at least 5 years post -----------------------------------------*/;
data out.tomerge_30; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_30");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set in.ms_a_2012(keep=enrolid year) in.ms_a_2013(keep=enrolid year) in.ms_a_2014(keep=enrolid year) in.ms_a_2015(keep=enrolid year); 
   if ids.find()^=0 then delete; 
run; 

* Collapse to enrollee level; 
proc sql;
   create table out.tomerge_30 as 
   select enrolid, max(year) as lyear from out.tomerge_30
   group by enrolid; 
quit; 

* Merge in with out.new_30, keep those with 5 years enrollment;
data out.new_30; 
   merge out.new_30 out.tomerge_30; 

   if lyear - dx_year < 5 then delete; 
   famid = floor(enrolid/100); 
run; 

* Collapse to family ids; 
proc sql; 
   create table out.fams_30 as
   select famid from out.new_30
   group by famid; 
quit; 


/* --- 3. Draw a random sample of these families? -----------------------------------------*/;
* No need for this; 


/* --- 4. Look for secondary diagnoses within these families -----------------------------------------*/;
data out.subsequent_30; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.fams_30");
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

   if dx1 in: ('0363', '2510', '25200', '25201', '25202', '25208', '2521', '2528', '2529', '2530', '2531', '2532', '2533', '2534', '2535', '2536', '2537', '2538', '2539', '2540', '2541', '2548', '2549', '2550', '25510', '25511', '25512', '25513', '25514', '2552', '2553', '25541', '25542', '2555', '2556', '2558', '2559', '25801', '25802', '25803', '2581', '2588', '2589', '5881', '58881', 'A391', 'E035', 'E15', 'E200', 'E208', 'E209', 'E210', 'E211', 'E212', 'E213', 'E214', 'E215', 'E220', 'E221', 'E222', 'E228', 'E229', 'E230', 'E231', 'E232', 'E233', 'E236', 'E237', 'E240', 'E241', 'E242', 'E243', 'E244', 'E248', 'E249', 'E250', 'E258', 'E259', 'E2601', 'E2602', 'E2609', 'E261', 'E2681', 'E2689', 'E269', 'E270', 'E271', 'E272', 'E273', 'E2740', 'E2749', 'E275', 'E278', 'E279', 'E310', 'E311', 'E3120', 'E3121', 'E3122', 'E3123', 'E318', 'E319', 'E320', 'E321', 'E328', 'E329', 'E344', 'E892', 'E893', 'E896', 'N251', 'N2581') or 
      dx2 in: ('0363', '2510', '25200', '25201', '25202', '25208', '2521', '2528', '2529', '2530', '2531', '2532', '2533', '2534', '2535', '2536', '2537', '2538', '2539', '2540', '2541', '2548', '2549', '2550', '25510', '25511', '25512', '25513', '25514', '2552', '2553', '25541', '25542', '2555', '2556', '2558', '2559', '25801', '25802', '25803', '2581', '2588', '2589', '5881', '58881', 'A391', 'E035', 'E15', 'E200', 'E208', 'E209', 'E210', 'E211', 'E212', 'E213', 'E214', 'E215', 'E220', 'E221', 'E222', 'E228', 'E229', 'E230', 'E231', 'E232', 'E233', 'E236', 'E237', 'E240', 'E241', 'E242', 'E243', 'E244', 'E248', 'E249', 'E250', 'E258', 'E259', 'E2601', 'E2602', 'E2609', 'E261', 'E2681', 'E2689', 'E269', 'E270', 'E271', 'E272', 'E273', 'E2740', 'E2749', 'E275', 'E278', 'E279', 'E310', 'E311', 'E3120', 'E3121', 'E3122', 'E3123', 'E318', 'E319', 'E320', 'E321', 'E328', 'E329', 'E344', 'E892', 'E893', 'E896', 'N251', 'N2581'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 

* Remove principal diagnoses;
data out.subsequent_30; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_30");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set out.subsequent_30; 
   if ids.find()^=0;  
run; 

* Collapse to enrollee level; 
proc sql; 
   create table out.subsequent_30 as 
   select enrolid, famid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.subsequent_30
   group by enrolid; 
quit; 


/* --- 5. Merge the two data sets -----------------------------------------*/;   


/* --- N. Delete some superfluous data sets -----------------------------------------*/;
proc delete data=out.tomerge_30; 
run; 

proc delete data=out.fams_30; 
run; 

