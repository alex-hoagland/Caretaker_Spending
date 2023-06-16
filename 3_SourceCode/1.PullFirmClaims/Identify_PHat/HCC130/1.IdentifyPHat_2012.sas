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
 * 0. Identify all with HCC  claims in 2012-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Claims, 2012 - 2018 -----------------------------------------*/; 
data out.allclaims_hcc130_2012; 
   set in.ms_o_2012(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2012(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('39891', '40201', '40211', '40291', '40401', '40403', '40411', '40413', '40491', '40493', '4150', '4160', '4161', '4168', '4169', '4170', '4171', '4178', '4179', '4250', '42511', '42518', '4252', '4253', '4254', '4255', '4257', '4258', '4259', '4280', '4281', '42820', '42821', '42822', '42823', '42830', '42831', '42832', '42833', '42840', '42841', '42842', '42843', '4289', '4290', '4291', 'A3681', 'B3324', 'I0981', 'I110', 'I130', 'I132', 'I2601', 'I2602', 'I2609', 'I270', 'I271', 'I272', 'I2781', 'I2789', 'I279', 'I280', 'I281', 'I288', 'I289', 'I420', 'I421', 'I422', 'I423', 'I424', 'I425', 'I426', 'I427', 'I428', 'I429', 'I43', 'I501', 'I5020', 'I5021', 'I5022', 'I5023', 'I5030', 'I5031', 'I5032', 'I5033', 'I5040', 'I5041', 'I5042', 'I5043', 'I509', 'I514', 'I515'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc130_2012 as 
   select enrolid from out.allclaims_hcc130_2012
   group by enrolid; 
quit; 

data out.allenrollees_hcc130_2012;
   set out.allenrollees_hcc130_2012;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_130_2012; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc130_2012");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2012; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 