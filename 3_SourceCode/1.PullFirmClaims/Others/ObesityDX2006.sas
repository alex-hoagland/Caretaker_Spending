/*
*========================================================================*
* Program:   Adults/create_cohorts_claims.sas                            *
*                                                                        *
* Purpose:   This program pulls all preventive services for adults 18-64 * 
*		in the MarketScan data. 				 * 
*                                                                        *
* Author:    Alex Hoagland/Paul Shafer                                   *
*            Boston University				                 *
*                                                                        *
* Created:   June 16, 2020	                                         *
* Updated:   7/28: added all years at once                               *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/*----------------*
 * Create samples *
 *----------------*/;

*Pull all outpatient claims; 
data out.obesitydx2006(compress=yes); 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_o_2006(keep=enrolid year dx:); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   * Keep only the obesity DX; 
   if substr(dx1,1,3) = "E66" or substr(dx1,1,3) = "278" or 
      substr(dx2,1,3) = "E66" or substr(dx2,1,3) = "278" or 
      substr(dx3,1,3) = "E66" or substr(dx3,1,3) = "278" or 
      substr(dx4,1,3) = "E66" or substr(dx4,1,3) = "278";
   obesity = 1; 
run; 

*** Collapse to total spending in each category for each family/year; 
proc sql; 
    create table out.obesitydx2006 as 
    select enrolid, year, max(obesity) as new_obesity from out.obesitydx2006
    group by enrolid, year; 
quit; 

*Export claims; 
proc export data=out.obesitydx2006
    outfile = "/projectnb/caretaking/newObesity2006.dta"
    dbms=stata
    replace;
run; 

* Delete SAS data; 
proc delete data=out.obesitydx2006; 
run; 