/*
*========================================================================*
* Program:   Identifying family risk from diagnosis 		             *
*                                                                        *
* Purpose:   This code identifies non-sample individuals diagnosed 	 *
* 		with an HCC in 2007. Then, calculates the rate at which  *
*		other family members are diagnosed in next 10 years.     *
*                                                                        *
* Note: This file							 *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*									 *
* Created:   October, 2020		                                 *
* Updated:  		                                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/IdentifyPHat/';

/*------------------------------------------------------------------------*
 * 		ORDER OF OPERATIONS					  *
 * 0. Identify all with HCC  claims in 2009-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Claims, 2009 - 2018 -----------------------------------------*/; 
data out.allclaims_hcc20_2009; 
   set in.ms_o_2009(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2009(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('24940', '24941', '24950', '24951', '24960', '24961', '24970', '24971', '24980', '24981', '24990', '24991', '25040', '25041', '25042', '25043', '25050', '25051', '25052', '25053', '25060', '25061', '25062', '25063', '25070', '25071', '25072', '25073', '25080', '25081', '25082', '25083', '25090', '25091', '25092', '25093', '3572', '36201', '36202', '36203', '36204', '36205', '36206', '36207', '36641', 'E0821', 'E0822', 'E0829', 'E08311', 'E08319', 'E08321', 'E08329', 'E08331', 'E08339', 'E08341', 'E08349', 'E08351', 'E08359', 'E0836', 'E0839', 'E0840', 'E0841', 'E0842', 'E0843', 'E0844', 'E0849', 'E0851', 'E0852', 'E0859', 'E08610', 'E08618', 'E08620', 'E08621', 'E08622', 'E08628', 'E08630', 'E08638', 'E08649', 'E0865', 'E0869', 'E088', 'E0921', 'E0922', 'E0929', 'E09311', 'E09319', 'E09321', 'E09329', 'E09331', 'E09339', 'E09341', 'E09349', 'E09351', 'E09359', 'E0936', 'E0939', 'E0940', 'E0941', 'E0942', 'E0943', 'E0944', 'E0949', 'E0951', 'E0952', 'E0959', 'E09610', 'E09618', 'E09620', 'E09621', 'E09622', 'E09628', 'E09630', 'E09638', 'E09649', 'E0965', 'E0969', 'E098', 'E1021', 'E1022', 'E1029', 'E10311', 'E10319', 'E10321', 'E10329', 'E10331', 'E10339', 'E10341', 'E10349', 'E10351', 'E10359', 'E1036', 'E1039', 'E1040', 'E1041', 'E1042', 'E1043', 'E1044', 'E1049', 'E1051', 'E1052', 'E1059', 'E10610', 'E10618', 'E10620', 'E10621', 'E10622', 'E10628', 'E10630', 'E10638', 'E10649', 'E1065', 'E1069', 'E108', 'E1121', 'E1122', 'E1129', 'E11311', 'E11319', 'E11321', 'E11329', 'E11331', 'E11339', 'E11341', 'E11349', 'E11351', 'E11359', 'E1136', 'E1139', 'E1140', 'E1141', 'E1142', 'E1143', 'E1144', 'E1149', 'E1151', 'E1152', 'E1159', 'E11610', 'E11618', 'E11620', 'E11621', 'E11622', 'E11628', 'E11630', 'E11638', 'E11649', 'E1165', 'E1169', 'E118', 'E1321', 'E1322', 'E1329', 'E13311', 'E13319', 'E13321', 'E13329', 'E13331', 'E13339', 'E13341', 'E13349', 'E13351', 'E13359', 'E1336', 'E1339', 'E1340', 'E1341', 'E1342', 'E1343', 'E1344', 'E1349', 'E1351', 'E1352', 'E1359', 'E13610', 'E13618', 'E13620', 'E13621', 'E13622', 'E13628', 'E13630', 'E13638', 'E13649', 'E1365', 'E1369', 'E138'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc20_2009 as 
   select enrolid from out.allclaims_hcc20_2009
   group by enrolid; 
quit; 

data out.allenrollees_hcc20_2009;
   set out.allenrollees_hcc20_2009;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_20_2009; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc20_2009");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2009; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 