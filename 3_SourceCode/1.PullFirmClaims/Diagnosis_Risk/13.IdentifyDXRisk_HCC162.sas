/*
*========================================================================*
* Program:   Identifying family risk from diagnosis (HCC_162)             *
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
 * 0. Identify all HCC_162 claims in 2006				  *
 * 1. Identify all *new* HCC_162 claims in (2007-2010)			  *
 * 2. Keep all those who are enrolled at least 5 years post (2012-2015)   *
 * 3. Randomly sample families						  *
 * 4. Calculate rate of new diagnoses and time until dx			  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Diabetics in 2006 -----------------------------------------*/; 
data out.pe_162; 
   set in.ms_o_2006(keep=enrolid dx1 dx2) in.ms_s_2006(keep=enrolid dx1 dx2);
   
   if dx1 in: ('M3213', 'M3301', 'M3311', 'M3321', 'M3391', 'M3481', 'M3502', 'B4481', 'D860', 'D862', 'J60', 'J61', 'J620', 'J628', 'J630', 'J631', 'J632', 'J633', 'J634', 'J635', 'J636', 'J64', 'J65', 'J660', 'J661', 'J662', 'J668', 'J670', 'J671', 'J672', 'J673', 'J674', 'J675', 'J676', 'J677', 'J678', 'J679', 'J680', 'J681', 'J682', 'J683', 'J684', 'J688', 'J689', 'J700', 'J701', 'J82', 'J8401', 'J8402', 'J8403', 'J8409', 'J8410', 'J84111', 'J84112', 'J84113', 'J84114', 'J84115', 'J84116', 'J84117', 'J8417', 'J842', 'J8481', 'J8482', 'J8483', 'J84841', 'J84842', 'J84843', 'J84848', 'J8489', 'J849', 'J99', '135', '4950', '4951', '4952', '4953', '4954', '4955', '4956', '4957', '4958', '4959', '500', '501', '502', '503', '504', '505', '5060', '5061', '5062', '5063', '5064', '5069', '5080', '5081', '515', '5160', '5161', '5162', '51630', '51631', '51632', '51633', '51634', '51635', '51636', '51637', '5164', '5165', '51661', '51662', '51663', '51664', '51669', '5168', '5169', '5171', '5172', '5178', '5183', '5186') or 
      dx2 in: ('M3213', 'M3301', 'M3311', 'M3321', 'M3391', 'M3481', 'M3502', 'B4481', 'D860', 'D862', 'J60', 'J61', 'J620', 'J628', 'J630', 'J631', 'J632', 'J633', 'J634', 'J635', 'J636', 'J64', 'J65', 'J660', 'J661', 'J662', 'J668', 'J670', 'J671', 'J672', 'J673', 'J674', 'J675', 'J676', 'J677', 'J678', 'J679', 'J680', 'J681', 'J682', 'J683', 'J684', 'J688', 'J689', 'J700', 'J701', 'J82', 'J8401', 'J8402', 'J8403', 'J8409', 'J8410', 'J84111', 'J84112', 'J84113', 'J84114', 'J84115', 'J84116', 'J84117', 'J8417', 'J842', 'J8481', 'J8482', 'J8483', 'J84841', 'J84842', 'J84843', 'J84848', 'J8489', 'J849', 'J99', '135', '4950', '4951', '4952', '4953', '4954', '4955', '4956', '4957', '4958', '4959', '500', '501', '502', '503', '504', '505', '5060', '5061', '5062', '5063', '5064', '5069', '5080', '5081', '515', '5160', '5161', '5162', '51630', '51631', '51632', '51633', '51634', '51635', '51636', '51637', '5164', '5165', '51661', '51662', '51663', '51664', '51669', '5168', '5169', '5171', '5172', '5178', '5183', '5186'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.pe_162 as 
   select enrolid from out.pe_162
   group by enrolid; 
quit; 


/* --- 1. All NEW Diabetics in 2007-2010 -----------------------------------------*/; 
data out.new_162; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_162");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_o_2007(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2007(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2008(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2008(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2009(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2009(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2010(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2010(keep=enrolid age year dx1 dx2 svcdate fachdid);
   if ids.find()^=0;
   
   if dx1 in: ('M3213', 'M3301', 'M3311', 'M3321', 'M3391', 'M3481', 'M3502', 'B4481', 'D860', 'D862', 'J60', 'J61', 'J620', 'J628', 'J630', 'J631', 'J632', 'J633', 'J634', 'J635', 'J636', 'J64', 'J65', 'J660', 'J661', 'J662', 'J668', 'J670', 'J671', 'J672', 'J673', 'J674', 'J675', 'J676', 'J677', 'J678', 'J679', 'J680', 'J681', 'J682', 'J683', 'J684', 'J688', 'J689', 'J700', 'J701', 'J82', 'J8401', 'J8402', 'J8403', 'J8409', 'J8410', 'J84111', 'J84112', 'J84113', 'J84114', 'J84115', 'J84116', 'J84117', 'J8417', 'J842', 'J8481', 'J8482', 'J8483', 'J84841', 'J84842', 'J84843', 'J84848', 'J8489', 'J849', 'J99', '135', '4950', '4951', '4952', '4953', '4954', '4955', '4956', '4957', '4958', '4959', '500', '501', '502', '503', '504', '505', '5060', '5061', '5062', '5063', '5064', '5069', '5080', '5081', '515', '5160', '5161', '5162', '51630', '51631', '51632', '51633', '51634', '51635', '51636', '51637', '5164', '5165', '51661', '51662', '51663', '51664', '51669', '5168', '5169', '5171', '5172', '5178', '5183', '5186') or 
      dx2 in: ('M3213', 'M3301', 'M3311', 'M3321', 'M3391', 'M3481', 'M3502', 'B4481', 'D860', 'D862', 'J60', 'J61', 'J620', 'J628', 'J630', 'J631', 'J632', 'J633', 'J634', 'J635', 'J636', 'J64', 'J65', 'J660', 'J661', 'J662', 'J668', 'J670', 'J671', 'J672', 'J673', 'J674', 'J675', 'J676', 'J677', 'J678', 'J679', 'J680', 'J681', 'J682', 'J683', 'J684', 'J688', 'J689', 'J700', 'J701', 'J82', 'J8401', 'J8402', 'J8403', 'J8409', 'J8410', 'J84111', 'J84112', 'J84113', 'J84114', 'J84115', 'J84116', 'J84117', 'J8417', 'J842', 'J8481', 'J8482', 'J8483', 'J84841', 'J84842', 'J84843', 'J84848', 'J8489', 'J849', 'J99', '135', '4950', '4951', '4952', '4953', '4954', '4955', '4956', '4957', '4958', '4959', '500', '501', '502', '503', '504', '505', '5060', '5061', '5062', '5063', '5064', '5069', '5080', '5081', '515', '5160', '5161', '5162', '51630', '51631', '51632', '51633', '51634', '51635', '51636', '51637', '5164', '5165', '51661', '51662', '51663', '51664', '51669', '5168', '5169', '5171', '5172', '5178', '5183', '5186'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.new_162 as 
   select enrolid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.new_162
   group by enrolid; 
quit; 

* Make sure these new diabetics have at least a year of non-dx time before hand; 
data out.check_162;
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_162");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_a_2006(keep=enrolid year) in.ms_a_2007(keep=enrolid year) in.ms_a_2008(keep=enrolid year) in.ms_a_2009(keep=enrolid year);
   if ids.find()^=0 then delete;
run; 

proc sql; 
   create table out.check_162 as 
   select enrolid, min(year) as fyear from out.check_162
   group by enrolid; 
quit;

data out.new_162; 
   merge out.new_162 out.check_162; 
   by enrolid;

   if dx_year - fyear < 1 then delete; 
run; 

proc delete data=out.check_162; 
run; 


/* --- 2. Keep all new diabetics enrolled at least 5 years post -----------------------------------------*/;
data out.tomerge_162; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_162");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set in.ms_a_2012(keep=enrolid year) in.ms_a_2013(keep=enrolid year) in.ms_a_2014(keep=enrolid year) in.ms_a_2015(keep=enrolid year); 
   if ids.find()^=0 then delete; 
run; 

* Collapse to enrollee level; 
proc sql;
   create table out.tomerge_162 as 
   select enrolid, max(year) as lyear from out.tomerge_162
   group by enrolid; 
quit; 

* Merge in with out.new_162, keep those with 5 years enrollment;
data out.new_162; 
   merge out.new_162 out.tomerge_162; 

   if lyear - dx_year < 5 then delete; 
   famid = floor(enrolid/100); 
run; 

* Collapse to family ids; 
proc sql; 
   create table out.fams_162 as
   select famid from out.new_162
   group by famid; 
quit; 


/* --- 3. Draw a random sample of these families? -----------------------------------------*/;
* No need for this; 


/* --- 4. Look for secondary diagnoses within these families -----------------------------------------*/;
data out.subsequent_162; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.fams_162");
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

   if dx1 in: ('M3213', 'M3301', 'M3311', 'M3321', 'M3391', 'M3481', 'M3502', 'B4481', 'D860', 'D862', 'J60', 'J61', 'J620', 'J628', 'J630', 'J631', 'J632', 'J633', 'J634', 'J635', 'J636', 'J64', 'J65', 'J660', 'J661', 'J662', 'J668', 'J670', 'J671', 'J672', 'J673', 'J674', 'J675', 'J676', 'J677', 'J678', 'J679', 'J680', 'J681', 'J682', 'J683', 'J684', 'J688', 'J689', 'J700', 'J701', 'J82', 'J8401', 'J8402', 'J8403', 'J8409', 'J8410', 'J84111', 'J84112', 'J84113', 'J84114', 'J84115', 'J84116', 'J84117', 'J8417', 'J842', 'J8481', 'J8482', 'J8483', 'J84841', 'J84842', 'J84843', 'J84848', 'J8489', 'J849', 'J99', '135', '4950', '4951', '4952', '4953', '4954', '4955', '4956', '4957', '4958', '4959', '500', '501', '502', '503', '504', '505', '5060', '5061', '5062', '5063', '5064', '5069', '5080', '5081', '515', '5160', '5161', '5162', '51630', '51631', '51632', '51633', '51634', '51635', '51636', '51637', '5164', '5165', '51661', '51662', '51663', '51664', '51669', '5168', '5169', '5171', '5172', '5178', '5183', '5186') or 
      dx2 in: ('M3213', 'M3301', 'M3311', 'M3321', 'M3391', 'M3481', 'M3502', 'B4481', 'D860', 'D862', 'J60', 'J61', 'J620', 'J628', 'J630', 'J631', 'J632', 'J633', 'J634', 'J635', 'J636', 'J64', 'J65', 'J660', 'J661', 'J662', 'J668', 'J670', 'J671', 'J672', 'J673', 'J674', 'J675', 'J676', 'J677', 'J678', 'J679', 'J680', 'J681', 'J682', 'J683', 'J684', 'J688', 'J689', 'J700', 'J701', 'J82', 'J8401', 'J8402', 'J8403', 'J8409', 'J8410', 'J84111', 'J84112', 'J84113', 'J84114', 'J84115', 'J84116', 'J84117', 'J8417', 'J842', 'J8481', 'J8482', 'J8483', 'J84841', 'J84842', 'J84843', 'J84848', 'J8489', 'J849', 'J99', '135', '4950', '4951', '4952', '4953', '4954', '4955', '4956', '4957', '4958', '4959', '500', '501', '502', '503', '504', '505', '5060', '5061', '5062', '5063', '5064', '5069', '5080', '5081', '515', '5160', '5161', '5162', '51630', '51631', '51632', '51633', '51634', '51635', '51636', '51637', '5164', '5165', '51661', '51662', '51663', '51664', '51669', '5168', '5169', '5171', '5172', '5178', '5183', '5186'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 

* Remove principal diagnoses;
data out.subsequent_162; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_162");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set out.subsequent_162; 
   if ids.find()^=0;  
run; 

* Collapse to enrollee level; 
proc sql; 
   create table out.subsequent_162 as 
   select enrolid, famid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.subsequent_162
   group by enrolid; 
quit; 


/* --- 5. Merge the two data sets -----------------------------------------*/;   


/* --- N. Delete some superfluous data sets -----------------------------------------*/;
proc delete data=out.tomerge_162; 
run; 

proc delete data=out.fams_162; 
run; 

