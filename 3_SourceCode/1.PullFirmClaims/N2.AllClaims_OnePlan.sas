/*
*========================================================================*
* Program:   pullclaims-MASTER		                                 *
*                                                                        *
* Purpose:   This program pulls all claims for chosen individuals	 * 
*                                                                        *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*                                                                        *
* Created:   July, 2020		                                         *
* Updated:  		                                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/projectnb2/marketscan/caretaking/';

/*----------------*
 * Create samples *
 *----------------*/;

proc import out=out.myplans
   datafile = "MyPlans.csv"
   dbms = csv; 
run; 

*Pull all claims for chosen plans; 
data out.claims_myplans; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.myplans");
   ids.definekey('plankey');
   ids.definedone();
   end;
        set in.ms_o_2006(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey)
	    in.ms_s_2006(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey) 
	in.ms_o_2007(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey)
	    in.ms_s_2007(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey) 
	    in.ms_d_2007(keep=enrolid svc: ndc: year netpay pay cob copay coins deduct plankey)
	in.ms_o_2008(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey)
	    in.ms_s_2008(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey) 
	    in.ms_d_2008(keep=enrolid svc: ndc: year netpay pay cob copay coins deduct plankey)
	in.ms_o_2009(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey)
	    in.ms_s_2009(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey) 
	    in.ms_d_2009(keep=enrolid svc: ndc: year netpay pay cob copay coins deduct plankey)
	in.ms_o_2010(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey)
	    in.ms_s_2010(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey) 
	    in.ms_d_2010(keep=enrolid svc: ndc: year netpay pay cob copay coins deduct plankey)
	in.ms_o_2011(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey)
	    in.ms_s_2011(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey) 
	    in.ms_d_2011(keep=enrolid svc: ndc: year netpay pay cob copay coins deduct plankey)
	in.ms_o_2012(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey)
	    in.ms_s_2012(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey) 
	    in.ms_d_2012(keep=enrolid svc: ndc: year netpay pay cob copay coins deduct plankey)
	in.ms_o_2013(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey)
	    in.ms_s_2013(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey) 
	    in.ms_d_2013(keep=enrolid svc: ndc: year netpay pay cob copay coins deduct plankey);  
   if ids.find()^=0 then delete;
run; 

*Export claims; 
proc export data=out.claims_myplans
    outfile = "/projectnb2/marketscan/caretaking/MyPlans_Claims.csv"
    dbms=csv
    replace;
run;
