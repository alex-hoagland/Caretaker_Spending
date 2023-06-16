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

* List of all families in working data (update as needed); 
proc import out=out.allfamilies
    datafile="allfamilies.csv"
    dbms=csv
    replace; 
run; 

*Pull all inpatient claims; 
data out.inpatient; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_i_2006(keep=enrolid year admdate drg)
        in.ms_i_2007(keep=enrolid year admdate drg)
        in.ms_i_2008(keep=enrolid year admdate drg)
        in.ms_i_2009(keep=enrolid year admdate drg)
        in.ms_i_2010(keep=enrolid year admdate drg)
        in.ms_i_2011(keep=enrolid year admdate drg)
        in.ms_i_2012(keep=enrolid year admdate drg)
        in.ms_i_2013(keep=enrolid year admdate drg)
        in.ms_i_2014(keep=enrolid year admdate drg); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
   i = 1; 
   month = month(admdate); 
run; 

*** Collapse to visit level (using admdate to identify individual visits);
proc sql; 
    create table out.visitlevel_ip as 
    select enrolid, year, admdate, month, i from out.inpatient
    group by enrolid, year, admdate, i; 
quit; 

*** Collapse to total number of vists in a month; 
proc sql; 
    create table out.toexport as 
    select enrolid, year, month, sum(i) as num_visits from out.visitlevel_ip
    group by enrolid, year, month; 
quit; 

*Export claims; 
proc export data=out.toexport
    outfile = "/projectnb2/marketscan/caretaking/firm6_InpatientVisits.dta"
    dbms=stata
    replace;
run; 

