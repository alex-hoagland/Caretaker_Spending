/*
*========================================================================*
* Program:   Maintenance Costs (PH Only)	                         *
*                                                                        *
* Purpose:   This program pulls all PH claims for those with a 		 * 
* 		pre-existing chronic condition				 *
*                                                                        *
* Author:    Alex Hoagland						 *
*            Boston University				                 *
*                                                                        *
* Created:   Nov 9, 2020	                                         *
* Updated:  				                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/*------------------------------------------------------------------------*
 * 		ORDER OF OPERATIONS					  *
 * 0. Identify all those with HCCs in 2006 (only on IP file) 		  *
 * 1. Identify all claims based for specific individual/dx's ('07-'18)    *
 * 2. Collapse to yearly spending level for individual-dx		  *
 *------------------------------------------------------------------------*/;

*** Append individual maintenance samples together for ease of pulling data; 
data out.pe_maintenancesample;
   enrolid = . ;
run; 

proc datasets; 
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc12;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc13;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc20;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc21;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc30;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc37;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc48;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc56;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc57;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc88;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc90;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc118;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc120;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc130;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc142;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc161;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc162;
   append base=out.pe_maintenancesample data=out.pe_maintenancesample_hcc217;
run; 

*** Pull all OUTPATIENT maintenance costs for these enrollees (2007-2018); 
data out.maintenance_costsPH; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_maintenancesample");
   ids.definekey('enrolid');
   ids.definedone();
   end;
    set in.ms_d_2007(keep=enrolid year pay cob copay coins deduct thercls)
        in.ms_d_2008(keep=enrolid year pay cob copay coins deduct thercls)
        in.ms_d_2009(keep=enrolid year pay cob copay coins deduct thercls)
        in.ms_d_2010(keep=enrolid year pay cob copay coins deduct thercls)
        in.ms_d_2011(keep=enrolid year pay cob copay coins deduct thercls)
        in.ms_d_2012(keep=enrolid year pay cob copay coins deduct thercls)
        in.ms_d_2013(keep=enrolid year pay cob copay coins deduct thercls)
        in.ms_d_2014(keep=enrolid year pay cob copay coins deduct thercls)
        in.ms_d_2015(keep=enrolid year pay cob copay coins deduct thercls)
        in.ms_d_2016(keep=enrolid year pay cob copay coins deduct thercls)
        in.ms_d_2017(keep=enrolid year pay cob copay coins deduct thercls)
        in.ms_d_2018(keep=enrolid year pay cob copay coins deduct thercls);
   if ids.find()^=0 then delete;

   if thercls in: ('21', '14', '16', '21', '27', '39', '40', '41', '42', '46', '47', '50', '51', '52', '53', '58', '59', '64', '68', '69', '70', '71', '72', '73', 
                   '74', '75', '76', '85', '107', '120', '121', '122', '123', '124', '125', '160', '162', '166', '167', '170', '172', '173', '174', '175', '176', 
                   '177', '178', '179', '181', '190', '191', '192', '193', '194', '242', '248', '250', '262', '263', '266', '267', '268'); 
   oop = copay + cob + coins + deduct;
run;  

*** Collapse to yearly spending by enrollee-thercls pairing (eventually need to merge this back into main sample);  
proc sql; 
   create table out.maintenance_costsPH as 
   select enrolid, thercls, year, sum(oop) as ip_oop, sum(pay) as ip_pay from out.maintenance_costsPH
   group by enrolid, thercls, year; 
quit;


*** Adjust for inflation; 
data out.maintenance_costsPH; 
   set out.maintenance_costsPH;

   * Change all spending to 2020 dollars;
   if year = 2006 then oop = oop * 1.2788;
   if year = 2006 then pay = pay * 1.2788 ;
   if year = 2007 then oop = oop * 1.2449;
   if year = 2007 then pay = pay * 1.2449;
   if year = 2008 then oop = oop * 1.1988;
   if year = 2008 then pay = pay * 1.1988 ;
   if year = 2009 then oop = oop * 1.2031 ;
   if year = 2009 then pay = pay * 1.2031 ;
   if year = 2010 then oop = oop * 1.1837 ;
   if year = 2010 then pay = pay * 1.1837 ;
   if year = 2011 then oop = oop * 1.1475 ;
   if year = 2011 then pay = pay * 1.1475 ;
   if year = 2012 then oop = oop * 1.1242 ;
   if year = 2012 then pay = pay * 1.1242  ;
   if year = 2013 then oop = oop * 1.1080 ;
   if year = 2013 then pay = pay * 1.1080 ;
   if year = 2014 then oop = oop * 1.0903 ;
   if year = 2014 then pay = pay * 1.0903 ;
   if year = 2015 then oop = oop * 1.0890 ;
   if year = 2015 then pay = pay * 1.0890 ;
   if year = 2016 then oop = oop * 1.0754 ;
   if year = 2016 then pay = pay * 1.0754 ;
   if year = 2017 then oop = oop * 1.0530 ;
   if year = 2017 then pay = pay * 1.0530 ;
   if year = 2018 then oop = oop * 1.0261 ;
   if year = 2018 then pay = pay * 1.0261 ;
run; 
