/*
*========================================================================*
* Program:   Adults/share_specialists.sas                                *
*                                                                        *
* Purpose:   This program calculates total spending on PCPs and specialists *
*		respectively. 		 				 * 
*                                                                        *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*                                                                        *
* Created:   March 2021	                                                 *
* Updated:   				                                 *
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
        set in.ms_o_2006(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2007(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2008(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2009(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2010(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2011(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2012(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2013(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2014(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2015(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2016(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2017(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate)
        in.ms_o_2018(keep=enrolid year netpay pay cob copay coins deduct stdplac stdprov svcscat dx: proc1 svcdate); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   * Keep only outpatient place claims; 
   if (svcscat >= 12210 & svcscat <= 12399) or (svcscat >= 21115 & svcscat <= 21199) or 
      (svcscat >= 21215 & svcscat <= 21299) or (svcscat >= 22315 & svcscat <= 22399); 
run; 

*** Export OP claims; 
proc export data=out.allfamilies_outpatient
    outfile = "/project/caretaking/allfamilies_OPRelevantSVCSCAT.dta"
    dbms=stata
    replace; 
run; 

proc delete data=out.allfamilies_outpatient;
run;
