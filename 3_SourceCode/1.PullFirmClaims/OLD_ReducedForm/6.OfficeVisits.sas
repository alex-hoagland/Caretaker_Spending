  /*
*========================================================================*
* Program:   Pulls all office visits for relevant family members         *
*                                                                        *
* Purpose:   This program pulls all office visits for relevant people    *
*		in the MarketScan data. 				 *
*                                                                        *
* Author:    Alex Hoagland		                                 *
*            Boston University				                 *
*                                                                        *
* Created:   Sep 10, 2020	                                         *
* Updated:  		                                                 *
*========================================================================*;
*/
   
*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/projectnb2/marketscan/caretaking/';
        
/*-------------------------*
* Create OUTPATIENT sample *
*--------------------------*/;
       
*Pull and save all outpatient preventive claims; 
data out.outpatient(compress=yes); 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_o_2007(keep=enrolid year dx: proc: netpay pay cob copay coins ded: svc: std: ntwkprov)
        set in.ms_o_2008(keep=enrolid year dx: proc: netpay pay cob copay coins ded: svc: std: ntwkprov)
        set in.ms_o_2009(keep=enrolid year dx: proc: netpay pay cob copay coins ded: svc: std: ntwkprov)
        set in.ms_o_2010(keep=enrolid year dx: proc: netpay pay cob copay coins ded: svc: std: ntwkprov)
        set in.ms_o_2011(keep=enrolid year dx: proc: netpay pay cob copay coins ded: svc: std: ntwkprov)
        set in.ms_o_2012(keep=enrolid year dx: proc: netpay pay cob copay coins ded: svc: std: ntwkprov)
        set in.ms_o_2013(keep=enrolid year dx: proc: netpay pay cob copay coins ded: svc: std: ntwkprov)
        set in.ms_o_2014(keep=enrolid year dx: proc: netpay pay cob copay coins ded: svc: std: ntwkprov); 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   /* ALL OFFICE VISITS ONLY */; 
   if (proc1 in: ('99201', '99202', '99203', '99204', '99205', '99211', '99212', '99213', '99214', '99215', '99241', '99242', '99243', '99244', '99245',
	'99499', 'G0101', 'G0344', 'G0402', 'G0438', 'G0439', 'G0445', 'S0610', 'S0612', 'S0613')); 
run;

*Export claims; 
proc export data=out.outpatient
    outfile = "/projectnb2/marketscan/caretaking/AllFamilies_OfficeVisits.dta"
    dbms=stata
    replace;
run; 

/*-----------------*
* Delete SAS data *
*------------------*/; 

proc delete data=out.outpatient;
run; 

