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
 * 0. Identify all with HCC  claims in 2006-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Claims, 2006 - 2018 -----------------------------------------*/; 
data out.allclaims_hcc30_2006; 
   set in.ms_o_2006(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2006(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('0363', '2510', '25200', '25201', '25202', '25208', '2521', '2528', '2529', '2530', '2531', '2532', '2533', '2534', '2535', '2536', '2537', '2538', '2539', '2540', '2541', '2548', '2549', '2550', '25510', '25511', '25512', '25513', '25514', '2552', '2553', '25541', '25542', '2555', '2556', '2558', '2559', '25801', '25802', '25803', '2581', '2588', '2589', '5881', '58881', 'A391', 'E035', 'E15', 'E200', 'E208', 'E209', 'E210', 'E211', 'E212', 'E213', 'E214', 'E215', 'E220', 'E221', 'E222', 'E228', 'E229', 'E230', 'E231', 'E232', 'E233', 'E236', 'E237', 'E240', 'E241', 'E242', 'E243', 'E244', 'E248', 'E249', 'E250', 'E258', 'E259', 'E2601', 'E2602', 'E2609', 'E261', 'E2681', 'E2689', 'E269', 'E270', 'E271', 'E272', 'E273', 'E2740', 'E2749', 'E275', 'E278', 'E279', 'E310', 'E311', 'E3120', 'E3121', 'E3122', 'E3123', 'E318', 'E319', 'E320', 'E321', 'E328', 'E329', 'E344', 'E892', 'E893', 'E896', 'N251', 'N2581'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc30_2006 as 
   select enrolid from out.allclaims_hcc30_2006
   group by enrolid; 
quit; 

data out.allenrollees_hcc30_2006;
   set out.allenrollees_hcc30_2006;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_30_2006; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc30_2006");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2006; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 