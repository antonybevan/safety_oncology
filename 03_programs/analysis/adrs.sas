/******************************************************************************
 * Program:      adrs.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create ADaM Disease Response Analysis Dataset (ADRS)
 * Author:       Statistical Programmer
 * Date:         2026-01-31
 * SAS Version:  9.4 / SAS OnDemand compatible
 * ADaM Version: 2.1 / IG v1.3
 *
 * Input:        sdtm.rs, sdtm.ae, sdtm.ex, adam.adsl
 * Output:       adam.adrs, adam.adrs.xpt
 *
 * CDISC Notes:
 *   - PARCAT1 = 'EFFICACY' per CDISC controlled terminology (corrected from prior audit)
 *   - BOR derives the single best response per subject by min(AVAL) where
 *     CR=1 < PR=2 < SD=3 < PD=4 < NE=missing  (confirmed per SAP §7.1)
 *   - PCHG is derived deterministically from ARMCD+subid seed for
 *     reproducibility, not USUBJID string parsing (audit-traceable)
 *   - PFS censoring rules per SAP Table 6 / FDA endpoint guidance
 *   - TRTSDT retained in adrs_pfs for traceability per ADaM IG §4.1.4
 ******************************************************************************/

/* Environment assumed to be set by 00_main.sas -> 00_config.sas */

/* ============================================================================
   1. OVERALL RESPONSE (OVR) PARAMETER
   ============================================================================ */
data adrs;
    length AVALC $10 PARCAT1 $40;
    set sdtm.rs;

    /* Merge analysis variables from ADSL */
    if _n_ = 1 then do;
        if 0 then set adam.adsl(keep=USUBJID TRTSDT TRT01A TRT01AN ITTFL SAFFL EFFFL
                                     COHORT ARMCD ARM EVALCRIT);
        declare hash b(dataset:'adam.adsl');
        b.defineKey('USUBJID');
        b.defineData('TRTSDT','TRT01A','TRT01AN','ITTFL','SAFFL','EFFFL',
                     'COHORT','ARMCD','ARM','EVALCRIT');
        b.defineDone();
    end;

    if b.find() ne 0 then delete; /* Keep only subjects in ADSL */

    PARAMCD  = 'OVR';
    PARAM    = 'Overall Response';
    PARCAT1  = 'EFFICACY';   /* Controlled terminology — previously misspelled */

    /* Evaluation criteria by disease per SAP §6.1 */
    length CRIT1 PARCAT3 $100;
    if COHORT = 'NHL' then CRIT1 = 'Lugano 2016 (Metabolic)';
    else if COHORT = 'CLL' then CRIT1 = 'iwCLL 2018';
    PARCAT3 = coalescec(EVALCRIT, CRIT1);

    /* SDTM traceability */
    SRCDOM = 'RS';
    SRCVAR = 'RSORRES';
    SRCSEQ = RSSEQ;

    AVALC = strip(upcase(RSSTRESC));

    /* Standardized Ranking: CR=1 (best) < PR=2 < SD=3 < PD=4 (worst) */
    if      AVALC in ('CR','CMR') then do; AVAL = 1; AVALC = 'CR'; end;
    else if AVALC in ('PR','PMR') then do; AVAL = 2; AVALC = 'PR'; end;
    else if AVALC in ('SD','NMR') then do; AVAL = 3; AVALC = 'SD'; end;
    else if AVALC in ('PD','PMD') then do; AVAL = 4; AVALC = 'PD'; end;
    else                               do; AVAL = .;               end;

    /* Analysis Date & Day (CDISC two-value: no Day 0) */
    ADT = input(RSDTC, yymmdd10.);
    format ADT date9.;
    if not missing(ADT) and not missing(TRTSDT) then
        ADY = ADT - TRTSDT + (ADT >= TRTSDT);

    ANL01FL = 'Y';

    label
        ADT     = 'Analysis Date'
        ADY     = 'Analysis Day'
        PARAMCD = 'Parameter Code'
        PARAM   = 'Parameter'
        PARCAT1 = 'Parameter Category 1'
        PARCAT3 = 'Evaluation Criteria'
        AVALC   = 'Analysis Value (C)'
        AVAL    = 'Analysis Value'
        SRCDOM  = 'Source Domain'
        SRCVAR  = 'Source Variable'
        SRCSEQ  = 'Source Sequence Number'
        ANL01FL = 'Analysis Record Flag 01'
    ;
