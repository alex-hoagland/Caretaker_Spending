/*
*========================================================================*
* Program:   3.Number of Visits.sas	                                 *
*                                                                        *
* Purpose:   This program examines frequency of visits, rather than 	 *
* 		spending among caretakers.				 * 
*                                                                        *
* Author:    Alex Hoagland						 *
*            Boston University				                 *
*                                                                        *
* Created:   August 21, 2020	                                         *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/projectnb2/marketscan/caretaking/';

/*----------------*
 * Create samples *
 *----------------*/;

*Pull all pharam claims; 
data out.pharma; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_d_2007(keep=enrolid year svcdate)
        in.ms_d_2008(keep=enrolid year svcdate)
        in.ms_d_2009(keep=enrolid year svcdate)
        in.ms_d_2010(keep=enrolid year svcdate)
        in.ms_d_2011(keep=enrolid year svcdate)
        in.ms_d_2012(keep=enrolid year svcdate)
        in.ms_d_2013(keep=enrolid year svcdate)
        in.ms_d_2014(keep=enrolid year svcdate); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
   i = 1; 
   month = month(svcdate); 
run; 

*** Collapse to visit level (using svcdate-to identify individual visits);
proc sql; 
    create table out.visitlevel_ph as 
    select enrolid, year, svcdate, month, i from out.pharma
    group by enrolid, year, svcdate, i; 
quit; 

*** Collapse to total number of vists in a month ; 
proc sql; 
    create table out.toexport3 as 
    select enrolid, year, month, sum(i) as num_visits from out.visitlevel_ph
    group by enrolid, year, month; 
quit; 

*Export claims; 
proc export data=out.toexport3
    outfile = "/projectnb2/marketscan/caretaking/firm6_PharmaVisits.dta"
    dbms=stata
    replace;
run; 

