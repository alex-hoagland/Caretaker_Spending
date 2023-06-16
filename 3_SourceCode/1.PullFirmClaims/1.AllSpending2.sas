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
data out.allfamilies_outpatient(compress=yes); 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_o_2006(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2007(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2008(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2009(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2010(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2011(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2012(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2013(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2014(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2015(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2016(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2017(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
        in.ms_o_2018(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   if stdplac = 24 then ambsc = 1; 
   else ambsc = 0; 
run; 

*** Export OP claims; 
proc export data=out.allfamilies_outpatient
    outfile = "/project/caretaking/allfamilies_OutpatientClaims.dta"
    dbms=stata
    replace; 
run; 


*** Collapse to total spending in each category for each family/year; 
proc sql; 
    create table out.toexport2 as 
    select enrolid, year, ambsc, specialist, sum(pay) as total_pay, sum(netpay) as net_pay, sum(deduct) as total_deduct, 
		sum(copay) as total_copay, sum(coins) as total_coins, sum(cob) as total_cob from out.allfamilies_outpatient
    group by enrolid, year, ambsc, specialist; 
quit; 

*Export claims; 
proc export data=out.toexport2
    outfile = "/project/caretaking/allfamilies_Outpatient.dta"
    dbms=stata
    replace;
run; 

* Delete SAS data; 
proc delete data=out.toexport2; 
run; 