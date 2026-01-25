/******************************************************************************
 * Program:      adrs.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create ADaM Response Analysis Dataset (ADRS)
 * Author:       Clinical Programming Lead
 * Date:         2026-01-25
 * SAS Version:  9.4
 * ADaM Version: 2.1 / IG v1.3
 *
 * Input:        sdtm.rs, adam.adsl
 * Output:       adam.adrs.xpt
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

/* 1. Setup ADRS Source */
data rs_pre;
    set sdtm.rs;
    where RSTESTCD = 'BOR'; /* We only care about Best Overall Response records */
    
    ADT = input(RSDTC, yymmdd10.);
    format ADT date9.;
    
    AVALC = RSORRES;
    PARAMCD = "BOR";
    PARAM   = "Best Overall Response";
    
    /* Assign Numeric Rank for sorting best response */
    /* 1=CR, 2=PR, 3=SD, 4=PD, 5=NE */
    if AVALC = 'CR' then _RANK = 1;
    else if AVALC = 'PR' then _RANK = 2;
    else if AVALC = 'SD' then _RANK = 3;
    else if AVALC = 'PD' then _RANK = 4;
    else _RANK = 5;
    
    keep USUBJID PARAMCD PARAM ADT AVALC _RANK;
run;

/* 2. Join ADSL */
data rs_adsl;
    set rs_pre;
    
    length TRT01A $40;
    if _n_ = 1 then do;
        if 0 then set adam.adsl(keep=USUBJID TRTSDT TRT01A TRT01AN);
        declare hash a(dataset:'adam.adsl');
        a.defineKey('USUBJID');
        a.defineData('TRTSDT', 'TRT01A', 'TRT01AN');
        a.defineDone();
    end;
    
    if a.find() ne 0 then do;
        TRTSDT = .; TRT01A = ""; TRT01AN = .;
    end;
    
    TRTA = TRT01A;
    TRTAN = TRT01AN;
run;

/* 3. Flag Best Response (ANL01FL) */
proc sort data=rs_adsl;
    by USUBJID _RANK ADT; 
run;

data adrs;
    set rs_adsl;
    by USUBJID _RANK;
    
    if first.USUBJID then ANL01FL = 'Y';
    else ANL01FL = 'N';
    
    label
        ADT     = "Analysis Date"
        AVALC   = "Analysis Value (C)"
        ANL01FL = "Analysis Flag 01 - Best Response"
        TRTA    = "Actual Treatment"
        TRTAN   = "Actual Treatment (N)"
    ;
run;

/* Create permanent SAS dataset */
data adam.adrs;
    set adrs;
run;

/* 4. Export to XPT */
libname xpt xport "&ADAM_PATH/adrs.xpt";
data xpt.adrs;
    set adrs(drop=_RANK);
run;
libname xpt clear;

proc freq data=adrs;
    tables TRTA * AVALC / nopercent norow nocol;
    where ANL01FL = 'Y';
    title "Best Overall Response by Treatment Arm";
run;
