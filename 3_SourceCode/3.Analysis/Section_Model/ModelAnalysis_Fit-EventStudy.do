/*******************************************************************************
* Title: Model Analysis: Event Study Responses
* Created by: Alex Hoagland
* Created on: 12/1/2022
* Last modified on: 
* Last modified by: 
* Purpose: This file performs TWFE regressions for two outcomes in Figure 1 
* 				across both real data (Figure 1) and model simulated data 
			
* Notes: 
			
* Key edits: 

*******************************************************************************/


***** 1. Regressions for total spending (ihs) 
cap graph drop * 
// generate pay_sim 
use "$mydata/Model/EquilibriumData_PayEventStudy.dta", clear
keep enrolid famid year pay_sim
replace enrolid = substr(enrolid,2,.)
destring enrolid, replace
save "$mydata/tomerge.dta", replace

use "$mydata/allfirms_HCCcollapsed.dta", clear
rename chronic_event ind_chronic_event 
rename acuteevent ind_acuteevent 

merge 1:1 enrolid famid year using "$mydata/tomerge.dta", keep(1 3) nogenerate
rm "$mydata/tomerge.dta" 

// drop extremely poor matches (TODO: fix this?)
replace todrop = (abs(tot_pay - pay_sim) > 2500 & !missing(pay_sim))
bysort famid: ereplace todrop = max(todrop) 
replace pay_sim = tot_pay if todrop == 1 & !missing(pay_sim) 
drop todrop 

// move families with pre-existing conditions to control group
replace ind_chronic_event = 0 if pe == 1
replace ind_acuteevent = 0 if pe == 1

// drop any families with acute events or multiple events
// gen eventyr = year if ind_chronic_event == 1 | ind_acuteevent == 1
// bysort famid: egen todrop1 = min(eventyr) 
// bysort famid: egen todrop2 = max(eventyr) 
// drop if todrop1 != todrop2 & !missing(todrop1) & !missing(todrop2) 
// drop todrop1 todrop2
// drop eventyr

// time series
gen eventyr = year if ind_chronic_event == 1
bysort famid: ereplace eventyr = min(eventyr) 
bysort enrolid: egen todrop = max(ind_chronic_event)
bysort famid: egen tokeep = max(todrop) 
drop if todrop == 1 // keep affected family members + control group
gen relyr = year - eventyr
drop if abs(relyr) > 4 & !missing(relyr)

gcollapse (sum) tot_pay pay_sim (max) tokeep, by(famid relyr year) fast // family level 
replace pay_sim = . if pay_sim == 0 // if there is all missing data for a household
replace tot_pay = asinh(tot_pay)
replace pay_sim = asinh(pay_sim)

qui sum relyr
local mymin = `r(min)'*-1
local mymax = `r(max)' 

forvalues i = 0/`mymax' { 
	qui gen dummy_`i' = (relyr == `i' & tokeep == 1)
	label var dummy_`i' "`i'"
} 
* Negatives
forvalues i = 1/`mymin' { 
	local j = `i' * -1
	qui gen dummy_neg_`i' = (relyr == `j' & tokeep == 1)
	label var dummy_neg_`i' "-`i'"
} 

drop dummy_neg_1 // This is the omitted category for these regressions
rename dummy_neg_`mymin' dropdummy

// Regressions
reghdfe pay_sim dummy*, absorb(famid year) vce(cluster famid)  // typical TWFE
preserve
regsave
tempfile es_pred
keep if strpos(var, "dummy")
gen group = "Predicted"
save `es_pred', replace
restore

reghdfe tot_pay dummy*, absorb(famid year) vce(cluster famid)  // typical TWFE
preserve
regsave
keep if strpos(var, "dummy")
gen group = "Actual"
append using `es_pred'

gen y = substr(var, 11, .)
destring y, replace
replace y = y * -1
replace y = real(substr(var, 7, .)) if missing(y)
local obs = _N+2
set obs `obs'
replace y = -1 if missing(y)
replace coef = 0 if missing(coef) 
replace stderr = 0 if missing(stderr)
gen lb = coef - stderr*1.96
gen ub = coef + stderr*1.96
replace group = "Actual" if missing(group) 
replace group = "Predicted" if _n == _N // one omitted dummy for each group

sort group y 
qui sum y
local mymin = r(min) 
local mymax = r(max)

