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

proc import out=out.firm22
   datafile = "Firm22Enrollees.csv"
   dbms = csv; 
run; 

*Pull all claims; 
data out.claimsfirm22; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.firm22");
   ids.definekey('enrolid');
   ids.definedone();
   end;
        set in.ms_o_2009(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey)
	    in.ms_s_2009(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey) 
	    in.ms_d_2009(keep=enrolid svc: ndc: year netpay pay cob copay coins deduct)
	in.ms_o_2013(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey)
	    in.ms_s_2013(keep=enrolid std: svc: dx: proc: year netpay pay cob copay coins deduct plankey) 
	    in.ms_d_2013(keep=enrolid svc: ndc: year netpay pay cob copay coins deduct);  
   if ids.find()^=0 then delete;
run; 

*Export claims; 
proc export data=out.claimsfirm22
    outfile = "/projectnb2/marketscan/caretaking/Firm22_Claims_2009_2013.csv"
    dbms=csv
    replace;
run;
