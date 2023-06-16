/*******************************************************************************
* Title: Utilization Responses for all chronic diagnoses (for running on the SCC)
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

cap graph drop * 
cd /usr3/graduate/alcobe 

//local 1 = "screen_cancer" // outcome variable
//local 2 = "new_cancer" // treatment variable
//local 3 = "Cancer" // label
//local 4 = "parents" // full sample, or one of (parents,spouses,children,siblings)

***** 0. Load Data
cap set scheme uncluttered
use "Caretaking/allfirms_HCCcollapsed.dta", clear
 
// Move treated with PEs to control group
foreach v of var chronic_event { 
	replace `v' = 0 if pe > 0 & !missing(pe)
}
******************************************************************************** 


***** 2. Event Studies -- Entire treatment group
local longoutcome = "`2'"
local sub1 = "any chronic"
local pop = "C"
local saveheader = "DXSpecific_`1'"
local oc = 1

* Construct first dummy: any chronic event in family
qui gen test = year if chronic_event == 1
bysort famid (year): egen treatdate = min(test)
qui gen treated = (!missing(treatdate))
qui gen period_yr = year - treatdate if !missing(treated)
qui gen byte on = (period_yr >= 0 & !missing(period_yr))

qui gen type_dx = emprel if chronic_event == 1 & year == treatdate
bysort famid: ereplace type_dx = mode(type_dx)  // keep first diagnosis only

* Construct second dummy: specific diagnosis in family
qui gen test2 = year if `2' == 1
bysort famid (year): egen treatdate2 = min(test2)
qui gen treated2 = (!missing(treatdate2))
qui gen period_yr2 = year - treatdate2 if !missing(treated2)
qui gen byte on2 = (period_yr2 >= 0 & !missing(period_yr2))

* Identify specific population to keep
if ("`4'" == "parents") {
	* turn off indicators if the appropriate type wasn't diagnosed
	replace on = 0 if on == 1 & type_dx != 3
	replace on2 = 0 if on2 == 1 & type_dx != 3
	
	* keep the appropriate sub-population
	gen child = (emprel == 3 | (emprel == 4 & age < 18))
	bysort famid: ereplace child = max(child)
	keep if child == 1 & inlist(emprel,1,2)
}
else if ("`4'" == "spouses") {
	* turn off indicators if the appropriate type wasn't diagnosed
	replace on = 0 if on == 1 & !inlist(type_dx,1,2)
	replace on2 = 0 if on2 == 1 & !inlist(type_dx,1,2)
	
	* keep the appropriate sub-population (all adults; dx'd individuals dropped later)
	keep if inlist(emprel,1,2)
}
else if ("`4'" == "children") {
	* turn off indicators if the appropriate type wasn't diagnosed
	replace on = 0 if on == 1 & !inlist(type_dx,1,2)
	replace on2 = 0 if on2 == 1 & !inlist(type_dx,1,2)
	
	* keep the appropriate sub-population
	keep if emprel == 3 | (emprel == 4 & age < 18)
}
else if ("`4'" == "siblings") {
	* turn off indicators if the appropriate type wasn't diagnosed
	replace on = 0 if on == 1 & type_dx != 3
	replace on2 = 0 if on2 == 1 & type_dx != 3
	
	* keep the appropriate sub-population (all children; dx'd individuals dropped later)
	keep if emprel == 3 | (emprel == 4 & age < 18)
}

* Drop dx'd individuals
if ("`pop'" == "C") {
	drop if !missing(treatdate) & inlist(1,dxd,chronic_event,`2')
} 
else if ("`pop'" == "D") { 
	drop if !missing(treatdate) & !inlist(1,dxd,chronic_event,`2')
} 

* Drop other dx'd families from control group
bysort famid: ereplace dxd = max(dxd) 
drop if missing(treatdate) & dxd == 1

* Collapse to family level
drop if missing(`1')
collapse (max) `1' (first) treated2 (max) on*, by(period_yr famid year) fast 

* Regression for whole family
sum `1' if on == 0
local mymean = `r(mean)'
reghdfe `1' on on2, absorb(famid year) vce(cluster famid) 
regsave
drop if var == "_cons"
gen diagnosis = "`3'"
gen population = "`4'"
gen mean = "`mymean'"
save /project/caretaking/Outputs/DDD_Screenings/DDD_Results_`3'_`4'.dta, replace
********************************************************************************
