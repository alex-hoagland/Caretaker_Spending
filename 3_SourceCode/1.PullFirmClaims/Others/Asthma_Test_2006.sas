/*
*========================================================================*
* Program:   Low Value Medications	                                 *
*                                                                        *
* Purpose:   								 * 
*                                                                        *
* Author:    Alex Hoagland		                                 *
*            Boston University				                 *
*                                                                        *
* Created:   March, 2020	                                         *
* Updated:   				                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/*----------------*
 * Create samples *
 *----------------*/;

data out.asthma2006; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_o_2006(keep=enrolid age sex year dx: proc:); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   * Keep relevant procedures; 
   if (dx1 in: ("V814", "Z1383") or dx2 in: ("V814", "Z1383") or
      dx3 in: ("V814", "Z1383") or dx4 in: ("V814", "Z1383") or proc1 in: ('G9432', 'G9434', '96160')); 
run; 

*** Export claims; 
proc export data=out.asthma2006
    outfile = "/projectnb/caretaking/AsthmaScreening2006.dta"
    dbms=stata
    replace; 
run; 

* Delete sas data; 
proc delete data=out.asthma2006; 
run; 

