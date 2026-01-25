/******************************************************************************
 * Program:      audit_environment.sas
 * Purpose:      Audit physical file structure and macro variables
 ******************************************************************************/

%macro load_config;
   %if %symexist(_SASPROGRAMFILE) %then %do;
      %let path = %sysfunc(prxchange(s/(.*)[\/\\].*$/$1/, 1, &_SASPROGRAMFILE));
      %if %sysfunc(fileexist(&path/00_config.sas)) %then %include "&path/00_config.sas";
      %else %if %sysfunc(fileexist(&path/../00_config.sas)) %then %include "&path/../00_config.sas";
   %end;
   %else %include "00_config.sas";
%mend;
%load_config;

%put --- AUDIT REPORT ---;
%put NOTE: PROJ_ROOT   = &PROJ_ROOT;
%put NOTE: LEGACY_PATH = &LEGACY_PATH;
%put NOTE: SDTM_PATH   = &SDTM_PATH;
%put NOTE: ADAM_PATH   = &ADAM_PATH;

%put NOTE: Checking for Raw Data Files:;
%let rc1 = %sysfunc(fileexist(&LEGACY_PATH/raw_dm.csv));
%let rc2 = %sysfunc(fileexist(&LEGACY_PATH/raw_ae.csv));
%put NOTE: raw_dm.csv exists: &rc1 (1=Yes, 0=No);
%put NOTE: raw_ae.csv exists: &rc2;

%put NOTE: Checking for SAS Datasets:;
%let rc3 = %sysfunc(fileexist(&SDTM_PATH/dm.sas7bdat));
%put NOTE: dm.sas7bdat exists: &rc3;

proc datasets lib=raw nolist; quit;
proc datasets lib=sdtm nolist; quit;
proc datasets lib=adam nolist; quit;

%put --- END AUDIT ---;