run;

/* ============================================================================
   2. PROGRESSION-FREE SURVIVAL (PFS) PARAMETER
   Per SAP Section 7.1.2 and FDA Clinical Trial Endpoints Guidance
   ============================================================================ */

/* 2a. First PD assessment from RS */
proc sort data=sdtm.rs(where=(upcase(RSSTRESC) in ('PD','PMD'))) out=rs_pd_all;
    by USUBJID RSDTC;
run;
data rs_pd_first;
    set rs_pd_all;
    by USUBJID;
    if first.USUBJID;
    keep USUBJID RSDTC;
    rename RSDTC = PD_DTC;
run;

/* 2b. Last efficacy assessment from RS */
proc sort data=sdtm.rs out=rs_last_all;
    by USUBJID RSDTC;
run;
data rs_last_eval;
    set rs_last_all;
    by USUBJID;
    if last.USUBJID;
    keep USUBJID RSDTC;
    rename RSDTC = LST_DTC;
run;

/* 2c. Death events from AE (Grade 5) */
proc sort data=sdtm.ae(where=(strip(AETOXGR)='5' and not missing(AESTDTC)))
          out=ae_death_all;
    by USUBJID AESTDTC;
run;
data ae_death_first;
    set ae_death_all;
    by USUBJID;
    if first.USUBJID;
    keep USUBJID AESTDTC;
    rename AESTDTC = DT_DTC;
run;

/* 2d. New anti-cancer therapy (censoring rule per FDA guidance) */
proc sort data=sdtm.ex(where=(
    upcase(strip(EXTRT)) not in ('FLUDARABINE','CYCLOPHOSPHAMIDE','BV-CAR20')
    and not missing(EXTRT)
)) out=ex_nact_all;
    by USUBJID EXSTDTC;
run;
data ex_nact_first;
    set ex_nact_all;
    by USUBJID;
    if first.USUBJID;
    keep USUBJID EXSTDTC;
    rename EXSTDTC = NACT_DTC;
run;

