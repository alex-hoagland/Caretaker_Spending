/*******************************************************************************
* Title: Collapsing HCCs
* Created by: Alex Hoagland
* Created on: 8/27/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file collapses HCCs into 4 categories: 
	- Chronic high risk (e.g., multiple sclerosis) 
	- Chronic low risk (e.g., diabetes)
	- Acute high risk (e.g., viral meningitis)
	- Acute low risk (e.g., COPD)
			
* Notes:
			
* Key edits: 
*******************************************************************************/

***** Packages
* ssc install 
**********


***** 0. Prepare HCC file to merge
use "2_Data/0.HCCs_Switching/allfirms_HCCs.dta", clear

gen cat_chronhigh = (onhcc_12 == 1 | onhcc_30 == 1 | onhcc_56 == 1 | onhcc_118 == 1 | onhcc_130 == 1)
gen cat_chronlow = (onhcc_13 == 1 | onhcc_20 == 1 | onhcc_21 == 1 | onhcc_37 == 1 | onhcc_48 == 1 | ///
	onhcc_57 == 1 | onhcc_88 == 1 | onhcc_90 == 1 | onhcc_120 == 1 | onhcc_142 == 1 | onhcc_161 == 1 | onhcc_162 == 1 | onhcc_217 == 1)
gen cat_acutehigh = (onhcc_2 == 1 | onhcc_3 == 1 | onhcc_4 == 1 | onhcc_127 == 1 | onhcc_132 == 1)
gen cat_acutelow = (onhcc_38 == 1 | onhcc_47 == 1 | onhcc_142 == 1 | onhcc_156 == 1 | onhcc_160 == 1)

label var cat_chronhigh "High-risk chronic condition"
label var cat_chronlow "Low-risk chronic condition"
label var cat_acutehigh "High-risk acute condition"
label var cat_acutelow "Low-risk acute condition"

* Keep only families with one event in their timeline
bysort famid: egen todrop1 = total(cat_chronhigh)
bysort famid: egen todrop2 = total(cat_chronlow)
bysort famid: egen todrop3 = total(cat_acutehigh)
bysort famid: egen todrop4 = total(cat_acutelow)
drop if todrop1 > 1 | todrop2 > 1 | todrop3 > 1 | todrop4 > 1 // deletes 330k of almost 1M
egen todrop5 = rowtotal(todrop*)
drop if todrop5 > 1 // deletes 98k
drop todrop*

keep enrolid famid year cat_*
********************************************************************************


***** 1. Merge into spending file 
merge 1:1 enrolid year using "2_Data/1.Spending/allfirms_allspending.dta", ///
	keep(2 3) nogenerate

gen tot_pay = ip_pay + op_pay + ph_pay
gen tot_oop = ip_oop + op_oop + ph_oop

egen numon = rowtotal(cat_*)
bysort enrolid: egen dxd = max(numon) // flags treated individuals
foreach v of var cat_* { 
	replace `v' = 0 if missing(`v')
	} 
********************************************************************************


***** N. Clean up
cap rm "2_Data/0.HCCs_Switching/tomerge.dta"
********************************************************************************
