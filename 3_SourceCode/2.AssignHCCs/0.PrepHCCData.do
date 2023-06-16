/*******************************************************************************
* Title: Prep HCC Data
* Created by: Alex Hoagland
* Created on: March 2020
* Last modified on: 2/9/2021
* Last modified by: 
* Purpose: 
			
* Notes: - Splits large claim data sets into firm-plankey-year data sets
			
* Key edits: 

*******************************************************************************/


***** 1. Data preparation
cd "/projectnb/caretaking/SpendingFiles"

* Start with inpatient claims
forvalues y = 2006/2018 { 
   use "allfamilies_InpatientClaims.dta" if year == `y', clear
   save "Claims_allfams_`y'.dta", replace
} 

* Add in OP claims and trim data sets
forvalues y = 2006/2018 { 
   di `y'
   use "allfamilies_OutpatientClaims_`y'.dta", clear
   append using "Claims_allfams_`y'.dta"
   cap gen dx3 = ""
   cap gen dx4 = "" 
   drop if missing(dx1) & missing(dx2) & missing(dx3) & missing(dx4)

	***** 2. Keep only(!) lab and x-ray claims
        di "Cleaning for year `y'"
	* Drop certain places of service
	destring stdplac, replace

	drop if inlist(stdplac,12,31,32,33,34,41,42,65,81,99)

	* Drop certain procedure codes
	drop if inlist(proc1,"36415","36416")
	drop if inlist(substr(proc1,1,2),"70","71","72","73","74","75","76","78")
	drop if inlist(substr(proc1,1,2),"80","81","82","83","84","85","86","87")
	drop if substr(proc1,1,3)=="880"
	drop if inlist(substr(proc1,1,3), "881","882","883")
	drop if inlist(substr(proc1,1,4),"8872","8873") | proc1 == "88741"
	drop if inlist(substr(proc1,1,4),"9925","9926")
	drop if inlist(substr(proc1,1,3),"930","931","932")
	drop if inlist(substr(proc1,1,4),"9330","9331","9332","9333","9334") | proc1 == "93350"
	drop if proc1 == "99000" | proc1 == "99001"
	drop if substr(proc1,1,2) == "A0"
	drop if inlist(proc1,"A4206","A4207","A4208","A4209")
	drop if inlist(substr(proc1,1,3),"A43","A44","A45","A46","A47","A48","A49")
	drop if inlist(substr(proc1,1,2),"A5","A6","A7","A8","A9")
	drop if inlist(proc1,"B4304","B4305","B4306","B4307","B4308","B4309")
	drop if inlist(substr(proc1,1,4),"B431","B432","B433","B434","B435","B436","B437","B438","B439")
	drop if inlist(substr(proc1,1,3),"B44","B45","B46","B47","B48","B49")
	drop if inlist(substr(proc1,1,2),"B5","B6","B7","B8","B9")
	drop if proc1 == "G0001"
	drop if substr(proc1,1,1) == "E" & substr(proc1,1,3) != "E00"
	drop if substr(proc1,1,1) == "K"
	drop if substr(proc1,1,1) == "L" & (substr(proc1,1,3) != "L00" | substr(proc1,1,3) != "L99")
	drop if proc1 == "L9900"
	drop if inlist(proc1,"P2028","P2029")
	drop if inlist(substr(proc1,1,3),"P21","P22","P23","P24","P25","P26","P27","P28","P29")
	drop if inlist(substr(proc1,1,2),"P3","P4","P5","P6","P7","P8","P9")
	drop if substr(proc1,1,4) == "R007" & !inlist(proc1,"R0077","R0078","R0079")

	* Keep important variables now
	keep enrolid year dx* svcdate

   compress
   save "Claims_allfams_`y'.dta", replace
} 
********************************************************************************
