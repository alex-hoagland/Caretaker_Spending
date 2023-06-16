/*
*========================================================================*
* Program:   Adults/Kowalski Injuries	                                 *
*                                                                        *
* Purpose:   This program flags all enrollee-years who experienced an    *
*		injury Kowalski used in her JMP. 			 *
*                                                                        *
* Author:    Alex Hoagland	                                         *
*            Boston University				                 *
*                                                                        *
* Created:   Sep 8, 2020	                                         *
* Updated:  		                                                 *
*========================================================================*;
*/
   
*Set libraries;
libname in '/projectnb2/marketscan' access=readonly;
libname out '/projectnb2/marketscan/caretaking/';
        
/*--------------------------------------*
* Look at both INPATIENT and OUTPATIENT *
*---------------------------------------*/;
       
data out.kowalski(compress=yes); 
   if _N_=1 then do;
   declare hash ids(dataset:"out.allfamilies");
   ids.definekey('famid');
   ids.definedone();
   end;
        set in.ms_s_2007(keep=enrolid year dx:)
            in.ms_o_2007(keep=enrolid year dx:)
            in.ms_s_2008(keep=enrolid year dx:)
            in.ms_o_2008(keep=enrolid year dx:)
            in.ms_s_2009(keep=enrolid year dx:)
            in.ms_o_2009(keep=enrolid year dx:)
            in.ms_s_2010(keep=enrolid year dx:)
            in.ms_o_2010(keep=enrolid year dx:)
            in.ms_s_2011(keep=enrolid year dx:)
            in.ms_o_2011(keep=enrolid year dx:)
            in.ms_s_2012(keep=enrolid year dx:)
            in.ms_o_2012(keep=enrolid year dx:)
            in.ms_s_2013(keep=enrolid year dx:)
            in.ms_o_2013(keep=enrolid year dx:)
            in.ms_s_2014(keep=enrolid year dx:)
            in.ms_o_2014(keep=enrolid year dx:); 
   famid = floor(enrolid/100); 
   if ids.find()^=0 then delete;

   dxc1 = input(substr(dx1,1,3), 3.); 
   dxc2 = input(substr(dx2,1,3), 3.); 
   dxc3 = input(substr(dx3,1,3), 3.); 
   dxc4 = input(substr(dx4,1,3), 3.); 

   /* Fractures */; 
   if ((dxc1 >= 800 and dxc1 <= 829) or (dxc2 >= 800 and dxc2 <= 829) or 
	(dxc3 >= 800 and dxc3 <= 829) or (dxc4 >= 800 and dxc4 <= 829)) 
     then kowalski = 1; 

   /* Thoracic Injuries */; 
   if ((dxc1 >= 860 and dxc1 <= 869) or (dxc2 >= 860 and dxc2 <= 869) or 
	(dxc3 >= 860 and dxc3 <= 869) or (dxc4 >= 860 and dxc4 <= 869)) 
     then kowalski = 1; 

   /* Blood vessel injuries */; 
   if ((dxc1 >= 900 and dxc1 <= 904) or (dxc2 >= 900 and dxc2 <= 904) or 
	(dxc3 >= 900 and dxc3 <= 904) or (dxc4 >= 900 and dxc4 <= 904)) 
     then kowalski = 1; 

   /* Late effects of injuries/poisonings */; 
   if ((dxc1 >= 905 and dxc1 <= 909) or (dxc2 >= 905 and dxc2 <= 909) or 
	(dxc3 >= 905 and dxc3 <= 909) or (dxc4 >= 905 and dxc4 <= 909)) 
     then kowalski = 1; 

   /* Foreign body injuries */; 
   if ((dxc1 >= 930 and dxc1 <= 939) or (dxc2 >= 930 and dxc2 <= 939) or 
	(dxc3 >= 930 and dxc3 <= 939) or (dxc4 >= 930 and dxc4 <= 939)) 
     then kowalski = 1; 

   /* Burns */; 
   if ((dxc1 >= 940 and dxc1 <= 949) or (dxc2 >= 940 and dxc2 <= 949) or 
	(dxc3 >= 940 and dxc3 <= 949) or (dxc4 >= 940 and dxc4 <= 949)) 
     then kowalski = 1; 

   /* Nerve injuries */; 
   if ((dxc1 >= 950 and dxc1 <= 957) or (dxc2 >= 950 and dxc2 <= 957) or 
	(dxc3 >= 950 and dxc3 <= 957) or (dxc4 >= 950 and dxc4 <= 957)) 
     then kowalski = 1; 

   /* Poisonings */; 
   if ((dxc1 >= 960 and dxc1 <= 979) or (dxc2 >= 960 and dxc2 <= 979) or 
	(dxc3 >= 960 and dxc3 <= 979) or (dxc4 >= 960 and dxc4 <= 979)) 
     then kowalski = 1; 

   /* Complications, NEC */; 
   if ((dxc1 >= 996 and dxc1 <= 999) or (dxc2 >= 996 and dxc2 <= 999) or 
	(dxc3 >= 996 and dxc3 <= 999) or (dxc4 >= 996 and dxc4 <= 999)) 
     then kowalski = 1; 
   
   if kowalski = 1; 
run;

*Export claims; 
proc export data=out.kowalski
    outfile = "/projectnb2/marketscan/caretaking/AllFamilies_Kowalski.dta"
    dbms=stata
    replace;
run; 

/*-----------------*
* Delete SAS data *
*------------------*/; 

proc delete data=out.kowalski;
run; 

