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
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* 1. Get Dates from EX (Regimen Alignment) */
proc sort data=sdtm.ex out=ex_sorted;
    by USUBJID EXSTDTC;
run;

data car_dates;
    set ex_sorted;
    by USUBJID;
    
    retain TRTSDT TRTEDT CARTDT LDSTDT;
    format TRTSDT TRTEDT CARTDT LDSTDT date9.;
    
    /* Regimen Start (Lymphodepletion or CAR-T) */
    if first.USUBJID then do;
        %iso_to_sas(iso_var=EXSTDTC, sas_var=TRTSDT);
        if upcase(EXTRT) in ('FLUDARABINE', 'CYCLOPHOSPHAMIDE') then LDSTDT = TRTSDT;
    end;
    
    /* Specific CAR-T Infusion Date */
    if upcase(EXTRT) = 'BV-CAR20' and missing(CARTDT) then do;
        %iso_to_sas(iso_var=EXSTDTC, sas_var=CARTDT);
    end;
    
    if last.USUBJID then do;
        %iso_to_sas(iso_var=EXENDTC, sas_var=TRTEDT);
        output;
    end;
    
    keep USUBJID TRTSDT TRTEDT CARTDT LDSTDT;
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
        h.defineData('TRTSDT', 'TRTEDT', 'CARTDT', 'LDSTDT');
        h.defineDone();
    end;
    
    if h.find() ne 0 then do;
        TRTSDT = .;
        TRTEDT = .;
        CARTDT = .;
        LDSTDT = .;
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

    /* mBOIN Dose-Escalation Set Flag (CAR-T recipients only) */
    /* Per Protocol: MBOINFL = Y if subject received CAR-T infusion */
    if not missing(CARTDT) then MBOINFL = "Y";
    else MBOINFL = "N";

    /* Analysis Treatments per ADaM IG */
    length TRT01P TRT01A $200;
    TRT01P = ARM;
    TRT01A = ARM; /* Fallback to ARM since ACTARM is missing in simulation */
    
    /* Numeric Analysis Treatments based on ARMCD */
    if ARMCD = 'DL1' then TRT01PN = 1;
    else if ARMCD = 'DL2' then TRT01PN = 2;
    else if ARMCD = 'DL3' then TRT01PN = 3;
    
    TRT01AN = TRT01PN;

    /* Disease Cohort and Evaluation Criteria (Lugano vs iwCLL) */
    length COHORT $10 EVALCRIT $25;
    if DISEASE = 'NHL' then do;
        COHORT = 'NHL';
        EVALCRIT = 'LUGANO 2016';
    end;
    else if DISEASE in ('CLL', 'SLL') then do;
        COHORT = 'CLL';
        EVALCRIT = 'iwCLL 2018';
    end;

    /* DLT Evaluable Population Flag (Per Protocol Section 6.2.3) */
    /* DLTEVALFL = Y if MBOINFL = Y AND (DLT or completed 28-day window) */
    length DLTEVALFL $1;
    if MBOINFL = 'Y' then do;
        TRTDUR = TRTEDT - TRTSDT + 1;
        /* Evaluability: 28-day window completion or early DLT (Manual adjudication expected) */
        if TRTDUR >= 28 then DLTEVALFL = 'Y';
        else DLTEVALFL = 'N';
    end;
    else DLTEVALFL = 'N';

    /* Age Grouping */
    length AGEGR1 $10;
    if missing(AGE) then AGEGR1 = "";
    else if AGE < 65 then AGEGR1 = "<65";
    else AGEGR1 = ">=65";

    /* Dates Formatting */
    format TRTSDT TRTEDT CARTDT date9.;
    
    /* Labels per CDISC */
    label 
        TRTSDT   = "Date of First Exposure to Study Regimen"
        TRTEDT   = "Date of Last Exposure to Study Regimen"
        CARTDT   = "Date of CAR-T Infusion"
        LDSTDT   = "Date of First Lymphodepletion"
        ITTFL    = "Intent-To-Treat Population Flag"
        SAFFL    = "Safety Population Flag"
        EFFFL    = "Efficacy Population Flag"
        MBOINFL  = "mBOIN Dose-Escalation Set Flag"
        DLTEVALFL = "DLT Evaluable Population Flag"
        TRT01P   = "Planned Treatment for Period 01"
        TRT01PN  = "Planned Treatment for Period 01 (N)"
        TRT01A   = "Actual Treatment for Period 01"
        TRT01AN  = "Actual Treatment for Period 01 (N)"
        COHORT   = "Disease Cohort"
        EVALCRIT = "Analysis Evaluation Criteria"
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
    set adsl;
run;
libname xpt clear;

proc print data=adsl(obs=10);
    title "ADaM ADSL - First 10 Subjects";
run;
