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

*Pull all outpatient claims; 
data out.outpatient; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_o_2006(keep=enrolid year stdplac svcdate)
        in.ms_o_2007(keep=enrolid year stdplac svcdate)
        in.ms_o_2008(keep=enrolid year stdplac svcdate)
        in.ms_o_2009(keep=enrolid year stdplac svcdate)
        in.ms_o_2010(keep=enrolid year stdplac svcdate)
        in.ms_o_2011(keep=enrolid year stdplac svcdate)
        in.ms_o_2012(keep=enrolid year stdplac svcdate)
        in.ms_o_2013(keep=enrolid year stdplac svcdate)
        in.ms_o_2014(keep=enrolid year stdplac svcdate); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
   i = 1; 
   month = month(svcdate); 
run; 

*** Collapse to visit level (using svcdate-stdplac to identify individual visits);
proc sql; 
    create table out.visitlevel_op as 
    select enrolid, year, stdplac, svcdate, month, i from out.outpatient
    group by enrolid, year, stdplac, svcdate, i; 
quit; 

*** Collapse to total number of vists in a month ; 
proc sql; 
    create table out.toexport2 as 
    select enrolid, year, month, sum(i) as num_visits from out.visitlevel_op
    group by enrolid, year, month; 
quit; 

*Export claims; 
proc export data=out.toexport2
    outfile = "/projectnb2/marketscan/caretaking/firm6_OutpatientVisits.dta"
    dbms=stata
    replace;
run; 

