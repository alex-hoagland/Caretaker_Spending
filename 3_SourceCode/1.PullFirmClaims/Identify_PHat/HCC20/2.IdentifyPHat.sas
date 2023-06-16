/*
*========================================================================*
* Program:   Identifying family risk from diagnosis 		            *
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
 * 0. Identify all with HCC_20 claims in 2006-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
proc import datafile="/project/caretaking/IdentifyPHat/allenrollees_hcc20.dta"
   out = out.allenrollees_hcc20
   dbms = stata
   replace;
run;

data out.allenrollment_20; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc20");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2006(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL) in.ms_a_2007(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL) in.ms_a_2008(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL)
       in.ms_a_2009(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL) in.ms_a_2010(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL) in.ms_a_2011(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL)
       in.ms_a_2012(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL) in.ms_a_2013(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL) in.ms_a_2014(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL)
       in.ms_a_2015(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL) in.ms_a_2016(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL)
       in.ms_a_2017(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL) in.ms_a_2018(keep = ENROLID MEMDAYS YEAR AGE SEX EMPREL); 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 