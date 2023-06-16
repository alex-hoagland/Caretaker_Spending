/*******************************************************************************
* Title: Health Information Master
* Created by: Alex Hoagland (alexander.hoagland@utoronto.ca)
* Created on: 2020
* Last modified on: November 8, 2022
* Last modified by: 
* Purpose: This file runs all code necessary for the health information project. 
		   
* Notes: 
		
* Key edits: 
   -  
*******************************************************************************/

***** 0. Any packages to cite + directories
* ssc install ereplace
* ssc install ftools // for reghdfe
* ssc install reghdfe
* ssc install regsave
* ssc install twowayfeweights // Chaisemartin & d'Haultfoeuille
* ssc install fuzzydid
* ssc install did_multiplegt
* ssc install csdid
* ssc install drdid
* ssc install texdoc
* ssc install gtools
* ssc install stackedev
* ssc install carryforward

// Directories
global today : di %td_CYND date("$S_DATE", "DMY")
global today $today 
global mydata "C:\Users\alexh\Dropbox\Caretaker_Spending\2_Data\CodeCleaning_Data"
global mycode "C:\Users\alexh\Dropbox\Caretaker_Spending\3_SourceCode\3NEW_AllAnalyticalFiles\"
global myouts "C:\Users\alexh\Dropbox\Caretaker_Spending\4_Output\CodeCleaning_Outputs\"
clear all
set more off

// Stata scheme setup (?) 


// OLD, but useful for descriptive table creation
// global hccs 3 4 13 19 20 21 37 38 45 88 90 118 120 127 130 156 160 161 162 163
********************************************************************************


***** 1. Data cleaning

********************************************************************************


***** 2. Section 2: Data 
texdoc do "$mycode\Section_Data\SummaryTable.do" // summary stat table 

// move file that constructs table 2 to appendix: 
********************************************************************************


***** 3. Section 3: Reduced-Form Evidence
// Figure 1: Effect of chronic diagnosis on non-diagnosed household members' spending
// arguments are: (1) treatment, (2) outcome variable, (3) outcome units, (4) plan types to limit to, (5) title of graph, and (6) way to collapse across familymembers
do "$mycode\Section_RF\1_EventStudies_NewHCCs.do" "chronic_event" "tot_oop" "C_ihs" "" "ChronicEvent_OOPSpending" "sum" 
	// panel a: total oop spending

do "$mycode\Section_RF\1_EventStudies_NewHCCs.do" "chronic_event" "newprev_numvisits" "C_level" "" "ChronicEvent_PrevNumVisits" "sum" 
	// panel b (version 1): total # of wellness visits (Poisson) 

// Figure 2: Rate of diabetes screening around time of diagnosis 
	// moved to appendix B (figure B1) 

// Table 3: DDD 
	// split into two (?) 
	// do for *full* set of diagnosis --> screening pairs
	
** THINK ABOUT COLLAPSING THESE INTO ONE SECTION ** 
** Maybe a single table, with individual figures in Appendix ? **
// Figure 3: Moral Hazard
do "$mycode\Section_RF\1_EventStudies_NewHCCs.do" "chronic_event" "tot_oop" "C_ihs" "zeroded" "ChronicEvent_OOPSpending" "sum" 
	// panel a: total oop spending (zeroded)

do "$mycode\Section_RF\1_EventStudies_NewHCCs.do" "chronic_event" "newprev_numvisits" "C_level" "zeroded" "ChronicEvent_PrevNumVisits" "sum" 
	// panel b (version 1): total # of wellness visits (zeroded, Poisson) 


// Figure 4: Salience
do "$mycode\Section_RF\1_EventStudies_NewHCCs.do" "acuteevent" "tot_oop" "C_ihs" "" "AcuteEvent_OOPSpending" "sum" 
	// panel a: total oop spending

do "$mycode\Section_RF\1_EventStudies_NewHCCs.do" "acuteevent" "newprev_numvisits" "C_level" "" "AcuteEvent_PrevNumVisits" "sum" 
	// panel b (version 1): total # of wellness visits (Poisson) 
do "$mycode\Section_RF\3_CombineAcuteChronicGraphs.do"

// Figure 5: New Health Information 
	// Can I genralize this somehow? 
	
** ** 

// Table 4: Low-Value Care 

********************************************************************************


***** 4. Preparation to run model  (in R)

********************************************************************************


***** 5. Appendix codes
*** Appendix A

*** Appendix B
// Figure 1: Effect of chronic diagnosis on OWN spending
// arguments are: (1) treatment, (2) outcome variable, (3) outcome units, (4) plan types to limit to, (5) title of graph, and (6) way to collapse across familymembers
do "$mycode\Section_RF\1_EventStudies_NewHCCs.do" "chronic_event" "tot_oop" "S_ihs" "" "ChronicEvent_OOPSpending" "sum" 
	// panel a: total oop spending

do "$mycode\Section_RF\1_EventStudies_NewHCCs.do" "chronic_event" "newprev_numvisits" "S_level" "" "ChronicEvent_PrevNumVisits" "sum" 
	// panel b (version 1): total # of wellness visits (Poisson) 


*** Appendix C

*** Appendix D

*** Additional archived results

********************************************************************************
