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
 * 0. Identify all with HCC  claims in 2011-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Claims, 2011 - 2018 -----------------------------------------*/; 
data out.allclaims_hcc90_2011; 
   set in.ms_o_2011(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2011(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('30012', '30013', '30014', '30015', '3006', '3010', '30110', '30111', '30112', '30113', '30120', '30121', '30122', '3013', '3014', '30150', '30151', '30159', '3016', '3017', '30181', '30182', '30183', '30184', '30189', '3019', 'F21', 'F440', 'F441', 'F4481', 'F481', 'F600', 'F601', 'F602', 'F603', 'F604', 'F605', 'F606', 'F607', 'F6081', 'F6089', 'F609'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc90_2011 as 
   select enrolid from out.allclaims_hcc90_2011
   group by enrolid; 
quit; 

data out.allenrollees_hcc90_2011;
   set out.allenrollees_hcc90_2011;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_90_2011; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc90_2011");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2011; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 