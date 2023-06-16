/*
*========================================================================*
* Program:   Identifying family risk from diagnosis (HCC_130)             *
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
 * 0. Identify all HCC_130 claims in 2006				  *
 * 1. Identify all *new* HCC_130 claims in (2007-2010)			  *
 * 2. Keep all those who are enrolled at least 5 years post (2012-2015)   *
 * 3. Randomly sample families						  *
 * 4. Calculate rate of new diagnoses and time until dx			  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Diabetics in 2006 -----------------------------------------*/; 
data out.pe_130; 
   set in.ms_o_2006(keep=enrolid dx1 dx2) in.ms_s_2006(keep=enrolid dx1 dx2);
   
   if dx1 in: ('39891', '40201', '40211', '40291', '40401', '40403', '40411', '40413', '40491', '40493', '4150', '4160', '4161', '4168', '4169', '4170', '4171', '4178', '4179', '4250', '42511', '42518', '4252', '4253', '4254', '4255', '4257', '4258', '4259', '4280', '4281', '42820', '42821', '42822', '42823', '42830', '42831', '42832', '42833', '42840', '42841', '42842', '42843', '4289', '4290', '4291', 'A3681', 'B3324', 'I0981', 'I110', 'I130', 'I132', 'I2601', 'I2602', 'I2609', 'I270', 'I271', 'I272', 'I2781', 'I2789', 'I279', 'I280', 'I281', 'I288', 'I289', 'I420', 'I421', 'I422', 'I423', 'I424', 'I425', 'I426', 'I427', 'I428', 'I429', 'I43', 'I501', 'I5020', 'I5021', 'I5022', 'I5023', 'I5030', 'I5031', 'I5032', 'I5033', 'I5040', 'I5041', 'I5042', 'I5043', 'I509', 'I514', 'I515') or 
      dx2 in: ('39891', '40201', '40211', '40291', '40401', '40403', '40411', '40413', '40491', '40493', '4150', '4160', '4161', '4168', '4169', '4170', '4171', '4178', '4179', '4250', '42511', '42518', '4252', '4253', '4254', '4255', '4257', '4258', '4259', '4280', '4281', '42820', '42821', '42822', '42823', '42830', '42831', '42832', '42833', '42840', '42841', '42842', '42843', '4289', '4290', '4291', 'A3681', 'B3324', 'I0981', 'I110', 'I130', 'I132', 'I2601', 'I2602', 'I2609', 'I270', 'I271', 'I272', 'I2781', 'I2789', 'I279', 'I280', 'I281', 'I288', 'I289', 'I420', 'I421', 'I422', 'I423', 'I424', 'I425', 'I426', 'I427', 'I428', 'I429', 'I43', 'I501', 'I5020', 'I5021', 'I5022', 'I5023', 'I5030', 'I5031', 'I5032', 'I5033', 'I5040', 'I5041', 'I5042', 'I5043', 'I509', 'I514', 'I515'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.pe_130 as 
   select enrolid from out.pe_130
   group by enrolid; 
quit; 


/* --- 1. All NEW Diabetics in 2007-2010 -----------------------------------------*/; 
data out.new_130; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_130");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_o_2007(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2007(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2008(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2008(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2009(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2009(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2010(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2010(keep=enrolid age year dx1 dx2 svcdate fachdid);
   if ids.find()^=0;
   
   if dx1 in: ('39891', '40201', '40211', '40291', '40401', '40403', '40411', '40413', '40491', '40493', '4150', '4160', '4161', '4168', '4169', '4170', '4171', '4178', '4179', '4250', '42511', '42518', '4252', '4253', '4254', '4255', '4257', '4258', '4259', '4280', '4281', '42820', '42821', '42822', '42823', '42830', '42831', '42832', '42833', '42840', '42841', '42842', '42843', '4289', '4290', '4291', 'A3681', 'B3324', 'I0981', 'I110', 'I130', 'I132', 'I2601', 'I2602', 'I2609', 'I270', 'I271', 'I272', 'I2781', 'I2789', 'I279', 'I280', 'I281', 'I288', 'I289', 'I420', 'I421', 'I422', 'I423', 'I424', 'I425', 'I426', 'I427', 'I428', 'I429', 'I43', 'I501', 'I5020', 'I5021', 'I5022', 'I5023', 'I5030', 'I5031', 'I5032', 'I5033', 'I5040', 'I5041', 'I5042', 'I5043', 'I509', 'I514', 'I515') or 
      dx2 in: ('39891', '40201', '40211', '40291', '40401', '40403', '40411', '40413', '40491', '40493', '4150', '4160', '4161', '4168', '4169', '4170', '4171', '4178', '4179', '4250', '42511', '42518', '4252', '4253', '4254', '4255', '4257', '4258', '4259', '4280', '4281', '42820', '42821', '42822', '42823', '42830', '42831', '42832', '42833', '42840', '42841', '42842', '42843', '4289', '4290', '4291', 'A3681', 'B3324', 'I0981', 'I110', 'I130', 'I132', 'I2601', 'I2602', 'I2609', 'I270', 'I271', 'I272', 'I2781', 'I2789', 'I279', 'I280', 'I281', 'I288', 'I289', 'I420', 'I421', 'I422', 'I423', 'I424', 'I425', 'I426', 'I427', 'I428', 'I429', 'I43', 'I501', 'I5020', 'I5021', 'I5022', 'I5023', 'I5030', 'I5031', 'I5032', 'I5033', 'I5040', 'I5041', 'I5042', 'I5043', 'I509', 'I514', 'I515'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.new_130 as 
   select enrolid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.new_130
   group by enrolid; 
quit; 

* Make sure these new diabetics have at least a year of non-dx time before hand; 
data out.check_130;
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_130");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_a_2006(keep=enrolid year) in.ms_a_2007(keep=enrolid year) in.ms_a_2008(keep=enrolid year) in.ms_a_2009(keep=enrolid year);
   if ids.find()^=0 then delete;
run; 

proc sql; 
   create table out.check_130 as 
   select enrolid, min(year) as fyear from out.check_130
   group by enrolid; 
quit;

data out.new_130; 
   merge out.new_130 out.check_130; 
   by enrolid;

   if dx_year - fyear < 1 then delete; 
run; 

proc delete data=out.check_130; 
run; 


/* --- 2. Keep all new diabetics enrolled at least 5 years post -----------------------------------------*/;
data out.tomerge_130; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_130");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set in.ms_a_2012(keep=enrolid year) in.ms_a_2013(keep=enrolid year) in.ms_a_2014(keep=enrolid year) in.ms_a_2015(keep=enrolid year); 
   if ids.find()^=0 then delete; 
run; 

* Collapse to enrollee level; 
proc sql;
   create table out.tomerge_130 as 
   select enrolid, max(year) as lyear from out.tomerge_130
   group by enrolid; 
quit; 

* Merge in with out.new_130, keep those with 5 years enrollment;
data out.new_130; 
   merge out.new_130 out.tomerge_130; 

   if lyear - dx_year < 5 then delete; 
   famid = floor(enrolid/100); 
run; 

* Collapse to family ids; 
proc sql; 
   create table out.fams_130 as
   select famid from out.new_130
   group by famid; 
quit; 


/* --- 3. Draw a random sample of these families? -----------------------------------------*/;
* No need for this; 


/* --- 4. Look for secondary diagnoses within these families -----------------------------------------*/;
data out.subsequent_130; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.fams_130");
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

   if dx1 in: ('39891', '40201', '40211', '40291', '40401', '40403', '40411', '40413', '40491', '40493', '4150', '4160', '4161', '4168', '4169', '4170', '4171', '4178', '4179', '4250', '42511', '42518', '4252', '4253', '4254', '4255', '4257', '4258', '4259', '4280', '4281', '42820', '42821', '42822', '42823', '42830', '42831', '42832', '42833', '42840', '42841', '42842', '42843', '4289', '4290', '4291', 'A3681', 'B3324', 'I0981', 'I110', 'I130', 'I132', 'I2601', 'I2602', 'I2609', 'I270', 'I271', 'I272', 'I2781', 'I2789', 'I279', 'I280', 'I281', 'I288', 'I289', 'I420', 'I421', 'I422', 'I423', 'I424', 'I425', 'I426', 'I427', 'I428', 'I429', 'I43', 'I501', 'I5020', 'I5021', 'I5022', 'I5023', 'I5030', 'I5031', 'I5032', 'I5033', 'I5040', 'I5041', 'I5042', 'I5043', 'I509', 'I514', 'I515') or 
      dx2 in: ('39891', '40201', '40211', '40291', '40401', '40403', '40411', '40413', '40491', '40493', '4150', '4160', '4161', '4168', '4169', '4170', '4171', '4178', '4179', '4250', '42511', '42518', '4252', '4253', '4254', '4255', '4257', '4258', '4259', '4280', '4281', '42820', '42821', '42822', '42823', '42830', '42831', '42832', '42833', '42840', '42841', '42842', '42843', '4289', '4290', '4291', 'A3681', 'B3324', 'I0981', 'I110', 'I130', 'I132', 'I2601', 'I2602', 'I2609', 'I270', 'I271', 'I272', 'I2781', 'I2789', 'I279', 'I280', 'I281', 'I288', 'I289', 'I420', 'I421', 'I422', 'I423', 'I424', 'I425', 'I426', 'I427', 'I428', 'I429', 'I43', 'I501', 'I5020', 'I5021', 'I5022', 'I5023', 'I5030', 'I5031', 'I5032', 'I5033', 'I5040', 'I5041', 'I5042', 'I5043', 'I509', 'I514', 'I515'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 

* Remove principal diagnoses;
data out.subsequent_130; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_130");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set out.subsequent_130; 
   if ids.find()^=0;  
run; 

* Collapse to enrollee level; 
proc sql; 
   create table out.subsequent_130 as 
   select enrolid, famid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.subsequent_130
   group by enrolid; 
quit; 


/* --- 5. Merge the two data sets -----------------------------------------*/;   


/* --- N. Delete some superfluous data sets -----------------------------------------*/;
proc delete data=out.tomerge_130; 
run; 

proc delete data=out.fams_130; 
run; 

