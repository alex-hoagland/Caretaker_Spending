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
local longoutcome = "Total Billed Spending"
local sub1 = substr("`1'", 1, 5)
local sub2 = substr("`1'", 6, .)
local saveheader = "RCM_UC_Control_TotPay"
local collapse = "mean" // really, only will need either mean or median here. 
local oc = 1

qui gen byte todrop = (cat_`1' == 1)
bysort famid: ereplace todrop = max(todrop)
drop if todrop == 1 // keep only the control group

* Collapse to family level
collapse (sum) `outcome', by(famid year) fast
gen lspend = `outcome'

* Collapse to period-year level
collapse (`collapse') mean=lspend (sd) sd=lspend (count) n=lspend, by(year) fast

* Generate standard errors
gen se = sd/sqrt(n)
gen ub = mean+1.96*se
gen lb = mean-1.96*se 

twoway (line mean year) ///
       (line lb year, lpattern(dash) lcolor(gs10)) (line ub year, lpattern(dash) lcolor(gs10)), ///
       	graphregion(color(white)) legend(off) ///
	subtitle("Trends of `longoutcome' around `sub1' `sub2' risk DX") xtitle("Year") ///
	name("`saveheader'_`1'") 
	* note("Note: Trends in `note' for `who' around diagnosis event.")
graph save "`saveheader'_`1'.gph", replace
graph export "`saveheader'_`1'.eps", name("`saveheader'_`1'") as(eps) replace
********************************************************************************