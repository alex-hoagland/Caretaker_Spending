/*
*========================================================================*
* Program:   Low Value Services.sas                                      * 
*                                                                        *
* Purpose:   This program identifies the following collections of low-	 *
* 		value services: 				    	 *
*		  1. Pediatric Screenings/Medications		         * 
* 		  2. Adult Medications			 		 *
* 		  3. Adult Imaging			 		 *
*		  4. Adult Cardiac Testing				 *  
* 		  5. Other Adult Low-Value				 *
*                                                                        *
* Author:    Alex Hoagland		                                 *
*            Boston University				                 *
*                                                                        *
* Created:   March 2021		                                         *
* Notes: This is for medical services; see companion file for drugs      *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/*----------------*
 * Create samples *
 *----------------*/;

*Pull all outpatient claims; 
data out.lowval2006(compress=yes); 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_o_2006(keep=enrolid year age sex dx1 dx2 proc1 svcdate); 
        famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

	/*----------------*
	 * 1. Pediatrics  *
	 *----------------*/;

   * Vitamin D Screening; 
   if age <= 18 & proc1 in: ('82306','82652') then lv_1ped_vitd = 1; 
   if age > 18 & proc1 in: ('82306','82652') then lv_5adult_vitd = 1; 

   * Cervical cancer screening;
   if age >= 14 & age <= 21 & sex = 2 & 
     proc1 in: ('87620','87621','87622', '87623', '87624', '87625', '88141', '88142', '88143', '88147', '88148',
	'88150', '88152', '88153', '88154', '88155', '88164', '88165','88166', '88167', '88174', '88175', 'G0123',
	'G0124', 'G0141', 'G0143','G0144', 'G0145', 'G0147', 'G0148', 'P3000', 'P3001', 'Q0091')
   then lv_1ped_cervscreen = 1;

   * Head imaging for headache (NEEDS TO BE COMBINED LATER); 
   * Done for adults and children; 
   if proc1 in: ('70450','70460','70470','70551','70552','70553') then tocombine_headimaging = 1; 
   if (substr(dx1,1,4) in: ('3390', '3391', '3460', '3461', '3462', '3464', '3465', '3467', '3468', '3469', '7840', '3393', 
  			    'G440', 'G441', 'G442', 'G444', 'G430', 'G431', 'G435', 'G437', 'G438', 'G439') or 
         dx1 in: ('30781','33983', '33984', '33985', 'R51', 'R510', 'R519', 'G4483', 'G4484', 'G4485') or 
      substr(dx2,1,4) in: ('3390', '3391', '3460', '3461', '3462', '3464', '3465', '3467', '3468', '3469', '7840', '3393', 
  			    'G440', 'G441', 'G442', 'G444', 'G430', 'G431', 'G435', 'G437', 'G438', 'G439') or 
         dx2 in: ('30781','33983', '33984', '33985', 'R51', 'R510', 'R519', 'G4483', 'G4484', 'G4485')) then tocombine_simpleheadache = 1; 

	/*-----------------------*
	 * For appropriate meds  *
	 *-----------------------*/;
 
   * Migraines; 
   if substr(dx1,1,3) in: ('346','G43') or
      substr(dx2,1,3) in: ('346','G43') then tocombine_migraine = 1;

   * Children respiratory infections;
   if age <= 18 and (substr(dx1,1,3) in: ('460','465','J00','J06','H65','H60','H61','H62') or 
                     substr(dx1,1,4) in: ('3810','3814') or 
                     dx1 in: ('38010','38011','38012','38013','46611','46619','J210','J218','H6590') or 
                     substr(dx2,1,3) in: ('460','465','J00','J06','H65','H60','H61','H62') or 
                     substr(dx2,1,4) in: ('3810','3814') or 
                     dx2 in: ('38010','38011','38012','38013','46611','46619','J210','J218','H6590')) then tocombine_resp = 1; 

   * Bronchiolitis;
   if age <= 18 and (dx1 in: ('46611','46619','J210','J218') or 
       dx2 in: ('46611','46619','J210','J218')) then tocombine_bronch = 1; 
    
	/*-------------------*
	 * 3. Adult Imaging  *
	 *-------------------*/;
   
   * Low back imaging for pain w/in first 6 weeks (NEEDS TO BE COMBINED LATER); 
   if proc1 in: ('72010', '72020','72052', '72100', '72110', '72114','72120', '72200', '72202', '72220', '72131', '72132',
		'72133', '72141', '72142', '72146', '72147', '72148','72149', '72156', '72157', '72158') then tocombine_backimag = 1; 

   if (substr(dx1,1,4) in: ('7213', '7226', '7242', '7243', '7244','7245', '7246','7385', '7393','7394', '8460', '8461',
                          '8462', '8463', '8468', '8469', '8472','M432','M512','M513','M518','M533','M545','M541','M543','M998') or 
      dx1 in:('72190', '72210', '72252', '72293', '72402','72470', '72471', '72479', 'M47817','M532X7','M9903','M9904',
 	      'S338XXA','S336XXA','S339XXA','S335XXA','M47819','M4647','M4806','M532X8') or
     substr(dx2,1,4) in: ('7213', '7226', '7242', '7243', '7244','7245', '7246','7385', '7393','7394', '8460', '8461',
                          '8462', '8463', '8468', '8469', '8472','M432','M512','M513','M518','M533','M545','M541','M543','M998') or 
      dx2 in:('72190', '72210', '72252', '72293', '72402','72470', '72471', '72479', 'M47817','M532X7','M9903','M9904',
 	      'S338XXA','S336XXA','S339XXA','S335XXA','M47819','M4647','M4806','M532X8')) then tocombine_backpain = 1;

   * Arthroscopic surgery for knee osteoarthritis (NEEDS TO BE COMBINED LATER); 
   if proc1 in: ('29877', '29879', 'G0289') then tocombine_arthrosurgery = 1; 
   if (substr(dx1,1,4) in: ('8360', '8361', '8362', '7170','S832') or dx1 in:('71741','M23202','M23205') or
 	substr(dx2,1,4) in: ('8360', '8361', '8362', '7170','S832') or dx1 in:('71741','M23202','M23205')) then tocombine_kneeinj = 1; 

   * Screening for carotid artery disease (NEEDS TO BE COMBINED LATER); 
   if proc1 in: ('36222', '36223', '36224', '70498', '70547', '70548','70549', '93880', '93882', '3100F') then tocombine_carotid = 1; 

   if (substr(dx1,1,3) in: ('430', '431', '434','436','781','I63','I66','R25','R26','R27','R29','R47','G45','H34','R55','R20') or 
      substr(dx1,1,4) in:('4350', '4351', '4353', '4358', '4359','3623', '7802','7820','I609','I619') or 
      dx1 in: ('43301', '43311', '43321', '43331','43381', '43391', '99702', 'V1254',
		'36284', '78451', '78452', '78459','I6789','I67848','I97811','I97821','Z8673','H3582') or 
      substr(dx2,1,3) in: ('430', '431', '434','436','781','I63','I66','R25','R26','R27','R29','R47','G45','H34','R55','R20') or 
      substr(dx2,1,4) in:('4350', '4351', '4353', '4358', '4359','3623', '7802','7820','I609','I619') or 
      dx2 in: ('43301', '43311', '43321', '43331','43381', '43391', '99702', 'V1254',
		'36284', '78451', '78452', '78459','I6789','I67848','I97811','I97821','Z8673','H3582')) then tocombine_stroke = 1; 

   * Cardiac Imaging; 
   if proc1 in: ('0144T', '0145T', '0146T', '0147T', '0148T', '0149T', '0150T', '75552', '75553', '75554', '75555',
		 '75556', '75557', '75558', '75559', '75561', '75562', '75565', '75571', '75572', '75573', '75574',
   		 '78451', '78452', '78453', '78454', '78460', '78461', '78464', '78465', '78478', '78480', '78459',
		 '78481', '78483', '78491', '78492', '78494', '78496', '78499')
   then lv_3adult_cardimag = 1; 

	/*-------------------*
	 * 4. Adult Testing  *
	 *-------------------*/;

   * Cardiac testing on low-risk patients; 
   if proc1 in: ('93015', '93016', '93017', '93018', '93350', '93351','78451', '78452', '78453', '78454', '78460',
		 '78461','78464', '78465', '78472', '78473', '78481', '78483','78491', '78492') then lv_4adult_stresstest = 1; 

   if proc1 in: ('93303', '93304', '93306', '93307', '93308', '93312','93315', '93318') then lv_4adult_echocardiogram = 1;  
   if proc1 in: ('3120F', '93000', '93005', '93010', 'G0366', 'G0367', 'G0368', 'G0403', 'G0404', 'G0405') then lv_4adult_electrocardiogram = 1;  

   * Pre-operative testing (NEEDS TO BE COMBINED LATER); 
   if proc1 in: ('71010', '71015', '71020', '71021', '71022', '71023', '71030', '71034', '71035', '93303', '93304',
                 '93306', '93307', '93308', '93312', '93315', '93318', '94010', '78451', '78452', '78453', '78454',
	 	 '78460', '78461', '78464', '78465', '78472', '78473', '78481', '78483', '78491', '78492', '93015',
		 '93016', '93017', '93018', '93350', '93351') then tocombine_preoptest = 1;
   if proc1 in: ('19120', '19125', '47562', '47563', '49560', '58558') then tocombine_lowrisksurg = 1;

   * Keep only relevant services; 
   if lv_1ped_vitd = 1 or lv_5adult_vitd =1 or lv_1ped_cervscreen = 1 or tocombine_headimaging = 1 or tocombine_simpleheadache = 1 or
      tocombine_backimag = 1 or tocombine_backpain = 1 or tocombine_arthrosurgery = 1 or tocombine_kneeinj = 1 or tocombine_lowrisksurg = 1 or 
      tocombine_preoptest = 1 or tocombine_stroke = 1 or tocombine_carotid = 1 or lv_4adult_stresstest = 1 or lv_4adult_echocardiogram = 1 or 
      lv_4adult_echocardiogram = 1 or lv_3adult_cardimag = 1 or tocombine_bronch = 1 or tocombine_migraine = 1 or tocombine_resp = 1; 

run; 

*Export claims; 
proc export data=out.lowval2006
    outfile = "/projectnb/caretaking/LowValueServices2006.dta"
    dbms=stata
    replace;
run; 

* Delete SAS data; 
proc delete data=out.lowval2006; 
run; 