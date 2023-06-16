/*******************************************************************************
* Title: Assign HHS-HCC Variables (2015 categories) based on Diagnosis Codes
* Created by: Alex Hoagland
* Created on: March 2020
* Last modified on: 2/9/2021
* Last modified by: 
* Purpose: 
			
* Notes: - Best used after running "0.PrepHCCData.do", which splits large data sets into firm-plankey-year data sets
	 - When used on SCC, first local is the plan and second local is the year
	 - Drops all labs and x-ray claims for fear of false positives
	 - Works for both ICD-9-CM and ICD-10-CM codes
			
* Key edits: 

*******************************************************************************/


***** 1. Data preparation
use "/projectnb/caretaking/SpendingFiles/Claims_`1'_`2'.dta", clear
cap rename dxver ver
************************************************************************************************************************


***** 2. ICD-9
gen ICD9 = ""
foreach v of var dx* { 
	local num = substr("`v'", 3, .)
	replace ICD9 = `v' if ver == "9" | year < 2015
	merge m:1 ICD9 using "ICD9_HCC2015_first.dta", keep(1 3) nogenerate
	rename HCC hcc9`num'_1
	merge m:1 ICD9 using "ICD9_HCC2015_second.dta", keep(1 3) nogenerate
	rename HCC hcc9`num'_2
} 

***** 3. ICD-10
gen ICD10 = ""
foreach v of var dx* { 
	local num = substr("`v'", 3, .)
	replace ICD10 = `v' if ver == "0"
	merge m:1 ICD10 using "ICD10_HCC2015_first.dta", keep(1 3) nogenerate
	rename HCC hcc0`num'_1
	merge m:1 ICD10 using "ICD10_HCC2015_second.dta", keep(1 3) nogenerate
	rename HCC hcc0`num'_2
} 
drop ICD*

destring hcc*, replace
egen test = rownonmiss(hcc*)
drop if test == 0
drop test
************************************************************************************************************************


***** 4. Now getting enrollee-year level HCCs
keep enrolid year hcc*

local hccs 1 2 3 4 6 8 9 10 11 12 13 18 19 20 21 23 26 27 28 29 30 34 35 36 37 38 ///
		41 42 45 46 47 48 54 55 56 57 61 62 63 64 66 67 68 69 70 71 73 74 75 81 82 87 ///
		88 89 90 94 96 97 102 103 106 107 108 109 110 111 112 113 114 115 117 118 119 ///
		120 121 122 125 126 127 128 129 130 131 132 135 137 138 139 142 145 146 149 150 ///
		151 153 154 156 158 159 160 161 162 163 183 184 187 188 203 204 205 207 208 ///
		209 217 226 227 242 243 244 245 246 247 248 249 251 253 254 
foreach h of local hccs { 
	qui gen onhcc_`h' = 0 
	foreach v of varlist hcc* { 
		qui replace onhcc_`h' = 1 if `v' == `h' 
	} 
} 

collapse (max) onhcc*, by(enrolid year) fast
save "/project/caretaking/FalsePositives_HCCs_`1'_`2'.dta", replace
rm "/projectnb/caretaking/SpendingFiles/Claims_`1'_`2'.dta"
************************************************************************************************************************
