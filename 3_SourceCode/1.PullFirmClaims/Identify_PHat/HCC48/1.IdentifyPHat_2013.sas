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
data out.allclaims_hcc48_2013; 
   set in.ms_o_2013(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2013(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('5550', '5551', '5552', '5559', '5560', '5561', '5562', '5563', '5564', '5565', '5566', '5568', '5569', 'K5000', 'K50011', 'K50013', 'K50014', 'K50018', 'K50019', 'K5010', 'K50111', 'K50113', 'K50114', 'K50118', 'K50119', 'K5080', 'K50811', 'K50813', 'K50814', 'K50818', 'K50819', 'K5090', 'K50911', 'K50913', 'K50914', 'K50918', 'K50919', 'K5100', 'K51011', 'K51013', 'K51014', 'K51018', 'K51019', 'K5120', 'K51211', 'K51213', 'K51214', 'K51218', 'K51219', 'K5130', 'K51311', 'K51313', 'K51314', 'K51318', 'K51319', 'K5140', 'K51411', 'K51413', 'K51414', 'K51418', 'K51419', 'K5150', 'K51511', 'K51513', 'K51514', 'K51518', 'K51519', 'K5180', 'K51811', 'K51813', 'K51814', 'K51818', 'K51819', 'K5190', 'K51911', 'K51913', 'K51914', 'K51918', 'K51919', 'K50012', 'K50112', 'K50812', 'K50912', 'K51012', 'K51212', 'K51312', 'K51412', 'K51512', 'K51812', 'K51912'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc48_2013 as 
   select enrolid from out.allclaims_hcc48_2013
   group by enrolid; 
quit; 

data out.allenrollees_hcc48_2013;
   set out.allenrollees_hcc48_2013;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_48_2013; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc48_2013");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2013; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 