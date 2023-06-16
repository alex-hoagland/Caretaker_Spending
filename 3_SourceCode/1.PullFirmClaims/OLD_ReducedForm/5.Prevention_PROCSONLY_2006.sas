  /*
*========================================================================*
* Program:   Adults/create_cohorts_claims.sas                            *
*                                                                        *
* Purpose:   This program pulls all preventive services for adults 18-64 *
*		in the MarketScan data. 				 *
*                                                                        *
* Author:    Alex Hoagland/Paul Shafer                                   *
*            Boston University				                 *
*                                                                        *
* Created:   June 16, 2020	                                         *
* Updated:  		                                                 *
*========================================================================*;
*/
   
*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

proc import out=out.allfamilies
    datafile="AllFamilies.csv"
    dbms=csv;
run; 
        
/*-------------------------*
* Create OUTPATIENT sample *
*--------------------------*/;
       
*Pull and save all outpatient preventive claims; 
data out.outpatient2006(compress=yes); 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_o_2006(keep=enrolid year sex proc1 pay cob copay coins ded:); 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   /* ALL PREVENTIVE SERVICES ONLY */; 

   /*Administration & management of contraceptives */;
   if (proc1 in: ('11975', '11976', '11981', '11982', '11983', '58300', '58301', 'A4261', 'J1050', 'J1051', 'J1055', 'J1056', 'J7300', 'J7302', 'J7306', 'J7307', 'S4981', 'S4989')) 
    then svc_contraceptive = 1; 
    else svc_contraceptive = 0; 

   /* Alcohol/Tobacco Misuse Counseling */;
   if (proc1 in: ('C9801', 'C9802', 'G0396', 'G0397', 'G0436', 'G0437', 'G0442', 'S9075', 'S9453')) 
   then svc_subab = 1;
   else svc_subab = 0; 

   /* All Cancer Screenings */;
   if (proc1 in: ('44388', '44389', '44390', '44391', '44392', '44393', '44394', '45300', '45301', '45302', '45303', '45304', '45305', '45306', '45307', '45308', '45309', '45310', '45311', '45312', '45313', '45314', '45315', '45316', '45317', '45318', '45319', '45320', '45321', '45330', '45331', '45332', '45333', '45334', '45335', '45338', '45339', '45340', '45378', '45379', '45380', '45381', '45382', '45383', '45384', '45385', '45386', '71250', '71260', '74261', '74262', '74263', '76083', '76090', '76091', '76092', '76093', '76094', '77052', '77057', '77063', '77065', '77066', '77067', '88141', '88142', '88143', '88147', '88148', '88150', '88152', '88153', '88154', '88155', '88164', '88165', '88166', '88167', '88174', '88175', '88300', '88302', '88304', '88305', '88307', '88309', '96040', 'G0101', 'G0104', 'G0105', 'G0106', 'G0107', 'G0120', 'G0121', 'G0122', 'G0123', 'G0124', 'G0141', 'G0143', 'G0144', 'G0145', 'G0147', 'G0148', 'G0202', 'G0296', 'G0297', 'G0328', 'G0394', 'P3000', 'P3001', 'Q0091', 'S0265', 'S0601', 'S3890', 'S8032', 'S8092')) 
   then svc_cancerscreen = 1;
   else svc_cancerscreen = 0;

   /*Cholesterol Screening */;
   if (proc1 in: ('80061', '82465', '83718', '83719', '83721', '84478')) 
   then svc_cholesterol = 1;
   else svc_cholesterol = 0;

   /*Depression Screening*/;
   if (proc1 in: ('96127', '96160', '96161', 'G0444')) 
   then svc_depression = 1;
   else svc_depression = 0; 

   /*Diabetes Screening*/;
   if (proc1 in: ('82947', '82948', '82950', '82951', '82952', '83036')) 
    then svc_diabetes = 1;
    else svc_diabetes = 0;

   /* All Immunizations */; 
   if (proc1 in: ('90460', '90461', '90465', '90466', '90467', '90468', '90470', '90471', '90472', '90473', '90474', '90632', '90633', '90634', '90636', '90644', '90645', '90646', '90647', '90648', '90649', '90650', '90653', '90654', '90655', '90656', '90657', '90658', '90660', '90661', '90662', '90664', '90666', '90667', '90668', '90669', '90670', '90672', '90680', '90681', '90685', '90686', '90687', '90688', '90696', '90698', '90700', '90701', '90702', '90703', '90704', '90705', '90706', '90707', '90708', '90710', '90712', '90713', '90714', '90715', '90716', '90718', '90719', '90720', '90721', '90723', '90732', '90733', '90734', '90736', '90740', '90743', '90744', '90746', '90747', '90748', 'G0008', 'G0009', 'G0010', 'G0377', 'G9141', 'J3530', 'Q2033', 'Q2034', 'Q2035', 'Q2036', 'Q2037', 'Q2038', 'Q2039', 'S0195')) 
   then svc_immunization = 1;
   else svc_immunization = 0; 

   /*Obesity Screening*/;
   if (proc1 in: ('97802', '97803', '97804', 'G0270', 'G0271', 'G0446', 'G0447', 'G0449', 'S9470')) 
   then svc_obesity = 1;
   else svc_obesity = 0; 

   /*General E/M or Wellness Visits? */;
   if (proc1 in: ('99201', '99202', '99203', '99204', '99205', '99211', '99212', '99213', '99214', '99215', '99381', '99382', '99383', '99384', '99385', '99386', '99387', '99388', '99389', '99390', '99391', '99392', '99393', '99394', '99395', '99396', '99397', '99401', '99402', '99403', '99404', '99411', '99412', '99461', 'G0344', 'G0402', 'G0438', 'G0439', 'S0610', 'S0612', 'S0613')) 
   then svc_wellness = 1;
   else svc_wellness = 0;

        if svc_contraceptive = 1 or svc_subab = 1 or svc_cancerscreen = 1 or svc_cholesterol = 1 or svc_depression = 1 or svc_diabetes = 1 or 
	   svc_immunization = 1 or svc_obesity = 1 or svc_wellness = 1; 
run;

*Export claims; 
proc export data=out.outpatient2006
    outfile = "/project/caretaking/AllFamilies_Prevention_2006.dta"
    dbms=stata
    replace;
run; 

/*-----------------*
* Delete SAS data *
*------------------*/; 

proc delete data=out.outpatient2006;
run; 

