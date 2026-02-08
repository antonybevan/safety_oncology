/******************************************************************************
 * Program:      adrs.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create ADaM Disease Response Analysis Dataset (ADRS)
 * Author:       Clinical Programming Lead
 * Date:         2026-01-31
 * SAS Version:  9.4
 * ADaM Version: 2.1 / IG v1.3
 *
 * Input:        sdtm.rs, adam.adsl
 * Output:       adam.adrs.xpt
 ******************************************************************************/

/* Environment assumed to be set by 00_main.sas -> 00_config.sas */

/* 1. Setup ADRS */
data adrs;
    set sdtm.rs;
    
    /* Analysis Parameters with Criteria-Specific Mapping */
    if _n_ = 1 then do;
        if 0 then set adam.adsl(keep=USUBJID TRTSDT TRT01A TRT01AN ITTFL SAFFL EFFFL DISEASE ARMCD ARM EVALCRIT);
        declare hash b(dataset:'adam.adsl');
        b.defineKey('USUBJID');
        b.defineData('TRTSDT', 'TRT01A', 'TRT01AN', 'ITTFL', 'SAFFL', 'EFFFL', 'DISEASE', 'ARMCD', 'ARM', 'EVALCRIT');
        b.defineDone();
    end;
    
    if b.find() = 0; /* Subset to subjects in ADSL */

    PARAMCD = "BOR";
    PARAM = "Best Overall Response";
    
    /* Lugano 2016 for NHL, iwCLL 2018 for CLL */
    length CRIT1 PARCAT3 $100;
    if DISEASE = 'NHL' then CRIT1 = "Lugano 2016 (Metabolic)";
    else if DISEASE = 'CLL' then CRIT1 = "iwCLL 2018";
    
    PARCAT3 = EVALCRIT;

    /* Traceability Variables */
    SRCDOM  = "RS";
    SRCVAR  = "RSORRES";
    SRCSEQ  = RSSEQ;
    
    AVALC = strip(upcase(RSSTRESC));
    
    /* Standardized Ranking: CR=1, PR=2, SD=3, PD=4 */
    if AVALC = "CR" or AVALC = "CMR" then do; AVAL = 1; AVALC = "CR"; end;
    else if AVALC = "PR" or AVALC = "PMR" then do; AVAL = 2; AVALC = "PR"; end;
    else if AVALC = "SD" or AVALC = "NMR" then do; AVAL = 3; AVALC = "SD"; end;
    else if AVALC = "PD" or AVALC = "PMD" then do; AVAL = 4; AVALC = "PD"; end;
    else AVAL = .;

    /* Analysis Date */
    ADT = input(RSDTC, yymmdd10.);
    format ADT date9.;

    /* Treatment Analysis Day per CDISC: No Day 0 */
    if not missing(ADT) and not missing(TRTSDT) then 
        ADY = ADT - TRTSDT + (ADT >= TRTSDT);

    /* Result Analysis Flag (for BOR derivation later if needed) */
    ANL01FL = "Y";

    /* Labels */
    label 
        ADT      = "Analysis Date"
        ADY      = "Analysis Day"
        PARAMCD  = "Parameter Code"
        PARAM    = "Parameter"
        AVALC    = "Analysis Value (C)"
        AVAL     = "Analysis Value"
        CNSR     = "Censor Flag"
        PARCAT1  = "Parameter Category 1"
        PARCAT3  = "Evaluation Criteria"
        SRCDOM   = "Source Domain"
        SRCVAR   = "Source Variable"
        SRCSEQ   = "Source Sequence Number"
        ANL01FL  = "Analysis Record Flag 01"
    ;
run;

/* 2. Add PFS Parameter (SAP Section 7.1.2) */
proc sort data=sdtm.rs(where=(upcase(RSSTRESC) in ("PD", "PMD"))) out=rs_pd_all;
    by USUBJID RSDTC;
run;

data rs_pd_first;
    set rs_pd_all;
    by USUBJID RSDTC;
    if first.USUBJID;
    keep USUBJID RSDTC;
run;

proc sort data=sdtm.rs out=rs_last_eval_all;
    by USUBJID RSDTC;
run;

data rs_last_eval;
    set rs_last_eval_all;
    by USUBJID RSDTC;
    if last.USUBJID;
    keep USUBJID RSDTC;
run;

/* De-duplicate death events for stable hash lookup */
proc sort data=sdtm.ae(where=(strip(AETOXGR)='5' and not missing(AESTDTC)))
          out=ae_death_all;
    by USUBJID AESTDTC;
run;

data ae_death_first;
    set ae_death_all;
    by USUBJID AESTDTC;
    if first.USUBJID;
    keep USUBJID AESTDTC;
run;

/* First non-protocol anti-cancer therapy date from EX */
proc sort data=sdtm.ex(
    where=(not missing(EXTRT) and upcase(strip(EXTRT)) not in ("FLUDARABINE", "CYCLOPHOSPHAMIDE", "BV-CAR20"))
) out=ex_nact_all;
    by USUBJID EXSTDTC;
run;

data ex_nact_first;
    set ex_nact_all;
    by USUBJID EXSTDTC;
    if first.USUBJID;
    keep USUBJID EXSTDTC;
