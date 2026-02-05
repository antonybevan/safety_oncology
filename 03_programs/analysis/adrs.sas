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

/* 2. Add PFS Parameter (SAP §7.1.2) */
data adrs_pfs;
    set adam.adsl(keep=USUBJID TRTSDT CARTDT ITTFL SAFFL EFFFL EVALCRIT TRTEDT);
    
    PARAMCD = "PFS";
    PARAM = "Progression-Free Survival (Days)";
    PARCAT1 = "TIME-TO-EVENT";
    
    /* Find progression date from RS (Simplified check) */
    if _n_ = 1 then do;
        declare hash p(dataset:'sdtm.rs(where=(upcase(RSSTRESC) in ("PD", "PMD")))');
        p.defineKey('USUBJID');
        p.defineData('RSDTC');
        p.defineDone();
    end;
    
    length PD_DTC $10;
    if p.find() = 0 then PD_DTC = RSDTC;
    else PD_DTC = "";
    
    format PD_DT date9.;
    if not missing(PD_DTC) then PD_DT = input(PD_DTC, yymmdd10.);
    
    /* Censoring Logic (SAP Table 6) */
    /* 1. If PD found -> Event (CNSR=0) */
    if not missing(PD_DT) then do;
        ADT = PD_DT;
        CNSR = 0;
    end;
    /* 2. Otherwise -> Censored at last exposure/contact (Simplified) */
    else do;
        ADT = TRTEDT;
        CNSR = 1;
    end;
    
    if not missing(ADT) and not missing(TRTSDT) then do;
        AVAL = ADT - TRTSDT + 1;
    end;
    
    format ADT date9.;
    label CNSR = "Censor Flag (0=Event, 1=Censored)";
    
    /* Essential traceability */
    SRCDOM = "RS/ADSL";
    SRCVAR = "RSDTC/TRTEDT";
    
    drop PD_DTC PD_DT TRTSDT CARTDT;
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
    set adrs;
run;
libname xpt clear;

proc freq data=adrs;
    tables AVALC * TRT01A / nopercent norow nocol;
    title "Response Frequency by Dose Level";
run;
