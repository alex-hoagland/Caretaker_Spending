***** Map from plnkeys to newplans
* note: no need to do this for PBD files, as those are not monthly

* Firm 6
replace newplan = 601 if inlist(`1', 2650,2652,2654,2655,2677,2668,2686,2699,5457,5470,5490)
replace newplan = 602 if inlist(`1', 2656,2678,2684,5450,5455,5472,5491)
replace newplan = 603 if inlist(`1', 2653,2679,2695,5451,5466)
replace newplan = 604 if inlist(`1', 2671,2682,2658,5454,5476,5477)
replace newplan = 605 if inlist(`1', 2674,2680,2659,5461,5475,5486)
replace newplan = 606 if inlist(`1', 2675,2693,2660,5464,5474,5487)
replace newplan = 607 if inlist(`1', 2676,2696,2697,5452)
replace newplan = 608 if inlist(`1', 2662,2688,2698,5459,5468,5489)
replace newplan = 609 if inlist(`1', 5488)
replace newplan = 610 if missing(newplan) & !missing(`1') & firm == 6

* Firm 22
replace newplan = 2201 if inlist(`1', 6268,6279,6281)
replace newplan = 2202 if inlist(`1', 6262,6280,6283,6269,6270)
replace newplan = 2203 if inlist(`1', 6264,6272,6285)
replace newplan = 2204 if inlist(`1', 6265,6273,6286)
replace newplan = 2205 if inlist(`1', 6271,6278,6282)
replace newplan = 2206 if missing(newplan) & !missing(`1') & firm == 22

* Firm 65
replace newplan = 6501 if inlist(`1', 6535,6537,6534,6541,6549,6546,6551,6554,6558)
replace newplan = 6502 if inlist(`1', 6536,6538,6540,6544,6543,6547,6550,6555,6552,6556)
replace newplan = 6503 if inlist(`1', 6533,6539,6542,6545,6553,6557)
replace newplan = 6504 if missing(newplan) & !missing(`1') & firm == 65
