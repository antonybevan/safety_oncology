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
    
    /* Join ADSL variables */
    length TRT01A $40;
    if _n_ = 1 then do;
        if 0 then set adam.adsl(keep=USUBJID TRTSDT TRT01A TRT01AN ITTFL SAFFL EFFFL);
        declare hash a(dataset:'adam.adsl');
        a.defineKey('USUBJID');
        a.defineData('TRTSDT', 'TRT01A', 'TRT01AN', 'ITTFL', 'SAFFL', 'EFFFL');
        a.defineDone();
    end;
    
    if a.find() ne 0 then do;
        TRTSDT = .; TRT01A = ""; TRT01AN = .; ITTFL = ""; SAFFL = ""; EFFFL = "";
    end;

    /* Analysis Parameters */
    PARAMCD = "OVRLRESP";
    PARAM = "Overall Response";
    
    AVALC = RSSTRESC;
    if AVALC = "CR" then AVAL = 1;
    else if AVALC = "PR" then AVAL = 2;
    else if AVALC = "SD" then AVAL = 3;
    else if AVALC = "PD" then AVAL = 4;
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
