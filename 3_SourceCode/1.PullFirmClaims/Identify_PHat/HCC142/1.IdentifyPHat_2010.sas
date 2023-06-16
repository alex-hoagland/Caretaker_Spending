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
 * 0. Identify all with HCC  claims in 2010-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Claims, 2010 - 2018 -----------------------------------------*/; 
data out.allclaims_hcc142_2010; 
   set in.ms_o_2010(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2010(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('4260', '4270', '4271', '4272', '42731', '42732', '42781', 'I442', 'I470', 'I471', 'I472', 'I479', 'I480', 'I481', 'I482', 'I483', 'I484', 'I4891', 'I4892', 'I492', 'I495'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc142_2010 as 
   select enrolid from out.allclaims_hcc142_2010
   group by enrolid; 
quit; 

data out.allenrollees_hcc142_2010;
   set out.allenrollees_hcc142_2010;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_142_2010; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc142_2010");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2010; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 