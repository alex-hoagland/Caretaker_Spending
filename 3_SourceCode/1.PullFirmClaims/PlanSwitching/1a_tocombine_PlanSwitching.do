/*******************************************************************************
* Title: Plan Switching Event Studies
* Created by: Alex Hoagland
* Created on: 8/18/2020
* Last modified on: 
* Last modified by: 
* Purpose: This file looks at trends in plan switching after HCC diagnosis
				* add a list of things to look at here. 
			
* Notes:
			
* Key edits: 
   - 
*******************************************************************************/

***** Packages
* None yet
**********


***** 0. Prepare HCC file to merge
local firm 6 // firms are 6, 22, 28, 35, and 36. 6 is the original firm. 
			  // cannot use all firms here (not all have good plan info)
********************************************************************************


***** 1. Merge this into spending file 
use "2_Data/0.HCCs_Switching/Firm`firm'/Firm`firm'_AllHCCs_EnrolleeLevel.dta", clear
collapse (max) onhcc_* pe (sum) num_hccs, by(famid year) fast
merge 1:1 famid year using "2_Data/2.PlanChoices/1_Firm`firm'/firm`firm'_switching.dta", ///
		keep(2 3) nogenerate

bysort famid (year): drop if _n == 1 // can't count this as a switch
drop if exit == 1

egen numon = rowtotal(onhcc*)
bysort famid: egen dxd = max(numon) // flags treated individuals
replace dxd = 1 if dxd > 1 // shouldn't be any
********************************************************************************


***** 2. Recentered means for family members and diagnosed (per person)
	* Add this in later
********************************************************************************


***** 3. Event Studies
local outcome = "switch"
local varlist = substr("`outcome'", 1, strpos("`outcome'", "_"))
local longoutcome = "Plan Switching"
* local filepath = "4_Output\5.Caretakers_Pharma"
local note = "likelihood of switching plans in January"

* do "3_SourceCode\caretakers_master.do"
* foreach h of global hccs {  

local hccs 118 
foreach h of local hccs { 
	preserve
	
	qui gen test = year if onhcc_`h' == 1
	bysort famid (year): egen treatdate = min(test)
	qui gen treated2 = (!missing(treatdate))
	qui gen period_yr = year - treatdate if !missing(treated2)
	
	qui sum period_yr
	local mymin = `r(min)'*-1
	local mymax = `r(max)' 
	
	forvalues i = 0/`mymax' { 
		qui gen dummy_`i' = (period_yr == `i' & treated2 == 1)
		label var dummy_`i' "`i'"
	} 
	* Negatives
	forvalues i = 2/`mymin' { 
		local j = `i' * -1
		qui gen dummy_neg_`i' = (period_yr == `j' & treated2 == 1)
		label var dummy_neg_`i' "-`i'"
	} 
	
	rename dummy_neg_`mymin' dropdummy

	* Regression for whole family
	qui reghdfe `outcome' dummy* famsize, absorb(famid year)
	regsave
	keep if strpos(var, "dummy")
	gen y = substr(var, 11, .)
	destring y, replace
	replace y = y * -1
	replace y = real(substr(var, 7, .)) if missing(y)
	local obs = _N+1
	set obs `obs'
	replace y = -1 in `obs'
	replace coef = 0 in `obs'
	replace stderr = 0 in `obs'
	gen lb = coef - stderr*1.96
	gen ub = coef + stderr*1.96

	sort y
	qui sum y
	local mymin = r(min) 
	local mymax = r(max)
	
	qui do "3_SourceCode\2.AssignHCCs\CC_Labels.do"
	local HCC:  label short_ccs `h'
	twoway (line coef y) ///
		(line lb y, lpattern(dash) lcolor(gs10)) (line ub y, lpattern(dash) lcolor(gs10)), ///
		xline(0, lpattern(dash) lcolor(gs8)) yline(0, lcolor(red)) ///
		xsc(r(`mymin'(1)`mymax')) xlab(`mymin'(1)`mymax') ///
		subtitle("Effect of DX on `longoutcome': `HCC'") xtitle("Years Around Diagnosis") /// 
		note("Note: Estimates effect of DX on `note' for family members of the diagnosed." ///
		"Controls for family size and age/sex composition, as well as individual/time fixed effects." ///
		"This approach uses the full control group, including those w/ and w/o other HCCs.")
	* graph save "`filepath'\HCC_`h'.gph", replace
	* graph export "`filepath'\HCC_`h'.png", replace as(png)
	restore
} 
********************************************************************************


***** 4. What do these switches look like? 
*****    Pick out two groups (i) those who switched before a dx (or in control group) 
*****					and (ii) those who switched after a dx,
*****		and see what kinds of switching occurred. 

gen pre_dx = 1
gen test = year if numon == 1
bysort famid: egen dxyear = min(test)
replace pre_dx = 0 if dxd == 1 & year >= dxyear
drop test dxyear

* Make this into a loop later
gen test = (onhcc_118 == 1)
bysort famid: egen test2 = max(test)
drop if pre_dx == 0 & test2 == 0
drop test*

keep if switch == 1 // keep only family-years with switches
drop if oldplan == 700 | newplan == 700

levelsof newplan, local(new)
foreach p of local new { 
	gen dest_`p' = (newplan == `p')
} 
levelsof oldplan, local(old)
foreach p of local old { 
	gen orig_`p' = (oldplan == `p')
} 
collapse (mean) orig_* dest_*, by(pre_dx) fast 
********************************************************************************


***** Clean up
* 
********************************************************************************
