/*
*========================================================================*
* Program:   HCCClaimsPH.sas     		                         *
*                                                                        *
* Purpose:   This program pulls all PH claims for specific chronic HCCs  *
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

proc import out=out.allfamilies
    datafile='AllFamilies.csv'
    dbms = csv; 
run; 

/*----------------*
 * Create samples *
 *----------------*/;

*Pull all pharma claims; 
data out.pe_pharma; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_d_2006(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2007(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2008(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2009(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2010(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2011(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2012(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2013(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2014(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2015(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2016(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2017(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate)
        in.ms_d_2018(keep=enrolid year netpay pay cob copay coins deduct thercls svcdate); 
   famid = floor(enrolid/100);
   if ids.find()^=0 then delete;

   if thercls in: ('21', '14', '16', '21', '27', '39', '40', '41', '42', '46', '47', '50', '51', '52', '53', '58', '59', '64', '68', '69', '70', '71', '72', '73', 
                   '74', '75', '76', '85', '107', '120', '121', '122', '123', '124', '125', '160', '162', '166', '167', '170', '172', '173', '174', '175', '176', 
                   '177', '178', '179', '181', '190', '191', '192', '193', '194', '242', '248', '250', '262', '263', '266', '267', '268'); 

run; 

*** ONLY ADJUST FOR INFLATION -- nothing else here without more information. 
data out.pe_pharma; 
    set out.pe_pharma;
    oop = deduct + cob + copay + coins; 

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

*** Export PH Diagnostic Costs;  
proc export data=out.pe_pharma
    outfile = "/project/caretaking/DiagnosticCost_PH.dta"
    dbms=stata
    replace; 
run; 

* Delete SAS data; 
proc delete data=out.pe_pharma; 
run; 
