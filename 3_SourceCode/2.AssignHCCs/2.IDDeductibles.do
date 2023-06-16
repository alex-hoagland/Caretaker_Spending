use "2_Data\2.PlanChoices\allfirms_switches.dta", clear
keep if year > 2012 // Keeping those with BPD files
keep famid newplan year

*** Go to PBD files
merge 1:m famid year using "2_Data\2.PlanChoices\AllFirms_PlanBenefitDesign", ///
	keep(3) nogenerate

*** Calculate family deductible as mode of nonmissing info w/in newplan year
drop if missing(newplan)
sort newplan year
by newplan year: egen plan_famded = mode(deduct_fam), maxmode
by newplan year: egen plan_indded = mode(deduct_ind), maxmode
by newplan year: egen plan_famoopmax = mode(oop_max_fam), maxmode
by newplan year: egen plan_indoopmax = mode(oop_max_ind), maxmode

drop plan_beg_dt plan_end_dt
collapse (first) plan_*, by(newplan year)
bysort newplan (year): carryforward plan_*, replace
do 3_SourceCode/Inflation.do "plan_*"
save "2_Data\2.PlanChoices\newplans_deductibles", replace

***** Merge into main file, flag which switches are to lower deductibles
merge 1:m newplan year using "2_Data\1.Spending\allfirms_HCCcollapsed", keep(2 3) nogenerate
sort firm famid enrolid year
order firm famid enrolid year newplan switch
drop if firm == 6 | firm == 28
keep if year > 2012

gen switch_ld = 0 if !missing(switch)
bysort firm famid enrolid (year): replace switch_ld = 1 if ///
	switch_ld == 0 & switch == 1 & plan_famded[_n] < plan_famded[_n-1] & ///
	!missing(plan_famded[_n]) & !missing(plan_famded[_n-1])
bysort firm famid enrolid (year): replace switch_ld = . if _n == 1

save "2_Data/1.Spending/allfirms_lowerdeduct", replace
