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

data out.allfamilies_pharma; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_d_2006(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2007(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2008(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2009(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2010(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2011(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2012(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2013(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2014(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2015(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2016(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2017(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate)
        in.ms_d_2018(keep=enrolid year netpay pay cob copay coins deduct genind thercls svcdate); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   if genind = 4 or genind = 5 then generic = 1; 
   else generic = 0; 
run; 

*** Export Pharma claims; 
proc export data=out.allfamilies_pharma
    outfile = "/project/caretaking/allfamilies_PharmaClaims.dta"
    dbms=stata
    replace; 
run; 


*** Collapse to total spending in each category for each family/year; 
proc sql; 
    create table out.toexport3 as 
    select enrolid, year, generic, sum(pay) as total_pay, sum(netpay) as net_pay, sum(deduct) as total_deduct, 
		sum(copay) as total_copay, sum(coins) as total_coins, sum(cob) as total_cob from out.allfamilies_pharma
    group by enrolid, year, generic; 
quit; 

*Export claims; 
proc export data=out.toexport3
    outfile = "/project/caretaking/allfamilies_Pharma.dta"
    dbms=stata
    replace;
run; 

* Delete sas data; 
proc delete data=out.toexport3; 
run; 

