/*******************************************************************************
* Title: Listing enrollees to double check (for HCCs)
* Created by: Alex Hoagland
* Created on: August 2020
* Last modified on: 
* Last modified by: 
* Purpose: Make a list of all enrollees that either: 
	1. are in years you have HCCs and don't have plankey info (weren't initially calculated)
	2. are in years w/o HCCs info (need to re-do whole year)
		   
* Notes: 
		
* Key edits: 
   -  
*******************************************************************************/


local firm 6
use "2_Data/1.Spending/Firm`firm'/Firm`firm'_AllHCCs_EnrolleeLevel.dta", clear
levelsof year, local(hcc_years)

use "2_Data/1.Spending/Firm`firm'/firm`firm'_allspending.dta", clear
foreach y of local hcc_years { 
	drop if year == `y' & !missing(plnkey1)
	} 
	
keep enrolid year
duplicates drop
levelsof year, local(saveyears)
foreach y of local saveyears { 
	preserve
	keep if year == `y'
	keep enrolid
	sort enrolid
	export delimited "2_Data/1.Spending/Firm`firm'/Firm`firm'_Check_`y'.csv", replace
	restore
	} 
********************************************************************************
