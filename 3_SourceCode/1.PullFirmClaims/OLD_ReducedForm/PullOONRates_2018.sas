/*
*========================================================================*
* Program:   Identifying family risk from diagnosis (HCC_20)             *
*                                                                        *
* Purpose:   This code identifies non-sample individuals diagnosed 	 *
* 		with an HCC in 2018. Then, calculates the rate at which  *
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
libname out '/project/caretaking/';

/* Pull all outpatient claims with network infomation */; 
data out.oon_2018; 
   if _N_=1 then do; 
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end; 
   
   set in.ms_o_2018(keep=enrolid ntwkprov); 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete; 

   if missing(ntwkprov) then delete; 
   if ntwkprov = "Y" then oon = 0; 
   else oon = 100; 
run; 

* Collapse to enrollee level; 
proc sql; 
   create table out.oon_2018 as 
   select enrolid, famid, mean(oon) as perc_oon from out.oon_2018
   group by enrolid; 
quit; 