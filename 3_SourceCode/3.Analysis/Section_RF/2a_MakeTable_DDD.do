/*******************************************************************************
* Title: Make table for DDD Screening Regression Results
* Created by: Alex Hoagland
* Created on: 2/25/2021
* Last modified on: 
* Last modified by: 
* Purpose: hard codes the table for DDD screening regression results
			
* Notes: 
			
* Key edits: 

*******************************************************************************/


***** 0. Packages
*ssc install sg97_5 // frmttable
cd /project/caretaking/Outputs/DDD_Screenings/
clear
forvalues i = 1/6 {
	estimates use FamilyDDD, number(`i')
	est sto model`i'
}

* Generate variable labels
gen on2 = 0
gen on_parent = 0
gen on_spouse = 0
gen on_sibling = 0
label var on2 "Post$ _t \times$ Diagnosis$ _f$"
label var on_parent "Post$ _t \times$ Diagnosis$ _f \times$ Parent$ _j$"
label var on_spouse "Post$ _t \times$ Diagnosis$ _f \times$ Spouse$ _j$"
label var on_sibling "Post$ _t \times$ Diagnosis$ _f \times$ Sibling$ _j$"

esttab model5 model1 model2 model6 model3 model4 using Tab_ScreeningDDD.tex , b(2) se(2) ar2 label ///
	nonumbers replace ///
	mtitle("Hypertension" "Diabetes" "Cholesterol" "High BMI" "Cancer" "Depression") ///
	subs("Post$ _t \times$ Diagnosis$ _f$" "Post$ _t \times$ Diagnosis$ _f\$")
********************************************************************************

//
// ***** 1. append all data sets
// * Add in full interaction terms
// clear
// local files: dir . files "DDD_Results_Full*"
// foreach f of local files { 
// 	append using `f'
// }
// ********************************************************************************
//
//
// ***** 2. identify significance
// gen lb90 = coef-1.645*stderr
// gen ub90 = coef+1.645*stderr
// gen sig90 = !(inrange(0,lb90,ub90))
//
// gen lb95 = coef-1.96*stderr
// gen ub95 = coef+1.96*stderr
// gen sig95 = !(inrange(0,lb95,ub95))
//
// gen lb99 = coef-2.575*stderr
// gen ub99 = coef+2.575*stderr
// gen sig99 = !(inrange(0,lb99,ub99))
// drop lb* ub*
// ********************************************************************************
//
//
// ***** 3. Make matrix of coefficients/means
// * First and second columns only need to appear for certain rows
// replace mean = "" if var != "on_parent" & var != "simple_DDD"
// gen coef_DD = coef if var == "simple_DD" 
// gen se_DD = stderr if var == "simple_DD"
// bysort diagnosis: ereplace coef_DD = max(coef_DD)
// bysort diagnosis: ereplace se_DD = max(se_DD)
// replace coef_DD = . if var != "simple_DDD"
// replace se_DD = . if var != "simple_DDD"
// gen test = coef if var == "full_DD"
// gen test2 = stderr if var == "full_DD"
// bysort diagnosis: ereplace test = max(test)
// bysort diagnosis: ereplace test2 = max(test2)
// replace coef_DD = test if var == "on_parent"
// replace se_DD = test2 if var == "on_parent"
// drop test*
// drop if var == "full_DD" | var == "simple_DD"
//
// * Sort variables appropriately
// gen order = .
// replace order = 1 if diagnosis == "Diabetes"
// replace order = 2 if diagnosis == "cancer"
// replace order = 3 if diagnosis == "depression"
// replace order = 4 if diagnosis == "ht_diabetes"
// replace order = 5 if diagnosis == "cholesterol"
//
// gen order2 = . 
// replace order2 = 1 if var == "simple_DDD"
// replace order2 = 2 if var == "on_parent"
// replace order2 = 3 if var == "on_spouse"
// replace order2 = 4 if var == "on_child"
// replace order2 = 5 if var == "on_sibling"
//
// sort order order2
// destring mean, replace
//
// label var mean "Pre-DX Average"
// label var coef_DD "DD Coefficient"
// label var se_DD "DD Standard Error"
// label var coef "DDD Coefficient"
// label var stderr "DDD Standard Error"
//
// // add blank rows for row labels
// local obs = _N
// local newobs = `obs'+5
// set obs `newobs'
// gen sort = _n
//
// local newobs = _N
// local test4 = `newobs'-4
// local test3 = `newobs'-3
// local test2 = `newobs'-2
// local test1 = `newobs'-1
// replace sort = 0 in `test1'
// replace sort = 5.5 in `test2'
// replace sort = 10.5 in `test3'
// replace sort = 15.5 in `test4'
// replace sort = 20.5 in `newobs'
// sort sort
//
// gen mean_se = .
//
// * Define the matrix
// mkmat mean mean_se coef_DD se_DD coef stderr, matrix(dddout)
// ********************************************************************************
//
//
// ***** 4. Output to Tex
// frmttable using Tab_ScreeningDDD.tex, replace tex fragment statmat(dddout) varlabels substat(1) ///
// 	rtitles("Diabetes"\""\"Entire household"\""\"Parents"\""\"Spouses"\""\"Children"\""\"Siblings"\""\ ///
// 		"Cancer"\""\"Entire household"\""\"Parents"\""\"Spouses"\""\"Children"\""\"Siblings"\ ""\ ///
// 		"Depression"\""\"Entire household"\""\"Parents"\""\"Spouses"\""\"Children"\""\"Siblings"\""\ ///
// 		"Hypertension (following Diabetes)"\""\"Entire household"\""\"Parents"\""\"Spouses"\""\"Children"\""\"Siblings"\"" ///
// 		"Cholesterol"\""\"Entire household"\""\"Parents"\""\"Spouses"\""\"Children"\""\"Siblings"\"") ///
// 	hlines(11000000000001000000000001000000000001000000000001000000000001)
// ********************************************************************************
