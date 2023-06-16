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
data out.maintenance_costs_hcc162_op; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_maintenancesample_hcc162");
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

    *162     "Fibrosis of Lung";
    if (dx1 in: ('M3213', 'M3301', 'M3311', 'M3321', 'M3391', 'M3481', 'M3502', 'B4481', 'D860', 'D862', 'J60', 'J61', 'J620', 'J628', 'J630', 'J631', 'J632', 'J633', 'J634', 'J635', 'J636', 'J64', 'J65', 'J660', 'J661', 'J662', 'J668', 'J670', 'J671', 'J672', 'J673', 'J674', 'J675', 'J676', 'J677', 'J678', 'J679', 'J680', 'J681', 'J682', 'J683', 'J684', 'J688', 'J689', 'J700', 'J701', 'J82', 'J8401', 'J8402', 'J8403', 'J8409', 'J8410', 'J84111', 'J84112', 'J84113', 'J84114', 'J84115', 'J84116', 'J84117', 'J8417', 'J842', 'J8481', 'J8482', 'J8483', 'J84841', 'J84842', 'J84843', 'J84848', 'J8489', 'J849', 'J99', '135', '4950', '4951', '4952', '4953', '4954', '4955', '4956', '4957', '4958', '4959', '500', '501', '502', '503', '504', '505', '5060', '5061', '5062', '5063', '5064', '5069', '5080', '5081', '515', '5160', '5161', '5162', '51630', '51631', '51632', '51633', '51634', '51635', '51636', '51637', '5164', '5165', '51661', '51662', '51663', '51664', '51669', '5168', '5169', '5171', '5172', '5178', '5183', '5186') or 
        dx2 in: ('M3213', 'M3301', 'M3311', 'M3321', 'M3391', 'M3481', 'M3502', 'B4481', 'D860', 'D862', 'J60', 'J61', 'J620', 'J628', 'J630', 'J631', 'J632', 'J633', 'J634', 'J635', 'J636', 'J64', 'J65', 'J660', 'J661', 'J662', 'J668', 'J670', 'J671', 'J672', 'J673', 'J674', 'J675', 'J676', 'J677', 'J678', 'J679', 'J680', 'J681', 'J682', 'J683', 'J684', 'J688', 'J689', 'J700', 'J701', 'J82', 'J8401', 'J8402', 'J8403', 'J8409', 'J8410', 'J84111', 'J84112', 'J84113', 'J84114', 'J84115', 'J84116', 'J84117', 'J8417', 'J842', 'J8481', 'J8482', 'J8483', 'J84841', 'J84842', 'J84843', 'J84848', 'J8489', 'J849', 'J99', '135', '4950', '4951', '4952', '4953', '4954', '4955', '4956', '4957', '4958', '4959', '500', '501', '502', '503', '504', '505', '5060', '5061', '5062', '5063', '5064', '5069', '5080', '5081', '515', '5160', '5161', '5162', '51630', '51631', '51632', '51633', '51634', '51635', '51636', '51637', '5164', '5165', '51661', '51662', '51663', '51664', '51669', '5168', '5169', '5171', '5172', '5178', '5183', '5186')) 
        then hcc=162;

   if hcc = 0 then delete;   
  
   oop = copay + cob + coins + deduct;
run; 


*** Collapse to yearly spending by enrollee-hcc pairing (eventually need to merge this back into main sample);  
proc sql; 
   create table out.maintenance_costs_hcc162_op as 
   select enrolid, hcc, year, sum(oop) as op_oop, sum(pay) as op_pay from out.maintenance_costs_hcc162_op
   group by enrolid, hcc, year; 
quit;


*** Adjust for inflation; 
data out.maintenance_costs_hcc162_op; 
   set out.maintenance_costs_hcc162_op;

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
