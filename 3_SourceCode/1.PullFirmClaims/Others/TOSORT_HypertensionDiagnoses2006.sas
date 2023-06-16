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
data out.allfamilies_outpatient2006(compress=yes); 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_o_2006(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   * Keep only hypertension diagnoses; 
   if (substr(dx1,1,2) = 'I1' or substr(dx1,1,2) = '40' or 
       substr(dx2,1,2) = 'I1' or substr(dx2,1,2) = '40' or 
       substr(dx3,1,2) = 'I1' or substr(dx3,1,2) = '40' or 
       substr(dx4,1,2) = 'I1' or substr(dx4,1,2) = '40');
run; 

*** Export hypertension claims; 
proc export data=out.allfamilies_outpatient2006
    outfile = "/project/caretaking/allfamilies_hypertension2006.dta"
    dbms=stata
    replace; 
run; 

* Delete SAS data; 
proc delete data=out.allfamilies_outpatient2006; 
run; 