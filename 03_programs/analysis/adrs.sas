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

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* 1. Setup ADRS */
data adrs;
    set sdtm.rs;
    
    /* Analysis Parameters with Criteria-Specific Mapping */
    if _n_ = 1 then do;
        if 0 then set adam.adsl(keep=USUBJID TRTSDT TRT01A TRT01AN ITTFL SAFFL EFFFL DISEASE);
        declare hash b(dataset:'adam.adsl');
        b.defineKey('USUBJID');
        b.defineData('TRTSDT', 'TRT01A', 'TRT01AN', 'ITTFL', 'SAFFL', 'EFFFL', 'DISEASE');
        b.defineDone();
    end;
    
    if b.find() = 0; /* Subset to subjects in ADSL */

    PARAMCD = "BOR";
    PARAM = "Best Overall Response";
    
    /* Lugano 2016 for NHL, iwCLL 2018 for CLL */
    length CRIT1 $100;
    if DISEASE = 'NHL' then CRIT1 = "Lugano 2016 (Metabolic)";
    else if DISEASE = 'CLL' then CRIT1 = "iwCLL 2018";
    
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
        ANL01FL  = "Analysis Record Flag 01"
    ;
run;

/* Create permanent SAS dataset */
data adam.adrs;
    set adrs;
run;

/* 2. Export to XPT */
libname xpt xport "&ADAM_PATH/adrs.xpt";
data xpt.adrs;
    set adrs;
run;
libname xpt clear;

proc freq data=adrs;
    tables AVALC * TRT01A / nopercent norow nocol;
    title "Response Frequency by Dose Level";
run;
