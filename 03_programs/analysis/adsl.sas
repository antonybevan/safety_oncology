/******************************************************************************
 * Program:      adsl.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create ADaM Subject Level Analysis Dataset (ADSL)
 * Author:       Statistical Programmer
 * Date:         2026-01-25
 * SAS Version:  9.4 / SAS OnDemand compatible
 * ADaM Version: 2.1 / IG v1.3
 *
 * Input:        sdtm.dm, sdtm.ex, sdtm.rs, sdtm.ae
 * Output:       adam.adsl, adam.adsl.xpt
 *
 * CDISC / Population Notes:
 *   - Screen failures: ITTFL='N', SAFFL='N', EFFFL='N' — never eligible
 *   - ITT Population: All subjects who signed ICF and were enrolled
 *   - Safety Population (SAFFL='Y'): All subjects who received any study drug
 *   - Efficacy Population (EFFFL='Y'): Safety subjects with >= 1 post-baseline
 *     response assessment
 *   - DLTEVLFL='Y': Received CAR-T AND (completed 28d window OR had DLT)
 *   - TRTDUR: computed as &DCUTDT - CARTDT + 1 using fixed submission date
 *   - All dates in SAS date9. format; ISO character dates kept as DTC variables
 ******************************************************************************/

/* Environment assumed to be set by 00_main.sas -> 00_config.sas */

/* ============================================================================
   1. TREATMENT DATES FROM EX
   ============================================================================ */
proc sort data=sdtm.ex out=ex_sorted;
    by USUBJID EXSTDTC;
run;

data car_dates;
    set ex_sorted;
    by USUBJID;

    retain TRTSDT TRTEDT CARTDT LDSTDT;
    format TRTSDT TRTEDT CARTDT LDSTDT date9.;

    /* First exposure = regimen start (lymphodepletion or CAR-T) */
    if first.USUBJID then do;
        TRTSDT = .;
        CARTDT = .;
        LDSTDT = .;
        %iso_to_sas(iso_var=EXSTDTC, sas_var=TRTSDT);
        if upcase(EXTRT) in ('FLUDARABINE','CYCLOPHOSPHAMIDE') then LDSTDT = TRTSDT;
    end;

    /* First CAR-T infusion date */
    if upcase(EXTRT) = 'BV-CAR20' and missing(CARTDT) then
        %iso_to_sas(iso_var=EXSTDTC, sas_var=CARTDT);

    /* Last exposure date */
    if last.USUBJID then do;
        %iso_to_sas(iso_var=EXENDTC, sas_var=TRTEDT);
        output;
    end;

    keep USUBJID TRTSDT TRTEDT CARTDT LDSTDT;
run;

/* ============================================================================
   2. EFFICACY ASSESSMENT PRESENCE (from RS)
   ============================================================================ */
proc sort data=sdtm.rs out=rs_subj(keep=USUBJID) nodupkey;
    by USUBJID;
run;

/* ============================================================================
   3. DEATH EVENTS (Grade 5 AE — first per subject)
   ============================================================================ */
proc sort data=sdtm.ae(where=(strip(AETOXGR)='5' and not missing(AESTDTC)))
          out=ae_death_all;
    by USUBJID AESTDTC;
run;
data ae_death_first;
    set ae_death_all;
    by USUBJID;
    if first.USUBJID;
    keep USUBJID AESTDTC AEDECOD;
run;

/* ============================================================================
   4. DLT EVENTS (Grades 3-5, treatment-related, for evaluability flag)
   ============================================================================ */
proc sort data=sdtm.ae(where=(
    AETOXGR in ('3','4','5')
    and upcase(AEREL) not in ('NOT RELATED','NONE','UNRELATED')
    and not missing(AESTDTC)
)) out=ae_dlts;
    by USUBJID AESTDTC;
run;
data sdtm_dlts;
    set ae_dlts;
    by USUBJID;
    if first.USUBJID;
    keep USUBJID AESTDTC;
run;

/* ============================================================================
   5. BUILD ADSL
   ============================================================================ */
