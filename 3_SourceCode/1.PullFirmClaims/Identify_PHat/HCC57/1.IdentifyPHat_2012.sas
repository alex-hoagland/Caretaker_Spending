/*
*========================================================================*
* Program:   Identifying family risk from diagnosis 		             *
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
libname out '/project/caretaking/IdentifyPHat/';

/*------------------------------------------------------------------------*
 * 		ORDER OF OPERATIONS					  *
 * 0. Identify all with HCC  claims in 2012-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Claims, 2012 - 2018 -----------------------------------------*/; 
data out.allclaims_hcc57_2012; 
   set in.ms_o_2012(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2012(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('0993', '4465', '7100', '7102', '7105', '7108', '7109', '71110', '71111', '71112', '71113', '71114', '71115', '71116', '71117', '71118', '71119', '7144', '71489', '7149', '725', 'M0230', 'M02311', 'M02312', 'M02319', 'M02321', 'M02322', 'M02329', 'M02331', 'M02332', 'M02339', 'M02341', 'M02342', 'M02349', 'M02351', 'M02352', 'M02359', 'M02361', 'M02362', 'M02369', 'M02371', 'M02372', 'M02379', 'M0238', 'M0239', 'M064', 'M1200', 'M12011', 'M12012', 'M12019', 'M12021', 'M12022', 'M12029', 'M12031', 'M12032', 'M12039', 'M12041', 'M12042', 'M12049', 'M12051', 'M12052', 'M12059', 'M12061', 'M12062', 'M12069', 'M12071', 'M12072', 'M12079', 'M1208', 'M1209', 'M315', 'M316', 'M320', 'M3210', 'M3211', 'M3212', 'M3213', 'M3214', 'M3215', 'M3219', 'M328', 'M329', 'M3500', 'M3501', 'M3502', 'M3503', 'M3504', 'M3509', 'M351', 'M353', 'M355', 'M358', 'M359', 'M368'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc57_2012 as 
   select enrolid from out.allclaims_hcc57_2012
   group by enrolid; 
quit; 

data out.allenrollees_hcc57_2012;
   set out.allenrollees_hcc57_2012;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_57_2012; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc57_2012");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2012; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 