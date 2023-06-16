/*
*========================================================================*
* Program:   Identifying family risk from diagnosis (HCC_13)             *
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
 * 0. Identify all HCC_13 claims in 2006				  *
 * 1. Identify all *new* HCC_13 claims in (2007-2010)			  *
 * 2. Keep all those who are enrolled at least 5 years post (2012-2015)   *
 * 3. Randomly sample families						  *
 * 4. Calculate rate of new diagnoses and time until dx			  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Diabetics in 2006 -----------------------------------------*/; 
data out.pe_13; 
   set in.ms_o_2006(keep=enrolid dx1 dx2) in.ms_s_2006(keep=enrolid dx1 dx2);
   
   if dx1 in: ('1720', '1721', '1722', '1723', '1724', '1725', '1726', '1727', '1728', '1729', '1860', '1869', '1871', '1872', '1873', '1874', '1875', '1876', '1877', '1878', '1879', '193', '1941', '1945', '1946', '1948', '1949', '1991', '23770', '23771', '23772', '23773', '23779', '2592', 'C430', 'C4310', 'C4311', 'C4312', 'C4320', 'C4321', 'C4322', 'C4330', 'C4331', 'C4339', 'C434', 'C4351', 'C4352', 'C4359', 'C4360', 'C4361', 'C4362', 'C4370', 'C4371', 'C4372', 'C438', 'C439', 'C600', 'C601', 'C602', 'C608', 'C609', 'C6200', 'C6201', 'C6202', 'C6210', 'C6211', 'C6212', 'C6290', 'C6291', 'C6292', 'C6300', 'C6301', 'C6302', 'C6310', 'C6311', 'C6312', 'C632', 'C637', 'C638', 'C639', 'C73', 'C750', 'C754', 'C755', 'C758', 'C759', 'C801', 'D030', 'D0310', 'D0311', 'D0312', 'D0320', 'D0321', 'D0322', 'D0330', 'D0339', 'D034', 'D0351', 'D0352', 'D0359', 'D0360', 'D0361', 'D0362', 'D0370', 'D0371', 'D0372', 'D038', 'D039', 'E340', 'Q8500', 'Q8501', 'Q8502', 'Q8503', 'Q8509') or 
      dx2 in: ('1720', '1721', '1722', '1723', '1724', '1725', '1726', '1727', '1728', '1729', '1860', '1869', '1871', '1872', '1873', '1874', '1875', '1876', '1877', '1878', '1879', '193', '1941', '1945', '1946', '1948', '1949', '1991', '23770', '23771', '23772', '23773', '23779', '2592', 'C430', 'C4310', 'C4311', 'C4312', 'C4320', 'C4321', 'C4322', 'C4330', 'C4331', 'C4339', 'C434', 'C4351', 'C4352', 'C4359', 'C4360', 'C4361', 'C4362', 'C4370', 'C4371', 'C4372', 'C438', 'C439', 'C600', 'C601', 'C602', 'C608', 'C609', 'C6200', 'C6201', 'C6202', 'C6210', 'C6211', 'C6212', 'C6290', 'C6291', 'C6292', 'C6300', 'C6301', 'C6302', 'C6310', 'C6311', 'C6312', 'C632', 'C637', 'C638', 'C639', 'C73', 'C750', 'C754', 'C755', 'C758', 'C759', 'C801', 'D030', 'D0310', 'D0311', 'D0312', 'D0320', 'D0321', 'D0322', 'D0330', 'D0339', 'D034', 'D0351', 'D0352', 'D0359', 'D0360', 'D0361', 'D0362', 'D0370', 'D0371', 'D0372', 'D038', 'D039', 'E340', 'Q8500', 'Q8501', 'Q8502', 'Q8503', 'Q8509'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.pe_13 as 
   select enrolid from out.pe_13
   group by enrolid; 
quit; 


/* --- 1. All NEW Diabetics in 2007-2010 -----------------------------------------*/; 
data out.new_13; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_13");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_o_2007(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2007(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2008(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2008(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2009(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2009(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2010(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2010(keep=enrolid age year dx1 dx2 svcdate fachdid);
   if ids.find()^=0;
   
   if dx1 in: ('1720', '1721', '1722', '1723', '1724', '1725', '1726', '1727', '1728', '1729', '1860', '1869', '1871', '1872', '1873', '1874', '1875', '1876', '1877', '1878', '1879', '193', '1941', '1945', '1946', '1948', '1949', '1991', '23770', '23771', '23772', '23773', '23779', '2592', 'C430', 'C4310', 'C4311', 'C4312', 'C4320', 'C4321', 'C4322', 'C4330', 'C4331', 'C4339', 'C434', 'C4351', 'C4352', 'C4359', 'C4360', 'C4361', 'C4362', 'C4370', 'C4371', 'C4372', 'C438', 'C439', 'C600', 'C601', 'C602', 'C608', 'C609', 'C6200', 'C6201', 'C6202', 'C6210', 'C6211', 'C6212', 'C6290', 'C6291', 'C6292', 'C6300', 'C6301', 'C6302', 'C6310', 'C6311', 'C6312', 'C632', 'C637', 'C638', 'C639', 'C73', 'C750', 'C754', 'C755', 'C758', 'C759', 'C801', 'D030', 'D0310', 'D0311', 'D0312', 'D0320', 'D0321', 'D0322', 'D0330', 'D0339', 'D034', 'D0351', 'D0352', 'D0359', 'D0360', 'D0361', 'D0362', 'D0370', 'D0371', 'D0372', 'D038', 'D039', 'E340', 'Q8500', 'Q8501', 'Q8502', 'Q8503', 'Q8509') or 
      dx2 in: ('1720', '1721', '1722', '1723', '1724', '1725', '1726', '1727', '1728', '1729', '1860', '1869', '1871', '1872', '1873', '1874', '1875', '1876', '1877', '1878', '1879', '193', '1941', '1945', '1946', '1948', '1949', '1991', '23770', '23771', '23772', '23773', '23779', '2592', 'C430', 'C4310', 'C4311', 'C4312', 'C4320', 'C4321', 'C4322', 'C4330', 'C4331', 'C4339', 'C434', 'C4351', 'C4352', 'C4359', 'C4360', 'C4361', 'C4362', 'C4370', 'C4371', 'C4372', 'C438', 'C439', 'C600', 'C601', 'C602', 'C608', 'C609', 'C6200', 'C6201', 'C6202', 'C6210', 'C6211', 'C6212', 'C6290', 'C6291', 'C6292', 'C6300', 'C6301', 'C6302', 'C6310', 'C6311', 'C6312', 'C632', 'C637', 'C638', 'C639', 'C73', 'C750', 'C754', 'C755', 'C758', 'C759', 'C801', 'D030', 'D0310', 'D0311', 'D0312', 'D0320', 'D0321', 'D0322', 'D0330', 'D0339', 'D034', 'D0351', 'D0352', 'D0359', 'D0360', 'D0361', 'D0362', 'D0370', 'D0371', 'D0372', 'D038', 'D039', 'E340', 'Q8500', 'Q8501', 'Q8502', 'Q8503', 'Q8509'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.new_13 as 
   select enrolid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.new_13
   group by enrolid; 
quit; 

* Make sure these new diabetics have at least a year of non-dx time before hand; 
data out.check_13;
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_13");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_a_2006(keep=enrolid year) in.ms_a_2007(keep=enrolid year) in.ms_a_2008(keep=enrolid year) in.ms_a_2009(keep=enrolid year);
   if ids.find()^=0 then delete;
run; 

proc sql; 
   create table out.check_13 as 
   select enrolid, min(year) as fyear from out.check_13
   group by enrolid; 
quit;

data out.new_13; 
   merge out.new_13 out.check_13; 
   by enrolid;

   if dx_year - fyear < 1 then delete; 
run; 

proc delete data=out.check_13; 
run; 


/* --- 2. Keep all new diabetics enrolled at least 5 years post -----------------------------------------*/;
data out.tomerge_13; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_13");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set in.ms_a_2012(keep=enrolid year) in.ms_a_2013(keep=enrolid year) in.ms_a_2014(keep=enrolid year) in.ms_a_2015(keep=enrolid year); 
   if ids.find()^=0 then delete; 
run; 

* Collapse to enrollee level; 
proc sql;
   create table out.tomerge_13 as 
   select enrolid, max(year) as lyear from out.tomerge_13
   group by enrolid; 
quit; 

* Merge in with out.new_13, keep those with 5 years enrollment;
data out.new_13; 
   merge out.new_13 out.tomerge_13; 

   if lyear - dx_year < 5 then delete; 
   famid = floor(enrolid/100); 
run; 

* Collapse to family ids; 
proc sql; 
   create table out.fams_13 as
   select famid from out.new_13
   group by famid; 
quit; 


/* --- 3. Draw a random sample of these families? -----------------------------------------*/;
* No need for this; 


/* --- 4. Look for secondary diagnoses within these families -----------------------------------------*/;
data out.subsequent_13; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.fams_13");
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

   if dx1 in: ('1720', '1721', '1722', '1723', '1724', '1725', '1726', '1727', '1728', '1729', '1860', '1869', '1871', '1872', '1873', '1874', '1875', '1876', '1877', '1878', '1879', '193', '1941', '1945', '1946', '1948', '1949', '1991', '23770', '23771', '23772', '23773', '23779', '2592', 'C430', 'C4310', 'C4311', 'C4312', 'C4320', 'C4321', 'C4322', 'C4330', 'C4331', 'C4339', 'C434', 'C4351', 'C4352', 'C4359', 'C4360', 'C4361', 'C4362', 'C4370', 'C4371', 'C4372', 'C438', 'C439', 'C600', 'C601', 'C602', 'C608', 'C609', 'C6200', 'C6201', 'C6202', 'C6210', 'C6211', 'C6212', 'C6290', 'C6291', 'C6292', 'C6300', 'C6301', 'C6302', 'C6310', 'C6311', 'C6312', 'C632', 'C637', 'C638', 'C639', 'C73', 'C750', 'C754', 'C755', 'C758', 'C759', 'C801', 'D030', 'D0310', 'D0311', 'D0312', 'D0320', 'D0321', 'D0322', 'D0330', 'D0339', 'D034', 'D0351', 'D0352', 'D0359', 'D0360', 'D0361', 'D0362', 'D0370', 'D0371', 'D0372', 'D038', 'D039', 'E340', 'Q8500', 'Q8501', 'Q8502', 'Q8503', 'Q8509') or 
      dx2 in: ('1720', '1721', '1722', '1723', '1724', '1725', '1726', '1727', '1728', '1729', '1860', '1869', '1871', '1872', '1873', '1874', '1875', '1876', '1877', '1878', '1879', '193', '1941', '1945', '1946', '1948', '1949', '1991', '23770', '23771', '23772', '23773', '23779', '2592', 'C430', 'C4310', 'C4311', 'C4312', 'C4320', 'C4321', 'C4322', 'C4330', 'C4331', 'C4339', 'C434', 'C4351', 'C4352', 'C4359', 'C4360', 'C4361', 'C4362', 'C4370', 'C4371', 'C4372', 'C438', 'C439', 'C600', 'C601', 'C602', 'C608', 'C609', 'C6200', 'C6201', 'C6202', 'C6210', 'C6211', 'C6212', 'C6290', 'C6291', 'C6292', 'C6300', 'C6301', 'C6302', 'C6310', 'C6311', 'C6312', 'C632', 'C637', 'C638', 'C639', 'C73', 'C750', 'C754', 'C755', 'C758', 'C759', 'C801', 'D030', 'D0310', 'D0311', 'D0312', 'D0320', 'D0321', 'D0322', 'D0330', 'D0339', 'D034', 'D0351', 'D0352', 'D0359', 'D0360', 'D0361', 'D0362', 'D0370', 'D0371', 'D0372', 'D038', 'D039', 'E340', 'Q8500', 'Q8501', 'Q8502', 'Q8503', 'Q8509'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 

* Remove principal diagnoses;
data out.subsequent_13; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_13");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set out.subsequent_13; 
   if ids.find()^=0;  
run; 

* Collapse to enrollee level; 
proc sql; 
   create table out.subsequent_13 as 
   select enrolid, famid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.subsequent_13
   group by enrolid; 
quit; 


/* --- 5. Merge the two data sets -----------------------------------------*/;   


/* --- N. Delete some superfluous data sets -----------------------------------------*/;
proc delete data=out.tomerge_13; 
run; 

proc delete data=out.fams_13; 
run; 

