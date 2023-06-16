/*******************************************************************************
* Title: Add Supplemental Variables
* Created by: Alex Hoagland
* Created on: 8/31/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file adds in extra variables to a data set for analysis: 
	- number of unique prescriptions
		- % of these which are generic
		- % of these which are in top tier class
		- split by therapeutic classes
	- frequency of visits (to add) 
	- types of hospitalizations: 
		- non-deferrable
		- preventable 
		
* Notes: 

* Key edits: 
	
*******************************************************************************/

***** Packages
* None yet
**********


***** 1. Begin with info on number of prescriptions
use "2_Data/1.Spending/allfirms_allscrips.dta", clear

gen generic = (genind == 4 | genind == 5)

gen cat1 = (thercls >= 58 & thercls <= 63)
gen cat2 = (thercls >= 4 & thercls <= 12)
gen cat3 = (thercls >= 69 & thercls <= 70)
gen cat4 = (thercls == 53)
gen cat5 = (thercls == 166)
gen cat6 = (thercls >= 190 & thercls <= 195)
replace cat6 = 1 if thercls == 138
gen cat7 = (thercls == 27)
gen cat8 = (thercls >= 46 & thercls <= 52)
gen cat9 = (thercls == 162)
gen cat10 = (thercls == 168)
gen cat11 = (thercls >= 14 & thercls <= 16)
gen cat12 = (thercls >= 178 & thercls <= 179)
gen cat13 = (thercls >= 73 & thercls <= 74)
gen cat14 = (thercls == 1)
gen cat15 = (thercls >= 29 & thercls <= 31)
gen cat16 = (thercls == 75)
gen cat17 = (thercls >= 128 & thercls <= 131)
gen cat18 = (thercls >= 172 & thercls <= 174)
gen cat19 = (thercls >= 132 & thercls <= 138)
gen cat20 = (thercls >= 71 & thercls <= 72)
gen cat21 = (thercls >= 169 & thercls <= 170)
gen cat22 = (thercls >= 64 & thercls <= 68)
gen cat23 = (thercls >= 120 & thercls <= 125)
gen cat24 = (thercls == 160)
gen cat25 = 1 
forvalues i = 1/24 { 
	replace cat25 = 0 if cat`i' == 1
	} 

collapse (count) numscrips=ndcnum (sum) generic cat* total_days pay_per_day, by(enrolid year) fast

gen perc_gen = (generic / numscrips ) * 100
compress
save "2_Data/1.Spending/allfirms_numscrips"

merge 1:1 enrolid year using "2_Data/1.Spending/allfirms_allspending.dta", keep(2 3) nogenerate
foreach v of varlist numscrips-perc_gen {
replace `v' = 0 if missing(`v')
} 

save "2_Data/1.Spending/allfirms_allspending.dta", replace

*** 1a: Adding in high-cost drugs 
use "2_Data/1.Spending/allfirms_allscrips.dta", clear
sum pay_per_day , de
gen highcost = (pay_per_day > 5) // about 15% of drugs fit this bill
drop if highcost == 0
collapse (sum) highcost , by(enrolid year) fast
rename highcost num_highcost
gen any_highcost = (num_highcost > 0)

merge 1:1 enrolid year using "2_Data/1.Spending/allfirms_HCCcollapsed.dta", keep(2 3) nogenerate
foreach v of varlist *highcost {
replace `v' = 0 if missing(`v')
} 

save "2_Data/1.Spending/allfirms_HCCcollapsed.dta", replace
********************************************************************************


***** 2. Frequency of visits

********************************************************************************


***** 3. Types of hospitalizations
use "2_Data/1.Spending/allfirms_HospitalizationTypes.dta", clear

collapse (sum) preventable nondef, by(enrolid year) fast
gen any_hprev = (preventable > 0) 
gen any_hnondef = (nondef > 0)

merge 1:1 enrolid year using "2_Data/1.Spending/allfirms_allspending.dta", keep(2 3) nogenerate
foreach v of varlist preventable-any_hnondef {
replace `v' = 0 if missing(`v')
} 

save "2_Data/1.Spending/allfirms_allspending.dta", replace
********************************************************************************








