/*******************************************************************************
* Title: Plan Switching
* Created by: Alex Hoagland
* Created on: 8/18/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file constructs measures of plan switching among the diagnosed. 
		   
* Notes: 
		
* Key edits: 
   -  9.23.2020: Updated to include all relevant firms (with understood plan identifiers)
*******************************************************************************/

***** Packages
* ssc install carryforward
**********


***** 0. Pull all relevant families from firm files
cap rm "2_Data/2.PlanChoices/allfirms_switches.dta" // start data file fresh

** 			- from trimmed spending: the families we are considering
**			- from enrollment: their plan choices (only keep those with good info)

* Firm 6
use "2_Data/1.Spending/IndividualFirms/Firm6/firm6_allspending_trimmed.dta" ///
	if year >= 2006 & year <= 2013, clear
keep enrolid famid year
merge 1:1 enrolid year using "2_Data/1.Spending/IndividualFirms/Firm6/firm6_enrollment.dta", ///
	keep(3) nogenerate keepusing(plnkey* newplan)
gen firm = 6
save "2_Data/2.PlanChoices/allfirms_switches.dta"

* Firm 22
use "2_Data/1.Spending/IndividualFirms/Firm22/firm22_allspending_trimmed.dta" ///
	if year >= 2010, clear
keep enrolid famid year
merge 1:1 enrolid year using "2_Data/1.Spending/IndividualFirms/Firm22/firm22_enrollment.dta", ///
	keep(3) nogenerate keepusing(plnkey* newplan)
gen firm = 22
append using "2_Data/2.PlanChoices/allfirms_switches.dta"
save "2_Data/2.PlanChoices/allfirms_switches.dta", replace

* Firm 23
use "2_Data/1.Spending/IndividualFirms/Firm23/firm23_allspending_trimmed.dta" ///
	if year >= 2013, clear
keep enrolid famid year
merge 1:1 enrolid year using "2_Data/1.Spending/IndividualFirms/Firm23/firm23_enrollment.dta", ///
	keep(3) nogenerate keepusing(plnkey* newplan)
gen firm = 23
append using "2_Data/2.PlanChoices/allfirms_switches.dta"
save "2_Data/2.PlanChoices/allfirms_switches.dta", replace

* Firm 56
use "2_Data/1.Spending/IndividualFirms/Firm56/firm56_allspending_trimmed.dta" ///
	if year >= 2013, clear
keep enrolid famid year
merge 1:1 enrolid year using "2_Data/1.Spending/IndividualFirms/Firm56/firm56_enrollment.dta", ///
	keep(3) nogenerate keepusing(plnkey* newplan)
gen firm = 56
append using "2_Data/2.PlanChoices/allfirms_switches.dta"
save "2_Data/2.PlanChoices/allfirms_switches.dta", replace

* Firm 65
use "2_Data/1.Spending/IndividualFirms/Firm65/firm65_allspending_trimmed.dta" ///
	if year >= 2008, clear
keep enrolid famid year
merge 1:1 enrolid year using "2_Data/1.Spending/IndividualFirms/Firm65/firm65_enrollment.dta", ///
	keep(3) nogenerate keepusing(plnkey* newplan)
gen firm = 65
append using "2_Data/2.PlanChoices/allfirms_switches.dta"

compress
order enrolid famid year newplan
********************************************************************************


***** 1. Collapse data to plan choice (family-year) level
*** Drop enrollees who never have plan information 
egen test = rownonmiss(newplan plnkey*)
bysort firm enrolid: ereplace test = max(test)
drop if test == 0
drop test

*** Assign plans to those who have info only mid-year 
* Also double check that all firms start in Jan
gen startplan = . 
* gen startmonth = . 
forvalues i = 1/12 { 
	replace startplan = plnkey`i' if missing(newplan) & missing(startplan) & !missing(plnkey`i')
	* replace startmonth = `i' if missing(newplan) & missing(startmonth) & !missing(plnkey`i')
} 
* drop startmonth // seems uniform for all firms
do 3_SourceCode/2.AssignHCCs/0.AssignNewPlans.do "startplan"
drop startplan
	
*** Insist that all family members are in the same plans
bysort firm famid year (newplan): carryforward newplan plnkey*, replace
bysort firm famid year (newplan): drop if newplan[1] != newplan[_N] 

*** Collapse to family level
collapse (first) newplan plnkey* firm, by(famid year) fast
********************************************************************************


