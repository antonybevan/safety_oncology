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
   %if %symexist(_SASPROGRAMFILE) %then %do;
      %let path = %sysfunc(prxchange(s/(.*)[\/\\].*$/$1/, 1, &_SASPROGRAMFILE));
      %if %sysfunc(fileexist(&path/00_config.sas)) %then %include "&path/00_config.sas";
      %else %if %sysfunc(fileexist(&path/../00_config.sas)) %then %include "&path/../00_config.sas";
   %end;
   %else %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
   %else %if %sysfunc(fileexist(../../03_programs/00_config.sas)) %then %include "../../03_programs/00_config.sas";
   %else %put ERROR: Could not find 00_config.sas;
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
    
    if _n_ = 1 then do;
        declare hash a(dataset:'adam.adsl(keep=USUBJID TRTSDT TRT01A TRT01AN)');
        a.defineKey('USUBJID');
        a.defineData('TRTSDT', 'TRT01A', 'TRT01AN');
        a.defineDone();
    end;
    
    if a.find() ne 0 then do;
        TRTSDT = .; TRT01A = ""; TRT01AN = .;
    end;
    
    /* Treatment Variables */
    TRTA = TRT01A;
    TRTAN = TRT01AN;
    
    /* Relative Day */
    if not missing(ADT) and not missing(TRTSDT) then do;
        ADY = ADT - TRTSDT;
        if ADY >= 0 then ADY = ADY + 1;
    end;
run;

/* 3. Baseline Flagging (ABLFL) */
/* Definition: Last non-missing value on or before Treatment Start */
proc sort data=lb_adsl;
    by USUBJID PARAMCD ADT;
run;

data lb_base_flags;
    set lb_adsl;
    by USUBJID PARAMCD ADT;
    
    retain TEMP_BASE_DT;
    
    if first.PARAMCD then TEMP_BASE_DT = .;
    
    if not missing(AVAL) and ADT <= TRTSDT then do;
        TEMP_BASE_DT = ADT;
    end;
    
    /* Check if this record is the baseline */
    if ADT = TEMP_BASE_DT then ABLFL = 'Y';
    else ABLFL = '';
    
    drop TEMP_BASE_DT;
run;

/* 4. Derive Change from Baseline & Shift */
/* First, get the baseline value for each parameter/subject and merge it back */
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
    
    /* Normal Range Logic (Simplified for Portfolio) */
    length ANRIND $10 BNRIND $10;
    
    /* Current Range */
    if not missing(AVAL) and not missing(LBORNRLO) and AVAL < LBORNRLO then ANRIND = 'LOW';
    else if not missing(AVAL) and not missing(LBORNRHI) and AVAL > LBORNRHI then ANRIND = 'HIGH';
    else if not missing(AVAL) then ANRIND = 'NORMAL';
    
    /* Baseline Range (Approximation: Ideally we merge actual baseline indicator, but simplified logic here) */
    /* For robust production, we'd look up the ANRIND of the ABLFL='Y' record. */
    if not missing(BASE) and not missing(LBORNRLO) and BASE < LBORNRLO then BNRIND = 'LOW';
    else if not missing(BASE) and not missing(LBORNRHI) and BASE > LBORNRHI then BNRIND = 'HIGH';
    else if not missing(BASE) then BNRIND = 'NORMAL';
    
    /* Shift Variable */
    if not missing(BNRIND) and not missing(ANRIND) then 
        SHIFT1 = catx(' to ', BNRIND, ANRIND);
        
    label
        ADT    = "Analysis Date"
        ADY    = "Analysis Relative Day"
        ABLFL  = "Baseline Record Flag"
        BASE   = "Baseline Value"
        CHG    = "Change from Baseline"
        ANRIND = "Analysis Range Indicator"
        BNRIND = "Baseline Range Indicator"
        SHIFT1 = "Shift from Baseline to Analysis"
        TRTA   = "Actual Treatment"
        TRTAN  = "Actual Treatment (N)"
    ;
run;

/* Create permanent SAS dataset */
data adam.adlb;
    set adlb;
run;

/* 5. Export to XPT */
libname xpt xport "&ADAM_PATH/adlb.xpt";
data xpt.adlb;
    set adlb;
run;
libname xpt clear;

proc freq data=adlb;
    tables PARAMCD * SHIFT1 / list missing;
    title "Lab Toxicity Shifts (Baseline to Post-Baseline)";
run;
