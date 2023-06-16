cd /project/caretaking

* First, rename files
local files: dir . files "PDC_*.dta"
foreach f of local files { 
	if length("`f'") == 28 {
		local y = substr("`f'", 5, 4)
		local t = substr("`f'", 19, 3)
		local t2 = int(`t')
		di "PDC_`y'_`t2'.dta"
		! mv "`f'" "PDC_`y'_`t2'.dta"	
	}
}

* Append files, adding var for thercls as we go
clear
gen year = . 
gen thercls = . 
local files: dir . files "PDC_*.dta"
foreach f of local files { 
	append using `f'
	local y = substr("`f'",5,4)
	replace year = `y' if missing(year)
	local t = substr("`f'",10, length("`f'")-13)
	replace thercls = `t' if missing(thercls)
	rm `f'
}

* Keep only therapeutic classes represented in every year
sort thercls year
egen id = group(thercls year)
by thercls: gen num_yrs = id[_N]-id[1]+1
keep if num_yrs == 13
drop num_yrs id // keeps 25 therapeutic classes

* Flag enrollees who start using the prescription in the middle of a year
drop end_dt
sort thercls enrolid year
gen m = 12
gen d = 31
gen endyr = mdy(m,d,year)
format endyr %td
gen diff = endyr - start_dt
replace diff = dayscovered/diff
replace diff = . if diff > 1

* If enrollees are in their first year of using the drug, and the new PDC from 
* the midyear is >= 80%, then make *that* the PDC count for the first year. 
bysort thercls enrolid (year): replace p_dc = diff if ///
	!missing(diff) & diff >= 0.8 & _n == 1
drop m-diff

* Organize data set
replace p_dc = p_dc * 100

order enrolid year thercls p_dc start dayscovered
sort enrolid year thercls
compress
save "PDC_Top25TherCls.dta"

* Create an average across classes for each enrollee-year
collapse (mean) p_dc, by(enrolid year) fast
save "PDC_Collapsed.dta"
