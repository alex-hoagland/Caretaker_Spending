/*
*========================================================================*
* Program:   Prescription Adherence Calculations                         *
*                                                                        *
* Purpose:   This program calculates PDC for enrollees' major 		 *
* 		medications. Uses only meds filled for at least 90 	 *
* 		cumulative days in at least one year. 			 * 
* Notes: - Counts as drugs in a therapeutic class as equivalent, so the  * 
* 		PDC is calculated at a thercls level. 	 		 *
* 	 - PDC looks at all days in a 365-day period following the 	 *
* 		earliest fill to check for coverage. 			 *
* 	 - Methodology is based on Leslie et al. "Calculating Medication *
*		Compliance, Adherence and Persistence in Administrative  * 
* 		Pharmacy Claims Databases" (2008)			 *
*                                                                        *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*                                                                        *
* Created:   October 2020		                                 *
* Updated:   				                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/*----------------*
 * Create samples *
 *----------------*/;

* Pull all families in working data (update as needed);

* Pull all therapeutic classes with at least 90 days supply in a year;  
data out.scrips2006(compress=yes); 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_d_2006(keep=enrolid thercls daysupp year); 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
  
   * Drop a few therapeutic classes; 
   if thercls in: ('299', '999', '234', '237') then delete; 
   if missing(thercls) then delete; 
run; 

* Collapse to cumulative day supply by thercls-year; 
proc sql; 
    create table out.thercls_yr2006 as 
    select enrolid, year, thercls, sum(daysupp) as total_days from out.scrips2006
    group by enrolid, year, thercls; 
quit; 

* Collapse to max day supply across all years; 
proc sql; 
   create table out.thercls_yr2006 as 
   select enrolid, thercls, max(total_days) as max_days from out.thercls_yr2006
   group by enrolid, thercls; 
quit; 

* Keep only the enrollees-therclasses that have 90+ days in a year; 
data out.thercls_yr2006; 
   set out.thercls_yr2006; 
   if max_days >= 90; 
   drop max_days; 
run; 

* Now keep only the top 40 therapeutic classes; 
proc sql;
   create table out.thercls_final2006 as 
   select count(enrolid) as num_enrollees, thercls from out.thercls_yr2006
   group by thercls; 
quit; 

proc sort data=out.thercls_final2006;
by descending num_enrollees; 
run; 

data out.thercls_final2006;
   set out.thercls_final2006(firstobs=40); 
run; 

proc sort data=out.thercls_yr2006; 
by thercls;
run; 

proc sort data=out.thercls_final2006;
by thercls;
run; 

data out.thercls_yr2006; 
   merge out.thercls_yr2006 out.thercls_final2006; 
   by thercls; 
   if missing(num_enrollees) then delete; 
run; 

* Now pull claims only for the relevant enrollee-therclasses (across all years); 
* This is to calculate PDC at the month level; 
data out.scrips2006(compress=yes); 
   if _N_=1 then do;
   declare hash ids(dataset:"out.thercls_yr2006");
   ids.definekey('enrolid','thercls');
   ids.definedone();
   end;
        set in.ms_d_2006(keep=enrolid thercls daysupp svcdate); 
   if ids.find()^=0 then delete;

   * Drop a few therapeutic classes; 
   if thercls in: ('299', '999', '234', '237') then delete; 
   if missing(thercls) then delete; 
run; 

proc sort data=out.thercls_final2006;
by descending num_enrollees; 
run; 

* NOTE: Now I employ the methodology of Leslie et al. (2008) separately for each of the chosen therapeutic classes; 
%macro m1; 
%do j = 1 %to 40; 

	* Step 0: Keep only the relevant data;
        data out.key2006; 
           set out.thercls_final2006(firstobs = &j obs = &j); 
           call symput("tc", thercls); 
        run; 

        data out.working2006; 
           if _N_ = 1 then do; 
           declare hash ids(dataset:"out.key2006"); 
           ids.definekey('thercls'); 
           ids.definedone(); 
           end; 
              set out.scrips2006; 
           if ids.find()^=0 then delete; 
        run; 

        * Step 1: Transposing the data to a single observation per patient; 
	proc sort data=out.working2006; 
	by enrolid svcdate; 
	run; 

	proc transpose data=out.working2006 out=out.fill_dates2006 (drop=_name_) prefix=svcdate; 
	by enrolid; 
	var svcdate;
	run; 

	proc transpose data=out.working2006 out=out.days_supply2006 (drop=_name_) prefix=daysupp;
	by enrolid; 
	var daysupp; 
	run; 

	data out.both2006; 
	merge out.fill_dates2006 out.days_supply2006; 
	by enrolid; 
	format start_dt end_dt mmddyy10.;
	start_dt=svcdate1;
	end_dt=svcdate1+364; 
	run; 

	* Step 2: Find the days of medication coverage for each patient and calculate the PDC for the review period; 
	data out.pdc2006; 
	set out.both2006; 
	array daydummy(365) day1-day365; 
	array filldates(*) svcdate1-svcdate100; 
	array days_supply(*) daysupp1-daysupp100;

	   do ii=1 to 365; daydummy(ii)=0; end; 

	   do ii=1 to 365; 
		  do i=1 to dim(filldates) while (filldates(i) ne .); 
			 if filldates(i) <= start_dt + ii - 1 <= filldates(i)+days_supply(i)-1
			 then daydummy(ii)=1; 
		  end; 
	   end; 
	drop i ii; 
	dayscovered = sum(of day1 - day365); label dayscovered='Total Days Covered'; 
	p_dc = dayscovered/365; label p_dc='Proportion of Days Covered';
	run; 

	*Export claims; 
	proc export data=out.pdc2006(keep=enrolid start_dt end_dt dayscovered p_dc)
		outfile = "/project/caretaking/PDC_2006_&tc.dta"
		dbms=stata
		replace;
	run;

        * Delete working data; 
        proc delete data=out.key2006; 
        run; 

        proc delete data=out.working2006; 
        run; 

        proc delete data=out.both2006; 
        run; 

        proc delete data=out.pdc2006; 
        run; 
%end;
%mend m1; 

%m1;  

* Deleting other SAS datasets; 
proc delete data=out.both2006; 
run; 

proc delete data=out.days_supply2006; 
run; 

proc delete data=out.fill_dates2006; 
run; 

proc delete data=out.scrips2006; 
run; 

proc delete data=out.thercls_final2006; 
run; 

proc delete data=out.thercls_yr2006; 
run; 