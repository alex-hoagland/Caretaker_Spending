/*******************************************************************************
* Title: Plan Switching
* Created by: Alex Hoagland
* Created on: 8/18/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file constructs measures of plan switching among the diagnosed. 
		   
* Notes: Currently only does so for firm 6 (the largest firm in sample, w/ best plan info)
		
* Key edits: 
   -  TD: Add other firms to this 
*******************************************************************************/

***** Packages
* None yet
**********


***** 1. Load and collapse spending data to plan choice (family-year) level
local firm = 6 // Main firm is 6
use 2_Data/1.Spending/Firm`firm'/firm`firm'_allspending_trimmed.dta, clear

bysort enrolid (year): gen lagplan = plankey[_n-1]

*** Collapse to family level with variable for family size
collapse (first) plankey lagplan bu_msa famsize ///
	(sum) female (mean) age, by(famid year) fast

*** Drop families who never have plan information
bysort famid: egen test = count(plankey)
drop if test == 0
drop test
********************************************************************************


***** 2. Merge in plan characteristics
merge m:1 plankey year using "C:\Users\alexh\Dropbox\Switching_T1D\2_Data\6.PlanCharacteristics\1_Firm6\BigPlans_Firm6.dta", ///
	keepusing(newplan)
drop if _merge == 2 // Any plans w/o enrollment (shouldn't be any)
drop _merge

	* Merge in last year's plan information and verify that it matches
	preserve
	use "C:\Users\alexh\Dropbox\Switching_T1D\2_Data\6.PlanCharacteristics\1_Firm6\BigPlans_Firm6.dta", clear
	rename plankey lagplan
	rename newplan oldplan
	replace year = year + 1
	keep lagplan year oldplan
	save tomerge.dta, replace
	restore

merge m:1 lagplan year using tomerge.dta
drop if _merge == 2
drop _merge
rm tomerge.dta
	
*** Rectangularize the data set (will drop some of these below) 
sort famid year
fillin famid year // use _fillin var to determine "missing" years
bysort famid (year): carryforward famsize bu_msa, replace
bysort famid (year): replace oldplan = newplan[_n-1] if _fillin == 1

*** Drop years for each family before we see them in the sample
gen test = year if !missing(newplan)
bysort famid: egen yrmin = min(test)
drop if year < yrmin
bysort famid: egen yrmax = max(test) 
drop test  

*** Fill in gaps --> missing years with same plan choice before/after
* Fill one year gaps
bysort famid (year): replace newplan = newplan[_n-1] if missing(newplan) & ///
						newplan[_n-1] == newplan[_n+1] & !missing(newplan[_n-1])
bysort famid (year): replace oldplan = newplan[_n-2] if missing(oldplan) & ///
						oldplan[_n-1] == oldplan[_n+1] & !missing(oldplan[_n-1])
						
// For now, have not fixed gaps longer than a year. 

* Fixing plans that start/end within time frame
bysort famid (year): drop if year == 2007 & missing(newplan) & ///
 (newplan[_n+1] >= 604 & newplan[_n+1] <= 607) // Plans did not start in 2007
// bysort famid (year): drop if year < 2013 & missing(newplan) & ///
// 	year < yrmin & ///
//  (newplan[_n+1] >= 608 & newplan[_n+1] <= 609) // Plans did not start until 2013
	// NOTE: Already dropped all with year < yrmin
bysort famid (year): replace newplan = . if year < 2013 & newplan == 609 // Plan did not start until 2013
bysort famid (year): replace oldplan = . if oldplan == 609
 
bysort famid (year): drop if year > 2011 & missing(newplan) & ///
	year > yrmax & /// 
 ((newplan[_n-1] == 603 | newplan[_n-1] == 607) | (newplan[_n-2] == 603 | newplan[_n-2] == 607)) // Plans end in 2011
