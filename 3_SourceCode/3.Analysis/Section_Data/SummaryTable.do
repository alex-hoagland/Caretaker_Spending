/*******************************************************************************
* Title: Summary Table
* Created by: Alex Hoagland
* Last modified on: 11/8/2022
* Last modified by: 
* Purpose: Table of summary stats at household level
*
* Output: - texdoc table
* 
* Key edits: 
   -
*******************************************************************************/


***** 1. Make data + Store globals ******
// Original data + risk scores + deductibles + dx/maintenance spending
use "$mydata/allfirms_HCCcollapsed.dta", clear
merge 1:1 enrolid year using "$mydata/ACG_PredictedRiskScores", ///
	keep(1 3) nogenerate
rename rescaled_acg riskscore
merge m:1 firm plankey year using "$mydata/AllDeductibles.dta", ///
	keep(1 3) nogenerate
egen myded = rowmax(familyded indded) 
replace myded = . if myded < 0 
merge 1:1 enrolid year using "$mydata/MaintenanceCosts.dta", ///
	keep(1 3) nogenerate 
replace female = female * 100 

// Identify sub-cohorts: (1): chronic diagnosis (2): acute event year
// note: these are for diagnosed individuals only 
gen cohort = (acuteevent == 1)
replace cohort = 2 if chronic_event == 1