twoway (line coef y if group == "Predicted", color(navy)) ///
		(scatter coef y if group == "Predicted", color(navy)) ///
       (rarea lb ub y  if group == "Predicted", lpattern(dash) lcolor(ebblue%30) fcolor(ebblue%20)) ///
	   (line coef y if group == "Actual", color(maroon)) ///
		(scatter coef y if group == "Actual", color(maroon)) ///
       (rarea lb ub y  if group == "Actual", lpattern(dash) lcolor(maroon%30) fcolor(maroon%20)), ///
       	graphregion(color(white)) legend(off) ///
	xline(-0.25, lpattern(dash) lcolor(gs8)) yline(0, lcolor(red)) ///
	xsc(r(`mymin'(1)`mymax')) xlab(`mymin'(1)`mymax', gstyle(dot) glcolor(white)) ///
	ysc(r(-.4(.1).2)) ylab(-.4(.1).2,angle(horizontal) glcolor(ebg)) ///
	xtitle("Years Around Diagnosis") ///
	legend(on) legend(order(1 "Predicted" 4 "Actual")) legend(size(small))
graph save "$myouts/Model/ModelFit_TotPay_EventStudy.gph", replace
graph export "$myouts/Model/ModelFit_TotPay_EventStudy.pdf", replace
restore
********************************************************************************


***** 2. Regressions for prevention (poisson) 
cap graph drop * 
use "$mydata/Model/EquilibriumData.dta", clear

gen todrop = missing(simple_visits) | missing(sample_sstar) 
bysort famid: ereplace todrop = max(todrop) 
drop if todrop == 1

// drop any families with acute events or multiple events
gen eventyr = year if ind_chronic_event == 1 | ind_acuteevent == 1
bysort famid: egen todrop1 = min(eventyr) 
bysort famid: egen todrop2 = max(eventyr) 
drop if todrop1 != todrop2 & !missing(todrop1) & !missing(todrop2) 
drop todrop1 todrop2

// time series
replace eventyr = year if ind_chronic_event == 1
bysort famid: ereplace eventyr = min(eventyr) 
bysort enrolid: ereplace todrop = max(ind_chronic_event)
bysort famid: egen tokeep = max(todrop) 
drop if todrop == 1 // keep affected family members + control group
gen relyr = year - eventyr

gcollapse (sum) simple_visits sample_sstar (max) tokeep, by(famid relyr year) fast // family level 

qui sum relyr
local mymin = `r(min)'*-1
local mymax = `r(max)' 

forvalues i = 0/`mymax' { 
	qui gen dummy_`i' = (relyr == `i' & tokeep == 1)
	label var dummy_`i' "`i'"
} 
* Negatives
forvalues i = 1/`mymin' { 
	local j = `i' * -1
	qui gen dummy_neg_`i' = (relyr == `j' & tokeep == 1)
	label var dummy_neg_`i' "-`i'"
} 

drop dummy_neg_1 // This is the omitted category for these regressions
// rename dummy_neg_`mymin' dropdummy
replace sample_sstar = sample_sstar + .5 // move away from zero values?
ppmlhdfe simple_visits dummy*, absorb(famid year) vce(cluster famid)  // Poisson regression
ppmlhdfe sample_sstar dummy*, absorb(famid year) vce(cluster famid)  // Poisson regression
********************************************************************************


***** 2. Regressions for beliefs (levels?) 
cap graph drop * 
use "$mydata/Model/EquilibriumData.dta", clear

gen todrop = missing(pred_beliefs)
bysort famid: ereplace todrop = max(todrop) 
drop if todrop == 1

// drop any families with acute events or multiple events
gen eventyr = year if ind_chronic_event == 1 | ind_acuteevent == 1
bysort famid: egen todrop1 = min(eventyr) 
bysort famid: egen todrop2 = max(eventyr) 
drop if todrop1 != todrop2 & !missing(todrop1) & !missing(todrop2) 
drop todrop1 todrop2

// time series
replace eventyr = year if ind_chronic_event == 1
bysort famid: ereplace eventyr = min(eventyr) 
bysort enrolid: ereplace todrop = max(ind_chronic_event)
bysort famid: egen tokeep = max(todrop) 
drop if todrop == 1 // keep affected family members + control group
gen relyr = year - eventyr

gcollapse (mean) pred_beliefs (max) tokeep, by(famid relyr year) fast // family level 

qui sum relyr
local mymin = `r(min)'*-1
local mymax = `r(max)' 

forvalues i = 0/`mymax' { 
	qui gen dummy_`i' = (relyr == `i' & tokeep == 1)
	label var dummy_`i' "`i'"
} 
* Negatives
forvalues i = 1/`mymin' { 
	local j = `i' * -1
	qui gen dummy_neg_`i' = (relyr == `j' & tokeep == 1)
	label var dummy_neg_`i' "-`i'"
} 

drop dummy_neg_1 // This is the omitted category for these regressions
// rename dummy_neg_`mymin' dropdummy
reghdfe pred_beliefs dummy*, absorb(famid year) vce(cluster famid) 
	// note: this one should be mechanical 
********************************************************************************