run;

data adrs_pfs;
    set adam.adsl(keep=USUBJID TRTSDT CARTDT ITTFL SAFFL EFFFL EVALCRIT TRTEDT);
    
    PARAMCD = "PFS";
    PARAM = "Progression-Free Survival (Days)";
    PARCAT1 = "TIME-TO-EVENT";
    
    /* 1. Initialize Lookups (PD, Death, Last Assessment, New Therapy) */
    if _n_ = 1 then do;
        /* PD Assessments from RS */
        declare hash p(dataset:'rs_pd_first');
        p.defineKey('USUBJID');
        p.defineData('RSDTC');
        p.defineDone();
        
        /* Death Events from AE */
        declare hash d(dataset:'ae_death_first');
        d.defineKey('USUBJID');
        d.defineData('AESTDTC');
        d.defineDone();
        
        /* Last Assessment Date from RS */
        declare hash l(dataset:'rs_last_eval');
        l.defineKey('USUBJID');
        l.defineData('RSDTC');
        l.defineDone();

        /* New anti-cancer therapy date from EX */
        declare hash n(dataset:'ex_nact_first');
        n.defineKey('USUBJID');
        n.defineData('EXSTDTC');
        n.defineDone();
    end;
        
    /* Hash lookups */
    length PD_DTC DT_DTC LST_DTC NACT_DTC $10;
    if p.find() = 0 then PD_DTC = RSDTC; else PD_DTC = "";
    if d.find() = 0 then DT_DTC = AESTDTC; else DT_DTC = "";
    if l.find() = 0 then LST_DTC = RSDTC; else LST_DTC = "";
    if n.find() = 0 then NACT_DTC = EXSTDTC; else NACT_DTC = "";

    format PD_DT DT_DT LST_DT NACT_DT EVNT_DT date9.;
    if not missing(PD_DTC) then PD_DT = input(PD_DTC, yymmdd10.);
    if not missing(DT_DTC) then DT_DT = input(DT_DTC, yymmdd10.);
    if not missing(LST_DTC) then LST_DT = input(LST_DTC, yymmdd10.);
    if not missing(NACT_DTC) then NACT_DT = input(NACT_DTC, yymmdd10.);

    if not missing(PD_DT) and not missing(DT_DT) then EVNT_DT = min(PD_DT, DT_DT);
    else if not missing(PD_DT) then EVNT_DT = PD_DT;
    else if not missing(DT_DT) then EVNT_DT = DT_DT;
    else EVNT_DT = .;

    if not missing(NACT_DT) and not missing(TRTSDT) and NACT_DT < TRTSDT then NACT_DT = .;

    /* PFS Derivation Logic (SAP Table 6 / FDA Guidance) */
    /* Priority 1: Censor at new anti-cancer therapy before event */
    if not missing(NACT_DT) and (missing(EVNT_DT) or NACT_DT <= EVNT_DT) then do;
        if not missing(LST_DT) then ADT = min(LST_DT, NACT_DT);
        else ADT = NACT_DT;
        if missing(ADT) then ADT = TRTSDT;
        CNSR = 1;
        EVNTDESC = "Censored at New Anti-Cancer Therapy";
    end;
    /* Priority 2: Event (Progression or Death) */
    else if not missing(EVNT_DT) then do;
        ADT = EVNT_DT;
        CNSR = 0;
        EVNTDESC = "Event";
    end;
    /* Priority 3: Censored at Last Assessment */
    else do;
        ADT = LST_DT;
        if missing(ADT) then ADT = TRTSDT; /* Fallback to Day 0 if no assessment */
        CNSR = 1;
        EVNTDESC = "Censored";
    end;

    /* Missed Visit Handling (Simplified): If gap > 90d between LST_DT and event date, censor at LST_DT */
    if CNSR = 0 and not missing(LST_DT) then do;
        if ADT - LST_DT > 90 then do; /* >2 scheduled visits missed */
            ADT = LST_DT;
            CNSR = 1;
        end;
    end;

    if not missing(ADT) and not missing(TRTSDT) then 
        AVAL = ADT - TRTSDT + 1;

    format ADT date9.;
    label CNSR = "Censor Flag (0=Event, 1=Censored)";
    
    /* Essential traceability */
    SRCDOM = "RS/AE/EX/ADSL";
    SRCVAR = "RSDTC/AESTDTC/EXSTDTC";
    
    drop PD_DTC DT_DTC LST_DTC NACT_DTC PD_DT DT_DT LST_DT NACT_DT EVNT_DT EXSTDTC TRTSDT CARTDT ITTFL SAFFL EFFFL EVALCRIT TRTEDT;
run;

/* 3. Combine and Finalize */
data adrs_combined;
    set adrs(in=a) adrs_pfs(in=b);
    if a and missing(PARCAT1) then PARCAT1 = "EFFICIENCY";
run;

data adam.adrs;
    set adrs_combined;
run;

/* 2. Export to XPT */
libname xpt xport "&ADAM_PATH/adrs.xpt";
data xpt.adrs;
    set adrs_combined;
run;
libname xpt clear;

proc freq data=adrs;
    tables AVALC * TRT01A / nopercent norow nocol;
    title "Response Frequency by Dose Level";
run;

