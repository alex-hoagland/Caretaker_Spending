/*******************************************************************************
* Title: Plan Switching: Likelihood of Switching to a Lower Deductible Plan
* Created by: Alex Hoagland
* Created on: 12/7/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file looks at the likelihood of making a "good" plan switch, 
	as measured by switching to a plan with a lower deductible. 
			
* Notes: - There are two versions of this: one with the full sample, and one
	with just those who ever make at least one active choice in the sample window. 
			
* Key edits: 

*******************************************************************************/

***** Packages
* ssc install ftools // for reghdfe
* ssc install reghdfe
* ssc install regsave
**********


***** 0. Load Data
set scheme uncluttered
use "Caretaking/allfirms_extraoutcomes.dta", clear
* keep if firm == 6

// Move treated with PEs to control group
foreach v of var cat_* { 
	replace `v' = 0 if pe > 0 & !missing(pe)
}
******************************************************************************** 


***** 2. Event Studies -- Entire treatment group
local outcome = "switch_ld"
local varlist = "`outcome'"
local longoutcome = "Pr(Switch to a Lower Deductible Plan)"
local dollar = "" // Include this if you want a dollar sign on pre-treatment median
local sub1 = "any chronic"
local pop = "C"
local val = "perc"
local saveheader = "Switch_LowDed_FullSample"
local collapse = "max"
local oc = 1

qui gen test = year if (cat_chronhigh == 1 | cat_chronlow == 1) 
bysort famid (year): egen treatdate = min(test)
qui gen treated2 = (!missing(treatdate))
qui gen period_yr = year - treatdate if !missing(treated2)

* Drop dx'd individuals
if ("`pop'" == "C") {
	drop if !missing(treatdate) & dxd == 1
} 
else if ("`pop'" == "D") { 
	drop if !missing(treatdate) & dxd == 0
} 

* Drop other dx'd families from control group
bysort famid: ereplace dxd = max(dxd) 
drop if missing(treatdate) & dxd == 1
keep `varlist'* treated2 period_yr famid year female age

* Collapse to family level
drop if missing(`outcome')
collapse (`collapse') `varlist'* (first) treated2, by(period_yr famid year) fast // (mean) perc_female = female (count) famsize=enrolid ///
* replace perc_female = perc_female/famsize

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
qui reghdfe lspend dummy*, absorb(famid year) vce(cluster famid) // control for perc_female, not famsize
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
	subtitle("Effect of `sub1' DX on `longoutcome'") xtitle("Years Around Diagnosis") /// 
	name("`saveheader'") text(`myy' `myx' "Pre-treatment mean: `dollar'`pretreat'", place(e)) 

graph export "`saveheader'.eps", as(eps) name("`saveheader'") replace
********************************************************************************
