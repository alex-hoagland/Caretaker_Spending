/*
*========================================================================*
* Program:   HCCClaimsOP.sas     		                         *
*                                                                        *
* Purpose:   This program pulls all OP claims for specific chronic HCCs  *
*		in the MarketScan data. 				 * 
*                                                                        *
* Author:    Alex Hoagland						 *
*            Boston University				                 *
*                                                                        *
* Created:   Sep 30, 2020	                                         *
* Updated:  				                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/projectnb2/marketscan/caretaking/';

proc import out=out.pe_enrollees
    datafile='PE_Enrollees.csv'
    dbms = csv; 
run; 

/*----------------*
 * Create samples *
 *----------------*/;

*Pull all pharma claims; 
data out.pe_pharma; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_enrollees");
   ids.definekey('enrolid');
   ids.definedone();
   end;
        set in.ms_d_2006(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2007(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2008(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2009(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2010(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2011(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2012(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2013(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2014(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2015(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2016(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2017(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp)
        in.ms_d_2018(keep=enrolid year netpay pay cob copay coins deduct svcdate ndcnum thercls thergrp); 
   if ids.find()^=0 then delete;

   * Drop some common therapeutic classes that aren't chronic related; 
   if missing(thercls) then delete; 
   if thercls = 1 or (thercls >= 4 and thercls <= 14) or (thercls >= 78 and thercls <= 83) or thercls = 92 or thercls = 99 or thercls = 100 or thercls = 119 or 
      (thercls >= 128 and thercls <= 140) or thercls = 144 or (thercls >= 146 and thercls <= 156) or thercls = 168 or thercls = 169 or thercls = 189 or 
      (thercls >= 218 & thercls <= 233) then delete; 
run; 

*** Export OP claims; 
proc export data=out.pe_pharma
    outfile = "/projectnb2/marketscan/caretaking/PE_PharmaClaims.dta"
    dbms=stata
    replace; 
run; 

* Delete SAS data; 
proc delete data=out.pe_pharma; 
run; 

