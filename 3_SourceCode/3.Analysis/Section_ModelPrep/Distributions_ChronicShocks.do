* Sample stata code to find mean, mean + sd, and mean-sd of costs: 
* 	Control group: all diagnostic costs
* 	Treated group 1: diagnostic costs for those with speific family history
* 	Treated group 2: maintenance costs post-diagnosis
* Each of these is fit as a shifted log-normal distribution 
* Note: always drop 0 spending, since we use these for expected value when an event occurs 

// start with control group 
import delimited "$mydata/MCH_EmpiricalDistributions/AllDiagnosticCosts.csv", clear
drop if tot_pay == 0
gen cell = -9 // -9 for control group 

// Now add in cells for each specific HCC
local hccs 12 13 20 21 30 37 48 56 57 88 90 118 120 130 142 161 162 217 
foreach h of local hccs { 
	di "HCC: `h'" 
	quietly{
	preserve
	tempfile hcc_`h'
	import delimited "$mydata/MCH_EmpiricalDistributions/MCH_HCC`h'.csv", clear
	drop if tot_pay == 0
	gen cell = `h' 
	save `hcc_`h''
	restore
	append using `hcc_`h''
	} 
	}

replace dxyear = 1 if cell == -9

// now collapse by cell and create distribution parameters
gcollapse (mean) lam_bar=tot_pay (p50) lam_med=tot_pay (sd) lam_sd=tot_pay, by(cell dxyear) fast

// solve for parameters using moments
gen myvar = log((lam_sd / lam_bar)^2+1) 
	// coefficient of variation gives you estimate for variance
gen mymean = log((lam_bar-lam_med)/(exp(.5*myvar)-1))
gen myshift = (exp(.5*myvar)*lam_med-lam_bar)/(exp(.5*myvar)-1)
gen mysd = sqrt(myvar)

// Organize and save
keep cell dxyear my*
rename cell hcc
compress
saveold "$mydata/MCH_EmpiricalDistributions/LogNormalDistributions.dta", v(12) replace