// Repeat this for three cohorts: full sample, those with chronic dx, and those with acute event
forvalues c = 0/2 {
	di "***** COHORT `c' ******" 
	preserve

	gen recur_oop = . // defined only for cohort > 0
	if (`c' > 0) { // keep full household-year affected by event
	    gen yr_event = year if cohort == `c'
		bysort enrolid: ereplace yr_event = min(yr_event)
		bysort enrolid: replace recur_oop = maint_oop if !missing(yr_event) & year > yr_event // for identifying recurring costs
		bysort enrolid: ereplace recur_oop = mean(recur_oop)
		cap drop tokeep
		bysort famid year: egen tokeep = max(cohort)
		keep if tokeep == `c'
	}
	
	// sample sizes  
	egen samp_ind = group(enrolid)
	qui sum samp_ind 
	global n_ind_`c': di %15.0fc `r(max)'
	egen samp_hh = group(famid)
	qui sum samp_hh
	global n_fam_`c': di %15.0fc `r(max)'

	// First, individual level globals 
	bysort enrolid (year): gen numyears = _N
	gen zero_pay = (tot_pay == 0)*100
	gen zero_oop = (tot_oop == 0)*100
	foreach v of varlist age female riskscore numyears tot_pay tot_oop ///
		zero_pay zero_oop { 
		qui sum `v' , d
		global mean_`v'_`c': di %10.2fc `r(mean)'
		global med_`v'_`c': di %10.2fc `r(p50)'
		global se_`v'_`c': di %4.3fc `r(sd)'/sqrt(`r(N)')
	}

	// collapse to family level now
	replace age = . if emprel != 1 // keep only employee age/sex
	replace fem = . if emprel != 1
	replace maint_pay = . if cohort != `c' // only keep dx cost for affected enrollees in dx year
	replace maint_oop = . if cohort != `c'
	// replace recur_oop = . if !missing(maint_oop) // just want follow-up years
	
	// make sure conditional averages aren't ruined by collapse
	gen toreplace = (!missing(maint_pay))
	
	gcollapse (mean) age_emp=age fem_emp=fem (count) famsize=enrolid ///
			(max) myded zeroded toreplace (sum) maint_* recur*, ///
		by(famid year) fast 
	foreach v of var maint_* recur_* { 
		replace `v' = . if toreplace != 1
		} 
	replace zeroded = zeroded * 100
	foreach v of varlist famsize age_emp fem_emp myded zeroded maint_pay maint_oop recur_oop { 
		qui sum `v' , d
		global mean_`v'_`c': di %10.2fc `r(mean)'
		global med_`v'_`c': di %10.2fc `r(p50)'
		global se_`v'_`c': di %4.3fc `r(sd)'/sqrt(`r(N)')
	}
	
	restore
}
********************************************************************************


***** 2. Make Table *****	
texdoc init "$myouts\Tab_SummaryStats.tex", replace 
tex \begin{table}[htbp]
tex \centering
tex \begin{threeparttable}
tex \begin{tabular}{l|ccc}
tex \toprule
tex & \multicolumn{1}{c}{Full Sample} & \multicolumn{1}{c}{Acute Events} & \multicolumn{1}{c}{Chronic Events} \\
tex \midrule
tex \multicolumn{2}{l}{\textbf{Panel A:} Household Demographics} \\
tex Family size & ${mean_famsize_0} (${se_famsize_0}) & ${mean_famsize_1} (${se_famsize_1}) & ${mean_famsize_2} (${se_famsize_2}) \\ 
tex Employee age & ${mean_age_emp_0} (${se_age_emp_0}) & ${mean_age_emp_1} (${se_age_emp_1}) & ${mean_age_emp_2} (${se_age_emp_2}) \\
tex Enrollee age & ${mean_age_0} (${se_age_0}) & ${mean_age_1} (${se_age_1}) & ${mean_age_2} (${se_age_2}) \\
tex \% female employees & ${mean_fem_emp_0} (${se_fem_emp_0}) & ${mean_fem_emp_1} (${se_fem_emp_1}) & ${mean_fem_emp_2} (${se_fem_emp_2}) \\
tex \% female enrollees & ${mean_female_0} (${se_female_0}) & ${mean_female_1} (${se_female_1}) & ${mean_female_2} (${se_female_2}) \\
tex Risk Score & ${mean_riskscore_0} (${se_riskscore_0}) & ${mean_riskscore_1} (${se_riskscore_1}) & ${mean_riskscore_2} (${se_riskscore_2}) \\
tex Years Observed &${mean_numyears_0} (${se_numyears_0}) & --- & --- \\ 
tex \midrule
tex \multicolumn{2}{l}{\textbf{Panel B:} Household Medical Utilization} \\
tex Total medical spending & \\$ ${mean_tot_pay_0} [\\$ ${med_tot_pay_0}] (${se_tot_pay_0}) & \\$ ${mean_tot_pay_1} [\\$ ${med_tot_pay_1}] (${se_tot_pay_1}) & \\$ ${mean_tot_pay_2} [\\$ ${med_tot_pay_2}] (${se_tot_pay_2}) \\
tex OOP medical spending & \\$ ${mean_tot_oop_0} [\\$ ${med_tot_oop_0}] (${se_tot_oop_0}) & \\$ ${mean_tot_oop_1} [\\$ ${med_tot_oop_1}] (${se_tot_oop_1}) & \\$ ${mean_tot_oop_2} [\\$ ${med_tot_oop_2}] (${se_tot_oop_2}) \\
tex \% enrollees w/ 0 spending & ${mean_zero_pay_0} (${se_zero_pay_0}) & ${mean_zero_pay_1} (${se_zero_pay_1}) & ${mean_zero_pay_2} (${se_zero_pay_2}) \\
tex \% enrollees w/ 0 OOP & ${mean_zero_oop_0} (${se_zero_oop_0}) & ${mean_zero_oop_1} (${se_zero_oop_1}) & ${mean_zero_oop_2} (${se_zero_oop_2}) \\
tex Household deductible & \\$ ${mean_myded_0} (${se_myded_0}) & \\$ ${mean_myded_1} (${se_myded_1})  & \\$ ${mean_myded_2} (${se_myded_2}) \\
tex \% w/ 0 deductible & ${mean_zeroded_0} (${se_zeroded_0})  & ${mean_zeroded_1} (${se_zeroded_1})  & ${mean_zeroded_2} (${se_zeroded_2}) \\
tex \midrule
tex \multicolumn{2}{l}{\textbf{Panel C:} Individual Major Medical Events} \\
tex Total cost, Diagnosis & --- & \\$ ${mean_maint_pay_1} [\\$ ${med_maint_pay_1}] (${se_maint_pay_1}) & \\$ ${mean_maint_pay_2} [\\$ ${med_maint_pay_2}] (${se_maint_pay_2}) \\
tex OOP, Diagnosis & --- & \\$ ${mean_maint_oop_1} [\\$ ${med_maint_oop_1}] (${se_maint_oop_1}) & \\$ ${mean_maint_oop_2} [\\$ ${med_maint_oop_2}] (${se_maint_oop_2}) \\
tex OOP, Recurring & --- & --- & \\$ ${mean_recur_oop_2} [\\$ ${med_recur_oop_2}] (${se_recur_oop_2}) \\
tex \midrule
tex \$N_\text{households}\$ &  ${n_fam_0} & ${n_fam_1} & ${n_fam_2} \\
tex \$N_\text{individuals}\$ & ${n_ind_0} & ${n_ind_1} & ${n_ind_2} \\
tex \bottomrule
tex \end{tabular}
tex \begin{tablenotes}
tex    \small
tex    \item \textit{Notes}: Values based on Marketscan claims data, 2006–2018. Enrollees are employees plus their covered dependents. Spending values are reported in 2020 USD. Standard errors are reported in parentheses and sample medians (when reported) are in brackets.
tex    \end{tablenotes}
tex    \caption{\label{tab:hhsum} Household Summary Statistics}
tex \end{threeparttable}
tex \end{table}
texdoc close 
********************************************************************************

