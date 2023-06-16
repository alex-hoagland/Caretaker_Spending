/*
*========================================================================*
* Program:   pull number of prescriptions-MASTER                         *
*                                                                        *
* Purpose:   This program pulls number of prescriptions for each 	 *
* 		individual @ the monthly level. 			 * 
*                                                                        *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*                                                                        *
* Created:   July, 2020		                                         *
* Updated:   7/28: added generic indicator                               *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/projectnb2/marketscan/caretaking/';

/*----------------*
 * Create samples *
 *----------------*/;

* Pull all families in working data (update as needed); 

* Pull all pharma;  
data out.scrips; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_d_2006(keep=enrolid thercls ndcnum daysupp year genind pay cob copay coins ded:)
            in.ms_d_2007(keep=enrolid thercls ndcnum daysupp year genind pay cob copay coins ded:)
            in.ms_d_2008(keep=enrolid thercls ndcnum daysupp year genind pay cob copay coins ded:)
            in.ms_d_2009(keep=enrolid thercls ndcnum daysupp year genind pay cob copay coins ded:)
            in.ms_d_2010(keep=enrolid thercls ndcnum daysupp year genind pay cob copay coins ded:)
            in.ms_d_2011(keep=enrolid thercls ndcnum daysupp year genind pay cob copay coins ded:)
            in.ms_d_2012(keep=enrolid thercls ndcnum daysupp year genind pay cob copay coins ded:)
            in.ms_d_2013(keep=enrolid thercls ndcnum daysupp year genind pay cob copay coins ded:)
            in.ms_d_2014(keep=enrolid thercls ndcnum daysupp year genind pay cob copay coins ded:); 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
   if daysupp > 0 then pay_per_day = pay/daysupp; 
   oop = cob + copay + coins + deduct; 
   if pay > 0 then coins_rate = coins / pay; 
run; 

* Collapse to each ndcnum with mean price per daysupp (pay / daysupp); 
proc sql; 
    create table out.toexport_scrips as 
    select enrolid, year, ndcnum, thercls, genind, sum(daysupp) as total_days, mean(pay_per_day) as pay_per_day,
	mean(oop) as oop, mean(coins_rate) as coins_rate from out.scrips
    group by enrolid, year, ndcnum, thercls, genind; 
quit; 


*Export claims; 
proc export data=out.toexport_scrips
    outfile = "/projectnb2/marketscan/caretaking/AllFirms_AllScrips.dta"
    dbms=stata
    replace;
run;
