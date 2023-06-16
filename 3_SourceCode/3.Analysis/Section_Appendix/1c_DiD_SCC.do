/*******************************************************************************
* Title: Utilization Responses (for running on the SCC) -- difference in differences
* Created by: Alex Hoagland
* Created on: 8/20/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file calculates DiD coefficients for changes in utilization among family members of diagnosed: 
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
**********


***** 0. Load Data
set scheme uncluttered
use "Caretaking/allfirms_HCCcollapsed.dta", clear

local 1 = "chronic_event"
local 2 = "pred_prob"
local 3 = "Predicted Beliefs"
local 4 = "C_perc"
local 5 = ""
local 6 = ""
local saveheader = "Model1_Beliefs_1khh"
drop if missing(`2')

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


***** 1. Difference in Differences Regression
local outcome = "`2'"
local varlist = "`outcome'"
local longoutcome = "`3'"
local sub1 = substr("`1'", 1, 5)
if ("`sub1'" == "chron") { 
	local sub1 = "chronic"
}
local sub2 = substr("`1'", 6, .)
local pop = substr("`4'", 1, 1)
local val = substr("`4'", 3, .)
local saveheader = "`pop'_`2'"
local collapse = "sum"
local oc = 1

qui gen treated2 = year if `1' == 1
bysort famid: ereplace treated2 = min(treated2)
qui gen byte on = (year >= treated2 & !missing(treated2))

* Keep part of families in treated group that you're interested in
if ("`pop'" == "C") {
	drop if !missing(treated2) & dxd == 1
} 
else if ("`pop'" == "D") { 
	drop if !missing(treated2) & dxd == 0
} 

* Drop other dx'd families from control group
bysort famid: ereplace dxd = max(dxd) 
drop if missing(treated2) & dxd == 1
keep `varlist'* treated2 on famid year female

* Collapse to family level
collapse (`collapse') `varlist'* (first) treated2 on, by(famid year) fast // (mean) perc_female = female (count) famsize=enrolid ///
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

* Store mean before treatment
qui sum `outcome' if on == 0, detail
local pretreat = round(`r(p50)')

* Regression for whole family
reghdfe lspend on, absorb(famid year) vce(cluster famid)

* Keep coefficient
regsave
keep var-stderr
keep if var == "on"
replace var = "`2'_`1'_`pop'" // name the variable outcome_treatment_population
rename var variable
gen lb = coef - stderr*1.96
gen ub = coef + stderr*1.96
gen pt_median = `pretreat'

* Add to master data file
save "/project/caretaking/Outputs/DiD/DiD_`2'_`1'_`pop'"
********************************************************************************
