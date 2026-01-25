/******************************************************************************
 * Program:      debug_data_dump.sas
 * Purpose:      Verify raw data content and import success
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

/* 1. Peek inside the raw CSV file on disk */
data _null_;
   infile "&LEGACY_PATH/raw_dm.csv" obs=5;
   input;
   put _infile_;
run;

/* 2. Attempt a simplified re-import */
proc import datafile="&LEGACY_PATH/raw_dm.csv"
    out=test_dm
    dbms=csv
    replace;
    getnames=yes;
run;

/* 3. Check what got created */
proc contents data=test_dm; run;
proc print data=test_dm(obs=10); 
    title "Check: Is test_dm empty?";
run;

/* 4. Check the permanent SDTM library */
proc contents data=sdtm.dm; run;
proc print data=sdtm.dm(obs=10);
    title "Check: Is sdtm.dm empty?";
run;