data adsl;
    length DTHCAUS $100 COHORT $10 EVALCRIT $25 DLTEV_FL $1 _dth_dtc $10 _dth_decod $100 _dlt_dtc $10;
    set sdtm.dm;

    /* ---- Merge Treatment Dates (Hash) ---- */
    if _n_ = 1 then do;
        declare hash h(dataset:'car_dates');
        h.defineKey('USUBJID');
        h.defineData('TRTSDT','TRTEDT','CARTDT','LDSTDT');
        h.defineDone();

        /* Efficacy assessments */
        declare hash e(dataset:'rs_subj');
        e.defineKey('USUBJID');
        e.defineDone();

        /* Death info */
        declare hash d(dataset:'ae_death_first(rename=(AESTDTC=_dth_dtc AEDECOD=_dth_decod))');
        d.defineKey('USUBJID');
        d.defineData('_dth_dtc','_dth_decod');
        d.defineDone();

        /* DLT events */
        declare hash dlt(dataset:'sdtm_dlts(rename=(AESTDTC=_dlt_dtc))');
        dlt.defineKey('USUBJID');
        dlt.defineData('_dlt_dtc');
        dlt.defineDone();
    end;

    if h.find() ne 0 then do;
        TRTSDT = .; TRTEDT = .; CARTDT = .; LDSTDT = .;
    end;

    /* Initialize intermediate lookup variables to prevent uninitialized notes */
    length _DEATHDTC $10 _DEATHDECOD $100 _DLTDTC $10 _dlt_dt 8;
    call missing(_dth_dtc, _dth_decod, _dlt_dtc, _DEATHDTC, _DEATHDECOD, _DLTDTC, _dlt_dt);

    /* ---- Death Derivation ---- */
    if d.find() = 0 then do;
        _DEATHDTC   = _dth_dtc;
        _DEATHDECOD = _dth_decod;
        %iso_to_sas(iso_var=_DEATHDTC, sas_var=DTHDT);
        DTHDTC = _DEATHDTC;
        DTHCAUS = _DEATHDECOD;
        DTHFL = 'Y';
    end;
    else do;
        DTHDT = .; DTHDTC = ''; DTHCAUS = ''; DTHFL = 'N';
    end;

    /* ---- DLT Evaluability (within 28 days of CAR-T) ---- */
    if dlt.find() = 0 then do;
        _DLTDTC = _dlt_dtc;
        %iso_to_sas(iso_var=_DLTDTC, sas_var=_dlt_dt);
        if not missing(_dlt_dt) and not missing(CARTDT) then do;
            if 0 <= (_dlt_dt - CARTDT) <= 28 then DLTEV_FL = 'Y';
            else DLTEV_FL = 'N';
        end;
        else DLTEV_FL = 'N';
    end;
    else DLTEV_FL = 'N';

    /* ---- Last Known Alive Date ---- */
    if      not missing(TRTEDT) then LSTALVDT = TRTEDT;
    else if not missing(TRTSDT) then LSTALVDT = TRTSDT;
    else                             LSTALVDT = .;

    /* ---- Population Flags (CDISC ADaM IG §3.3) ----
       Screen failures come from DM already flagged ITTFL/SAFFL='N'
       We override only for confirmed treated subjects                  */
    /* ITT: all enrolled (ICF signed, not screen failure) */
    if upcase(strip(ITTFL)) ne 'N' then ITTFL = 'Y';

    /* Safety: received any study drug */
    if not missing(TRTSDT) then SAFFL = 'Y';
    else SAFFL = 'N';

    /* Efficacy: safety subject with >= 1 post-baseline assessment */
    if SAFFL = 'Y' and e.find() = 0 then EFFFL = 'Y';
    else EFFFL = 'N';

    /* Dose-escalation set: received CAR-T */
    if not missing(CARTDT) then DSCLFL = 'Y';
    else DSCLFL = 'N';

    /* ---- Analysis Treatments per ADaM IG ---- */
    length TRT01P TRT01A $200;
    TRT01P = ARM;
    TRT01A = ARM;
    TRT01PN = .;
    if ARMCD = 'DL1' then TRT01PN = 1;
    else if ARMCD = 'DL2' then TRT01PN = 2;
    else if ARMCD = 'DL3' then TRT01PN = 3;
    TRT01AN = TRT01PN;

    /* ---- Disease Cohort ---- */
    if DISEASE = 'NHL' then do;
        COHORT = 'NHL';
        EVALCRIT = 'LUGANO 2016';
    end;
    else if DISEASE in ('CLL','SLL') then do;
        COHORT = 'CLL';
        EVALCRIT = 'iwCLL 2018';
    end;

    /* ---- DLT Evaluable Population (3+3 Dose Escalation) ----
       DLT evaluable = received CAR-T AND (completed 28d window OR had DLT)  */
    length DLTEVLFL $1;
    if DSCLFL = 'Y' and not missing(CARTDT) then do;
        /* TRTDUR from CAR-T to fixed data cutoff (not today() — reproducible) */
        TRTDUR = &DCUTDT - CARTDT + 1;

        if (TRTDUR >= 28 or DLTEV_FL = 'Y') then DLTEVLFL = 'Y';
        else DLTEVLFL = 'N';

    end;
    else do;
        TRTDUR   = .;
        DLTEVLFL = 'N';
    end;

    /* ---- Age Group ---- */
    length AGEGR1 $10;
    if      missing(AGE)  then AGEGR1 = '';
    else if AGE < 65      then AGEGR1 = '<65';
    else                       AGEGR1 = '>=65';

    /* ---- End of Study Status ---- */
    length EOSSTT $30;
    if      DTHFL = 'Y'           then EOSSTT = 'DEAD';
    else if not missing(TRTSDT)   then EOSSTT = 'ONGOING';
    else                               EOSSTT = 'DISCONTINUED';

    /* ---- Date Formats ---- */
    format TRTSDT TRTEDT CARTDT LDSTDT DTHDT LSTALVDT date9.;

    /* ---- Labels (CDISC ADaM IG) ---- */
    label
        TRTSDT   = 'Date of First Exposure to Study Regimen'
        TRTEDT   = 'Date of Last Exposure to Study Regimen'
        CARTDT   = 'Date of CAR-T Infusion'
        LDSTDT   = 'Date of First Lymphodepletion'
        TRTDUR   = 'Treatment Duration (Days to Data Cutoff)'
        ITTFL    = 'Intent-To-Treat Population Flag'
        SAFFL    = 'Safety Population Flag'
        EFFFL    = 'Efficacy Population Flag'
        DSCLFL   = 'Dose-Escalation Set Flag'
        DLTEVLFL = 'DLT Evaluability Flag'
        TRT01P   = 'Planned Treatment for Period 01'
        TRT01PN  = 'Planned Treatment for Period 01 (N)'
        TRT01A   = 'Actual Treatment for Period 01'
        TRT01AN  = 'Actual Treatment for Period 01 (N)'
        COHORT   = 'Disease Cohort'
        EVALCRIT = 'Analysis Evaluation Criteria'
        AGEGR1   = 'Pooled Age Group 1'
        DTHDT    = 'Date of Death'
        DTHDTC   = 'Date/Time of Death (ISO 8601)'
        DTHCAUS  = 'Cause of Death'
        DTHFL    = 'Death Flag'
        LSTALVDT = 'Last Known Alive Date'
        EOSSTT   = 'End of Study Status'
        DLTEV_FL = 'DLT Event in Window Flag'
    ;

    /* Drop internal intermediate variables */
    drop _dth_dtc _dth_decod _dlt_dtc _DEATHDTC _DEATHDECOD _DLTDTC _dlt_dt DISEASE;
run;

/* ============================================================================
   6. PERMANENT SAS DATASET
   ============================================================================ */
data adam.adsl;
    set adsl;
run;

/* ============================================================================
   7. XPT EXPORT
   ============================================================================ */
data adsl_xpt;
    set adam.adsl;
    /* AESTDTC/AEDECOD are absorbed into DTHDT/DTHDTC/DTHCAUS above */
run;
%xpt_export(ds=adsl_xpt, xptpath=&ADAM_PATH/adsl.xpt, outname=adsl);

/* ============================================================================
   8. VALIDATION
   ============================================================================ */
proc freq data=adam.adsl;
    tables ITTFL SAFFL EFFFL DLTEVLFL / missing;
    title "ADaM ADSL: Population Flag Frequencies";
run;

proc print data=adam.adsl(obs=10);
    var USUBJID ARMCD TRTSDT CARTDT SAFFL ITTFL EFFFL DLTEVLFL DTHFL EOSSTT;
    title "ADaM ADSL - First 10 Subjects";
run;
