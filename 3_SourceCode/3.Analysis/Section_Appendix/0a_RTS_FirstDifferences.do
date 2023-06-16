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
	 - this file uses first differences to remove a linear time trend from the graph
			
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
local longoutcome = "IHS(Total Billed Spending)"
* local note = "% of prescriptions which are generic"
local sub1 = substr("`1'", 1, 5)
local sub2 = substr("`1'", 6, .)
local saveheader = "RCM_Carers_IHSTotPay"
local collapse = "mean" // really, only will need either mean or median here. 
local oc = 1
local who = "caretakers"

* Identify treated families and timing
qui gen test = year if cat_`1' == 1
bysort famid (year): egen treatdate = min(test)
qui gen treated2 = (!missing(treatdate))
qui gen period_yr = year - treatdate if !missing(treated2)

* Keep treated families but drop dx'd individuals
keep if treated2 == 1 & dxd == 0

* Keep diagnosed individuals
* keep if treated2 == 1 & dxd == 1

* Keep treated families
* keep if treated2 == 1

* Collapse to family-year level
* collapse (sum) `outcome' (max) period_yr, by(famid year) fast

* Collapse to period-year level
* gen lspend = log(`outcome'+1)
gen lspend = asinh(`outcome')
collapse (`collapse') mean=lspend (sd) sd=lspend (count) n=lspend, by(period_yr) fast

* Use first differences
sort period_yr
gen diff = mean[_n]-mean[_n-1]

* Generate standard errors
gen se = sd/sqrt(n)
gen ub = diff+1.96*se
gen lb = diff-1.96*se 

keep if period_yr <= 5 & period_yr >= -5

twoway (line diff period_yr) ///
       (line lb period_yr, lpattern(dash) lcolor(gs10)) ///
	(line ub period_yr, lpattern(dash) lcolor(gs10)), ///
       	graphregion(color(white)) legend(off) ///
	xline(0, lcolor(red) lpattern(dash)) yline(0, lcolor(red) lpattern(dash)) ///
	xsc(r(-5(1)5)) xlab(-5(1)5) /// 
	subtitle("First Differences of `longoutcome' around `sub1' `sub2' risk DX") xtitle("Years Around Diagnosis") ///
	note("Note: Trends in `note' for `who' around diagnosis event.") ///
	name("`saveheader'_`1'")
graph save "`saveheader'_`1'.gph", replace
graph export "`saveheader'_`1'.eps", name("`saveheader'_`1'") as(eps) replace
********************************************************************************