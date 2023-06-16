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
data out.maintenance_costs_hcc48_ip; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_maintenancesample_hcc48");
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

    *48     "Inflammatory Bowel Disease";
    if (dx1 in: ('5550', '5551', '5552', '5559', '5560', '5561', '5562', '5563', '5564', '5565', '5566', '5568', '5569', 'K5000', 'K50011', 'K50013', 'K50014', 'K50018', 'K50019', 'K5010', 'K50111', 'K50113', 'K50114', 'K50118', 'K50119', 'K5080', 'K50811', 'K50813', 'K50814', 'K50818', 'K50819', 'K5090', 'K50911', 'K50913', 'K50914', 'K50918', 'K50919', 'K5100', 'K51011', 'K51013', 'K51014', 'K51018', 'K51019', 'K5120', 'K51211', 'K51213', 'K51214', 'K51218', 'K51219', 'K5130', 'K51311', 'K51313', 'K51314', 'K51318', 'K51319', 'K5140', 'K51411', 'K51413', 'K51414', 'K51418', 'K51419', 'K5150', 'K51511', 'K51513', 'K51514', 'K51518', 'K51519', 'K5180', 'K51811', 'K51813', 'K51814', 'K51818', 'K51819', 'K5190', 'K51911', 'K51913', 'K51914', 'K51918', 'K51919', 'K50012', 'K50112', 'K50812', 'K50912', 'K51012', 'K51212', 'K51312', 'K51412', 'K51512', 'K51812', 'K51912') or 
        dx2 in: ('5550', '5551', '5552', '5559', '5560', '5561', '5562', '5563', '5564', '5565', '5566', '5568', '5569', 'K5000', 'K50011', 'K50013', 'K50014', 'K50018', 'K50019', 'K5010', 'K50111', 'K50113', 'K50114', 'K50118', 'K50119', 'K5080', 'K50811', 'K50813', 'K50814', 'K50818', 'K50819', 'K5090', 'K50911', 'K50913', 'K50914', 'K50918', 'K50919', 'K5100', 'K51011', 'K51013', 'K51014', 'K51018', 'K51019', 'K5120', 'K51211', 'K51213', 'K51214', 'K51218', 'K51219', 'K5130', 'K51311', 'K51313', 'K51314', 'K51318', 'K51319', 'K5140', 'K51411', 'K51413', 'K51414', 'K51418', 'K51419', 'K5150', 'K51511', 'K51513', 'K51514', 'K51518', 'K51519', 'K5180', 'K51811', 'K51813', 'K51814', 'K51818', 'K51819', 'K5190', 'K51911', 'K51913', 'K51914', 'K51918', 'K51919', 'K50012', 'K50112', 'K50812', 'K50912', 'K51012', 'K51212', 'K51312', 'K51412', 'K51512', 'K51812', 'K51912')) 
        then hcc=48;

   if hcc = 0 then delete;   
  
   oop = copay + cob + coins + deduct;
run; 


*** Collapse to yearly spending by enrollee-hcc pairing (eventually need to merge this back into main sample);  
proc sql; 
   create table out.maintenance_costs_hcc48_ip as 
   select enrolid, hcc, year, sum(oop) as ip_oop, sum(pay) as ip_pay from out.maintenance_costs_hcc48_ip
   group by enrolid, hcc, year; 
quit;


*** Adjust for inflation; 
data out.maintenance_costs_hcc48_ip; 
   set out.maintenance_costs_hcc48_ip;

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
