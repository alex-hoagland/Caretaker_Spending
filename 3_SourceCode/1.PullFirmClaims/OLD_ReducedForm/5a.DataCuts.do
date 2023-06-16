cd /project/caretaking

* Cut 1: All office visits
use AllFamilies_Prevention.dta, clear
keep if svc_ov == 1
gen oop = cob + coi + cop + ded 

keep oop pay enrolid famid year
collapse (sum) oop pay, by(enrolid famid year) fast
compress
save "AllFamilies_OfficeVisits.dta", replace


* Cut 2: All non-preventive OV's
use AllFamilies_Prevention.dta, clear
keep if svc_ov == 1 
drop svc_ov svc_any
egen test = rowtotal(svc_*)
drop if test == 1 // any preventive service included in the OV
gen oop = cob + coi + cop + ded 

keep oop pay enrolid famid year
collapse (sum) oop pay, by(enrolid famid year) fast
compress
save "AllFamilies_NonPrev_OfficeVisits.dta", replace


* Cut 3: All prevention
use AllFamilies_Prevention.dta, clear
drop svc_ov svc_any
egen test = rowtotal(svc_*)
keep if test >= 1 // any preventive service 
gen oop = cob + coi + cop + ded 

keep oop pay enrolid famid year
collapse (sum) oop pay, by(enrolid famid year) fast
compress
save "AllFamilies_PreventiveServices.dta", replace


* Cut 4: HCC-specific prevention (add later)