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
data out.maintenance_costs_hcc13_ip; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_maintenancesample_hcc13");
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
    
    *13     "Thyroid Cancer";
    if (dx1 in: ('1720', '1721', '1722', '1723', '1724', '1725', '1726', '1727', '1728', '1729', '1860', '1869', '1871', '1872', '1873', '1874', '1875', '1876', '1877', '1878', '1879', '193', '1941', '1945', '1946', '1948', '1949', '1991', '23770', '23771', '23772', '23773', '23779', '2592', 'C430', 'C4310', 'C4311', 'C4312', 'C4320', 'C4321', 'C4322', 'C4330', 'C4331', 'C4339', 'C434', 'C4351', 'C4352', 'C4359', 'C4360', 'C4361', 'C4362', 'C4370', 'C4371', 'C4372', 'C438', 'C439', 'C600', 'C601', 'C602', 'C608', 'C609', 'C6200', 'C6201', 'C6202', 'C6210', 'C6211', 'C6212', 'C6290', 'C6291', 'C6292', 'C6300', 'C6301', 'C6302', 'C6310', 'C6311', 'C6312', 'C632', 'C637', 'C638', 'C639', 'C73', 'C750', 'C754', 'C755', 'C758', 'C759', 'C801', 'D030', 'D0310', 'D0311', 'D0312', 'D0320', 'D0321', 'D0322', 'D0330', 'D0339', 'D034', 'D0351', 'D0352', 'D0359', 'D0360', 'D0361', 'D0362', 'D0370', 'D0371', 'D0372', 'D038', 'D039', 'E340', 'Q8500', 'Q8501', 'Q8502', 'Q8503', 'Q8509') or 
        dx2 in: ('1720', '1721', '1722', '1723', '1724', '1725', '1726', '1727', '1728', '1729', '1860', '1869', '1871', '1872', '1873', '1874', '1875', '1876', '1877', '1878', '1879', '193', '1941', '1945', '1946', '1948', '1949', '1991', '23770', '23771', '23772', '23773', '23779', '2592', 'C430', 'C4310', 'C4311', 'C4312', 'C4320', 'C4321', 'C4322', 'C4330', 'C4331', 'C4339', 'C434', 'C4351', 'C4352', 'C4359', 'C4360', 'C4361', 'C4362', 'C4370', 'C4371', 'C4372', 'C438', 'C439', 'C600', 'C601', 'C602', 'C608', 'C609', 'C6200', 'C6201', 'C6202', 'C6210', 'C6211', 'C6212', 'C6290', 'C6291', 'C6292', 'C6300', 'C6301', 'C6302', 'C6310', 'C6311', 'C6312', 'C632', 'C637', 'C638', 'C639', 'C73', 'C750', 'C754', 'C755', 'C758', 'C759', 'C801', 'D030', 'D0310', 'D0311', 'D0312', 'D0320', 'D0321', 'D0322', 'D0330', 'D0339', 'D034', 'D0351', 'D0352', 'D0359', 'D0360', 'D0361', 'D0362', 'D0370', 'D0371', 'D0372', 'D038', 'D039', 'E340', 'Q8500', 'Q8501', 'Q8502', 'Q8503', 'Q8509')) 
        then hcc=13;

   if hcc = 0 then delete;   
  
   oop = copay + cob + coins + deduct;
run; 


*** Collapse to yearly spending by enrollee-hcc pairing (eventually need to merge this back into main sample);  
proc sql; 
   create table out.maintenance_costs_hcc13_ip as 
   select enrolid, hcc, year, sum(oop) as ip_oop, sum(pay) as ip_pay from out.maintenance_costs_hcc13_ip
   group by enrolid, hcc, year; 
quit;


*** Adjust for inflation; 
data out.maintenance_costs_hcc13_ip; 
   set out.maintenance_costs_hcc13_ip;

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
