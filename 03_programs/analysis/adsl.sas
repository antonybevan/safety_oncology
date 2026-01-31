/******************************************************************************
 * Program:      adsl.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create ADaM Subject Level Analysis Dataset (ADSL)
 * Author:       Clinical Programming Lead
 * Date:         2026-01-25
 * SAS Version:  9.4
 * ADaM Version: 2.1 / IG v1.3
 *
 * Input:        sdtm.dm, sdtm.ex, sdtm.rs
 * Output:       adam.adsl.xpt
 ******************************************************************************/

%macro load_config;
   /* 1. Try to find config in the same directory as this script (SAS Studio only) */
   %if %symexist(_SASPROGRAMFILE) %then %do;
      %let path = %sysfunc(prxchange(s/(.*)[\/\\].*$/$1/, 1, &_SASPROGRAMFILE));
      %if %sysfunc(fileexist(&path/00_config.sas)) %then %include "&path/00_config.sas";
      %else %if %sysfunc(fileexist(&path/../00_config.sas)) %then %include "&path/../00_config.sas";
   %end;
   /* 2. Fallback to relative paths for local PC / Batch mode */
   %else %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
   %else %if %sysfunc(fileexist(../../03_programs/00_config.sas)) %then %include "../../03_programs/00_config.sas";
   %else %put ERROR: Could not find 00_config.sas;
%mend;
%load_config;

/* 1. Get First/Last Dose from EX (Traceability) */
proc sort data=sdtm.ex out=ex_sorted;
    by USUBJID EXSTDTC;
    where upcase(EXTRT) = 'BV-CAR20';
run;

data car_dates;
    set ex_sorted;
    by USUBJID;
    
    retain TRTSDT TRTEDT;
    format TRTSDT TRTEDT date9.;
    
    if first.USUBJID then do;
        TRTSDT = input(EXSTDTC, yymmdd10.);
    end;
    
    if last.USUBJID then do;
        TRTEDT = input(EXENDTC, yymmdd10.);
        output;
    end;
    
    keep USUBJID TRTSDT TRTEDT;
run;

/* 2. Check for Efficacy Assessments in RS */
proc sort data=sdtm.rs out=rs_subj(keep=USUBJID) nodupkey;
    by USUBJID;
run;

/* 3. Build ADSL */
data adsl;
    set sdtm.dm;
    
    /* Merge in dates */
    if _n_ = 1 then do;
        declare hash h(dataset:'car_dates');
        h.defineKey('USUBJID');
        h.defineData('TRTSDT', 'TRTEDT');
        h.defineDone();
    end;
    
    if h.find() ne 0 then do;
        TRTSDT = .;
        TRTEDT = .;
    end;

    /* Merge in Efficacy Flag */
    if _n_ = 1 then do;
        declare hash e(dataset:'rs_subj');
        e.defineKey('USUBJID');
        e.defineDone();
    end;
    
    /* Population Flags */
    ITTFL = "Y";
    
    if not missing(TRTSDT) then SAFFL = "Y";
    else SAFFL = "N";
    
    if SAFFL = "Y" and e.find() = 0 then EFFFL = "Y";
    else EFFFL = "N";

    /* Analysis Treatments per ADaM IG */
    length TRT01P TRT01A $40;
    TRT01P = ARM;
    TRT01A = ARM; /* Fallback to ARM since ACTARM is missing in simulation */
    
    /* Numeric Analysis Treatments based on ARMCD */
    if ARMCD = 'DL1' then TRT01PN = 1;
    else if ARMCD = 'DL2' then TRT01PN = 2;
    else if ARMCD = 'DL3' then TRT01PN = 3;
    
    TRT01AN = TRT01PN;

    /* Age Grouping */
    length AGEGR1 $10;
    if missing(AGE) then AGEGR1 = "";
    else if AGE < 65 then AGEGR1 = "<65";
    else AGEGR1 = ">=65";

    /* Dates Formatting */
    format TRTSDT TRTEDT date9.;
    
    /* Labels per CDISC */
    label 
        TRTSDT   = "Date of First Exposure to Study Drug"
        TRTEDT   = "Date of Last Exposure to Study Drug"
        ITTFL    = "Intent-To-Treat Population Flag"
        SAFFL    = "Safety Population Flag"
        EFFFL    = "Efficacy Population Flag"
        TRT01P   = "Planned Treatment for Period 01"
        TRT01PN  = "Planned Treatment for Period 01 (N)"
        TRT01A   = "Actual Treatment for Period 01"
        TRT01AN  = "Actual Treatment for Period 01 (N)"
        AGEGR1   = "Pooled Age Group 1"
    ;
    
run;

/* Create permanent SAS dataset for other ADaM use */
data adam.adsl;
    set adsl;
run;

/* 4. Export to XPT - Drop non-standard variables for V6 compatibility */
libname xpt xport "&ADAM_PATH/adsl.xpt";
data xpt.adsl;
    set adsl(drop=dose_level subid dt i);
run;
libname xpt clear;

proc print data=adsl(obs=10);
    title "ADaM ADSL - First 10 Subjects";
run;
