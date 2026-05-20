/******************************************************************************
 * Program:      adex.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create ADaM Exposure Analysis Dataset (ADEX)
 * Author:       Statistical Programmer
 * Date:         2026-01-25
 * SAS Version:  9.4 / SAS OnDemand compatible
 * ADaM Version: 2.1 / IG v1.3
 *
 * Input:        sdtm.ex, adam.adsl
 * Output:       adam.adex, adam.adex.xpt
 *
 * CDISC Notes:
 *   - PARAMCD max 8 chars: mapped to controlled codes (CYCLOFLUD, FLUDAR, BVCAR20)
 *     rather than a fragile substr() truncation.
 *   - Mixed dose units (cells/kg vs flat cells) flagged via EXDOSU — not summed.
 *   - ADY uses CDISC two-value convention (no Day 0): ..., -1, 1, 2, ...
 ******************************************************************************/

/* Environment assumed to be set by 00_main.sas -> 00_config.sas */

/* 1. Setup ADEX Source with Proper PARAMCD Mapping */
data ex_pre;
    set sdtm.ex;

    /* Analysis Dates */
    ASTDT = input(EXSTDTC, yymmdd10.);
    AENDT = input(EXENDTC, yymmdd10.);
    format ASTDT AENDT date9.;

    /* Analysis Values */
    AVAL  = EXDOSE;
    AVALU = EXDOSU;

    /* Parameters — PARAMCD must be <= 8 chars per CDISC controlled terminology */
    PARAM = strip(EXTRT);
    if      upcase(strip(EXTRT)) = 'CYCLOPHOSPHAMIDE' then PARAMCD = 'CYCLOPHO';
    else if upcase(strip(EXTRT)) = 'FLUDARABINE'      then PARAMCD = 'FLUDARAB';
    else if upcase(strip(EXTRT)) = 'BV-CAR20'         then PARAMCD = 'BVCAR20';
    else PARAMCD = 'OTHER'; /* Unknown treatments mapped to OTHER — do NOT truncate blindly */

    /* PARCAT1: Regimen phase classification — aligned with EXCAT from ex.sas */
    if EXCAT = 'LYMPHODEPLETION' then PARCAT1 = 'LYMPHODEPLETION';
    else if EXCAT = 'CAR-T INFUSION' then PARCAT1 = 'CAR-T THERAPY';
    else PARCAT1 = 'OTHER';

    /* MNC Traceability Variables (CDISC ADaM IG v1.3) */
    length SRCDOM $8 SRCVAR $20;
    SRCDOM = 'EX';
    SRCVAR = 'EXDOSE';
    SRCSEQ = EXSEQ;

    keep USUBJID PARAM PARAMCD PARCAT1 AVAL AVALU ASTDT AENDT SRCDOM SRCVAR SRCSEQ EXCAT;
run;

/* 2. Join ADSL for Treatment Variables */
data adex;
    set ex_pre;

    length TRT01A $200;
    if _n_ = 1 then do;
        if 0 then set adam.adsl(keep=USUBJID TRTSDT CARTDT TRT01A TRT01AN ARM ARMCD);
        declare hash a(dataset:'adam.adsl');
        a.defineKey('USUBJID');
        a.defineData('TRTSDT', 'CARTDT', 'TRT01A', 'TRT01AN', 'ARM', 'ARMCD');
        a.defineDone();
    end;

    if a.find() ne 0 then do;
        TRTSDT = .; CARTDT = .; TRT01A = ''; TRT01AN = .;
    end;

    TRTA  = TRT01A;
    TRTAN = TRT01AN;
    STUDYID = "&STUDYID";

    /* Relative Day per CDISC: No Day 0 (..,-1, 1, 2,...) */
    if not missing(ASTDT) and not missing(TRTSDT) then
        ADY = ASTDT - TRTSDT + (ASTDT >= TRTSDT);

    label
        ASTDT   = 'Analysis Start Date'
        AENDT   = 'Analysis End Date'
        AVAL    = 'Analysis Value'
        AVALU   = 'Analysis Value Unit'
        PARCAT1 = 'Parameter Category 1'
        ADY     = 'Analysis Relative Day'
        TRTA    = 'Actual Treatment'
        TRTAN   = 'Actual Treatment (N)'
        SRCDOM  = 'Source Domain'
        SRCVAR  = 'Source Variable'
        SRCSEQ  = 'Source Sequence Number'
    ;
run;

/* 3. Create Permanent SAS Dataset */
data adam.adex;
    set adex;
run;

/* 4. Export to XPT — portable across SAS 9.4 & SAS OnDemand */
%xpt_export(ds=adam.adex, xptpath=&ADAM_PATH/adex.xpt, outname=adex);

/* 5. Validation Summary */
proc means data=adex n mean min max;
    class PARCAT1 TRTA;
    var AVAL;
    title "ADaM ADEX: Exposure Summary by Regimen Phase and Treatment";
run;
