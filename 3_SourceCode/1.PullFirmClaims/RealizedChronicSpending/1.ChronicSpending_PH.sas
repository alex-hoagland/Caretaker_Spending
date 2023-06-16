/*
*========================================================================*
* Program:   Realized Chronic Care Spending: IP.sas                      *
*                                                                        *
* Purpose:   This program identifies each enrollee-HCC's realized        *
* 		chronic care spenidng in a year.			 * 
*                                                                        *
* Author:    Alex Hoagland						 *
*            Boston University				                 *
*                                                                        *
* Created:   Feb, 2021		                                         *
* Updated:  				                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/caretaking/SpendingFiles/' access=readonly;
libname out '/project/caretaking/';

*** Start with all claims, keep only those associated with certain HCCs; 
data out.chroniccosts_ph(compress=yes); 
   set in.allfamilies_pharma(keep=enrolid year copay cob deduct coins pay thercls);
   if year > 2013 then delete;

    if thercls in: ('21', '14', '16', '21', '27', '39', '40', '41', '42', '46', '47', '50', '51', '52', '53', '58', '59', '64', '68', '69', '70', '71', '72', '73', 
                   '74', '75', '76', '85', '107', '120', '121', '122', '123', '124', '125', '160', '162', '166', '167', '170', '172', '173', '174', '175', '176', 
                   '177', '178', '179', '181', '190', '191', '192', '193', '194', '242', '248', '250', '262', '263', '266', '267', '268');  
  
   oop = copay + cob + coins + deduct;
run; 


*** Collapse to yearly spending by enrollee-thercls pairing (eventually need to merge this back into main sample);  
proc sql; 
   create table out.chroniccosts_ph_table as 
   select enrolid, thercls, year, sum(oop) as ph_oop, sum(pay) as ph_pay from out.chroniccosts_ph
   group by enrolid, thercls, year; 
quit;


*** Adjust for inflation; 
data out.chroniccosts_ph_table; 
   set out.chroniccosts_ph_table;

   * Change all spending to 2020 dollars;
   if year = 2006 then ph_oop = ph_oop * 1.2788;
   if year = 2006 then ph_pay = ph_pay * 1.2788 ;
   if year = 2007 then ph_oop = ph_oop * 1.2449;
   if year = 2007 then ph_pay = ph_pay * 1.2449;
   if year = 2008 then ph_oop = ph_oop * 1.1988;
   if year = 2008 then ph_pay = ph_pay * 1.1988 ;
   if year = 2009 then ph_oop = ph_oop * 1.2031 ;
   if year = 2009 then ph_pay = ph_pay * 1.2031 ;
   if year = 2010 then ph_oop = ph_oop * 1.1837 ;
   if year = 2010 then ph_pay = ph_pay * 1.1837 ;
   if year = 2011 then ph_oop = ph_oop * 1.1475 ;
   if year = 2011 then ph_pay = ph_pay * 1.1475 ;
   if year = 2012 then ph_oop = ph_oop * 1.1242 ;
   if year = 2012 then ph_pay = ph_pay * 1.1242  ;
   if year = 2013 then ph_oop = ph_oop * 1.1080 ;
   if year = 2013 then ph_pay = ph_pay * 1.1080 ;
   if year = 2014 then ph_oop = ph_oop * 1.0903 ;
   if year = 2014 then ph_pay = ph_pay * 1.0903 ;
   if year = 2015 then ph_oop = ph_oop * 1.0890 ;
   if year = 2015 then ph_pay = ph_pay * 1.0890 ;
   if year = 2016 then ph_oop = ph_oop * 1.0754 ;
   if year = 2016 then ph_pay = ph_pay * 1.0754 ;
   if year = 2017 then ph_oop = ph_oop * 1.0530 ;
   if year = 2017 then ph_pay = ph_pay * 1.0530 ;
   if year = 2018 then ph_oop = ph_oop * 1.0261 ;
   if year = 2018 then ph_pay = ph_pay * 1.0261 ;
run; 

*proc delete data=out.chroniccosts_ph; 
*run; 
