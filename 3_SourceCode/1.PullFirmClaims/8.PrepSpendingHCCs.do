/*******************************************************************************
* Title: Prep spending and HCCs 
* Created by: Alex Hoagland
* Created on: 8/6/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file picks the ENROLIDs for those with children under 18 on plan, 
	whether diagnosed or not. 
		   
* Notes: Requires the running of 0.PullingMarketScanData in order
			to collect all treatments and spending. 
		
* Key edits: 
	- 8.6: generalized to all firms
	- 8.18: // IMPORTANT NOTE: using floor(enrolid/100) does *NOT* adequately define family IDs for some reason
*******************************************************************************/

***** Packages
* None yet
**********


***** 0. Local for firm number
local firm = 65
local home: pwd
cd "2_Data/1.Spending/Firm`firm'/"
********************************************************************************

***** 1. Prepping the spending file 
*** Start with enrollment, add in inpatient, outpatient, pharma
use firm`firm'_Enrollment.dta, clear
save firm`firm'_allspending.dta, replace

use firm`firm'_inpatient.dta, clear
gen ip_oop = total_ded + total_cop + total_cob + total_coi
keep enrolid year total_pay ip_oop ed 
rename total_pay ip_pay
gen ed_pay = ip_pay if ed == 1
gen ed_oop = ip_oop if ed == 1
collapse (sum) ip_* ed_*, by(enrolid year) fast
merge 1:1 enrolid year using firm`firm'_allspending.dta, keep(2 3) nogenerate
save firm`firm'_allspending.dta, replace

use firm`firm'_outpatient.dta, clear
gen op_oop = total_ded + total_cop + total_cob + total_coi
keep enrolid year total_pay op_oop ambsc specialist
rename total_pay op_pay
gen spec_pay = op_pay if specialist == 1
gen spec_oop = op_oop if specialist == 1
gen amb_pay = op_pay if ambsc == 1
gen amb_oop = op_oop if ambsc == 1
collapse (sum) op_* spec_* amb_*, by(enrolid year) fast
merge 1:1 enrolid year using firm`firm'_allspending.dta, keep(2 3) nogenerate
save firm`firm'_allspending.dta, replace

use firm`firm'_pharma.dta, clear
gen ph_oop = total_ded + total_cop + total_cob + total_coi
keep enrolid year total_pay ph_oop generic
rename total_pay ph_pay
gen gen_pay = ph_pay if generic == 1
gen gen_oop = ph_oop if generic == 1
collapse (sum) ph_* gen_*, by(enrolid year) fast
merge 1:1 enrolid year using firm`firm'_allspending.dta, keep(2 3) nogenerate
save firm`firm'_allspending.dta, replace

*** Basic variables
cap destring sex, replace
gen female = (sex == 2)
drop sex dattyp* enrind*

*** Keep only enrollee-years w/ 365 days of eligibility 
gen test = (memdays < 365 & age > 0) // keep newborns
bysort enrolid year: egen todrop = max(test) 
drop if todrop == 1
drop test todrop memday*

*** Keep all family-years with at least two people
bysort famid year: keep if _N > 1

*** Drop families that are missing years in middle of observed periods or 
*** only observed for one year
bysort enrolid (year): gen test = (year[_N]-year[1]+1 != _N )
bysort famid: egen todrop = max(test)
drop if todrop == 1
drop test todrop
bysort famid (year): drop if year[1] == year[_N]

*** Make data set with covariates 
	// Covariates include: dummies for diagnosed or family of diagnosed, diagnosis date
	//						plan key, family size, emprel, age, sex, bu_MSA
rename plnkey1 plankey // plan choice in January
drop plnkey2-plnkey12

*** Verify that all family members are in same plan
bysort famid year: egen test = count(plankey)
bysort famid year (plankey): gen test2 = (plankey[1] == plankey[test])
drop if test2 == 0 
drop test*
bysort famid year (plankey): carryforward plankey, replace
	// carryforward for all family members in a year missing plan
	
*** Add in MSA identifier
cd `home'
cap destring egeoloc, replace
do 3_SourceCode\Create_BUMSA.do

cap destring emprel, replace
gen test = bu_msa if emprel == 1 // Use employee's location wherever possible.
bysort famid year: egen test2 = max(test)
replace bu_msa = test2 if !missing(test2)
drop test*

*** Replace missing values with 0's
foreach v of var ip_* ed_* op_* spec_* amb_* ph_* gen_* {
	replace `v' = 0 if missing(`v')
	} 
	
*** Correct to 2020 dollars
do 3_SourceCode/Inflation.do "ip_* ed_* op_* spec_* amb_* ph_* gen_*"

*** Main data set
bysort famid year: egen famsize = count(enrolid)
sort famid enrolid year
order famid enrolid year 

drop agegrp phyflag enrmon plntyp2-plntyp12 efamid version
compress
save "2_Data/1.Spending/Firm`firm'/firm`firm'_allspending_trimmed.dta", replace
********************************************************************************


