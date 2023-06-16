/*
*========================================================================*
* Program:   Hospitalization types	                                 *
*                                                                        *
* Purpose:   This program pulls claims for 2 types:			 *
* 		* non-deferrable 					 *
* 		* preventable (ambulatory care sensitive)		 *
*                                                                        *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*                                                                        *
* Created:   August, 2020	                                         *
* Updated:  		                                                 *
*========================================================================*;
*/

*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/project/caretaking/';

/*----------------*
 * Create samples *
 *----------------*/;

*Pull all claims; 
data out.all_hospitalizations; 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set     in.ms_i_2006(keep=enrolid age adm: dx: pproc proc: year) 
		in.ms_i_2007(keep=enrolid age adm: dx: pproc proc: year) 
		in.ms_i_2008(keep=enrolid age adm: dx: pproc proc: year) 
		in.ms_i_2009(keep=enrolid age adm: dx: pproc proc: year) 
		in.ms_i_2010(keep=enrolid age adm: dx: pproc proc: year) 
		in.ms_i_2011(keep=enrolid age adm: dx: pproc proc: year) 
		in.ms_i_2012(keep=enrolid age adm: dx: pproc proc: year) 
		in.ms_i_2013(keep=enrolid age adm: dx: pproc proc: year) 
		in.ms_i_2014(keep=enrolid age adm: dx: pproc proc: year)
		in.ms_i_2015(keep=enrolid age adm: dx: pproc proc: year)
		in.ms_i_2016(keep=enrolid age adm: dx: pproc proc: year)
		in.ms_i_2017(keep=enrolid age adm: dx: pproc proc: year)
		in.ms_i_2018(keep=enrolid age adm: dx: pproc proc: year); 
   famid = floor(enrolid/100);
   if ids.find()^=0 then delete;

   /*-------------------------------------*
   * Preventable hospitalizations	  * 
   * (using https://tinyurl.com/y2xjcuc5) *
   *--------------------------------------*/; 

	* 2. Anemia;
		if ((dx1 in: ('2801', '2808', '2809', 'D501', 'D508', 'D509') or 
		     dx2 in: ('2801', '2808', '2809', 'D501', 'D508', 'D509') or 
		     dx3 in: ('2801', '2808', '2809', 'D501', 'D508', 'D509') or
		     dx4 in: ('2801', '2808', '2809', 'D501', 'D508', 'D509')) and age < 6) then preventable_hospitalization = 1; 
	* 3. Angina; 
		if (dx1 in: ('4111', '4118', '4130', '4131', '4139', 'I200', 'I201', 'I208', 'I209', 'I240', 'I248', 'I249') or 
		     dx2 in: ('4111', '4118', '4130', '4131', '4139', 'I200', 'I201', 'I208', 'I209', 'I240', 'I248', 'I249') or 
		     dx3 in: ('4111', '4118', '4130', '4131', '4139', 'I200', 'I201', 'I208', 'I209', 'I240', 'I248', 'I249') or
		     dx4 in: ('4111', '4118', '4130', '4131', '4139', 'I200', 'I201', 'I208', 'I209', 'I240', 'I248', 'I249')) then angina = 1; 
		* Remove surgical procedures;
		if (angina = 1 and length(pproc) = 4 and substr(pproc,1,2) ~= '00' and substr(pproc,1,1) ~= '9') then angina = 0; 
		if (angina = 1 and length(pproc) >= 5 and substr(pproc,1,1) in: ('0', '1')) then angina = 0; 

		if angina = 1 then preventable_hospitalization = 1; 
	* 4. Asthma; 
		if (dx1 in: ('49300', '49301', '49302', '49310', '49311', '49312', '49320', '49321', '49322', '49381', '49382', '49390', '49391', '49392', 
			    'J4520', 'J4521', 'J4522', 'J4530', 'J4531', 'J4532', 'J4540', 'J4541', 'J4542', 'J4550', 'J4541', 'J4552', 'J45901', 'J45902', 'J45909', 'J45990', 'J45991', 'J45998') or 
		     dx2 in: ('49300', '49301', '49302', '49310', '49311', '49312', '49320', '49321', '49322', '49381', '49382', '49390', '49391', '49392',
			    'J4520', 'J4521', 'J4522', 'J4530', 'J4531', 'J4532', 'J4540', 'J4541', 'J4542', 'J4550', 'J4541', 'J4552', 'J45901', 'J45902', 'J45909', 'J45990', 'J45991', 'J45998') or 
		     dx3 in: ('49300', '49301', '49302', '49310', '49311', '49312', '49320', '49321', '49322', '49381', '49382', '49390', '49391', '49392',
			    'J4520', 'J4521', 'J4522', 'J4530', 'J4531', 'J4532', 'J4540', 'J4541', 'J4542', 'J4550', 'J4541', 'J4552', 'J45901', 'J45902', 'J45909', 'J45990', 'J45991', 'J45998') or
		     dx4 in: ('49300', '49301', '49302', '49310', '49311', '49312', '49320', '49321', '49322', '49381', '49382', '49390', '49391', '49392',
			    'J4520', 'J4521', 'J4522', 'J4530', 'J4531', 'J4532', 'J4540', 'J4541', 'J4542', 'J4550', 'J4541', 'J4552', 'J45901', 'J45902', 'J45909', 'J45990', 'J45991', 'J45998'))
			 then asthma = 1;
		* Remove certain procedures; 
		if (asthma = 1  and pproc in: ('3601', '3602', '3605', '361', '3610', '375', '3750', '377', '3770')) then asthma = 0; 
		if asthma = 1 then preventable_hospitalization = 1; 
	* 5. Cellulitis; 
		if (dx1 in: ('68100', '68101' '68102', '68110', '68111', '6819', '6820', '6821', '6822', '6823', '6824', '6825', '6826', '6827', '6828', '6829', '683', '68600', '68601', '68609', '6861', '6868', '6869') or 
		     substr(dx1,1,3) in: ('L03', 'L04', 'L08', 'L88') or substr(dx1,1,4) = 'L980' or 
		     	dx2 in: ('68100', '68101' '68102', '68110', '68111', '6819', '6820', '6821', '6822', '6823', '6824', '6825', '6826', '6827', '6828', '6829', '683', '68600', '68601', '68609', '6861', '6868', '6869') or 
		     substr(dx2,1,3) in: ('L03', 'L04', 'L08', 'L88') or substr(dx2,1,4) = 'L980' or 
			dx3 in: ('68100', '68101' '68102', '68110', '68111', '6819', '6820', '6821', '6822', '6823', '6824', '6825', '6826', '6827', '6828', '6829', '683', '68600', '68601', '68609', '6861', '6868', '6869') or 
		     substr(dx3,1,3) in: ('L03', 'L04', 'L08', 'L88') or substr(dx3,1,4) = 'L980' or 
			dx4 in: ('68100', '68101' '68102', '68110', '68111', '6819', '6820', '6821', '6822', '6823', '6824', '6825', '6826', '6827', '6828', '6829', '683', '68600', '68601', '68609', '6861', '6868', '6869') or 
		     substr(dx4,1,3) in: ('L03', 'L04', 'L08', 'L88') or substr(dx4,1,4) = 'L980') then cellulitis = 1;
		* Remove surgical procedures;
 		if (cellulitis = 1 and length(pproc) = 4 and (substr(pproc,1,2) ~= '00' and substr(pproc,1,1) ~= '9' and substr(pproc,1,3) ~= '860')) then cellulitis = 0; 
		if (cellulitis = 1 and length(pproc) >= 5 and substr(pproc,1,1) in: ('0', '1') and substr(pproc,1,2) not in: ('0H', '0J', '0W', '0X')) then cellulitis = 0; 
		
		if cellulitis = 1 then preventable_hospitalization = 1; 
	* 6. COPD; 
		* Note: ignores dx code of 466.0 b/c that requires one of the others as a secondary dx; 
		if (substr(dx1,1,3) in: ('491', '492', '494', '496', 'J20', 'J40', 'J41', 'J42', 'J43', 'J44', 'J47') or
		    substr(dx2,1,3) in: ('491', '492', '494', '496', 'J20', 'J40', 'J41', 'J42', 'J43', 'J44', 'J47') or 
		    substr(dx3,1,3) in: ('491', '492', '494', '496', 'J20', 'J40', 'J41', 'J42', 'J43', 'J44', 'J47') or 
		    substr(dx4,1,3) in: ('491', '492', '494', '496', 'J20', 'J40', 'J41', 'J42', 'J43', 'J44', 'J47')) then preventable_hospitalization = 1; 
	* 7. Congestive heart failure; 
		if (substr(dx1,1,3) in: ('428', 'I50') or substr(dx1,1,4) in: ('I110', 'J810') or dx1 in: ('40201', '40211', '40291', '5184') or 
		    substr(dx2,1,3) in: ('428', 'I50') or substr(dx2,1,4) in: ('I110', 'J810') or dx2 in: ('40201', '40211', '40291', '5184') or 
		    substr(dx3,1,3) in: ('428', 'I50') or substr(dx3,1,4) in: ('I110', 'J810') or dx3 in: ('40201', '40211', '40291', '5184') or 
		    substr(dx4,1,3) in: ('428', 'I50') or substr(dx4,1,4) in: ('I110', 'J810') or dx4 in: ('40201', '40211', '40291', '5184')) then chf = 1; 

		* Removing certain procedures; 
		if (chf = 1 and pproc in: ('3601', '3602', '3605', '361', '3610', '375', '3750', '377', '3770')) then chf = 0; 
		if (chf = 1 and length(pproc) >= 5 and substr(pproc,1,2) = '02') then chf = 0; 
		if chf = 1 then preventable_hospitalization = 1; 
	* 8. Congenital syphilis;
		* ignoring this because it's for newborns only; 
	* 9. Convulsions (age < 6); 
		if (dx1 = '7803' or substr(dx1,1,3) = 'R56' or dx2 = '7803' or substr(dx2,1,3) = 'R56' or
		   dx3 = '7803' or substr(dx3,1,3) = 'R56' or dx4 = '7803' or substr(dx4,1,3) = 'R56') then preventable_hospitalization = 1; 
	* 10. Convulsions (age 6+); 
		* done above; 
	* 11. Epileptic convulsions; 
		if (substr(dx1,1,3) in: ('345', 'G40') or substr(dx2,1,3) in: ('345', 'G40') or 
			substr(dx3,1,3) in: ('345', 'G40') or substr(dx4,1,3) in: ('345', 'G40')) then preventable_hospitalization = 1; 
	* 12. Dehydration; 
		if (dx1 = '2765' or substr(dx1,1,3) = 'E86' or dx2 = '2765' or substr(dx2,1,3) = 'E86' or 
			dx3 = '2765' or substr(dx3,1,3) = 'E86' or dx4 = '2765' or substr(dx4,1,3) = 'E86') then preventable_hospitalization = 1; 
	* 13. Dental conditions; 
		if (substr(dx1,1,3) in: ('521', '522', '523', '525', '528', 'K02', 'K03', 'K04', 'K05', 'K08', 'K12', 'K13') or  
			substr(dx1,1,4) in: ('K060', 'K061', 'K062', 'M276', 'A690', 'K098') or 
		    substr(dx2,1,3) in: ('521', '522', '523', '525', '528', 'K02', 'K03', 'K04', 'K05', 'K08', 'K12', 'K13') or  
			substr(dx2,1,4) in: ('K060', 'K061', 'K062', 'M276', 'A690', 'K098') or 
		    substr(dx3,1,3) in: ('521', '522', '523', '525', '528', 'K02', 'K03', 'K04', 'K05', 'K08', 'K12', 'K13') or  
			substr(dx3,1,4) in: ('K060', 'K061', 'K062', 'M276', 'A690', 'K098') or 
		    substr(dx4,1,3) in: ('521', '522', '523', '525', '528', 'K02', 'K03', 'K04', 'K05', 'K08', 'K12', 'K13') or  
			substr(dx4,1,4) in: ('K060', 'K061', 'K062', 'M276', 'A690', 'K098')) then preventable_hospitalization = 1; 
	* 14. Diabetes; 
		if (substr(dx1,1,4) in: ('2501', '2502', '2503', '2508', '2509', 'E101', 'E131', 'E110', 'E130', 'E106', 'E116', 'E108', 'E118', 'E109', 'E119') or  
			dx1 in: ('E10641', 'E11641') or 
		    substr(dx2,1,4) in: ('2501', '2502', '2503', '2508', '2509', 'E101', 'E131', 'E110', 'E130', 'E106', 'E116', 'E108', 'E118', 'E109', 'E119') or  
			dx2 in: ('E10641', 'E11641') or 
		    substr(dx3,1,4) in: ('2501', '2502', '2503', '2508', '2509', 'E101', 'E131', 'E110', 'E130', 'E106', 'E116', 'E108', 'E118', 'E109', 'E119') or  
			dx3 in: ('E10641', 'E11641') or 
		    substr(dx4,1,4) in: ('2501', '2502', '2503', '2508', '2509', 'E101', 'E131', 'E110', 'E130', 'E106', 'E116', 'E108', 'E118', 'E109', 'E119') or  
			dx4 in: ('E10641', 'E11641')) then preventable_hospitalization = 1; 
	* 15. EENT care; 
		if (substr(dx1,1,3) in: ('382', '462', '463', '465', 'H66', 'J02', 'J03', 'J06') or dx1 in: ('4721', 'J312') or 
		    substr(dx2,1,3) in: ('382', '462', '463', '465', 'H66', 'J02', 'J03', 'J06') or dx2 in: ('4721', 'J312') or 
		    substr(dx3,1,3) in: ('382', '462', '463', '465', 'H66', 'J02', 'J03', 'J06') or dx3 in: ('4721', 'J312') or 
		    substr(dx4,1,3) in: ('382', '462', '463', '465', 'H66', 'J02', 'J03', 'J06') or dx4 in: ('4721', 'J312')) then eent = 1; 
		* removing certain procedures; 
		if (eent = 1 and ((substr(dx1,1,3) in: ('382', 'H66', 'H67') or substr(dx2,1,3) in: ('382', 'H66', 'H67') or 
				   substr(dx3,1,3) in: ('382', 'H66', 'H67') or substr(dx4,1,3) in: ('382', 'H66', 'H67')) and 
				  (pproc in: ('2001', 'C835')))) then eent = 0; 
		if eent = 1 then preventable_hospitalization = 1;  
	* 16. Failure to thrive; 
		if (dx1 in: ('7834', 'R6251', 'R6252', 'R620', 'R6250') or dx2 in: ('7834', 'R6251', 'R6252', 'R620', 'R6250')  or 
		    dx3 in: ('7834', 'R6251', 'R6252', 'R620', 'R6250') or dx4 in: ('7834', 'R6251', 'R6252', 'R620', 'R6250')) then preventable_hospitalization = 1; 
	* 17. Gastroenteritis; 
		if (dx1 in: ('5589', 'k529', 'k5289') or dx2 in: ('5589', 'k529', 'k5289')  or 
		    dx3 in: ('5589', 'k529', 'k5289') or dx4 in: ('5589', 'k529', 'k5289')) then preventable_hospitalization = 1; 
	* 18. Hypertension; 
		if (dx1 in: ('4010', '4019', '40200', '40210', '40290') or substr(dx1,1,3) = 'I10' or substr(dx1,1,4) = 'I119' or 
		    dx2 in: ('4010', '4019', '40200', '40210', '40290') or substr(dx2,1,3) = 'I10' or substr(dx2,1,4) = 'I119' or 
		    dx3 in: ('4010', '4019', '40200', '40210', '40290') or substr(dx3,1,3) = 'I10' or substr(dx3,1,4) = 'I119' or 
		    dx4 in: ('4010', '4019', '40200', '40210', '40290') or substr(dx4,1,3) = 'I10' or substr(dx4,1,4) = 'I119') then hypert = 1; 
		* removing certain procedures; 
 		if (hypert = 1 and pproc in: ('3601', '3602', '3605', '361', '3610', '375', '3750', '377', '3770')) then hypert = 0; 
		if (hypert = 1 and length(pproc) >= 5 and substr(pproc,1,2) = '02') then hypert = 0; 
		if hypert = 1 then preventable_hospitalization = 1; 
	* 19. Hypoglycemia; 
		if (dx1 in: ('2512', 'E162') or dx2 in: ('2512', 'E162') or dx3 in: ('2512', 'E162') or dx4 in: ('2512', 'E162')) then preventable_hospitalization = 1; 
	* 20. Kidney/urinary infection; 
		if (substr(dx1,1,3) in: ('590', 'N10', 'N11', 'N12') or dx1 in: ('5990', '5999') or 
		    substr(dx2,1,3) in: ('590', 'N10', 'N11', 'N12') or dx2 in: ('5990', '5999') or 
		    substr(dx3,1,3) in: ('590', 'N10', 'N11', 'N12') or dx3 in: ('5990', '5999') or 
		    substr(dx4,1,3) in: ('590', 'N10', 'N11', 'N12') or dx4 in: ('5990', '5999')) then preventable_hospitalization = 1; 
	* 21. Nutritional deficiencies; 
		if (substr(dx1,1,3) in: ('260', '261', '262', 'E40', 'E41', 'E43') or substr(dx1,1,4) in: ('E550', 'E643') or dx1 in: ('2680', '2681') or 
		    substr(dx2,1,3) in: ('260', '261', '262', 'E40', 'E41', 'E43') or substr(dx2,1,4) in: ('E550', 'E643') or dx2 in: ('2680', '2681') or 
		    substr(dx3,1,3) in: ('260', '261', '262', 'E40', 'E41', 'E43') or substr(dx3,1,4) in: ('E550', 'E643') or dx3 in: ('2680', '2681') or 
		    substr(dx4,1,3) in: ('260', '261', '262', 'E40', 'E41', 'E43') or substr(dx4,1,4) in: ('E550', 'E643') or dx4 in: ('2680', '2681')) then preventable_hospitalization = 1; 
	* 22. Pneumonia (bacterial); 
		if (substr(dx1,1,3) in: ('481', '483', '485', '486', 'J13', 'J14', 'J16', 'J18') or dx1 in: ('4822', '4823', '4829') 
			or substr(dx1,1,4) in: ('J153', 'J154', 'J157', 'J159') or 
		    substr(dx2,1,3) in: ('481', '483', '485', '486', 'J13', 'J14', 'J16', 'J18') or dx2 in: ('4822', '4823', '4829') 
			or substr(dx2,1,4) in: ('J153', 'J154', 'J157', 'J159') or 
		    substr(dx3,1,3) in: ('481', '483', '485', '486', 'J13', 'J14', 'J16', 'J18') or dx3 in: ('4822', '4823', '4829') 
			or substr(dx3,1,4) in: ('J153', 'J154', 'J157', 'J159') or 
		    substr(dx4,1,3) in: ('481', '483', '485', '486', 'J13', 'J14', 'J16', 'J18') or dx4 in: ('4822', '4823', '4829') 
			or substr(dx4,1,4) in: ('J153', 'J154', 'J157', 'J159')) then pneumonia = 1; 
		* removing some procedures; 
		if (pneumonia = 1 and ((dx1 = '2826' or substr(dx1,1,3) = 'D57' or 
				       dx2 = '2826' or substr(dx2,1,3) = 'D57' or 
				       dx3 = '2826' or substr(dx3,1,3) = 'D57' or 
				       dx4 = '2826' or substr(dx4,1,3) = 'D57') or age = 0)) then pneumonia = 0; 
		if pneumonia = 1 then preventable_hospitalization = 1; 
	* 23. Skin grafts w/ cellulitis; 
		* Ignore this one, not going to worry about specific DRGs and admission types; 
	* 24. Pelvic inflammatory disease; 
		if (substr(dx1,1,3) in: ('614', 'N70', 'N73') or substr(dx2,1,3) in: ('614', 'N70', 'N73') or 
			substr(dx3,1,3) in: ('614', 'N70', 'N73') or substr(dx4,1,3) in: ('614', 'N70', 'N73')) then preventable_hospitalization = 1; 
	* 25. Tuberculosis, Pulmonary; 
		if (substr(dx1,1,3) = '011' or substr(dx1,1,4) in: ('A150', 'A155', 'A159') or 
		    substr(dx2,1,3) = '011' or substr(dx2,1,4) in: ('A150', 'A155', 'A159') or 
		    substr(dx3,1,3) = '011' or substr(dx3,1,4) in: ('A150', 'A155', 'A159') or 
		    substr(dx4,1,3) = '011' or substr(dx4,1,4) in: ('A150', 'A155', 'A159')) then preventable_hospitalization = 1; 
	* 26. Tuberculosis, non-pulmonary; 
		if (substr(dx1,1,3) in: ('012', '013', '014', '015', '016', '017', '018', 'A17', 'A18', 'A19') or 
			substr(dx1,1,4) in: ('A154', 'A156', 'A158') or 
		    substr(dx2,1,3) in: ('012', '013', '014', '015', '016', '017', '018', 'A17', 'A18', 'A19') or 
			substr(dx2,1,4) in: ('A154', 'A156', 'A158') or 
		    substr(dx3,1,3) in: ('012', '013', '014', '015', '016', '017', '018', 'A17', 'A18', 'A19') or 
			substr(dx3,1,4) in: ('A154', 'A156', 'A158') or 
		    substr(dx4,1,3) in: ('012', '013', '014', '015', '016', '017', '018', 'A17', 'A18', 'A19') or 
			substr(dx4,1,4) in: ('A154', 'A156', 'A158')) then preventable_hospitalization = 1; 
	* 27. Vaccine preventable conditions; 
		if (substr(dx1,1,3) in: ('033', '037', '045', '390', '391', 'A33', 'A34', 'A35', 'A37', 'A80', 'I01') or dx1 in: ('3200', 'G000') or 
		    substr(dx2,1,3) in: ('033', '037', '045', '390', '391', 'A33', 'A34', 'A35', 'A37', 'A80', 'I01') or dx2 in: ('3200', 'G000') or 
		    substr(dx3,1,3) in: ('033', '037', '045', '390', '391', 'A33', 'A34', 'A35', 'A37', 'A80', 'I01') or dx3 in: ('3200', 'G000') or 
		    substr(dx4,1,3) in: ('033', '037', '045', '390', '391', 'A33', 'A34', 'A35', 'A37', 'A80', 'I01') or dx4 in: ('3200', 'G000')) 
			then preventable_hospitalization = 1; 
		if (age > 0 and age < 6 and (dx1 in: ('3202', 'G002') or dx2 in: ('3202', 'G002') or dx3 in: ('3202', 'G002') or dx4 in: ('3202', 'G002')))
			then preventable_hospitalization = 1; 

	if preventable_hospitalization = 1; 
run; 

*Export claims; 
proc export data=out.all_hospitalizations
    outfile = "/project/caretaking/allfirms_PreventableHospitalizations.dta"
    dbms=stata
    replace;
run;

proc delete data=out.all_hospitalizations;
run;