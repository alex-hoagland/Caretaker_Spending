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
 * 0. Identify all with HCC  claims in 2010-2018			  *
 * 1. Pull enrollment files for all families in (0.)			  *
 * 2. The rest is done in stata						  *
 *------------------------------------------------------------------------*/;


/* --- 0. All Claims, 2010 - 2018 -----------------------------------------*/; 
data out.allclaims_hcc217_2010; 
   set in.ms_o_2010(keep=enrolid age sex year dx1 dx2 svcdate) in.ms_s_2010(keep=enrolid age sex year dx1 dx2 svcdate);
   
   if dx1 in: ('4540', '4542', '45911', '45913', '45931', '45933', '68601', '70710', '70711', '70712', '70713', '70714', '70715', '70719', '7078', '7079', 'I83001', 'I83002', 'I83003', 'I83004', 'I83005', 'I83008', 'I83009', 'I83011', 'I83012', 'I83013', 'I83014', 'I83015', 'I83018', 'I83019', 'I83021', 'I83022', 'I83023', 'I83024', 'I83025', 'I83028', 'I83029', 'I83201', 'I83202', 'I83203', 'I83204', 'I83205', 'I83208', 'I83209', 'I83211', 'I83212', 'I83213', 'I83214', 'I83215', 'I83218', 'I83219', 'I83221', 'I83222', 'I83223', 'I83224', 'I83225', 'I83228', 'I83229', 'I87011', 'I87012', 'I87013', 'I87019', 'I87031', 'I87032', 'I87033', 'I87039', 'I87311', 'I87312', 'I87313', 'I87319', 'I87331', 'I87332', 'I87333', 'I87339', 'L88', 'L97101', 'L97102', 'L97103', 'L97104', 'L97109', 'L97111', 'L97112', 'L97113', 'L97114', 'L97119', 'L97121', 'L97122', 'L97123', 'L97124', 'L97129', 'L97201', 'L97202', 'L97203', 'L97204', 'L97209', 'L97211', 'L97212', 'L97213', 'L97214', 'L97219', 'L97221', 'L97222', 'L97223', 'L97224', 'L97229', 'L97301', 'L97302', 'L97303', 'L97304', 'L97309', 'L97311', 'L97312', 'L97313', 'L97314', 'L97319', 'L97321', 'L97322', 'L97323', 'L97324', 'L97329', 'L97401', 'L97402', 'L97403', 'L97404', 'L97409', 'L97411', 'L97412', 'L97413', 'L97414', 'L97419', 'L97421', 'L97422', 'L97423', 'L97424', 'L97429', 'L97501', 'L97502', 'L97503', 'L97504', 'L97509', 'L97511', 'L97512', 'L97513', 'L97514', 'L97519', 'L97521', 'L97522', 'L97523', 'L97524', 'L97529', 'L97801', 'L97802', 'L97803', 'L97804', 'L97809', 'L97811', 'L97812', 'L97813', 'L97814', 'L97819', 'L97821', 'L97822', 'L97823', 'L97824', 'L97829', 'L97901', 'L97902', 'L97903', 'L97904', 'L97909', 'L97911', 'L97912', 'L97913', 'L97914', 'L97919', 'L97921', 'L97922', 'L97923', 'L97924', 'L97929', 'L98411', 'L98412', 'L98413', 'L98414', 'L98419', 'L98421', 'L98422', 'L98423', 'L98424', 'L98429', 'L98491', 'L98492', 'L98493', 'L98494', 'L98499', 'I70231', 'I70232', 'I70233', 'I70234', 'I70235', 'I70238', 'I70239', 'I70241', 'I70242', 'I70243', 'I70244', 'I70245', 'I70248', 'I70249', 'I7025', 'I70331', 'I70332', 'I70333', 'I70334', 'I70335', 'I70338', 'I70339', 'I70341', 'I70342', 'I70343', 'I70344', 'I70345', 'I70348', 'I70349', 'I7035', 'I70431', 'I70432', 'I70433', 'I70434', 'I70435', 'I70438', 'I70439', 'I70441', 'I70442', 'I70443', 'I70444', 'I70445', 'I70448', 'I70449', 'I7045', 'I70531', 'I70532', 'I70533', 'I70534', 'I70535', 'I70538', 'I70539', 'I70541', 'I70542', 'I70543', 'I70544', 'I70545', 'I70548', 'I70549', 'I7055', 'I70631', 'I70632', 'I70633', 'I70634', 'I70635', 'I70638', 'I70639', 'I70641', 'I70642', 'I70643', 'I70644', 'I70645', 'I70648', 'I70649', 'I7065', 'I70731', 'I70732', 'I70733', 'I70734', 'I70735', 'I70738', 'I70739', 'I70741', 'I70742', 'I70743', 'I70744', 'I70745', 'I70748', 'I70749', 'I7075'); 
run; 
  
* Collapse to enrollee level; 
proc sql; 
   create table out.allenrollees_hcc217_2010 as 
   select enrolid from out.allclaims_hcc217_2010
   group by enrolid; 
quit; 

data out.allenrollees_hcc217_2010;
   set out.allenrollees_hcc217_2010;

   famid = floor(enrolid/100); 
run; 

/* --- 1. Enrollment Info for all involved families -----------------------------------------*/; 
data out.allenrollment_217_2010; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allenrollees_hcc217_2010");
   ids.definekey('famid');
   ids.definedone();
   end;

   set in.ms_a_2010; 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;
run; 