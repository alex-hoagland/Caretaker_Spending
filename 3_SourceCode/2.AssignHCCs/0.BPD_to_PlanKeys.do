* Drop flags
foreach v of var * { 
	if (strpos("`v'", "flag")) { 
		drop `v'
	} 
} 

egen todrop = rownonmiss(coins_er* coins_inp* coins_ov* copay_er* copay_inp* copay_pc* ///
	copay_sp* deduct_* oop_max*)
drop if todrop == 0 
drop todrop // drop those with no information
egen plangp = group(coins_er* coins_inp* coins_ov* copay_er* copay_inp* copay_pc* ///
	copay_sp* deduct* oop_max*), missing

drop plan_*
