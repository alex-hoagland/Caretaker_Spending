/*******************************************************************************
* Title: Utilization Responses (for running on the SCC)
* Created by: Alex Hoagland
* Created on: 8/20/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file conducts stacked TWFE regressions + variations on TWFE
			
* Notes: 
			
* Key edits: 

*******************************************************************************/


***** 0. Load Data
* cap set scheme uncluttered
cap graph drop * 
use "$mydata/allfirms_HCCcollapsed.dta", clear
* gen posded = (zeroded == 0)

// local 1 = "chronic_event"
// local 2 = "tot_oop"
// local 3 = "C_ihs"
// local 4 = "" // if you want to keep only those with a specific plan type
local saveheader = "`5'_`4'"
local collapse = "`6'"

local want_csdid = "N" // Y for Callaway and Sant'Anna output as well as TWFE
local want_stacked = "N" // Y for stacked-DID

// local cd_correction = 0 // if you want to run the correction, change to 1. Else, 0. 
// local dynamic = 5 // number of dynamic period effects to estimate

// Move treated with PEs to control group
foreach v of var chronic_event acuteevent { 
	replace `v' = 0 if pe > 0 & !missing(pe)
}

* Keep plans with a specific plan type if needed
if (!missing("`4'") & "`4'" != "") {
	keep if `4' == 1
} 

* Merge in new preventive services if needed
if (substr("`2'",1,7) == "newprev") {
	capture confirm variable newprev_pay
	if (_rc != 0) { // if variable doesn't exist
		merge 1:1 famid enrolid year using "$mydata\NewPreventionMeasures_20221111.dta", ///
			keep(1 3) nogenerate
		foreach v of var newprev_* { 
			replace `v' = 0 if missing(`v') 
		} 
	} 
}
******************************************************************************** 


***** When doing event studies with acute events, only look at post years if 
// another acute event hasn't occurred
// Merge in new acute events

if ("`1'" == "acuteevent") {  
	gen test = year if acuteevent == 1
	bysort famid: egen first_ac = min(test) 
	replace test = . if test == first_ac
	bysort famid: egen second_ac = min(test)
	drop if !missing(second_ac) & year >= second_ac	
	// drop household years after/including second acute event
	drop test
} 
// // // // // 


