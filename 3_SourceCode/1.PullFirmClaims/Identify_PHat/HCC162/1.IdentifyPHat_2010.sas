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
data out.allclaims_hcc162_2010; 
   set in.ms_o_2010(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2010(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('M3213', 'M3301', 'M3311', 'M3321', 'M3391', 'M3481', 'M3502', 'B4481', 'D860', 'D862', 'J60', 'J61', 'J620', 'J628', 'J630', 'J631', 'J632', 'J633', 'J634', 'J635', 'J636', 'J64', 'J65', 'J660', 'J661', 'J662', 'J668', 'J670', 'J671', 'J672', 'J673', 'J674', 'J675', 'J676', 'J677', 'J678', 'J679', 'J680', 'J681', 'J682', 'J683', 'J684', 'J688', 'J689', 'J700', 'J701', 'J82', 'J8401', 'J8402', 'J8403', 'J8409', 'J8410', 'J84111', 'J84112', 'J84113', 'J84114', 'J84115', 'J84116', 'J84117', 'J8417', 'J842', 'J8481', 'J8482', 'J8483', 'J84841', 'J84842', 'J84843', 'J84848', 'J8489', 'J849', 'J99', '135', '4950', '4951', '4952', '4953', '4954', '4955', '4956', '4957', '4958', '4959', '500', '501', '502', '503', '504', '505', '5060', '5061', '5062', '5063', '5064', '5069', '5080', '5081', '515', '5160', '5161', '5162', '51630', '51631', '51632', '51633', '51634', '51635', '51636', '51637', '5164', '5165', '51661', '51662', '51663', '51664', '51669', '5168', '5169', '5171', '5172', '5178', '5183', '5186'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc162_2010 as 
   select enrolid from out.allclaims_hcc162_2010
   group by enrolid; 
quit; 

data out.allenrollees_hcc162_2010;
   set out.allenrollees_hcc162_2010;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_162_2010; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc162_2010");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2010; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 