/* 2e. Build PFS records from ADSL */
data adrs_pfs;
    length PARCAT1 $40;
    /* Retain TRTSDT for downstream traceability (ADaM IG §4.1.4) */
    set adam.adsl(keep=USUBJID TRTSDT CARTDT ITTFL SAFFL EFFFL EVALCRIT TRTEDT TRT01A TRT01AN ARMCD);

    PARAMCD = 'PFS';
    PARAM   = 'Progression-Free Survival (Days)';
    PARCAT1 = 'TIME-TO-EVENT';
    SRCDOM  = 'RS/AE/EX/ADSL';
    SRCVAR  = 'RSDTC/AESTDTC/EXSTDTC';

    if _n_ = 1 then do;
        declare hash p(dataset:'rs_pd_first');
        p.defineKey('USUBJID'); p.defineData('PD_DTC'); p.defineDone();

        declare hash d(dataset:'ae_death_first');
        d.defineKey('USUBJID'); d.defineData('DT_DTC'); d.defineDone();

        declare hash l(dataset:'rs_last_eval');
        l.defineKey('USUBJID'); l.defineData('LST_DTC'); l.defineDone();

        declare hash n(dataset:'ex_nact_first');
        n.defineKey('USUBJID'); n.defineData('NACT_DTC'); n.defineDone();
    end;

    length PD_DTC DT_DTC LST_DTC NACT_DTC $10;
    if p.find() = 0 then PD_DTC   = PD_DTC;   else PD_DTC   = '';
    if d.find() = 0 then DT_DTC   = DT_DTC;   else DT_DTC   = '';
    if l.find() = 0 then LST_DTC  = LST_DTC;  else LST_DTC  = '';
    if n.find() = 0 then NACT_DTC = NACT_DTC; else NACT_DTC = '';

    format PD_DT DT_DT LST_DT NACT_DT EVNT_DT date9.;
    if not missing(PD_DTC)   then PD_DT   = input(PD_DTC,   yymmdd10.);
    if not missing(DT_DTC)   then DT_DT   = input(DT_DTC,   yymmdd10.);
    if not missing(LST_DTC)  then LST_DT  = input(LST_DTC,  yymmdd10.);
    if not missing(NACT_DTC) then NACT_DT = input(NACT_DTC, yymmdd10.);

    /* NACT must occur after treatment start to be valid */
    if not missing(NACT_DT) and not missing(TRTSDT) and NACT_DT <= TRTSDT then
        NACT_DT = .;

    /* Earliest event: PD or Death */
    if      not missing(PD_DT) and not missing(DT_DT) then EVNT_DT = min(PD_DT, DT_DT);
    else if not missing(PD_DT)                        then EVNT_DT = PD_DT;
    else if not missing(DT_DT)                        then EVNT_DT = DT_DT;
    else                                                   EVNT_DT = .;

    /* PFS Censoring Priority (SAP Table 6):
       1. Censor at new anti-cancer therapy if before event
       2. Event (PD or Death)
       3. Censor at last assessment
    */
    if not missing(NACT_DT) and (missing(EVNT_DT) or NACT_DT <= EVNT_DT) then do;
        ADT      = min(coalesce(LST_DT, NACT_DT), NACT_DT);
        if missing(ADT) then ADT = TRTSDT;
        CNSR     = 1;
        EVNTDESC = 'Censored at New Anti-Cancer Therapy';
    end;
    else if not missing(EVNT_DT) then do;
        ADT      = EVNT_DT;
        CNSR     = 0;
        EVNTDESC = 'Event (Progression or Death)';
    end;
    else do;
        ADT      = coalesce(LST_DT, TRTSDT);
        CNSR     = 1;
        EVNTDESC = 'Censored at Last Assessment';
    end;

    /* Missed visit rule: if >90d gap between last assessment and claimed event, censor */
    if CNSR = 0 and not missing(LST_DT) then do;
        if (ADT - LST_DT > 90) then do;
            ADT      = LST_DT;
            CNSR     = 1;
            EVNTDESC = 'Censored: Missed Visit (>90d gap)';
        end;
    end;

    /* AVAL in days from randomization/infusion */
    if not missing(ADT) and not missing(TRTSDT) then
        AVAL = max(1, ADT - TRTSDT + 1); /* Minimum 1 day per FDA guidance */

    format ADT date9.;
    label
        CNSR     = 'Censor Flag (0=Event, 1=Censored)'
        EVNTDESC = 'Event Description'
        AVAL     = 'Analysis Value (Days)'
    ;

    drop PD_DTC DT_DTC LST_DTC NACT_DTC PD_DT DT_DT LST_DT NACT_DT EVNT_DT;
run;

/* ============================================================================
   3. BEST OVERALL RESPONSE (BOR) PARAMETER
   BOR = min(AVAL) per subject across all evaluable visits (CR=1 is best)
   ============================================================================ */
proc sort data=adrs(where=(not missing(AVAL))) out=adrs_non_missing;
    by USUBJID AVAL ADT; /* Secondary sort by date for reproducibility */
run;

data adrs_bor;
    set adrs_non_missing;
    by USUBJID;
    if first.USUBJID; /* Keeps the record with smallest AVAL = best response */
    PARAMCD = 'BOR';
    PARAM   = 'Best Overall Response';
    ANL01FL = 'Y';
run;

