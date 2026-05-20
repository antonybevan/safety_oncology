/******************************************************************************
 * Program:      adlb.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create ADaM Laboratory Analysis Dataset (ADLB)
 * Author:       Statistical Programmer
 * Date:         2026-01-25
 * SAS Version:  9.4 / SAS OnDemand compatible
 * ADaM Version: 2.1 / IG v1.3
 *
 * Input:        sdtm.lb, adam.adsl
 * Output:       adam.adlb, adam.adlb.xpt
 *
 * CDISC / CTCAE Notes:
 *   - Toxicity grading per CTCAE v5.0 parameter-specific absolute limits
 *   - ATOXGR (consolidated toxicity grade) = max(ATOXGRL, ATOXGRH) for final
 *     output — grade 0 when within normal range
 *   - ABLFL: last pre-treatment non-missing value on/before TRTSDT
 *   - ADY uses CDISC two-value convention referenced to CAR-T infusion (CARTDT)
 *     with TRTSDT fallback for subjects without infusion record
 *   - DTYPE = 'BASELINE' on baseline record (ADaM IG §4.5.2)
 *   - Missing LBORRES handled via ?? modifier (no missing-note pollution)
 ******************************************************************************/

/* Environment assumed to be set by 00_main.sas -> 00_config.sas */

/* ============================================================================
   1. PRE-PROCESS LAB DATA
   ============================================================================ */
data lb_pre;
    set sdtm.lb;

    /* Numeric result with ?? to suppress conversion notes */
    if not missing(LBORRES) then AVAL = input(LBORRES, ?? best32.);

    /* Analysis Date */
    ADT = input(LBDTC, yymmdd10.);
    format ADT date9.;

    /* Parameter Mapping */
    PARAMCD = strip(LBTESTCD);
    PARAM   = strip(LBTEST);
    AVISIT  = strip(VISIT);

    /* PARCAT1 per CDISC ADLB supplement */
    if LBCAT in ('HEMATOLOGY') then PARCAT1 = 'HEMATOLOGY';
    else if LBCAT in ('CHEMISTRY') then PARCAT1 = 'CHEMISTRY';
    else PARCAT1 = strip(LBCAT);

    /* MNC Traceability Variables (CDISC ADaM IG v1.3) */
    length SRCDOM $8 SRCVAR $20;
    SRCDOM = 'LB';
    SRCVAR = 'LBORRES';
    SRCSEQ = LBSEQ;

    keep USUBJID PARAMCD PARAM PARCAT1 ADT AVISIT AVAL
         LBORNRLO LBORNRHI SRCDOM SRCVAR SRCSEQ;
run;

/* ============================================================================
   2. JOIN ADSL FOR TREATMENT DATES AND TREATMENT VARIABLES
   ============================================================================ */
data lb_adsl;
    set lb_pre;

    length TRT01A $200;
    if _n_ = 1 then do;
        if 0 then set adam.adsl(keep=USUBJID TRTSDT CARTDT TRT01A TRT01AN ARM ARMCD);
        declare hash a(dataset:'adam.adsl');
        a.defineKey('USUBJID');
        a.defineData('TRTSDT','CARTDT','TRT01A','TRT01AN','ARM','ARMCD');
        a.defineDone();
    end;

    if a.find() ne 0 then do;
        TRTSDT = .; CARTDT = .; TRT01A = ''; TRT01AN = .;
    end;

    TRTA  = TRT01A;
    TRTAN = TRT01AN;

    /* Analysis Day: primary reference = CARTDT, fallback = TRTSDT (LD)
       CDISC two-value convention — no Day 0 (baseline day = -1 or 1 depending on side) */
    if not missing(ADT) and not missing(CARTDT) then
        ADY = ADT - CARTDT + (ADT >= CARTDT);
    else if not missing(ADT) and not missing(TRTSDT) then
        ADY = ADT - TRTSDT + (ADT >= TRTSDT);

    STUDYID = "&STUDYID";
run;

/* ============================================================================
   3. BASELINE FLAGGING (ABLFL)
   Baseline = last non-missing value on or before TRTSDT per PARAMCD
   ============================================================================ */
proc sort data=lb_adsl out=lb_base_candidates;
    by USUBJID PARAMCD descending ADT;
    where not missing(AVAL) and not missing(TRTSDT) and ADT <= TRTSDT;
run;

data lb_base_records;
    set lb_base_candidates;
    by USUBJID PARAMCD;
    if first.PARAMCD; /* First after descending sort = last before TRTSDT */
    BASEDT = ADT;
    BASE   = AVAL;
    DTYPE  = 'BASELINE';
    ABLFL  = 'Y';
    keep USUBJID PARAMCD BASEDT BASE DTYPE ABLFL;
run;

