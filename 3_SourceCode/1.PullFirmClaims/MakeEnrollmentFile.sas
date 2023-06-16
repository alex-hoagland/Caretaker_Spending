  /*
*========================================================================*
* Program:   Make Enrollment File	                                 *
*                                                                        *
* Purpose:   Starts the main enrollment file for my sample of interest   *
*                                                                        *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*                                                                        *
* Created:   Nov 17, 2020	                                         *
* Updated:  		                                                 *
*========================================================================*;
*/
   
*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';
        
/*-------------------------*
* Annual enrollment files  *
*--------------------------*/;
       
*Pull and save all outpatient preventive claims; 
data out.annualenrollment(compress=yes); 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_a_2006(keep=enrolid year sex age)
            in.ms_a_2007(keep=enrolid year sex age)
            in.ms_a_2008(keep=enrolid year sex age)
            in.ms_a_2009(keep=enrolid year sex age)
            in.ms_a_2010(keep=enrolid year sex age)
            in.ms_a_2011(keep=enrolid year sex age)
            in.ms_a_2012(keep=enrolid year sex age)
            in.ms_a_2013(keep=enrolid year sex age)
            in.ms_a_2014(keep=enrolid year sex age)
            in.ms_a_2015(keep=enrolid year sex age)
            in.ms_a_2016(keep=enrolid year sex age)
            in.ms_a_2017(keep=enrolid year sex age)
            in.ms_a_2018(keep=enrolid year sex age); 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run;

*Export claims; 
proc export data=out.annualenrollment
    outfile = "/project/caretaking/MainEnrollmentFile.dta"
    dbms=stata
    replace;
run; 

/*-----------------*
* Delete SAS data *
*------------------*/; 

proc delete data=out.annualenrollment;
run; 

