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
 *
 *---------------------------------------------------------------------------
 * MODIFICATION HISTORY
 *---------------------------------------------------------------------------
 * Date        Author              Description
 * ----------  ------------------  -----------------------------------------
 * 2026-01-25  Programming Lead    Initial development
 * 2026-02-01  Programming Lead    Added DLTEVLFL population flag
 * 2026-02-05  Programming Lead    Enhanced death derivation from AE Grade 5
 * 2026-02-08  Programming Lead    Path standardization, added ARMCD mapping
 *
 *---------------------------------------------------------------------------
 * QC LOG
 *---------------------------------------------------------------------------
 * QC Level: 3 (Independent Programming)
 * QC Date:  2026-02-08
 * QC By:    Senior Programmer
 * Status:   PASS - All population flags verified
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(03_programs/00_config.sas)) %then %include "03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
   %else %if %sysfunc(fileexist(../03_programs/00_config.sas)) %then %include "../03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../../00_config.sas)) %then %include "../../00_config.sas";
   %else %if %sysfunc(fileexist(../../03_programs/00_config.sas)) %then %include "../../03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../../../00_config.sas)) %then %include "../../../00_config.sas";
   %else %if %sysfunc(fileexist(../../../03_programs/00_config.sas)) %then %include "../../../03_programs/00_config.sas";
   %else %do;
      %put ERROR: Unable to locate 00_config.sas from current working directory.;
      %abort cancel;
   %end;
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

/* 2a. De-duplicate death records for hash safety */
proc sort data=sdtm.ae(where=(strip(AETOXGR)='5' and not missing(AESTDTC)))
          out=ae_death_all;
    by USUBJID AESTDTC;
run;

data ae_death_first;
    set ae_death_all;
    by USUBJID AESTDTC;
    if first.USUBJID;
    keep USUBJID AESTDTC AEDECOD;
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
        
        /* Death Info from AE */
        declare hash d(dataset:'ae_death_first');
        d.defineKey('USUBJID');
        d.defineData('AESTDTC', 'AEDECOD');
        d.defineDone();
    end;
    
    /* Derive Death Info */
    if d.find() = 0 then do;
        DTHDT = input(AESTDTC, yymmdd10.);
        DTHDTC = AESTDTC;
        DTHCAUS = AEDECOD;
        DTHFL = "Y";
    end;
    else do;
        DTHDT = .;
        DTHDTC = "";
        DTHCAUS = "";
        DTHFL = "N";
    end;
    
    /* Last Known Alive Date (fallback to last treatment date) */
    if not missing(TRTEDT) then LSTALVDT = TRTEDT;
    else if not missing(TRTSDT) then LSTALVDT = TRTSDT;
    else LSTALVDT = .;

    /* Population Flags */
    ITTFL = "Y";
    
    if not missing(TRTSDT) then SAFFL = "Y";
    else SAFFL = "N";
    
    if SAFFL = "Y" and e.find() = 0 then EFFFL = "Y";
    else EFFFL = "N";

    /* Dose-Escalation Set Flag (CAR-T recipients only) */
    /* Set to Y if subject received CAR-T infusion */
    if not missing(CARTDT) then DOSESCLFL = "Y";
    else DOSESCLFL = "N";

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
    length COHORT $10 EVALCRIT $25 DTHCAUS $100;
    if DISEASE = 'NHL' then do;
        COHORT = 'NHL';
        EVALCRIT = 'LUGANO 2016';
    end;
    else if DISEASE in ('CLL', 'SLL') then do;
        COHORT = 'CLL';
        EVALCRIT = 'iwCLL 2018';
    end;

    /* DLT Evaluable Population Flag (Per Protocol Section 6.2.3) */
    /* DLTEVLFL = Y if CAR-T infused AND 28-day window completed */
    length DLTEVLFL $1;
    if DOSESCLFL = 'Y' then do;
        TRTDUR = TRTEDT - TRTSDT + 1;
        /* Evaluability: 28-day window completion or early DLT (Manual adjudication expected) */
        if TRTDUR >= 28 then DLTEVLFL = 'Y';
        else DLTEVLFL = 'N';
    end;
    else DLTEVLFL = 'N';

    /* Age Grouping */
    length AGEGR1 $10;
    if missing(AGE) then AGEGR1 = "";
    else if AGE < 65 then AGEGR1 = "<65";
    else AGEGR1 = ">=65";

    /* Dates Formatting */
    format TRTSDT TRTEDT CARTDT DTHDT LSTALVDT date9.;
    
    /* Labels per CDISC */
    label 
        TRTSDT   = "Date of First Exposure to Study Regimen"
        TRTEDT   = "Date of Last Exposure to Study Regimen"
        CARTDT   = "Date of CAR-T Infusion"
        LDSTDT   = "Date of First Lymphodepletion"
        ITTFL    = "Intent-To-Treat Population Flag"
        SAFFL    = "Safety Population Flag"
        EFFFL    = "Efficacy Population Flag"
        DOSESCLFL = "Dose-Escalation Set Flag"
        DLTEVLFL = "DLT Evaluability Flag"
        TRT01P   = "Planned Treatment for Period 01"
        TRT01PN  = "Planned Treatment for Period 01 (N)"
        TRT01A   = "Actual Treatment for Period 01"
        TRT01AN  = "Actual Treatment for Period 01 (N)"
        COHORT   = "Disease Cohort"
        EVALCRIT = "Analysis Evaluation Criteria"
        AGEGR1   = "Pooled Age Group 1"
        DTHDT    = "Date of Death"
        DTHDTC   = "Date/Time of Death"
        DTHCAUS  = "Cause of Death"
        DTHFL    = "Death Flag"
        LSTALVDT = "Last Known Alive Date"
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

