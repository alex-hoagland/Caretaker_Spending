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

data out.lv_pharma2006; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_d_2006(keep=enrolid age year thercls svcdate); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   * Keep prescription opioids for migraines; 
   if thercls in: ('60','61','63') then tocombine_opioid = 1;
   
   * Keep cough/cold medicine for children < 6;
   if age <= 6 & thercls in: ('128','129','130','131') then lv_1ped_coldmed = 1;
   
   * Keep oral antibiotics for some dxs;
   if thercls in: ('6','7','9','10','11','12') then tocombine_antibiot = 1; 

   * Keep oral steroids for some dxs;
   if thercls = 166 then tocombine_ster = 1; 

   * Keep relevant drugs; 
   if tocombine_opioid = 1 or lv_1ped_coldmed = 1 or tocombine_antibiot = 1 or tocombine_ster = 1; 

run; 

*** Export Pharma claims; 
proc export data=out.lv_pharma2006
    outfile = "/projectnb/caretaking/LowValueMeds2006.dta"
    dbms=stata
    replace; 
run; 

* Delete sas data; 
proc delete data=out.lv_pharma2006; 
run; 

