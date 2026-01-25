/******************************************************************************
 * Program:      super_repair.sas
 * Purpose:      Force data import and diagnose "Empty Dataset" issues
 ******************************************************************************/

%macro load_config;
   %if %symexist(_SASPROGRAMFILE) %then %do;
      %let path = %sysfunc(prxchange(s/(.*)[\/\\].*$/$1/, 1, &_SASPROGRAMFILE));
      %if %sysfunc(fileexist(&path/00_config.sas)) %then %include "&path/00_config.sas";
      %else %if %sysfunc(fileexist(&path/../00_config.sas)) %then %include "../00_config.sas";
   %end;
   %else %include "00_config.sas";
%mend;
%load_config;

%put --- EMERGENCY REPAIR INITIATED ---;
%put NOTE: Testing Raw File Read on &LEGACY_PATH/raw_dm.csv;

/* 1. Raw Read Test (Bypass Proc Import) */
data _null_;
   infile "&LEGACY_PATH/raw_dm.csv" lrecl=32767 truncover obs=10;
   input line $char200.;
   put "FILE CONTENT: " line;
run;

/* 2. Force Import of DM with debug logging */
proc import datafile="&LEGACY_PATH/raw_dm.csv"
    out=raw_dm_fix
    dbms=csv
    replace;
    getnames=yes;
run;

/* 3. Report Results */
proc sql noprint;
   select count(*) into :obs_count from raw_dm_fix;
quit;

%put NOTE: REPAIR STATUS: Imported &obs_count observations into raw_dm_fix;

proc print data=raw_dm_fix(obs=5);
   title "REPAIR CHECK: First 5 Records of DM";
run;

/* 4. If observations = 0, check file size again */
data _null_;
   filename ref "&LEGACY_PATH/raw_dm.csv";
   fid = fopen('ref');
   if fid > 0 then do;
      info = finfo(fid, 'File Size (bytes)');
      put "CRITICAL: Physical File Size of raw_dm.csv is " info " bytes.";
      rc = fclose(fid);
   end;
run;
