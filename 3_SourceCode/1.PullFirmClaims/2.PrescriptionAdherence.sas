/*
*========================================================================*
* Program:   Adults/prescription adherence.sas                           *
*                                                                        *
* Purpose:   This program identifies prescriptions related to preventing *
*		cardiovascular disease around chronic/acute events	 * 
*                                                                        *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*                                                                        *
* Created:   March 2021		                                         *
* Updated:   				                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/*----------------*
 * Create samples *
 *----------------*/;

data out.allfamilies_pharma(compress=yes); 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_d_2006(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2007(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2008(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2009(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2010(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2011(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2012(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2013(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2014(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2015(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2016(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2017(keep=enrolid year thercls ndcnum svcdate daysupp)
        in.ms_d_2018(keep=enrolid year thercls ndcnum svcdate daysupp); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   * Keep only cardiovascular prevention meds; 
   if thercls in: ('51','54','53','39','47');
run; 

*** Export Pharma claims; 
proc export data=out.allfamilies_pharma
    outfile = "/project/caretaking/allfamilies_CVPrevention.dta"
    dbms=stata
    replace; 
run; 

proc delete data=out.allfamilies_pharma;
run;