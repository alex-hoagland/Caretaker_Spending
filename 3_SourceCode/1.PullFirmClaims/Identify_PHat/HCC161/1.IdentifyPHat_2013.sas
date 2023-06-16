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
 * 0. Identify all with HCC  claims in 2013-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Claims, 2013 - 2018 -----------------------------------------*/; 
data out.allclaims_hcc161_2013; 
   set in.ms_o_2013(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2013(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('49300', '49301', '49302', '49310', '49311', '49312', '49381', '49382', '49390', '49391', '49392', 'J4520', 'J4521', 'J4522', 'J4530', 'J4531', 'J4532', 'J4540', 'J4541', 'J4542', 'J4550', 'J4551', 'J4552', 'J45901', 'J45902', 'J45909', 'J45990', 'J45991', 'J45998'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc161_2013 as 
   select enrolid from out.allclaims_hcc161_2013
   group by enrolid; 
quit; 

data out.allenrollees_hcc161_2013;
   set out.allenrollees_hcc161_2013;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_161_2013; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc161_2013");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2013; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 