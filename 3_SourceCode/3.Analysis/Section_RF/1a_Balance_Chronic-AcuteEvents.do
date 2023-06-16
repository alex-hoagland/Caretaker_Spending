/*******************************************************************************
* Title: Show balance across chronic and acute events
* Created by: Alex Hoagland
* Created on: 6/15/2023
* Last modified on: 
* Last modified by: 
* Purpose: 
			
* Notes: 
			
* Key edits: 

*******************************************************************************/

***** Loop through data to collect measures
local myvalues `" "chronic_event" "acuteevent" "'
foreach 1 of local myvalues {
	di "***** LOOPING THROUGH `1' EVENTS *****"
	***** 0. Load Data
	use "$mydata/allfirms_HCCcollapsed.dta", clear
	
	// keep only relevant sample (3 years around dx)
	gen tokeep = (`1' == 1) 
	gen keepyear = year if tokeep == 1
	bysort enrolid: ereplace keepyear = min(keepyear) // just keep affected enrollees, not households
	drop if missing(keepyear) // drops control households
	keep if inrange(year, keepyear-1,keepyear+1)

	// For acute events, only look at post years if another acute event hasn't occurred
	if ("`test'" == "acuteevent") {  
		gen test = year if acuteevent == 1
		bysort famid: egen first_ac = min(test) 
		replace test = . if test == first_ac
		bysort famid: egen second_ac = min(test)
		drop if !missing(second_ac) & year >= second_ac	
		// drop household years after/including second acute event
		drop test
	} 
	
	// merge in additional outcomes
	merge 1:1 enrolid year using "$mydata/Robustness-AER/testing_20230615_dxdates.dta", keep(1 3) nogenerate
	********************************************************************************

	***** 2. Relevant variables 
	// diagnostic cost/OOP 
	qui sum dxday_total if `1' == 1 & dxday_total > 0
	global dxday_total_`1': di %6.2fc `r(mean)'
	global dxday_total_`1'sd: di %6.2fc `r(sd)' 
	qui sum dxday_oop if `1' == 1 & dxday_total > 0
	global dxday_oop_`1': di %6.2fc `r(mean)'
	global dxday_oop_`1'sd: di %6.2fc `r(sd)'

	// % hospitalized
	qui replace anyhosp = anyhosp * 100 if !missing(anyhosp) 
	qui sum anyhosp if `1' == 1 
	global anyhosp_`1': di %6.2fc `r(mean)'
	global anyhosp_`1'sd: di %6.2fc `r(sd)'

	// LOS/hospitalization
	qui sum cond_los if `1' == 1
	global los_`1': di %6.2fc `r(mean)'
	global los_`1'sd: di %6.2fc `r(sd)'

	// Yearly spending: t - 1
	qui sum tot_pay if year == keepyear - 1
	global spend_tminus1_`1': di %6.2fc `r(mean)'
	global spend_tminus1_`1'sd: di %6.2fc `r(sd)' 
	qui sum tot_oop if year == keepyear - 1
	global oop_tminus1_`1': di %6.2fc `r(mean)'
	global oop_tminus1_`1'sd: di %6.2fc `r(sd)'

	// Yearly spending: t
	qui sum tot_pay if year == keepyear
	global spend_t_`1': di %6.2fc `r(mean)'
	global spend_t_`1'sd: di %6.2fc `r(sd)'
	qui sum tot_oop if year == keepyear 
	global oop_t_`1': di %6.2fc `r(mean)'
	global oop_t_`1'sd: di %6.2fc `r(sd)'

	// Yearly spending: t + 1
	qui sum tot_pay if year == keepyear + 1
	global spend_tplus1_`1': di %6.2fc `r(mean)'
	global spend_tplus1_`1'sd: di %6.2fc `r(sd)'
	qui sum tot_oop if year == keepyear + 1
	global oop_tplus1_`1': di %6.2fc `r(mean)'
	global oop_tplus1_`1'sd: di %6.2fc `r(sd)'

	// N 
	preserve
	gcollapse (mean) pay*, by(enrolid) fast
	global n_`1': di %9.0fc _N
	restore
	
}
********************************************************************************

***** 3. Construct table 
texdoc init "$myouts/Balance_Chronic-AcuteEvents_Table.tex", replace force
tex \begin{table}[H]
tex \begin{tabular}{l|cc}
tex \toprule
tex & \multicolumn{1}{c}{Chronic Diagnoses} & \multicolumn{1}{c}{Acute Diagnoses} 
tex \midrule
tex Diagnostic Cost (Total) & ${dxday_total_chronic_event} & ${dxday_total_acuteevent} \\
tex   & (${dxday_total_chronic_eventsd}) & (${dxday_total_acuteeventsd}) \\
tex Diagnostic Cost (OOP) & ${dxday_oop_chronic_event} & ${dxday_oop_acuteevent} \\
tex   & (${dxday_oop_chronic_eventsd}) & (${dxday_oop_acuteeventsd}) \\
tex \% Hospitalized & ${anyhosp_chronic_event} & ${anyhosp_acuteevent} \\
tex & (${anyhosp_chronic_eventsd}) & (${anyhosp_acuteeventsd}) \\ 
tex Conditional Average LOS & ${los_chronic_event} & ${los_acuteevent} \\
tex   & (${los_chronic_eventsd}) & (${los_acuteeventsd}) \\
tex Yearly Spending, $t-1$ (Total) & ${spend_tminus1_chronic_event} & ${spend_tminus1_acuteevent} \\
tex  & ${spend_tminus1_chronic_eventsd} & ${spend_tminus1_acuteeventsd} \\
tex Yearly Spending, $t$ (Total) & ${spend_t_chronic_event} & ${spend_t_acuteevent} \\
tex  & ${spend_t_chronic_eventsd} & ${spend_t_acuteeventsd} \\
tex Yearly Spending, $t+1$ (Total) & ${spend_tplus1_chronic_event} & ${spend_tplus1_acuteevent} \\
tex  & ${spend_tplus1_chronic_eventsd} & ${spend_tplus1_acuteeventsd} \\
tex Yearly Spending, $t-1$ (OOP) & ${oop_tminus1_chronic_event} & ${oop_tminus1_acuteevent} \\
tex  & ${oop_tminus1_chronic_eventsd} & ${oop_tminus1_acuteeventsd} \\
tex Yearly Spending, $t$ (OOP) & ${oop_t_chronic_event} & ${oop_t_acuteevent} \\
tex  & ${oop_t_chronic_eventsd} & ${oop_t_acuteeventsd} \\
tex Yearly Spending, $t+1$ (OOP) & ${oop_tplus1_chronic_event} & ${oop_tplus1_acuteevent} \\
tex  & ${oop_tplus1_chronic_eventsd} & ${oop_tplus1_acuteeventsd} \\
tex \midrule
tex Observations & ${n_chronic_event} & ${n_acuteevent} \\
tex \bottomrule
tex \end{tabular}
tex \end{table}
texdoc close 
********************************************************************************