/* ============================================================================
   4. FINAL ADLB — Merge Baseline, Derive CHG, PCHG, Toxicity Grade
   ============================================================================ */
data adam.adlb;
    set lb_adsl;

    /* Merge baseline record */
    if _n_ = 1 then do;
        declare hash b(dataset:'lb_base_records');
        b.defineKey('USUBJID','PARAMCD');
        b.defineData('BASEDT','BASE','DTYPE','ABLFL');
        b.defineDone();
    end;

    if b.find() ne 0 then do;
        BASEDT = .; BASE = .; DTYPE = ''; ABLFL = '';
    end;

    /* Change from Baseline */
    if not missing(AVAL) and not missing(BASE) then do;
        CHG = AVAL - BASE;
        if BASE > 0 then PCHG = (AVAL - BASE) / BASE * 100;
    end;

    /* ==========================================================================
       CTCAE v5.0 Toxicity Grading (Parameter-Specific Absolute Limits)
       Source: NCI CTCAE v5.0, CTEP, November 2017
       Units: NEUT & PLAT in 10^9/L; FERR in ng/mL
       ========================================================================== */
    ATOXGRL = 0;  /* Grade for low-direction toxicity (NEUT, PLAT) */
    ATOXGRH = 0;  /* Grade for high-direction toxicity (FERR)       */

    if not missing(AVAL) then do;
        /* ----- Neutrophils (NEUT) [10^9/L] — CTCAE v5.0 Table -----
           Grade 1: <LLN to 1.5
           Grade 2: <1.5 to 1.0
           Grade 3: <1.0 to 0.5
           Grade 4: <0.5                                                         */
        if PARAMCD = 'NEUT' then do;
            if      AVAL <  0.5                                   then ATOXGRL = 4;
            else if AVAL <  1.0                                   then ATOXGRL = 3;
            else if AVAL <  1.5                                   then ATOXGRL = 2;
            else if not missing(LBORNRLO) and AVAL < LBORNRLO    then ATOXGRL = 1;
            else                                                       ATOXGRL = 0;
        end;
        /* ----- Platelets (PLAT) [10^9/L] — CTCAE v5.0 Table -----
           Grade 1: <LLN to 75
           Grade 2: <75 to 50
           Grade 3: <50 to 25
           Grade 4: <25                                                           */
        else if PARAMCD = 'PLAT' then do;
            if      AVAL <  25                                    then ATOXGRL = 4;
            else if AVAL <  50                                    then ATOXGRL = 3;
            else if AVAL <  75                                    then ATOXGRL = 2;
            else if not missing(LBORNRLO) and AVAL < LBORNRLO    then ATOXGRL = 1;
            else                                                       ATOXGRL = 0;
        end;
        /* ----- Ferritin (FERR) [ng/mL] — HLH/MAS/CRS Criteria -----
           Grade 1: >ULN to 450
           Grade 2: >450 to 1500
           Grade 3: >1500 to 3000
           Grade 4: >3000                                                         */
        else if PARAMCD = 'FERR' then do;
            if      AVAL >  3000                                  then ATOXGRH = 4;
            else if AVAL >  1500                                  then ATOXGRH = 3;
            else if AVAL >   450                                  then ATOXGRH = 2;
            else if not missing(LBORNRHI) and AVAL > LBORNRHI    then ATOXGRH = 1;
            else                                                       ATOXGRH = 0;
        end;
    end;

    /* Consolidated ATOXGR: worst of low / high direction */
    ATOXGR = max(ATOXGRL, ATOXGRH);

    label
        ADY     = 'Analysis Study Day'
        AVAL    = 'Analysis Value'
        BASE    = 'Baseline Value'
        BASEDT  = 'Baseline Date'
        ABLFL   = 'Baseline Record Flag'
        DTYPE   = 'Derivation Type'
        CHG     = 'Change from Baseline'
        PCHG    = 'Percent Change from Baseline'
        PARCAT1 = 'Parameter Category 1'
        ATOXGRL = 'Analysis Toxicity Grade Low'
        ATOXGRH = 'Analysis Toxicity Grade High'
        ATOXGR  = 'Analysis Toxicity Grade'
        TRTA    = 'Actual Treatment'
        TRTAN   = 'Actual Treatment (N)'
        SRCDOM  = 'Source Domain'
        SRCVAR  = 'Source Variable'
        SRCSEQ  = 'Source Sequence Number'
    ;
run;

/* 5. Export to XPT */
%xpt_export(ds=adam.adlb, xptpath=&ADAM_PATH/adlb.xpt, outname=adlb);

/* 6. Validation */
proc means data=adam.adlb n nmiss mean std min max;
    class PARAMCD;
    var AVAL BASE CHG ATOXGR;
    title "ADaM ADLB: Lab Value Summary by Parameter";
run;
