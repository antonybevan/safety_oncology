/******************************************************************************
 * Program:      adlb.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create ADaM Laboratory Analysis Dataset (ADLB)
 * Author:       Clinical Programming Lead
 * Date:         2026-01-25
 * SAS Version:  9.4
 * ADaM Version: 2.1 / IG v1.3
 *
 * Input:        sdtm.lb, adam.adsl
 * Output:       adam.adlb.xpt
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* 1. Pre-Process Lab Data */
/* Convert character results to numeric for analysis */
data lb_pre;
    set sdtm.lb;
    
    /* Numeric Result */
    if not missing(LBORRES) then AVAL = input(LBORRES, ?? 8.);
    
    /* Analysis Date */
    ADT = input(LBDTC, yymmdd10.);
    format ADT date9.;
    
    /* Parameters */
    PARAMCD = LBTESTCD;
    PARAM   = LBTEST;
    AVISIT  = VISIT;
    
    keep USUBJID PARAMCD PARAM ADT AVISIT AVAL LBORNRLO LBORNRHI;
run;

/* 2. Join ADSL for Treatment Start Date */
proc sort data=lb_pre; by USUBJID; run;

data lb_adsl;
    set lb_pre;
    
    length TRT01A $200;
    if _n_ = 1 then do;
        if 0 then set adam.adsl(keep=USUBJID TRTSDT TRT01A TRT01AN ARM ARMCD);
        declare hash a(dataset:'adam.adsl');
        a.defineKey('USUBJID');
        a.defineData('TRTSDT', 'TRT01A', 'TRTAN', 'ARM', 'ARMCD');
        a.defineDone();
    end;
    
    if a.find() ne 0 then do;
        TRTSDT = .; TRT01A = ""; TRT01AN = .;
    end;
    
    /* Treatment Variables */
    TRTA = TRT01A;
    TRTAN = TRT01AN;
    
    /* Relative Day per CDISC: No Day 0 */
    if not missing(ADT) and not missing(TRTSDT) then 
        ADY = ADT - TRTSDT + (ADT >= TRTSDT);
run;

/* 3. Baseline Flagging (ABLFL) */
proc sort data=lb_adsl;
    by USUBJID PARAMCD ADT;
run;

data lb_base_flags;
    set lb_adsl;
    by USUBJID PARAMCD ADT;
    
    retain TEMP_BASE_DT;
    
    if first.PARAMCD then TEMP_BASE_DT = .;
    
    if not missing(AVAL) and not missing(TRTSDT) then do;
        if ADT <= TRTSDT then TEMP_BASE_DT = ADT;
    end;
    
    /* Check if this record is the baseline */
    if ADT = TEMP_BASE_DT then ABLFL = 'Y';
    else ABLFL = '';
    
    drop TEMP_BASE_DT;
run;

/* 4. Derive Change from Baseline & Shift */
proc sort data=lb_base_flags out=baseline_vals(keep=USUBJID PARAMCD AVAL rename=(AVAL=BASE)) nodupkey;
    by USUBJID PARAMCD;
    where ABLFL = 'Y';
run;

data adlb;
    merge lb_base_flags(in=a) baseline_vals(in=b);
    by USUBJID PARAMCD;
    if a;
    
    /* Change from Baseline */
    if not missing(AVAL) and not missing(BASE) then CHG = AVAL - BASE;
    
    /* Normal Range Logic */
    length ANRIND $10 BNRIND $10;
    
    if not missing(AVAL) and not missing(LBORNRLO) and AVAL < LBORNRLO then ANRIND = 'LOW';
    else if not missing(AVAL) and not missing(LBORNRHI) and AVAL > LBORNRHI then ANRIND = 'HIGH';
    else if not missing(AVAL) then ANRIND = 'NORMAL';
    
    if not missing(BASE) and not missing(LBORNRLO) and BASE < LBORNRLO then BNRIND = 'LOW';
    else if not missing(BASE) and not missing(LBORNRHI) and BASE > LBORNRHI then BNRIND = 'HIGH';
    else if not missing(BASE) then BNRIND = 'NORMAL';
    
    if not missing(BNRIND) and not missing(ANRIND) then 
        SHIFT1 = catx(' to ', BNRIND, ANRIND);

    /* Toxicity Grading (Bi-directional per Oncology Standards) */
    ATOXGRL = 0; ATOXGRH = 0;
    length ATOXDSCL ATOXDSCH $100;
    
    if not missing(AVAL) and not missing(LBORNRLO) and AVAL < LBORNRLO then do;
        ATOXGRL = 1; /* Analysis Toxicity Grade Low */
        if AVAL < LBORNRLO * 0.8 then ATOXGRL = 2;
        if AVAL < LBORNRLO * 0.5 then ATOXGRL = 3;
        if AVAL < LBORNRLO * 0.2 then ATOXGRL = 4;
        ATOXDSCL = strip(PARAM) || " (Low)";
    end;
    
    if not missing(AVAL) and not missing(LBORNRHI) and AVAL > LBORNRHI then do;
        ATOXGRH = 1; /* Analysis Toxicity Grade High */
        if AVAL > LBORNRHI * 1.2 then ATOXGRH = 2;
        if AVAL > LBORNRHI * 1.5 then ATOXGRH = 3;
        if AVAL > LBORNRHI * 2.0 then ATOXGRH = 4;
        ATOXDSCH = strip(PARAM) || " (High)";
    end;

    label
        ADT      = "Analysis Date"
        ADY      = "Analysis Relative Day"
        ABLFL    = "Baseline Record Flag"
        BASE     = "Baseline Value"
        CHG      = "Change from Baseline"
        ANRIND   = "Analysis Range Indicator"
        BNRIND   = "Baseline Range Indicator"
        SHIFT1   = "Shift from Baseline to Analysis"
        ATOXGRL  = "Analysis Toxicity Grade Low"
        ATOXGRH  = "Analysis Toxicity Grade High"
        ATOXDSCL = "Analysis Toxicity Description Low"
        ATOXDSCH = "Analysis Toxicity Description High"
        TRTA     = "Actual Treatment"
        TRTAN    = "Actual Treatment (N)"
    ;
run;

/* Create permanent SAS dataset */
data adam.adlb;
    set adlb;
run;

/* 5. Export to XPT */
libname xpt xport "&ADAM_PATH/adlb.xpt";
data xpt.adlb;
    set adlb(drop=LBORNRLO LBORNRHI);
run;
libname xpt clear;

proc freq data=adlb;
    tables PARAMCD * SHIFT1 / list missing;
    title "Lab Toxicity Shifts (Baseline to Post-Baseline)";
run;
