/*******************************************************************************
* Title: Recentered Time Series Graphs
* Created by: Alex Hoagland
* Created on: 9/8/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file looks at trends in utilization among family members of diagnosed: 
				* all preventive care
				* all office visits
				* all specialist visits
				* all ED visits
				* all pharma spending (and generics)
	- rather than computing/plotting event studies, this uses raw trends only
			
* Notes: - this file uses the collapsed versions of the HCCs (4 categories)
			
* Key edits: 

*******************************************************************************/

***** Packages
* ssc install ftools // for reghdfe
* ssc install reghdfe
* ssc install regsave
**********


***** 0. Load Data
use "Caretaking/allfirms_HCCcollapsed.dta", clear
******************************************************************************** 


***** 1. Recentered Means/Medians
local outcome = "tot_pay"
local varlist = "`outcome'"
local longoutcome = "Log(Total Billed Spending)"
local note = "logarithm of total billed spending + 1"
local sub1 = substr("`1'", 1, 5)
local sub2 = substr("`1'", 6, .)
local saveheader = "Fam_TotPay"
local collapse = "mean" // really, only will need either mean or median here. 
local oc = 1
local who = "the entire family"

qui gen test = year if cat_`1' == 1
bysort famid (year): egen treatdate = min(test)
qui gen treated2 = (!missing(treatdate))
qui gen period_yr = year - treatdate if !missing(treated2)

* Keep treated families (drop dx'd individuals and control group)
* keep if treated2 == 1 & dxd == 0

* Keep diagnosed individuals
* keep if treated2 == 1 & dxd == 1

* Keep family
keep if treated2 == 1

* Collapse to period-year level
gen lspend = log(`outcome'+1)
collapse (`collapse') mean=lspend (sd) sd=lspend (count) n=lspend, by(period_yr) fast

* Generate standard errors
gen se = sd/sqrt(n)
gen ub = mean+1.96*se
gen lb = mean-1.96*se 

keep if period_yr <= 5 & period_yr >= -5

twoway (line mean period_yr) ///
       (line lb period_yr, lpattern(dash) lcolor(gs10)) (line ub period_yr, lpattern(dash) lcolor(gs10)), ///
       	graphregion(color(white)) legend(off) xline(0, lcolor(red) lpattern(dash)) ///
	xsc(r(-5(1)5)) xlab(-5(1)5) ///
	subtitle("Trends of `longoutcome' around `sub1' `sub2' risk DX") xtitle("Years Around Diagnosis") ///
	name("`saveheader'_`1'") /// 
	note("Note: Trends in `note' for `who' around diagnosis event.")
graph save "`saveheader'_`1'.gph", replace
graph export "`saveheader'_`1'.eps", name("`saveheader'_`1'") as(eps) replace
********************************************************************************