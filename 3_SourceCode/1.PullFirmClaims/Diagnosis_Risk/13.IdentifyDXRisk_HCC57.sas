/*
*========================================================================*
* Program:   Identifying family risk from diagnosis (HCC_57)             *
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
 * 0. Identify all HCC_57 claims in 2006				  *
 * 1. Identify all *new* HCC_57 claims in (2007-2010)			  *
 * 2. Keep all those who are enrolled at least 5 years post (2012-2015)   *
 * 3. Randomly sample families						  *
 * 4. Calculate rate of new diagnoses and time until dx			  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Diabetics in 2006 -----------------------------------------*/; 
data out.pe_57; 
   set in.ms_o_2006(keep=enrolid dx1 dx2) in.ms_s_2006(keep=enrolid dx1 dx2);
   
   if dx1 in: ('0993', '4465', '7100', '7102', '7105', '7108', '7109', '71110', '71111', '71112', '71113', '71114', '71115', '71116', '71117', '71118', '71119', '7144', '71489', '7149', '725', 'M0230', 'M02311', 'M02312', 'M02319', 'M02321', 'M02322', 'M02329', 'M02331', 'M02332', 'M02339', 'M02341', 'M02342', 'M02349', 'M02351', 'M02352', 'M02359', 'M02361', 'M02362', 'M02369', 'M02371', 'M02372', 'M02379', 'M0238', 'M0239', 'M064', 'M1200', 'M12011', 'M12012', 'M12019', 'M12021', 'M12022', 'M12029', 'M12031', 'M12032', 'M12039', 'M12041', 'M12042', 'M12049', 'M12051', 'M12052', 'M12059', 'M12061', 'M12062', 'M12069', 'M12071', 'M12072', 'M12079', 'M1208', 'M1209', 'M315', 'M316', 'M320', 'M3210', 'M3211', 'M3212', 'M3213', 'M3214', 'M3215', 'M3219', 'M328', 'M329', 'M3500', 'M3501', 'M3502', 'M3503', 'M3504', 'M3509', 'M351', 'M353', 'M355', 'M358', 'M359', 'M368') or 
      dx2 in: ('0993', '4465', '7100', '7102', '7105', '7108', '7109', '71110', '71111', '71112', '71113', '71114', '71115', '71116', '71117', '71118', '71119', '7144', '71489', '7149', '725', 'M0230', 'M02311', 'M02312', 'M02319', 'M02321', 'M02322', 'M02329', 'M02331', 'M02332', 'M02339', 'M02341', 'M02342', 'M02349', 'M02351', 'M02352', 'M02359', 'M02361', 'M02362', 'M02369', 'M02371', 'M02372', 'M02379', 'M0238', 'M0239', 'M064', 'M1200', 'M12011', 'M12012', 'M12019', 'M12021', 'M12022', 'M12029', 'M12031', 'M12032', 'M12039', 'M12041', 'M12042', 'M12049', 'M12051', 'M12052', 'M12059', 'M12061', 'M12062', 'M12069', 'M12071', 'M12072', 'M12079', 'M1208', 'M1209', 'M315', 'M316', 'M320', 'M3210', 'M3211', 'M3212', 'M3213', 'M3214', 'M3215', 'M3219', 'M328', 'M329', 'M3500', 'M3501', 'M3502', 'M3503', 'M3504', 'M3509', 'M351', 'M353', 'M355', 'M358', 'M359', 'M368'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.pe_57 as 
   select enrolid from out.pe_57
   group by enrolid; 
quit; 


/* --- 1. All NEW Diabetics in 2007-2010 -----------------------------------------*/; 
data out.new_57; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_57");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_o_2007(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2007(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2008(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2008(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2009(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2009(keep=enrolid age year dx1 dx2 svcdate fachdid)
       in.ms_o_2010(keep=enrolid age year dx1 dx2 svcdate fachdid) in.ms_s_2010(keep=enrolid age year dx1 dx2 svcdate fachdid);
   if ids.find()^=0;
   
   if dx1 in: ('0993', '4465', '7100', '7102', '7105', '7108', '7109', '71110', '71111', '71112', '71113', '71114', '71115', '71116', '71117', '71118', '71119', '7144', '71489', '7149', '725', 'M0230', 'M02311', 'M02312', 'M02319', 'M02321', 'M02322', 'M02329', 'M02331', 'M02332', 'M02339', 'M02341', 'M02342', 'M02349', 'M02351', 'M02352', 'M02359', 'M02361', 'M02362', 'M02369', 'M02371', 'M02372', 'M02379', 'M0238', 'M0239', 'M064', 'M1200', 'M12011', 'M12012', 'M12019', 'M12021', 'M12022', 'M12029', 'M12031', 'M12032', 'M12039', 'M12041', 'M12042', 'M12049', 'M12051', 'M12052', 'M12059', 'M12061', 'M12062', 'M12069', 'M12071', 'M12072', 'M12079', 'M1208', 'M1209', 'M315', 'M316', 'M320', 'M3210', 'M3211', 'M3212', 'M3213', 'M3214', 'M3215', 'M3219', 'M328', 'M329', 'M3500', 'M3501', 'M3502', 'M3503', 'M3504', 'M3509', 'M351', 'M353', 'M355', 'M358', 'M359', 'M368') or 
      dx2 in: ('0993', '4465', '7100', '7102', '7105', '7108', '7109', '71110', '71111', '71112', '71113', '71114', '71115', '71116', '71117', '71118', '71119', '7144', '71489', '7149', '725', 'M0230', 'M02311', 'M02312', 'M02319', 'M02321', 'M02322', 'M02329', 'M02331', 'M02332', 'M02339', 'M02341', 'M02342', 'M02349', 'M02351', 'M02352', 'M02359', 'M02361', 'M02362', 'M02369', 'M02371', 'M02372', 'M02379', 'M0238', 'M0239', 'M064', 'M1200', 'M12011', 'M12012', 'M12019', 'M12021', 'M12022', 'M12029', 'M12031', 'M12032', 'M12039', 'M12041', 'M12042', 'M12049', 'M12051', 'M12052', 'M12059', 'M12061', 'M12062', 'M12069', 'M12071', 'M12072', 'M12079', 'M1208', 'M1209', 'M315', 'M316', 'M320', 'M3210', 'M3211', 'M3212', 'M3213', 'M3214', 'M3215', 'M3219', 'M328', 'M329', 'M3500', 'M3501', 'M3502', 'M3503', 'M3504', 'M3509', 'M351', 'M353', 'M355', 'M358', 'M359', 'M368'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.new_57 as 
   select enrolid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.new_57
   group by enrolid; 
quit; 

* Make sure these new diabetics have at least a year of non-dx time before hand; 
data out.check_57;
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_57");
   ids.definekey('enrolid');
   ids.definedone();
   end;

   set in.ms_a_2006(keep=enrolid year) in.ms_a_2007(keep=enrolid year) in.ms_a_2008(keep=enrolid year) in.ms_a_2009(keep=enrolid year);
   if ids.find()^=0 then delete;
run; 

proc sql; 
   create table out.check_57 as 
   select enrolid, min(year) as fyear from out.check_57
   group by enrolid; 
quit;

data out.new_57; 
   merge out.new_57 out.check_57; 
   by enrolid;

   if dx_year - fyear < 1 then delete; 
run; 

proc delete data=out.check_57; 
run; 


/* --- 2. Keep all new diabetics enrolled at least 5 years post -----------------------------------------*/;
data out.tomerge_57; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_57");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set in.ms_a_2012(keep=enrolid year) in.ms_a_2013(keep=enrolid year) in.ms_a_2014(keep=enrolid year) in.ms_a_2015(keep=enrolid year); 
   if ids.find()^=0 then delete; 
run; 

* Collapse to enrollee level; 
proc sql;
   create table out.tomerge_57 as 
   select enrolid, max(year) as lyear from out.tomerge_57
   group by enrolid; 
quit; 

* Merge in with out.new_57, keep those with 5 years enrollment;
data out.new_57; 
   merge out.new_57 out.tomerge_57; 

   if lyear - dx_year < 5 then delete; 
   famid = floor(enrolid/100); 
run; 

* Collapse to family ids; 
proc sql; 
   create table out.fams_57 as
   select famid from out.new_57
   group by famid; 
quit; 


/* --- 3. Draw a random sample of these families? -----------------------------------------*/;
* No need for this; 


/* --- 4. Look for secondary diagnoses within these families -----------------------------------------*/;
data out.subsequent_57; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.fams_57");
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

   if dx1 in: ('0993', '4465', '7100', '7102', '7105', '7108', '7109', '71110', '71111', '71112', '71113', '71114', '71115', '71116', '71117', '71118', '71119', '7144', '71489', '7149', '725', 'M0230', 'M02311', 'M02312', 'M02319', 'M02321', 'M02322', 'M02329', 'M02331', 'M02332', 'M02339', 'M02341', 'M02342', 'M02349', 'M02351', 'M02352', 'M02359', 'M02361', 'M02362', 'M02369', 'M02371', 'M02372', 'M02379', 'M0238', 'M0239', 'M064', 'M1200', 'M12011', 'M12012', 'M12019', 'M12021', 'M12022', 'M12029', 'M12031', 'M12032', 'M12039', 'M12041', 'M12042', 'M12049', 'M12051', 'M12052', 'M12059', 'M12061', 'M12062', 'M12069', 'M12071', 'M12072', 'M12079', 'M1208', 'M1209', 'M315', 'M316', 'M320', 'M3210', 'M3211', 'M3212', 'M3213', 'M3214', 'M3215', 'M3219', 'M328', 'M329', 'M3500', 'M3501', 'M3502', 'M3503', 'M3504', 'M3509', 'M351', 'M353', 'M355', 'M358', 'M359', 'M368') or 
      dx2 in: ('0993', '4465', '7100', '7102', '7105', '7108', '7109', '71110', '71111', '71112', '71113', '71114', '71115', '71116', '71117', '71118', '71119', '7144', '71489', '7149', '725', 'M0230', 'M02311', 'M02312', 'M02319', 'M02321', 'M02322', 'M02329', 'M02331', 'M02332', 'M02339', 'M02341', 'M02342', 'M02349', 'M02351', 'M02352', 'M02359', 'M02361', 'M02362', 'M02369', 'M02371', 'M02372', 'M02379', 'M0238', 'M0239', 'M064', 'M1200', 'M12011', 'M12012', 'M12019', 'M12021', 'M12022', 'M12029', 'M12031', 'M12032', 'M12039', 'M12041', 'M12042', 'M12049', 'M12051', 'M12052', 'M12059', 'M12061', 'M12062', 'M12069', 'M12071', 'M12072', 'M12079', 'M1208', 'M1209', 'M315', 'M316', 'M320', 'M3210', 'M3211', 'M3212', 'M3213', 'M3214', 'M3215', 'M3219', 'M328', 'M329', 'M3500', 'M3501', 'M3502', 'M3503', 'M3504', 'M3509', 'M351', 'M353', 'M355', 'M358', 'M359', 'M368'); 

   if missing(fachdid) then ip=0; 
   else ip=1; 
run; 

* Remove principal diagnoses;
data out.subsequent_57; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.new_57");
   ids.definekey('enrolid');
   ids.definedone();
   end; 

   set out.subsequent_57; 
   if ids.find()^=0;  
run; 

* Collapse to enrollee level; 
proc sql; 
   create table out.subsequent_57 as 
   select enrolid, famid, age, min(year) as dx_year, min(svcdate) as dx_date, max(ip) as had_hosp from out.subsequent_57
   group by enrolid; 
quit; 


/* --- 5. Merge the two data sets -----------------------------------------*/;   


/* --- N. Delete some superfluous data sets -----------------------------------------*/;
proc delete data=out.tomerge_57; 
run; 

proc delete data=out.fams_57; 
run; 

