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
	- 9.21.2020: this version of the code makes a graph where year -1 is a benchmark,
		 and all other points are percent changes from that point.
*******************************************************************************/

***** Packages
* ssc install ftools // for reghdfe
* ssc install reghdfe
* ssc install regsave
**********


***** 0. Load Data
set scheme uncluttered
use "Caretaking/allfirms_HCCcollapsed.dta", clear
drop if year > 2014 | firm == 56
* drop if missing(switch) // keep all family-years with relevant plan info
******************************************************************************** 


***** 1. Recentered Means/Medians
local outcome = "tot_oop"
local longoutcome = "IHS(Total Family OOP)"
local sub1 = substr("`1'", 1, 5)
if ("`sub1'" == "chron") { 
	local sub1 = "chronic" 
} 
local sub2 = substr("`1'", 6, .)
local saveheader = "RCM_WholeFam_TotOOP"
local collapse1 = "sum" // how to aggregate to family level
local collapse2 = "mean" // really, only will need either mean or median here. 
local oc = 1
local maxper = 10

qui gen test = year if cat_`1' == 1
bysort famid (year): egen treatdate = min(test)
qui gen treated2 = (!missing(treatdate))
qui gen period_yr = year - treatdate if !missing(treated2)

* drop dx'd individuals, control group
keep if treated2 == 1 // & dxd == 1

* Collapse to family-year level
collapse (`collapse1') `outcome' (max) period_yr, by(famid year) fast
gen lspend = asinh(`outcome')
* gen lspend = `outcome' * 100

* Collapse to period-year level
collapse (`collapse2') mean=lspend (sd) sd=lspend (count) n=lspend, by(period_yr) fast

* Convert to percent changes with t=-1 as benchmark 
local nmaxper = `maxper' * -1
keep if period_yr <= `maxper' & period_yr >= `nmaxper'
sort period_yr
gen change = 100*(mean[_n]-mean[`maxper'])/mean[`maxper']

* Generate standard errors
gen se = sd/sqrt(n)
gen pse = abs(mean/mean[`maxper'])*sqrt(se^2/mean^2+se[`maxper']^2/mean[`maxper']^2)*100
gen ub = change+1.96*pse
gen lb = change-1.96*pse 
replace ub = 0 if _n == `maxper'
replace lb = 0 if _n == `maxper'

twoway (line change period_yr) ///
       (line lb period_yr, lpattern(dash) lcolor(gs10)) ///
	(line ub period_yr, lpattern(dash) lcolor(gs10)), ///
       	graphregion(color(white)) legend(off) ///
	xsc(r(`nmaxper'(1)`maxper')) xlab(`nmaxper'(1)`maxper') ///
	yline(0, lcolor(red) lpattern(dash)) xline(0, lcolor(red)) ///
	subtitle("% Changes in `longoutcome' around `sub1' `sub2' risk DX") xtitle("Years Around Diagnosis") ///
	name("`saveheader'_`1'")
* graph save "`saveheader'_`1'.gph", replace
graph export "`saveheader'_`1'.eps", name("`saveheader'_`1'") as(eps) replace
********************************************************************************
