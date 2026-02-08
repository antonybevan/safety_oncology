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

/* Environment assumed to be set by 00_main.sas -> 00_config.sas */

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
    
    /* MNC Traceability Variables (CDISC ADaM IG v1.3) */
    length SRCDOM $8 SRCVAR $20;
    SRCDOM = "LB";
    SRCVAR = "LBORRES";
    SRCSEQ = LBSEQ;
    
    keep USUBJID PARAMCD PARAM ADT AVISIT AVAL LBORNRLO LBORNRHI SRCDOM SRCVAR SRCSEQ;
run;

/* 2. Join ADSL for Treatment Start Date */
proc sort data=lb_pre; by USUBJID; run;

data lb_adsl;
    set lb_pre;
    
    length TRT01A $200;
    if _n_ = 1 then do;
        if 0 then set adam.adsl(keep=USUBJID TRTSDT TRT01A TRT01AN ARM ARMCD CARTDT);
        declare hash a(dataset:'adam.adsl');
        a.defineKey('USUBJID');
        a.defineData('TRTSDT', 'TRT01A', 'TRT01AN', 'ARM', 'ARMCD', 'CARTDT');
        a.defineDone();
    end;
    
    if a.find() ne 0 then do;
        TRTSDT = .; TRT01A = ""; TRT01AN = .; CARTDT = .;
    end;
    
    /* Treatment Variables */
    TRTA = TRT01A;
    TRTAN = TRT01AN;
    
    /* Analysis Day (SAP §5.7 specialized scale: -1, 0, 2) */
    if not missing(ADT) and not missing(CARTDT) then do;
        if ADT < CARTDT then ADY = ADT - CARTDT;
        else if ADT = CARTDT then ADY = 0;
        else ADY = ADT - CARTDT + 1; /* Scales 2, 3, etc. (Omit Day 1) */
    end;
    else if not missing(ADT) and not missing(TRTSDT) then 
        ADY = ADT - TRTSDT + (ADT >= TRTSDT); /* Fallback to LD if no CAR-T */

run;

/* 3. Baseline Flagging (ABLFL) */
proc sort data=lb_adsl;
    by USUBJID PARAMCD ADT;
run;

/* Baseline = last non-missing value on/before TRTSDT */
proc sort data=lb_adsl out=lb_base_candidates;
    by USUBJID PARAMCD descending ADT;
    where not missing(AVAL) and not missing(TRTSDT) and ADT <= TRTSDT;
run;

data lb_base_records;
    set lb_base_candidates;
    by USUBJID PARAMCD descending ADT;
    if first.PARAMCD;
    BASEDT = ADT;
    BASE = AVAL;
    BTYPE = "BASELINE";
    ABLFL = "Y";
    keep USUBJID PARAMCD BASEDT BASE BTYPE ABLFL;
run;

/* 4. Final ADLB Setup */
data adam.adlb;
    set lb_adsl;
    
    /* Merge Baseline */
    if _n_ = 1 then do;
        declare hash b(dataset:'lb_base_records');
        b.defineKey('USUBJID', 'PARAMCD');
        b.defineData('BASEDT', 'BASE', 'BTYPE', 'ABLFL');
        b.defineDone();
    end;
    
    if b.find() ne 0 then do;
        BASEDT = .; BASE = .; BTYPE = ""; ABLFL = "";
    end;

    /* Change from Baseline */
    if not missing(AVAL) and not missing(BASE) then 
        CHG = AVAL - BASE;
    
    /* Toxicity Grading (CTCAE v5.0 proportionality heuristics) */
    length ATOXGRL ATOXGRH 8;
    ATOXGRL = 0; ATOXGRH = 0;
    
    if not missing(AVAL) then do;
        /* Low direction */
        if AVAL < LBORNRLO then ATOXGRL = 1;
        if AVAL < LBORNRLO * 0.8 then ATOXGRL = 2;
        if AVAL < LBORNRLO * 0.5 then ATOXGRL = 3;
        if AVAL < LBORNRLO * 0.2 then ATOXGRL = 4;
        
        /* High direction */
        if AVAL > LBORNRHI then ATOXGRH = 1;
        if AVAL > LBORNRHI * 1.2 then ATOXGRH = 2;
        if AVAL > LBORNRHI * 1.5 then ATOXGRH = 3;
        if AVAL > LBORNRHI * 2.0 then ATOXGRH = 4;
    end;
    
    /* Study Identifier */
    STUDYID = "&STUDYID";
    
    label 
        ADY = "Analysis Study Day"
        AVAL = "Analysis Value"
        BASE = "Baseline Value"
        CHG = "Change from Baseline"
        ATOXGRL = "Analysis Toxicity Grade Low"
        ATOXGRH = "Analysis Toxicity Grade High"
    ;
run;
