/*
*========================================================================*
* Program:   Check Enrollment: HCC_12		                         *
*                                                                        *
* Purpose:   This program flags which years each person in our sample is *
*		available (to ensure 0's in distribution are correct).   *
*                                                                        *
* Author:    Alex Hoagland						 *
*            Boston University				                 *
*                                                                        *
* Created:   Nov 16, 2020	                                         *
* Updated:  				                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';


*** Pull all ENROLLMENT files (2007-2018); 
data out.mc_hcc12_enrolcheck; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_maintenancesample_hcc12");
   ids.definekey('enrolid');
   ids.definedone();
   end;
    set in.ms_a_2007(keep=enrolid year)
        in.ms_a_2008(keep=enrolid year)
        in.ms_a_2009(keep=enrolid year)
        in.ms_a_2010(keep=enrolid year)
        in.ms_a_2011(keep=enrolid year)
        in.ms_a_2012(keep=enrolid year)
        in.ms_a_2013(keep=enrolid year)
        in.ms_a_2014(keep=enrolid year)
        in.ms_a_2015(keep=enrolid year)
        in.ms_a_2016(keep=enrolid year)
        in.ms_a_2017(keep=enrolid year)
        in.ms_a_2018(keep=enrolid year); 
   if ids.find()^=0 then delete;
run; 
