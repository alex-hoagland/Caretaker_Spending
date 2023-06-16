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
use "$mydata/Model/EquilibriumData.dta", clear 

gen todrop = missing(pay_sim) | missing(tot_pay) 
bysort famid: ereplace todrop = max(todrop) 
drop if todrop == 1

// drop any families with acute events or multiple events
gen eventyr = year if ind_chronic_event == 1 | ind_acuteevent == 1
bysort famid: egen todrop1 = min(eventyr) 
bysort famid: egen todrop2 = max(eventyr) 
drop if todrop1 != todrop2 & !missing(todrop1) & !missing(todrop2) 
drop todrop1 todrop2

// time series for spillover spending
replace eventyr = year if ind_chronic_event == 1
bysort famid: ereplace eventyr = min(eventyr) 
bysort enrolid: ereplace todrop = max(ind_chronic_event)
bysort famid: egen tokeep = max(todrop) 
keep if tokeep == 1 & todrop == 0 // keep affected family members
gen relyr = year - eventyr
drop if abs(relyr) > 3

gcollapse (sum) tot_pay pay_sim, by(famid relyr) fast // family level 
replace tot_pay = asinh(tot_pay) 
replace pay_sim = asinh(pay_sim) 

gcollapse (mean) mean_1=tot_pay mean_2=pay_sim ///
		  (sd) sd_1=tot_pay sd_2=pay_sim ///
		  (count) n_1=tot_pay n_2=pay_sim, ///
	by(relyr) fast
	
gen se_1 = sd_1/sqrt(n_1) 
gen lb_1 = mean_1-1.96*se_1
gen ub_1 = mean_1+1.96*se_1

gen se_2 = sd_2/sqrt(n_2) 
gen lb_2 = mean_2-1.96*se_2
gen ub_2 = mean_2+1.96*se_2

twoway (line mean_1 relyr, color(navy%80)) (scatter mean_1 relyr, color(navy)) ///
       (rcap lb_1 ub_1 relyr, lpattern(dash) lcolor(ebblue%30) fcolor(ebblue%20)) ///
	   (line mean_2 relyr, color(maroon%80)) (scatter mean_2 relyr, color(maroon)) ///
       (rcap lb_2 ub_2 relyr, lpattern(dash) lcolor(maroon%30) fcolor(maroon%20)), ///
       	graphregion(color(white)) legend(off) ///
	xline(-0.25, lpattern(dash) lcolor(gs8)) ///
	xsc(r(-3(1)3)) xlab(-3(1)3, gstyle(dot) glcolor(white)) ///
	ylab(,angle(horizontal) glcolor(ebg)) ///
	xtitle("Years Around Diagnosis") ///
	legend(on) legend(order(1 "Observed" 4 "Predicted")) legend(size(small)) 
graph save "$myouts/Model/ModelFit_TotPay.gph", replace
graph export "$myouts/Model/ModelFit_TotPay.pdf", replace
********************************************************************************


***** 2. Regressions for preventive visits (#) 
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
keep if tokeep == 1 & todrop == 0 // keep affected family members
gen relyr = year - eventyr
drop if abs(relyr) > 3

gcollapse (mean) mean_1=simple_visits mean_2=sample_sstar ///
		  (sd) sd_1=simple_visits sd_2=sample_sstar ///
		  (count) n_1=simple_visits n_2=sample_sstar, ///
	by(relyr) fast
	
gen se_1 = sd_1/sqrt(n_1) 
gen lb_1 = mean_1-1.96*se_1
gen ub_1 = mean_1+1.96*se_1

gen se_2 = sd_2/sqrt(n_2) 
gen lb_2 = mean_2-1.96*se_2
gen ub_2 = mean_2+1.96*se_2

twoway (line mean_1 relyr, color(navy%80)) (scatter mean_1 relyr, color(navy)) ///
       (rcap lb_1 ub_1 relyr, lpattern(dash) lcolor(ebblue%30) fcolor(ebblue%20)) ///
	   (line mean_2 relyr, color(maroon%80)) (scatter mean_2 relyr, color(maroon)) ///
       (rcap lb_2 ub_2 relyr, lpattern(dash) lcolor(maroon%30) fcolor(maroon%20)), ///
       	graphregion(color(white)) legend(off) ///
	xline(-0.25, lpattern(dash) lcolor(gs8)) ///
	xsc(r(-3(1)3)) xlab(-3(1)3, gstyle(dot) glcolor(white)) ///
	ylab(,angle(horizontal) glcolor(ebg)) ///
	legend(on) legend(order(1 "Observed" 4 "Predicted")) legend(size(small)) ///
	xtitle("Years Around Diagnosis") 
graph save "$myouts/Model/ModelFit_PrevVisits.gph", replace
graph export "$myouts/Model/ModelFit_PrevVisits.pdf", replace
********************************************************************************


***** 3. Distribution of Beliefs
cap graph drop * 
use "$mydata/Model/EquilibriumData.dta", clear 

gen todrop = missing(pred_beliefs)
bysort famid: ereplace todrop = max(todrop) 
drop if todrop == 1

// drop any families with acute events or multiple events
// gen eventyr = year if ind_chronic_event == 1 | ind_acuteevent == 1
// bysort famid: egen todrop1 = min(eventyr) 
// bysort famid: egen todrop2 = max(eventyr) 
// drop if todrop1 != todrop2 & !missing(todrop1) & !missing(todrop2) 
// drop todrop1 todrop2

// time series
gen eventyr = year if ind_chronic_event == 1
bysort famid: ereplace eventyr = min(eventyr) 
bysort enrolid: ereplace todrop = max(ind_chronic_event)
bysort famid: egen tokeep = max(todrop) 
keep if tokeep == 1 & todrop == 0 // keep affected family members
gen relyr = year - eventyr
drop if abs(relyr) > 4

gcollapse (mean) mean_1=pred_beliefs (p50) p50=pred_beliefs ///
			(p25) p25=pred_beliefs (p75) p75=pred_beliefs ///
		  (sd) sd_1=pred_beliefs ///
		  (count) n_1=pred_beliefs, ///
	by(relyr) fast
gen se = sd/sqrt(n_1)
gen lb = mean_1-se*1.96
gen ub = mean_1+se*1.96

// Add in interval for ex-post conditional risk 
gen z1 = 0.041 if relyr >= 0
gen z2 = 0.069 if relyr >= 0

twoway  (scatter mean relyr, color(navy)) ///
		(rcap lb ub relyr, color(navy%50) lpattern(dash)) ///
		(line mean relyr, color(navy)) ///
		(scatter p50 relyr, color(ebblue)) /// 
		(line p50 relyr, color(ebblue)) ///
		(rarea z1 z2 relyr, color(orange%35)), /// 
       	graphregion(color(white)) legend(off) ///
	xline(-0.25, lpattern(dash) lcolor(gs8)) ///
	xsc(r(-4(1)4)) xlab(-4(1)4, gstyle(dot) glcolor(white)) ///
	ylab(,angle(horizontal) glcolor(ebg)) ///
	xtitle("Years Around Diagnosis") /// 
	yline(.027, lpattern(dash) lcolor(green)) ///
	legend(on) legend(order(3 "Mean" 5 "Median")) legend(size(small)) ///
	text(0.056 2 "Conditional ex-post risk, Type 1 Diabetes",  size(small))
graph save "$myouts/Model/ModelFit_Beliefs.gph", replace
graph export "$myouts/Model/ModelFit_Beliefs.pdf", replace
********************************************************************************
