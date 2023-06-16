/*******************************************************************************
* Title: Make coefficient plot for DDD Screening Regression Results
* Created by: Alex Hoagland
* Created on: 2/25/2021
* Last modified on: 3/15/2021
* Last modified by: 
* Purpose: hard codes the figure for DDD screening regression results
			
* Notes: 
			
* Key edits: 

*******************************************************************************/


***** 0. Packages
*ssc install sg97_5 // frmttable
cd /project/caretaking/Outputs/DDD_Screenings/
********************************************************************************


***** 1. append all data sets
* Simple regressions
clear
gen var = ""
local files: dir . files "DDD_Results_Simple*"
foreach f of local files { 
	append using `f'
}
replace var = "simple_DD" if var == "on"
replace var = "simple_DDD" if var == "on2"
cap drop if diagnosis == "ht_diabetes"
********************************************************************************


***** 2. identify significance
gen lb95 = coef-1.96*stderr
gen ub95 = coef+1.96*stderr
********************************************************************************


***** 3. Make both panels
replace diagnosis = "Cancer" if diagnosis == "cancer"
replace diagnosis = "Cholesterol" if diagnosis == "cholesterol_newdiabetes" 
replace diagnosis = "Depression" if diagnosis == "depression"
replace diagnosis = "Diabetes" if diagnosis == "diabetes"
replace diagnosis = "Hypertension" if diagnosis == "hypertension_anychronic"
// replace diagnosis = "Hypertension Diagnosis" if diagnosis == "ht_diabetes"

gen j = 0
replace j = 6 if diagnosis == "Hypertension"
replace j = 5 if diagnosis == "Diabetes"
replace j = 4 if diagnosis == "Cholesterol"
replace j =3 if diagnosis == "Obesity"
replace j = 2 if diagnosis == "Cancer"
replace j = 1 if diagnosis == "Depression"

labmask j, values(diagnosis)
gen group = strpos(var, "DDD")
replace group = 1 if group > 0

twoway (scatter j coef if group == 0) (rbar lb ub j if group == 0, horizontal barwidth(.05)), ///
	xline(0, lpattern(dash) lcolor(red)) graphregion(color(white)) ///
	legend(off) xtitle("") ytitle("") ///
	xsc(r(-1(.5)3)) xlab(-1(.5)3) ///
	ylab(1(1)6, valuelabel angle(horizontal))
graph save "Coefplot_DD_20210316", replace
graph export "Coefplot_DD_20210316.png", replace as(png)

twoway (scatter j coef if group == 1) (rbar lb ub j if group == 1, horizontal barwidth(.05)), ///
	xline(0, lpattern(dash) lcolor(red)) graphregion(color(white)) ///
	legend(off) xtitle("") ytitle("") ///
	xsc(r(-1(.5)3)) xlab(-1(.5)3) ///
	ylab(1(1)6, nolabels)
graph save "Coefplot_DDD_20210316", replace
graph export "Coefplot_DDD_20210316.png", replace as(png)

// for slides
twoway (rbar lb ub j , horizontal barwidth(.05) color(ebblue%70) ) (scatter j coef, color(maroon) ), ///
	xline(0, lpattern(dash) lcolor(red)) graphregion(color(white)) ///
	legend(off) xtitle("Coefficient (percentage points)") ytitle("") ///
	xsc(r(-1(.5)3)) xlab(-1(.5)3) ///
	ylab(1(1)6, valuelabel angle(horizontal))
graph save "Coefplot_DDD_20210901_Slides", replace
graph export "Coefplot_DDD_20210901_Slides.pdf", replace as(pdf)
********************************************************************************