***** 2. Prepping the HCC file
* get information about first visible year for pre-existing conditions
collapse (min) year, by(enrolid) fast
rename year fyear
save tomerge.dta, replace

use "2_Data/1.Spending/Firm`firm'/firm`firm'_AllHCCs_EnrolleeLevel.dta", clear
cap drop famid
tostring enrolid, gen(famid) format(%14.0f)
replace famid = substr(famid, 1, length(famid)-2)
destring famid, replace
* collapse (max) onhcc_*, by(enrolid year famid) fast

*** Impose HCC hierarchies?
* Note: I'm not going to impose these now, so that I can see chronic conditions

*** Identify pre-existing and chronic conditions, pull them out of HCCs
	** Pre-existing: on in first observed year; chronic: on for all years
	** Update the onhcc* variables to be off once you account for these
* pull in first year
merge m:1 enrolid using tomerge.dta, keep(3) nogenerate 
	// also drops HCC info for ppl already trimmed from spending file, a plus for me. 
cap drop pe
gen byte pe = 0
foreach v of varlist onhcc_* { 
	di "`v'"
	qui gen test = (`v' == 1 & year == fyear)
	bysort enrolid: egen test2 = max(test)
	replace pe = test2 if pe == 0 
	replace `v' = 0 if test2 == 1
	drop test*
} 

cap drop num_hccs
egen byte num_hccs = rowtotal(onhcc*) // note: can't drop anyone yet cause we want the PE condition dummy

*** Flag and drop spending files for families w/ >1 new HCCs in a single year (@ family level)
bysort famid year: egen test = total(num_hccs)  // total number of HCCs for an family in a year
bysort famid: egen test2 = max(test) // highest inidence of HCCs for a family across all years

preserve
keep if test2 > 1
save "2_Data/0.HCCs_Switching/Firm`firm'/MultipleHCCs.dta", replace
keep famid
duplicates drop
merge 1:m famid using "2_Data/1.Spending/Firm`firm'/firm`firm'_allspending_trimmed.dta", keep(2) nogenerate
save "2_Data/1.Spending/Firm`firm'/firm`firm'_allspending_trimmed.dta", replace
restore

drop if test2 > 1
drop test*
save "2_Data/0.HCCs_Switching/Firm`firm'/firm`firm'_AllHCCs_EnrolleeLevel.dta", replace

** Flag and create separate data set for all families where HCC enrollee is not visible for >= 1 full year post dx
** (potential deaths, plan switches out of Marketscan, etc.)

use "2_Data/1.Spending/Firm`firm'/firm`firm'_allspending_trimmed.dta", clear
gen byte flag = 0
bysort enrolid: egen lyear = max(year)
merge 1:1 enrolid year using "2_Data/0.HCCs_Switching/Firm`firm'/firm`firm'_AllHCCs_EnrolleeLevel.dta", keep(1 3) nogenerate ///
	keepusing(onhcc_*) // merge in HCC info (so you don't have to do it every time
save "2_Data/1.Spending/Firm`firm'/firm`firm'_allspending_trimmed.dta", replace

qui sum year
local maxyear = `r(max)' // latest year in the firm's sample (firm-wide)
foreach v of varlist onhcc_* { 
	di "`v'" 
	qui gen needyear = year+1 if `v' == 1
	replace needyear = `maxyear' if needyear > `maxyear' & !missing(needyear)
	bysort enrolid: ereplace needyear = min(needyear)
	replace flag = 1 if lyear < needyear & !missing(needyear) & flag == 0
	sleep 2000
	save "2_Data/1.Spending/Firm`firm'/firm`firm'_allspending_trimmed.dta", replace
	drop needyear
} 
drop onhcc_* 
bysort famid: egen todrop = max(flag)

preserve
keep if todrop == 1
save "2_Data/0.HCCs_Switching/Firm`firm'/MissingEnrollee_1YearPostHCC.dta", replace
restore
drop if todrop == 1
drop todrop flag lyear
save "2_Data/1.Spending/Firm`firm'/firm`firm'_allspending_trimmed.dta", replace

// ** Information about risk score changes
// preserve
// reshape long onhcc_, i(enrolid year) j(hcc)
// drop if onhcc_ == 0
// merge m:1 hcc using "2_Data\0.HCCs_Switching\Coefficients_HCCs_2019.dta", ///
// 	keepusing(coef_silver) keep(3) nogenerate
// collapse (sum) coef_silver, by(enrolid year) fast
// save tomerge.dta, replace
// restore
//	
// merge 1:1 enrolid year using tomerge.dta, nogenerate
// replace coef_silver = 0 if missing(coef_silver)
// rm tomerge.dta
// bysort enrolid (year): gen lag_rc = coef_silver[_n-1] if _n > 1
// bysort enrolid (year): replace lag_rc = 0 if _n > 1

rm tomerge.dta
********************************************************************************










