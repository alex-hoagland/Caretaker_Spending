 * Create CC from DX;
  data out.cc_long_&claimtype._&year.;
    set out.cc_long_&claimtype._&year.;

    * Keep only the ICD-10 claims (others done by Stata); 
    if DXVER = '0'; 
    cc1 = input(put(DX_ICD, $dx2CCS_1st.), 8.);
    cc2 = input(put(DX_ICD, $dx2CCS_2nd.), 8.);

    * CC wide to long;
    array c_array cc1-cc2;
    do i = 1 to dim(c_array);
      cc = c_array{i};
      if ~missing(cc) then output;
      if missing(cc) & missing(cc1) then output; *Keep mising CC only if DX did not map to CC;
    end;
    keep age sex
           /* DX1-DX4 */
          DX_ICD enrolid DXVER cc1 cc2 cc
          /* cc1-cc2 */;
  run;