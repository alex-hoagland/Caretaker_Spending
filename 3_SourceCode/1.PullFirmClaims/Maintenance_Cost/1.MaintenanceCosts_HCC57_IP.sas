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
data out.maintenance_costs_hcc57_ip; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.pe_maintenancesample_hcc57");
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

    *57     "Lupus";
    if (dx1 in: ('0993', '4465', '7100', '7102', '7105', '7108', '7109', '71110', '71111', '71112', '71113', '71114', '71115', '71116', '71117', '71118', '71119', '7144', '71489', '7149', '725', 'M0230', 'M02311', 'M02312', 'M02319', 'M02321', 'M02322', 'M02329', 'M02331', 'M02332', 'M02339', 'M02341', 'M02342', 'M02349', 'M02351', 'M02352', 'M02359', 'M02361', 'M02362', 'M02369', 'M02371', 'M02372', 'M02379', 'M0238', 'M0239', 'M064', 'M1200', 'M12011', 'M12012', 'M12019', 'M12021', 'M12022', 'M12029', 'M12031', 'M12032', 'M12039', 'M12041', 'M12042', 'M12049', 'M12051', 'M12052', 'M12059', 'M12061', 'M12062', 'M12069', 'M12071', 'M12072', 'M12079', 'M1208', 'M1209', 'M315', 'M316', 'M320', 'M3210', 'M3211', 'M3212', 'M3213', 'M3214', 'M3215', 'M3219', 'M328', 'M329', 'M3500', 'M3501', 'M3502', 'M3503', 'M3504', 'M3509', 'M351', 'M353', 'M355', 'M358', 'M359', 'M368') or 
        dx2 in: ('0993', '4465', '7100', '7102', '7105', '7108', '7109', '71110', '71111', '71112', '71113', '71114', '71115', '71116', '71117', '71118', '71119', '7144', '71489', '7149', '725', 'M0230', 'M02311', 'M02312', 'M02319', 'M02321', 'M02322', 'M02329', 'M02331', 'M02332', 'M02339', 'M02341', 'M02342', 'M02349', 'M02351', 'M02352', 'M02359', 'M02361', 'M02362', 'M02369', 'M02371', 'M02372', 'M02379', 'M0238', 'M0239', 'M064', 'M1200', 'M12011', 'M12012', 'M12019', 'M12021', 'M12022', 'M12029', 'M12031', 'M12032', 'M12039', 'M12041', 'M12042', 'M12049', 'M12051', 'M12052', 'M12059', 'M12061', 'M12062', 'M12069', 'M12071', 'M12072', 'M12079', 'M1208', 'M1209', 'M315', 'M316', 'M320', 'M3210', 'M3211', 'M3212', 'M3213', 'M3214', 'M3215', 'M3219', 'M328', 'M329', 'M3500', 'M3501', 'M3502', 'M3503', 'M3504', 'M3509', 'M351', 'M353', 'M355', 'M358', 'M359', 'M368')) 
        then hcc=57;

   if hcc = 0 then delete;   
  
   oop = copay + cob + coins + deduct;
run; 


*** Collapse to yearly spending by enrollee-hcc pairing (eventually need to merge this back into main sample);  
proc sql; 
   create table out.maintenance_costs_hcc57_ip as 
   select enrolid, hcc, year, sum(oop) as ip_oop, sum(pay) as ip_pay from out.maintenance_costs_hcc57_ip
   group by enrolid, hcc, year; 
quit;


*** Adjust for inflation; 
data out.maintenance_costs_hcc57_ip; 
   set out.maintenance_costs_hcc57_ip;

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
