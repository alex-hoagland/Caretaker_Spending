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
 * 0. Identify all with HCC  claims in 2007-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Claims, 2007 - 2018 -----------------------------------------*/; 
data out.allclaims_hcc13_2007; 
   set in.ms_o_2007(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2007(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('1720', '1721', '1722', '1723', '1724', '1725', '1726', '1727', '1728', '1729', '1860', '1869', '1871', '1872', '1873', '1874', '1875', '1876', '1877', '1878', '1879', '193', '1941', '1945', '1946', '1948', '1949', '1991', '23770', '23771', '23772', '23773', '23779', '2592', 'C430', 'C4310', 'C4311', 'C4312', 'C4320', 'C4321', 'C4322', 'C4330', 'C4331', 'C4339', 'C434', 'C4351', 'C4352', 'C4359', 'C4360', 'C4361', 'C4362', 'C4370', 'C4371', 'C4372', 'C438', 'C439', 'C600', 'C601', 'C602', 'C608', 'C609', 'C6200', 'C6201', 'C6202', 'C6210', 'C6211', 'C6212', 'C6290', 'C6291', 'C6292', 'C6300', 'C6301', 'C6302', 'C6310', 'C6311', 'C6312', 'C632', 'C637', 'C638', 'C639', 'C73', 'C750', 'C754', 'C755', 'C758', 'C759', 'C801', 'D030', 'D0310', 'D0311', 'D0312', 'D0320', 'D0321', 'D0322', 'D0330', 'D0339', 'D034', 'D0351', 'D0352', 'D0359', 'D0360', 'D0361', 'D0362', 'D0370', 'D0371', 'D0372', 'D038', 'D039', 'E340', 'Q8500', 'Q8501', 'Q8502', 'Q8503', 'Q8509'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc13_2007 as 
   select enrolid from out.allclaims_hcc13_2007
   group by enrolid; 
quit; 

data out.allenrollees_hcc13_2007;
   set out.allenrollees_hcc13_2007;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_13_2007; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc13_2007");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2007; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 