bysort famid (year): replace newplan = . if year > 2011 & missing(newplan) & ///
 ((newplan[_n-1] == 603 | newplan[_n-1] == 607) | (newplan[_n-2] == 603 | newplan[_n-2] == 607)) // Plans end in 2011
 
* If after all that, there's a blank year at the end with a missing plankey, fill it with last year's newplan
bysort famid (year): replace newplan = newplan[_N-1] if _n == _N & ///
	missing(newplan[_N]) & !missing(newplan[_N-1]) & missing(plankey[_N])
	
*** Add in exits (will drop them in later analysis)
* Identify small plans
replace newplan = 699 if missing(newplan) & _fillin == 0 
bysort famid (year): replace newplan = 699 if missing(newplan) & newplan[_n-1] == 699 & newplan[_n+1] == 699 
bysort famid (year): replace oldplan = 699 if newplan[_n-1] == 699 // small plans 

drop yrmax
gen test = year if !missing(newplan)
bysort famid: egen yrmax = max(test) 
drop test
drop if _fillin == 1 & missing(newplan) & year > yrmax // drop rectangularizations that we don't need
replace newplan = 700 if missing(newplan) & _fillin == 1 // exit (added back in for rectangularization) 

drop if yrmin == yrmax // Don't want families that you only see for one year

* Actual exits
bysort famid (year): gen test = (year[_N] < 2013 & _n == _N)
expand 2 if test == 1, gen(exit)
replace year = year + 1 if exit == 1
replace newplan = 700 if exit == 1
bysort famid (year): replace oldplan = newplan[_n-1] if exit == 1
replace exit = 1 if newplan == 700
sort famid year
drop test

*** Switching variable
bysort famid (year): replace oldplan = newplan[_n-1] if missing(oldplan) 
bysort famid (year): gen switch = (newplan != oldplan)
bysort famid (year): replace switch = 0 if _n == 1

*** Now merge in all plan characteristics
	preserve
	use "C:\Users\alexh\Dropbox\Switching_T1D\2_Data\6.PlanCharacteristics\1_Firm6\BigPlans_Firm6.dta", clear
	collapse (mean) frac_enrol overall_av plan_ded avg_enrollee_cost copay_Long copay_Short copay_Strips hhi_Specialist hhi_Pharm ///
		(first) plantyp, by(newplan year)
	save tomerge.dta, replace
	restore
	
merge m:1 newplan year using tomerge.dta, ///
	keepusing(plantyp frac_enrol overall_av plan_ded avg_enrollee_cost copay_Long copay_Short copay_Strips hhi_Specialist hhi_Pharm)
rename avg_enrollee_cost premium
egen copay_ins = rowmean(copay_Long copay_Short copay_Strips)
drop if _merge == 2
drop _merge 

	preserve
	use "C:\Users\alexh\Dropbox\Switching_T1D\2_Data\6.PlanCharacteristics\1_Firm6\BigPlans_Firm6.dta", clear
	rename plankey lagplan
	rename newplan oldplan
	replace year = year + 1
	egen lagged_ins = rowmean(copay_Long copay_Short copay_Strips)
	rename frac_enrol lagged_frac
	rename plan_ded lagged_ded
	rename avg_enrollee_cost lagged_prem
	rename overall_av lagged_av
	rename hhi_Specialist lagged_hhi 
	collapse (mean) lagged_*, by(oldplan year)
	save tomerge.dta, replace
	restore

	merge m:1 oldplan year using tomerge.dta
drop if _merge == 2
drop _merge
rm tomerge.dta

*** Since we don't have unified plan characteristics for small plans, add a dummy variable for that 
bysort famid (year): gen lagged_smallplan = (oldplan == 699)

*** Organizing
sort famid year
order famid year newplan oldplan switch bu_msa famsize
drop _fillin yrmin yrmax 
save "2_Data/2.PlanChoices/1_Firm`firm'/firm`firm'_switching.dta", replace
********************************************************************************







