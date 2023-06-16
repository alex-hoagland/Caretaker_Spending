/*
*========================================================================*
* Program:   Calculating deductuctibles manually for my sample              *
*                                                                        *
* Purpose:   Calculates the family deductuctible as the 90th percentile of  *
*		deductuctible spending within a plan-year		         *
*                                                                        *
* Note: This file							 *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*									 *
* Created:   December, 2020		                                 *
* Updated:  		                                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/* Pull all claims for our families */; 
data out.mandeduct_2006; 
   if _N_=1 then do; 
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end; 
   
   set in.ms_o_2006(keep=enrolid deduct) in.ms_s_2006(keep=enrolid deduct) in.ms_d_2006(keep=enrolid deduct); 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete; 

   if deduct <= 0 then delete; 
run; 

* Collapse to family level; 
proc sql; 
   create table out.mandeduct_2006 as 
   select famid, sum(deduct) fam_deduct_spend from out.mandeduct_2006
   group by famid; 
quit; 

* Export and delete SAS; 
proc export data=out.mandeduct_2006
   outfile="/project/caretaking/Manualdeductuctibles_2006.dta"
   dbms=stata
   replace;
run; 

proc delete data=out.mandeduct_2006;
run; 