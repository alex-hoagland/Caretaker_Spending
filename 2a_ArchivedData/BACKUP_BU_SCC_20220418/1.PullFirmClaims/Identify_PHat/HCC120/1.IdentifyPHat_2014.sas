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
 * 0. Identify all with HCC  claims in 2014-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Claims, 2014 - 2018 -----------------------------------------*/; 
data out.allclaims_hcc120_2014; 
   set in.ms_o_2014(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2014(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('34500', '34501', '34510', '34511', '3452', '3453', '34540', '34541', '34550', '34551', '34560', '34561', '34570', '34571', '34580', '34581', '34590', '34591', '7790', '78031', '78032', '78033', '78039', 'G40001', 'G40009', 'G40011', 'G40019', 'G40101', 'G40109', 'G40111', 'G40119', 'G40201', 'G40209', 'G40211', 'G40219', 'G40301', 'G40309', 'G40311', 'G40319', 'G40401', 'G40409', 'G40411', 'G40419', 'G40501', 'G40509', 'G40801', 'G40802', 'G40803', 'G40804', 'G40811', 'G40812', 'G40813', 'G40814', 'G40821', 'G40822', 'G40823', 'G40824', 'G4089', 'G40901', 'G40909', 'G40911', 'G40919', 'G40A01', 'G40A09', 'G40A11', 'G40A19', 'G40B01', 'G40B09', 'G40B11', 'G40B19', 'P90', 'R5600', 'R5601', 'R561', 'R569'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc120_2014 as 
   select enrolid from out.allclaims_hcc120_2014
   group by enrolid; 
quit; 

data out.allenrollees_hcc120_2014;
   set out.allenrollees_hcc120_2014;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_120_2014; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc120_2014");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2014; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 