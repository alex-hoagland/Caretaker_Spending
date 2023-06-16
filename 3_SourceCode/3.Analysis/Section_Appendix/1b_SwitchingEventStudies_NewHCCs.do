/*******************************************************************************
* Title: Utilization Responses (for running on the SCC)
* Created by: Alex Hoagland
* Created on: 8/20/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file looks at trends in utilization among family members of diagnosed: 
				* all preventive care
				* all office visits
				* all specialist visits
				* all ED visits
				* all pharma spending (and generics)
			
* Notes: - this file uses the collapsed versions of the HCCs (4 categories)
			
* Key edits: 

*******************************************************************************/

***** Packages
* ssc install ftools // for reghdfe
* ssc install reghdfe
* ssc install regsave
* ssc install twowayfeweights // Chaisemartin & d'Haultfoeuille
* ssc install fuzzydid
* ssc install did_multiplegt
**********


***** 0. Load Data
cap set scheme uncluttered
cap graph drop * 
use "Caretaking/allfirms_HCCcollapsed.dta", clear

drop if missing(switch)
// keep only active switchers
bysort famid: egen tokeep = max(switch)
keep if tokeep == 1
drop tokeep 

gen switch_zero = (switch == 1 & zeroded == 1)
* TO ADD: switch_low and switch_high

* gen posded = (zeroded == 0)

local 1 = "chronic_event"
local 2 = "switch_zero"
local 3 = "Pr(Switching to Zero-Deductible Plan)"
local 4 = "C_perc"
local 5 = ""
local 6 = ""
local saveheader = "Switch_ZeroDed"
drop if missing(`2')

local cd_correction = 0 // if you want to run the correction, change to 1. Else, 0. 
local dynamic = 5 // number of dynamic period effects to estimate

// Move treated with PEs to control group
foreach v of var chronic_event acuteevent { 
	replace `v' = 0 if pe > 0 & !missing(pe)
}

* Keep plans with a specific plan type if needed
if (!missing("`6'") & "`6'" != "") {
	keep if `6' == 1
	local saveheader = "NewHCCs_`2'_`6'"
} 
else {
	local saveheader = "NewHCCs_`2'_`6'_Full"
}
******************************************************************************** 


***** 2. Event Studies -- Entire treatment group
local outcome = "`2'"
local varlist = "`outcome'"
local longoutcome = "`3'"
local dollar = "`5'" // Include this if you want a dollar sign on pre-treatment median
local sub1 = substr("`1'", 1, 5)
if ("`sub1'" == "chron") { 
	local sub1 = "chronic"
}
local sub2 = substr("`1'", 6, .)
local pop = substr("`4'", 1, 1)
local val = substr("`4'", 3, .)
local collapse = "max"
local oc = 1

qui gen test = year if `1' == 1
bysort famid (year): egen treatdate = min(test)
qui gen treated2 = (!missing(treatdate))
qui gen period_yr = year - treatdate if !missing(treated2)

* Drop all dx'd individuals (any who ultimately have chronic event?)
if ("`pop'" == "C") {
        cap drop todrop
        bysort enrolid: egen todrop = max(`1')
        drop if todrop == 1
        drop todrop
} 

* Drop other dx'd families from control group
bysort famid: ereplace dxd = max(dxd) 
drop if missing(treatdate) & dxd == 1

* Collapse to family level
collapse (`collapse') `varlist'* (first) treated2, by(period_yr famid year) fast 

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

* Store mean before treatment
qui sum `outcome' if period_yr < 0 | missing(period_yr), detail
local pretreat = round(`r(mean)')

* Regression for whole family
reghdfe lspend dummy*, absorb(famid year) vce(cluster famid) 

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

twoway (line coef y) ///
       (line lb y, lpattern(dash) lcolor(gs10)) (line ub y, lpattern(dash) lcolor(gs10)), ///
       	graphregion(color(white)) legend(off) ///
	xline(0, lpattern(dash) lcolor(gs8)) yline(0, lcolor(red)) ///
	xsc(r(`mymin'(1)`mymax')) xlab(`mymin'(1)`mymax') ///
	subtitle("Effect of `1' on `longoutcome'") xtitle("Years Around Diagnosis") /// 
	name("`saveheader'") text(`myy' `myx' "Pre-treatment mean: `dollar'`pretreat'", place(e)) 
	*note("Note: Estimates effect of DX on `note' for diagnosed individuals." ///
	*"Controls for family size and age/sex composition, as well as individual/time fixed effects." ///
	*"Standard errors clustered at the family level." ///
	*"This approach uses the full control group, including those w/ and w/o other HCCs.")
graph save "`saveheader'.gph", replace
* graph export "`saveheader'.eps", as(eps) name("`saveheader'") replace
********************************************************************************