***** 2. Event Studies -- Entire treatment group
// Drop if missing outcome variable
drop if missing(`2')

local outcome = "`2'"
local varlist = "`outcome'"
local pop = substr("`3'", 1, 1)
local val = substr("`3'", 3, .)
local oc = 1

qui gen test = year if `1' == 1
bysort famid (year): egen treatdate = min(test)
qui gen treated2 = (!missing(treatdate))
qui gen period_yr = year - treatdate if !missing(treated2)

* Drop all dx'd individuals (any who ultimately have chronic event?)
if ("`pop'" == "C") {
        cap drop todrop
		cap gen todrop = 1 if `1' == 1 // | chronic_event == 1
        bysort enrolid: ereplace todrop = max(todrop)
        drop if todrop == 1
        drop todrop
} 
else if ("`pop'" == "S") {
		// keep only affected self
		cap drop todrop
		cap gen todrop = 1 if `1' == 1 
        bysort enrolid: ereplace todrop = max(todrop)
        keep if todrop == 1
        drop todrop
}

* Drop other dx'd families from control group
gen todrop = 1 if dxd == 1 | chronic_event == 1
bysort famid: ereplace todrop = max(todrop) 
drop if missing(treatdate) & todrop == 1

* Collapse to family level
gcollapse (`collapse') `varlist'* (first) treated2, by(period_yr famid year) fast 

di "Value: `val'"
if ("`val'" == "ihs") { 
	gen lspend = asinh(`outcome')
} 
else if ("`val'" == "perc") {
	gen lspend = `outcome'*100
	replace `outcome' = `outcome' * 100
} 
else if ("`val'" == "level") {
	gen lspend = `outcome'
} 
else if ("`val'" == "binary") { 
	gen lspend = (`outcome' > 0)
} 

qui sum period_yr
local mymin = `r(min)'*-1
local mymax = `r(max)' 

forvalues i = 0/`mymax' { 
	qui gen dummy_`i' = (period_yr == `i' & treated2 == 1)
	label var dummy_`i' "`i'"
} 
* Negatives
forvalues i = 1/`mymin' { 
	local j = `i' * -1
	qui gen dummy_neg_`i' = (period_yr == `j' & treated2 == 1)
	label var dummy_neg_`i' "-`i'"
} 

local noc = `oc' * -1
drop dummy_neg_`oc' // This is the omitted category for these regressions
rename dummy_neg_`mymin' dropdummy

* Store median before treatment
sum `outcome' if period_yr < 0 | missing(period_yr), detail
//local pretreat = round(`r(p50)')
local pretreat = round(`r(mean)',0.1)

break

*** Regression for whole family
* CSDID regression (if desired) 
if ("`want_csdid'" == "Y") {
	gen groupyr = year if period_yr == 0
	bysort famid: ereplace groupyr = mean(groupyr)
	replace groupyr = 0 if missing(groupyr)
	csdid lspend , time(year) gvar(groupyr) ///
				notyet cluster(famid) // if you don't cluster, replace cluster with ivar
}

* Stacked DID regression (if desired) 
if ("`want_stacked'" == "Y") {
	gen no_treat = missing(period_yr) // dummy for never treated
	gen first_treat = year if period_yr == 0 // year of first treatment
	bysort famid: ereplace first_treat = min(first_treat)
	stackedev lspend dummy*, cohort(first_treat) time(year) never_treat(no_treat) unit_fe(famid) clust_unit(famid)
}
else { // straight-forward TWFE
	if ("`val'"=="level") {
		ppmlhdfe lspend dummy*, absorb(famid year) vce(cluster famid)  // Poisson regression
	} 
	else {
		reghdfe lspend dummy*, absorb(famid year) vce(cluster famid)  // typical TWFE
	}
}

regsave
keep if strpos(var, "dummy")
gen y = substr(var, 11, .)
destring y, replace
replace y = y * -1
replace y = real(substr(var, 7, .)) if missing(y)
local obs = _N+1
set obs `obs'
replace y = `noc' in `obs'
replace coef = 0 in `obs'
replace stderr = 0 in `obs'
gen lb = coef - stderr*1.96
gen ub = coef + stderr*1.96

* Trim periods to make sure graph's not useless
gen diff = ub - lb
gen todrop = diff if y == -2
ereplace todrop = max(todrop)
replace todrop = todrop * 2.5

drop if abs(y) > 5 & diff > todrop // make sure to keep the window between -5 and 5
sort y
drop if y[_n+1]-y != 1 & _n < _N // make sure resulting window is continuous
drop if y - y[_n-1] != 1 & _n > 1

qui sum y
local mymin = r(min) 
local mymax = r(max)

* Local for where to put the text label
local myx = `mymax' * 0.05
qui sum ub
local myy = r(max) * 0.85

twoway (line coef y) (scatter coef y, color(maroon)) ///
       (rarea lb ub y, lpattern(dash) lcolor(ebblue%30) fcolor(ebblue%20)), ///
       	graphregion(color(white)) legend(off) ///
	xline(-0.25, lpattern(dash) lcolor(gs8)) yline(0, lcolor(red)) ///
	xsc(r(`mymin'(1)`mymax')) xlab(`mymin'(1)`mymax', gstyle(dot) glcolor(white)) ///
	ylab(,angle(horizontal) glcolor(ebg)) ///
	xtitle("Years Around Diagnosis") /// 
	name("`saveheader'") text(`myy' `myx' "Pre-treatment mean: `pretreat'", place(e))
	*note("Note: Estimates effect of DX on `note' for diagnosed individuals." ///
	*"Controls for family size and age/sex composition, as well as individual/time fixed effects." ///
	*"Standard errors clustered at the family level." ///
	*"This approach uses the full control group, including those w/ and w/o other HCCs.")

graph save "$myouts\`saveheader'.gph", replace
graph export "$myouts\`saveheader'.pdf", as(pdf) replace
********************************************************************************
