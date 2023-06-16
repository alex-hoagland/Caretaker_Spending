/*
*========================================================================*
* Program:   HCCClaimsop.sas     		                         *
*                                                                        *
* Purpose:   This program pulls all op claims for specific chronic HCCs  *
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
data out.maintenance_costs_hcc30_op; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_maintenancesample_hcc30");
   ids.definekey('enrolid');
   ids.definedone();
   end;
    set in.ms_o_2007(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_o_2008(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_o_2009(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_o_2010(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_o_2011(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_o_2012(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_o_2013(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_o_2014(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_o_2015(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_o_2016(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_o_2017(keep=enrolid year pay cob copay coins deduct dx: )
        in.ms_o_2018(keep=enrolid year pay cob copay coins deduct dx: ); 
   if ids.find()^=0 then delete;

   hcc = 0; 

    
    *30     "Adrenal/Pituitary Dis.";	
    if (dx1 in: ('0363', '2510', '25200', '25201', '25202', '25208', '2521', '2528', '2529', '2530', '2531', '2532', '2533', '2534', '2535', '2536', '2537', '2538', '2539', '2540', '2541', '2548', '2549', '2550', '25510', '25511', '25512', '25513', '25514', '2552', '2553', '25541', '25542', '2555', '2556', '2558', '2559', '25801', '25802', '25803', '2581', '2588', '2589', '5881', '58881', 'A391', 'E035', 'E15', 'E200', 'E208', 'E209', 'E210', 'E211', 'E212', 'E213', 'E214', 'E215', 'E220', 'E221', 'E222', 'E228', 'E229', 'E230', 'E231', 'E232', 'E233', 'E236', 'E237', 'E240', 'E241', 'E242', 'E243', 'E244', 'E248', 'E249', 'E250', 'E258', 'E259', 'E2601', 'E2602', 'E2609', 'E261', 'E2681', 'E2689', 'E269', 'E270', 'E271', 'E272', 'E273', 'E2740', 'E2749', 'E275', 'E278', 'E279', 'E310', 'E311', 'E3120', 'E3121', 'E3122', 'E3123', 'E318', 'E319', 'E320', 'E321', 'E328', 'E329', 'E344', 'E892', 'E893', 'E896', 'N251', 'N2581') or 
        dx2 in: ('0363', '2510', '25200', '25201', '25202', '25208', '2521', '2528', '2529', '2530', '2531', '2532', '2533', '2534', '2535', '2536', '2537', '2538', '2539', '2540', '2541', '2548', '2549', '2550', '25510', '25511', '25512', '25513', '25514', '2552', '2553', '25541', '25542', '2555', '2556', '2558', '2559', '25801', '25802', '25803', '2581', '2588', '2589', '5881', '58881', 'A391', 'E035', 'E15', 'E200', 'E208', 'E209', 'E210', 'E211', 'E212', 'E213', 'E214', 'E215', 'E220', 'E221', 'E222', 'E228', 'E229', 'E230', 'E231', 'E232', 'E233', 'E236', 'E237', 'E240', 'E241', 'E242', 'E243', 'E244', 'E248', 'E249', 'E250', 'E258', 'E259', 'E2601', 'E2602', 'E2609', 'E261', 'E2681', 'E2689', 'E269', 'E270', 'E271', 'E272', 'E273', 'E2740', 'E2749', 'E275', 'E278', 'E279', 'E310', 'E311', 'E3120', 'E3121', 'E3122', 'E3123', 'E318', 'E319', 'E320', 'E321', 'E328', 'E329', 'E344', 'E892', 'E893', 'E896', 'N251', 'N2581')) 
        then hcc=30; 

   if hcc = 0 then delete;   
  
   oop = copay + cob + coins + deduct;
run; 


*** Collapse to yearly spending by enrollee-hcc pairing (eventually need to merge this back into main sample);  
proc sql; 
   create table out.maintenance_costs_hcc30_op as 
   select enrolid, hcc, year, sum(oop) as op_oop, sum(pay) as op_pay from out.maintenance_costs_hcc30_op
   group by enrolid, hcc, year; 
quit;


*** Adjust for inflation; 
data out.maintenance_costs_hcc30_op; 
   set out.maintenance_costs_hcc30_op;

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
