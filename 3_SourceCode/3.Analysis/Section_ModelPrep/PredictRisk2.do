/*******************************************************************************
* Title: Regression-adjusted probability of chronic diagnosis 
* Created by: Alex Hoagland
* Last modified on: 11/22/2022
* Last modified by: 
* Purpose: Creates a simple proxy for external probability of risk based 
* 			on demographics + family history
*
* Output: 
* 
* Key edits: 
   -
*******************************************************************************/

// create family history variables
use "$mydata/AllChronicEvents_20221122.dta", clear
gen fam_chronic_past = 1 if fam_chronic_event == 1
bysort famid (year): carryforward fam_chronic_past, replace
bysort famid: egen fam_chronic_future = mean(fam_chronic_past)
replace fam_chronic_future = 0 if fam_chronic_past == 1
replace fam_chronic_past = 0 if missing(fam_chronic_past) 
replace fam_chronic_future = 0 if missing(fam_chronic_future) 
drop fam_chronic_event

// merge into demographic data
replace enrolid = substr(enrolid, 2, .)
destring enrolid, replace
merge 1:1 enrolid year using "$mydata/allfirms_HCCcollapsed.dta", ///
	keep(2 3) nogenerate

// drop diagnosed after year of dx, as their beliefs are finalized at 1 anyway
gen test = year if chronic_event == 1
bysort enrolid: ereplace test = mean(test) 
drop if year > test & !missing(test) 
drop test

// Organize other regression variables (age-sex bins) 
gen agesex_04 = inrange(age,0,4)
gen agesex_59 = inrange(age,5,9)
gen agesex_1014 = inrange(age,10,14)
gen agesex_1519 = inrange(age,15,19)
gen agesex_2024 = inrange(age,20,24)
gen agesex_2529 = inrange(age,25,29)
gen agesex_3034 = inrange(age,30,34)
gen agesex_3539 = inrange(age,35,39)
gen agesex_4044 = inrange(age,40,44)
gen agesex_4549 = inrange(age,45,49)
gen agesex_5054 = inrange(age,50,54)
gen agesex_5559 = inrange(age,55,59)
gen agesex_6064 = inrange(age,60,64)

foreach v of var agesex_* { 
	gen `v'_f = `v' * female
} 

// Run the Regression!
drop fam_chronic_future // keep this only for counterfactuals
logit chronic_event age female agesex_* fam_* i.year 
predict prob_true, pr
keep enrolid year prob_true
tostring enrolid, replace
replace enrolid = "A" + enrolid
compress
saveold "$mydata/PredictedProbabilities.dta", replace v(12) 