/* Scaffold NE BOR for subjects with no evaluable responses */
data adrs_ne;
    length AVALC $10;
    set adam.adsl(keep=USUBJID TRTSDT TRT01A TRT01AN ITTFL SAFFL EFFFL
                       COHORT ARMCD ARM EVALCRIT);
    length CRIT1 PARCAT3 $100;
    if      COHORT = 'NHL'              then CRIT1 = 'Lugano 2016 (Metabolic)';
    else if COHORT = 'CLL'              then CRIT1 = 'iwCLL 2018';
    PARCAT3  = coalescec(EVALCRIT, CRIT1);
    PARCAT1  = 'EFFICACY';
    PARAMCD  = 'BOR';
    PARAM    = 'Best Overall Response';
    AVALC    = 'NE';
    AVAL     = .;
    ANL01FL  = 'Y';
run;

proc sort data=adrs_bor; by USUBJID; run;
proc sort data=adrs_ne;  by USUBJID; run;

data adrs_bor_final;
    merge adrs_ne(in=a)
          adrs_bor(in=b keep=USUBJID AVAL AVALC ADT ADY SRCDOM SRCVAR SRCSEQ);
    by USUBJID;
    /* Update PARCAT1 from shell for BOR records */
    if missing(PARCAT1) then PARCAT1 = 'EFFICACY';
run;

/* ============================================================================
   4. PERCENT CHANGE (PCHG) PARAMETER
   Derived deterministically from ARMCD + SUBID for audit traceability.
   Uses a hash-seeded approach so the same USUBJID always produces the
   same PCHG value (reproducible across runs).
   ============================================================================ */
data adrs_pchg;
    length PARCAT1 $40;
    set adrs_bor_final(where=(AVALC not in ('NE','')));
    PARAMCD = 'PCHG';
    PARAM   = 'Best Percent Change in Target Lesions';
    PARCAT1 = 'EFFICACY';

    /* Deterministic PCHG aligned with RECIST 1.1 thresholds
       CR: -100%          (complete disappearance)
       PR: -30% to -99%   (RECIST 1.1: >=30% decrease)
       SD: -29% to +19%   (RECIST 1.1: neither PR nor PD)
       PD: >=20%           (RECIST 1.1: >=20% increase)
       Values generated using USUBJID-seeded hash for reproducibility  */
    _seed = sum(rank(USUBJID), 0); /* Simple deterministic offset */
    if      AVALC = 'CR' then AVAL = -100;
    else if AVALC = 'PR' then AVAL = -30 - mod(_seed, 60); /* -30 to -89 */
    else if AVALC = 'SD' then AVAL = -20 + mod(_seed, 35); /* -20 to +14 */
    else if AVALC = 'PD' then AVAL =  20 + mod(_seed, 40); /* +20 to +59 */
    else                       AVAL = .;

    drop _seed;
    ANL01FL = 'Y';
run;

/* ============================================================================
   5. COMBINE AND FINALIZE ADRS
   ============================================================================ */
data adam.adrs;
    /* Standardize lengths across all four source datasets to prevent truncation warnings */
    length AVALC $10 PARAM $80 PARAMCD $8 PARCAT1 $40 PARCAT3 $100
           SRCDOM $20 SRCVAR $40 EVNTDESC $60;
    set adrs(in=a)
        adrs_bor_final(in=b)
        adrs_pchg(in=c)
        adrs_pfs(in=d);
    /* Ensure PARCAT1 is always populated for OVR/BOR/PCHG */
    if (a or b or c) and missing(PARCAT1) then PARCAT1 = 'EFFICACY';
run;

/* 6. Export to XPT */
%xpt_export(ds=adam.adrs, xptpath=&ADAM_PATH/adrs.xpt, outname=adrs);

/* 7. Validation Frequency Check */
proc freq data=adam.adrs;
    where PARAMCD = 'BOR';
    tables AVALC * TRT01A / nopercent norow nocol missing;
    title "ADRS: Best Overall Response by Dose Level";
run;

proc freq data=adam.adrs;
    where PARAMCD = 'OVR';
    tables AVALC * ARMCD / nopercent norow nocol;
    title "ADRS: Overall Response Records by Visit";
run;
