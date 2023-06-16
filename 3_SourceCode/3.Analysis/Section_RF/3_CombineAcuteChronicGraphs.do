/*******************************************************************************
* Title: Combine Acute and Chronic Responses into a single graph
* Created by: Alex Hoagland
* Created on: 8/20/2020
* Last modified on: 11/10/22
* Last modified by: 
* Purpose: This file uses estimates from 1_EventStudies_NewHCCs.do 
			
* Notes:
			
* Key edits: 

*******************************************************************************/


***** 1. Panel (a): OOP Spending
serset dir
graph use "$myouts/ChronicEvent_OOPSpending_chro_.gph"
serset use, clear
tempfile chronic
rename coef c_coef
rename lb c_lb 
rename ub c_ub
save `chronic', replace

serset dir
graph use "$myouts/AcuteEvent_OOPSpending_acut_.gph"
serset use, clear
merge 1:1 y using `chronic', nogenerate
graph drop * 

drop if missing(coef) | missing(c_coef)

qui sum y
local mymin = r(min) 
local mymax = r(max)

* Local for where to put the text label
local myx = `mymax' * 0.05
qui sum ub
local myy = r(max) * 0.85

twoway (line coef y, color(maroon)) (scatter coef y, color(maroon)) ///
       (rarea lb ub y, lpattern(dash) lcolor(ebblue%30) fcolor(ebblue%20)) ///
	   (line c_coef y, color(navy)) (scatter c_coef y, color(navy)) ///
       (rarea c_lb c_ub y, lpattern(dash) lcolor(gold%30) fcolor(gold%20)), ///
       	graphregion(color(white)) legend(off) ///
	xline(-0.25, lpattern(dash) lcolor(gs8)) yline(0, lcolor(red)) ///
	xsc(r(`mymin'(1)`mymax')) xlab(`mymin'(1)`mymax', gstyle(dot) glcolor(white)) ///
	ylab(,angle(horizontal) glcolor(ebg)) ///
	xtitle("Years Around Diagnosis") /// 
	text(`myy' `myx' "Pre-treatment median: $1,128", place(e))
	*note("Note: Estimates effect of DX on `note' for diagnosed individuals." ///
	*"Controls for family size and age/sex composition, as well as individual/time fixed effects." ///
	*"Standard errors clustered at the family level." ///
	*"This approach uses the full control group, including those w/ and w/o other HCCs.")

graph save "$myouts\Joined_AcuteChronic_OOP.gph", replace
graph export "$myouts\Joined_AcuteChronic_OOP.pdf", as(pdf) replace
********************************************************************************


***** 2. Panel (b): Number of Visits
serset dir
graph use "$myouts/ChronicEvent_PrevNumVisits_chro_.gph"
serset use, clear
tempfile chronic
rename coef c_coef
rename lb c_lb 
rename ub c_ub
save `chronic', replace

serset dir
graph use "$myouts/AcuteEvent_PrevNumVisits_acut_.gph"
serset use, clear
merge 1:1 y using `chronic', nogenerate
graph drop * 

drop if missing(coef) | missing(c_coef)

qui sum y
local mymin = r(min) 
local mymax = r(max)

* Local for where to put the text label
local myx = `mymax' * 0.05
qui sum ub
local myy = r(max) * 0.85

twoway (line coef y, color(maroon)) (scatter coef y, color(maroon)) ///
       (rarea lb ub y, lpattern(dash) lcolor(ebblue%30) fcolor(ebblue%20)) ///
	   (line c_coef y, color(navy)) (scatter c_coef y, color(navy)) ///
       (rarea c_lb c_ub y, lpattern(dash) lcolor(gold%30) fcolor(gold%20)), ///
       	graphregion(color(white)) legend(off) ///
	xline(-0.25, lpattern(dash) lcolor(gs8)) yline(0, lcolor(red)) ///
	xsc(r(`mymin'(1)`mymax')) xlab(`mymin'(1)`mymax', gstyle(dot) glcolor(white)) ///
	ylab(,angle(horizontal) glcolor(ebg)) ///
	xtitle("Years Around Diagnosis") /// 
	text(`myy' `myx' "Pre-treatment median: 3", place(e))
	*note("Note: Estimates effect of DX on `note' for diagnosed individuals." ///
	*"Controls for family size and age/sex composition, as well as individual/time fixed effects." ///
	*"Standard errors clustered at the family level." ///
	*"This approach uses the full control group, including those w/ and w/o other HCCs.")

graph save "$myouts\Joined_AcuteChronic_PrevNumVisits.gph", replace
graph export "$myouts\Joined_AcuteChronic_PrevNumVisits.pdf", as(pdf) replace
********************************************************************************
