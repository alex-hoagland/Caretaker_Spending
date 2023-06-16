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
local files: dir . files "DDD_Results_ParentChild*"
foreach f of local files { 
	append using `f'
}
replace var = "simple_DD" if var == "on"
replace var = "simple_DDD" if var == "on2"
drop if diagnosis == "ht_diabetes"
********************************************************************************


***** 2. identify significance
gen lb95 = coef-1.96*stderr
gen ub95 = coef+1.96*stderr
********************************************************************************


***** 3. Make both panels
replace diagnosis = "Cancer" if diagnosis == "cancer"
replace diagnosis = "Cholesterol" if diagnosis == "cholesterol" 
replace diagnosis = "Depression" if diagnosis == "depression"
replace diagnosis = "Diabetes" if diagnosis == "diabetes"
replace diagnosis = "Hypertension" if diagnosis == "hypertension"
replace diagnosis = "Obesity" if diagnosis == "obesity"
// replace diagnosis = "Hypertension Diagnosis" if diagnosis == "ht_diabetes"

gen j = 0
replace j = 6 if diagnosis == "Hypertension"
replace j = 4 if diagnosis == "Diabetes"
replace j = 3 if diagnosis == "Cholesterol"
replace j =2 if diagnosis == "Obesity"
replace j = 5 if diagnosis == "Cancer"
replace j = 1 if diagnosis == "Depression"

labmask j, values(diagnosis)
gen group = strpos(var, "DDD")
replace group = 1 if group > 0

// for slides
keep if group == 1
twoway (rbar lb ub j , horizontal barwidth(.05) color(ebblue%70) ) (scatter j coef, color(maroon) ), ///
	xline(0, lpattern(dash) lcolor(red)) graphregion(color(white)) ///
	legend(off) xtitle("Coefficient (percentage points)") ytitle("") ///
	xsc(r(-5(1)10)) xlab(-5(1)10) ///
	ylab(1(1)6, valuelabel angle(horizontal))
graph save "Coefplot_DDD_20210901_ParentChild_Slides", replace
graph export "Coefplot_DDD_20210901_ParentChild_Slides.pdf", replace as(pdf)
********************************************************************************
