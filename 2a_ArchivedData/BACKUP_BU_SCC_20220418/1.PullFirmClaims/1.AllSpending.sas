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

* Pull enrollment files; 
data out.allfamilies_enrollment; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_a_2006 in.ms_a_2007 in.ms_a_2008 in.ms_a_2009 in.ms_a_2010 
		in.ms_a_2011 in.ms_a_2012 in.ms_a_2013 in.ms_a_2014 in.ms_a_2015
		in.ms_a_2016 in.ms_a_2017 in.ms_a_2018; 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 

*Export claims; 
proc export data=out.allfamilies_enrollment
    outfile = "/project/caretaking/allfamilies_Enrollment.dta"
    dbms=stata
    replace;
run; 

*Pull all inpatient claims; 
data out.allfamilies_inpatient; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_s_2006(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate) 
            in.ms_s_2007(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
            in.ms_s_2008(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
            in.ms_s_2009(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
            in.ms_s_2010(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
            in.ms_s_2011(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
            in.ms_s_2012(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
            in.ms_s_2013(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
            in.ms_s_2014(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
            in.ms_s_2015(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
            in.ms_s_2016(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
            in.ms_s_2017(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate)
            in.ms_s_2018(keep=enrolid year netpay pay cob copay coins deduct stdplac dx: proc1 svcdate);
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   if stdplac = 23 then ed = 1; 
   else ed = 0; 
run; 

*** Export IP claims; 
proc export data=out.allfamilies_inpatient
    outfile = "/project/caretaking/allfamilies_InpatientClaims.dta"
    dbms=stata
    replace; 
run; 


*** Collapse to total spending in each category for each enrollee/year; 
proc sql; 
    create table out.toexport as 
    select enrolid, year, ed, sum(pay) as total_pay, sum(netpay) as net_pay, sum(deduct) as total_deduct, 
		sum(copay) as total_copay, sum(coins) as total_coins, sum(cob) as total_cob from out.allfamilies_inpatient
    group by enrolid, year, ed; 
quit; 

*Export claims; 
proc export data=out.toexport
    outfile = "/project/caretaking/allfamilies_Inpatient.dta"
    dbms=stata
    replace;
run; 

* Delete sas data; 
proc delete data=out.toexport; 
run; 

proc delete data=out.allfamilies_enrollment; 
run; 
