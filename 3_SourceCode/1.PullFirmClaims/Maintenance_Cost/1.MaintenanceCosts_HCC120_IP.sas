/*
*========================================================================*
* Program:   HCCClaimsIP.sas     		                         *
*                                                                        *
* Purpose:   This program pulls all IP claims for specific chronic HCCs  *
*		in the MarketScan data. 				 * 
*                                                                        *
* Author:    Alex Hoagland						 *
*            Boston University				                 *
*                                                                        *
* Created:   Sep 30, 2020	                                         *
* Updated:  				                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/*------------------------------------------------------------------------*
 * 		ORDER OF OPERATIONS					  *
 * 0. Identify all those with HCCs in 2006				  *
 * 1. Identify all claims based for specific individual/dx's ('07-'18)    *
 * 2. Collapse to yearly spending level for individual-dx		  *
 *------------------------------------------------------------------------*/;

*** Pull all INPATIENT maintenance costs for these enrollees (2007-2018); 
data out.maintenance_costs_hcc120_ip; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_maintenancesample_hcc120");
   ids.definekey('enrolid');
   ids.definedone();
   end;
    set in.ms_s_2007(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2008(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2009(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2010(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2011(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2012(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2013(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2014(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2015(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2016(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2017(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_s_2018(keep=enrolid year pay cob copay coins deduct dx: ); 
   if ids.find()^=0 then delete;

   hcc = 0; 

    
    *120     "Seizures";
    if (dx1 in: ('34500', '34501', '34510', '34511', '3452', '3453', '34540', '34541', '34550', '34551', '34560', '34561', '34570', '34571', '34580', '34581', '34590', '34591', '7790', '78031', '78032', '78033', '78039', 'G40001', 'G40009', 'G40011', 'G40019', 'G40101', 'G40109', 'G40111', 'G40119', 'G40201', 'G40209', 'G40211', 'G40219', 'G40301', 'G40309', 'G40311', 'G40319', 'G40401', 'G40409', 'G40411', 'G40419', 'G40501', 'G40509', 'G40801', 'G40802', 'G40803', 'G40804', 'G40811', 'G40812', 'G40813', 'G40814', 'G40821', 'G40822', 'G40823', 'G40824', 'G4089', 'G40901', 'G40909', 'G40911', 'G40919', 'G40A01', 'G40A09', 'G40A11', 'G40A19', 'G40B01', 'G40B09', 'G40B11', 'G40B19', 'P90', 'R5600', 'R5601', 'R561', 'R569') or 
        dx2 in: ('34500', '34501', '34510', '34511', '3452', '3453', '34540', '34541', '34550', '34551', '34560', '34561', '34570', '34571', '34580', '34581', '34590', '34591', '7790', '78031', '78032', '78033', '78039', 'G40001', 'G40009', 'G40011', 'G40019', 'G40101', 'G40109', 'G40111', 'G40119', 'G40201', 'G40209', 'G40211', 'G40219', 'G40301', 'G40309', 'G40311', 'G40319', 'G40401', 'G40409', 'G40411', 'G40419', 'G40501', 'G40509', 'G40801', 'G40802', 'G40803', 'G40804', 'G40811', 'G40812', 'G40813', 'G40814', 'G40821', 'G40822', 'G40823', 'G40824', 'G4089', 'G40901', 'G40909', 'G40911', 'G40919', 'G40A01', 'G40A09', 'G40A11', 'G40A19', 'G40B01', 'G40B09', 'G40B11', 'G40B19', 'P90', 'R5600', 'R5601', 'R561', 'R569')) 
        then hcc=120;

   if hcc = 0 then delete;   
  
   oop = copay + cob + coins + deduct;
run; 


*** Collapse to yearly spending by enrollee-hcc pairing (eventually need to merge this back into main sample);  
proc sql; 
   create table out.maintenance_costs_hcc120_ip as 
   select enrolid, hcc, year, sum(oop) as ip_oop, sum(pay) as ip_pay from out.maintenance_costs_hcc120_ip
   group by enrolid, hcc, year; 
quit;


*** Adjust for inflation; 
data out.maintenance_costs_hcc120_ip; 
   set out.maintenance_costs_hcc120_ip;

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
