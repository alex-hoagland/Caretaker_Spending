/*******************************************************************************
* Title: Combine Firms
* Created by: Alex Hoagland
* Created on: 8/7/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file combines all eligible firms into one data set (spending + HCCs)
		   
* Notes: Requires the running of 0.PullingMarketScanData in order
			to collect all treatments and spending. 
		
* Key edits: 
*******************************************************************************/

***** Packages
* None yet
**********


***** 0. Local for all firms
local myfirms 22 28 35 36 6
********************************************************************************

***** 1. Combining spending files
foreach f of local myfirms { 
	di `f'
	use "2_Data/1.Spending/Firm`f'/firm`f'_allspending_trimmed.dta", clear
	cap drop version hlthplan eeclass eestatu mhsacovg
	destring emprel rx indstry region egeoloc, replace
	gen firm = `f'
	
	capture confirm file "2_Data/1.Spending/allfirms_allspending.dta"
	if (_rc == 0) { 
		append using "2_Data/1.Spending/allfirms_allspending.dta"
		save "2_Data/1.Spending/allfirms_allspending.dta", replace
	} 
	else { 
		save "2_Data/1.Spending/allfirms_allspending.dta", replace
	} 
} 
********************************************************************************


***** 2. Combining the HCC files
local myfirms 22 28 35 36 6
foreach f of local myfirms { 
	use "2_Data/0.HCCs_Switching/Firm`f'/firm`f'_AllHCCs_EnrolleeLevel.dta", clear
	gen firm = `f'
	
	capture confirm file "2_Data/0.HCCs_Switching/allfirms_HCCs.dta"
	if (_rc == 0) { 
		append using "2_Data/0.HCCs_Switching/allfirms_HCCs.dta"
		save "2_Data/0.HCCs_Switching/allfirms_HCCs.dta", replace
	} 
	else { 
		save "2_Data/0.HCCs_Switching/allfirms_HCCs.dta", replace
	} 
} 

compress
save "2_Data/0.HCCs_Switching/allfirms_HCCs.dta", replace 
********************************************************************************