***** 2. Merge in plan characteristics
* Add this later, once other characteristics are finished
// rename plnkey1 plankey
// merge m:1 plankey year using "C:\Users\alexh\Dropbox\Switching_T1D\2_Data\6.PlanCharacteristics\1_Firm6\BigPlans_Firm6.dta", ///
// 	keepusing(newplan)
// drop if _merge == 2 // Any plans w/o enrollment (shouldn't be any)
// drop _merge
//
// 	* Merge in last year's plan information and verify that it matches
// 	preserve
// 	use "C:\Users\alexh\Dropbox\Switching_T1D\2_Data\6.PlanCharacteristics\1_Firm6\BigPlans_Firm6.dta", clear
// 	rename plankey lagplan
// 	rename newplan oldplan
// 	replace year = year + 1
// 	keep lagplan year oldplan
// 	save tomerge.dta, replace
// 	restore
//
// merge m:1 lagplan year using tomerge.dta
// drop if _merge == 2
// drop _merge
// rm tomerge.dta
********************************************************************************


***** 3. More cleaning and identifying switches 
*** Check: do we need to use fillin? I don't think so in new context
* bysort firm famid (year): assert year[_n]-year[1] == _n-1 
	// mostly this is true, just a few outliers. Better to assume there's something weird with outliers than try to incorporate them.
bysort firm famid (year): drop if year[_n]-year[1] != _n-1 // drop those with gaps in enrollment
bysort firm famid (year): egen todrop = count(newplan) // drop those with only one observed choice
drop if todrop == 1
drop todrop

*** Trimming years without plan info 
gen minyear = year if !missing(newplan)
gen maxyear = year if !missing(newplan)
bysort firm famid: ereplace minyear = min(minyear)
bysort firm famid: ereplace maxyear = max(maxyear)
bysort firm famid: egen lastyear = max(year) // this is last *enrolled* year, used to identify firm exits
drop if year < minyear & missing(newplan)
drop if year > maxyear & missing(newplan)
drop minyear maxyear

* Fill in one and two year gaps only
bysort firm famid (year): replace newplan = newplan[_n-1] if missing(newplan) & ///
						newplan[_n-1] == newplan[_n+2] & !missing(newplan[_n-1])
						// two year gaps
bysort firm famid (year): replace newplan = newplan[_n-1] if missing(newplan) & ///
						newplan[_n-1] == newplan[_n+1] & !missing(newplan[_n-1])
						// one year gaps
						
* After this, drop individuals with missing data during observation window--can't identify when switch ocurred. 
gen todrop = (missing(newplan))
bysort firm famid: ereplace todrop = max(todrop)
drop if todrop == 1
drop todrop

*** Fixing plans that start/end within time frame (hopefully no changes here)
* firm 6
drop if year == 2006 & newplan == 602
drop if year > 2011 & newplan == 603
drop if year < 2008 & newplan == 604
drop if year < 2008 & newplan == 605
drop if year < 2008 & newplan == 606
drop if (year < 2008 | year > 2011) & newplan == 607
drop if year < 2008 & newplan == 608
drop if year < 2013 & newplan == 609

* firm 22
drop if year > 2017 & newplan == 2205

* firm 23
drop if year < 2014 & newplan == 2306
drop if year < 2018 & newplan == 2307

* firm 56
// none yet

* firm 65
// none yet

*** Identify (i) plan switches and (ii) firm exits
* First, plan switches
bysort firm famid (year): gen switch = (newplan != newplan[_n-1] & _n > 1)

* Second, firm exits (by firm)
replace lastyear = . if lastyear == 2013 & firm == 6
replace lastyear = lastyear + 1 if lastyear < 2013 & firm == 6

replace lastyear = . if lastyear == 2018 & firm == 22
replace lastyear = lastyear + 1 if lastyear < 2018 & firm == 22

replace lastyear = . if lastyear == 2018 & firm == 23
replace lastyear = lastyear + 1 if lastyear < 2018 & firm == 23

replace lastyear = . if lastyear == 2018 & firm == 56
replace lastyear = lastyear + 1 if lastyear < 2018 & firm == 56

replace lastyear = . if lastyear == 2017 & firm == 65
replace lastyear = lastyear + 1 if lastyear < 2017 & firm == 65
rename lastyear exityr

* Replace plan switch = 0 if it is actually an exit
replace switch = 0 if year == exityr & switch == 1

* Generate an exit variable (need to expand years)
fillin famid year
gen myear = year if !missing(firm)
bysort famid: ereplace firm = min(firm)
bysort firm famid: ereplace myear = min(myear)
bysort firm famid: ereplace exityr = max(exityr)
drop if (year < myear | year > exityr) & _fillin == 1 
	// don't want to add years before hand or after exit year
drop if _fillin == 1 & missing(exityr) // don't add years to those without exits

gen exit = (year == exityr)
drop exityr myear

* Make one master variable that includes both
gen anychange = switch
replace anychange = 1 if exit == 1
replace anychange = 0 if missing(anychange)

*** Organizing
sort firm famid year
order firm famid year newplan switch exit anychange
drop plnkey*
compress
save "2_Data/2.PlanChoices/allfirms_switches.dta", replace
********************************************************************************







