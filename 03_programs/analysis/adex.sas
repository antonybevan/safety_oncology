/******************************************************************************
 * Program:      adex.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create ADaM Exposure Analysis Dataset (ADEX)
 * Author:       Clinical Programming Lead
 * Date:         2026-01-25
 * SAS Version:  9.4
 * ADaM Version: 2.1 / IG v1.3
 *
 * Input:        sdtm.ex, adam.adsl
 * Output:       adam.adex.xpt
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

/* 1. Setup ADEX Source */
data ex_pre;
    set sdtm.ex;
    
    /* Analysis Dates */
    ASTDT = input(EXSTDTC, yymmdd10.);
    AENDT = input(EXENDTC, yymmdd10.);
    format ASTDT AENDT date9.;
    
    /* Analysis Values */
    AVAL = EXDOSE;
    AVALU = EXDOSU;
    
    /* Parameters */
    PARAM = EXTRT;
    PARAMCD = substr(EXTRT, 1, 8); /* Simple truncation for code */
    
    keep USUBJID PARAM PARAMCD AVAL AVALU ASTDT AENDT EXSEQ;
run;

/* 2. Join ADSL */
data adex;
    set ex_pre;
    
    if _n_ = 1 then do;
        declare hash a(dataset:'adam.adsl(keep=USUBJID TRTSDT TRT01A TRT01AN)');
        a.defineKey('USUBJID');
        a.defineData('TRTSDT', 'TRT01A', 'TRT01AN');
        a.defineDone();
    end;
    
    if a.find() ne 0 then do;
        TRTSDT = .; TRT01A = ""; TRT01AN = .;
    end;
    
    TRTA = TRT01A;
    TRTAN = TRT01AN;
    
    /* Relative Day */
    if not missing(ASTDT) and not missing(TRTSDT) then do;
        ADY = ASTDT - TRTSDT;
        if ADY >= 0 then ADY = ADY + 1;
    end;
    
    label
        ASTDT = "Analysis Start Date"
        AENDT = "Analysis End Date"
        AVAL  = "Analysis Value"
        AVALU = "Analysis Value Unit"
        ADY   = "Analysis Relative Day"
        TRTA  = "Actual Treatment"
        TRTAN = "Actual Treatment (N)"
    ;
run;

/* Create permanent SAS dataset */
data adam.adex;
    set adex;
run;

/* 3. Export to XPT */
libname xpt xport "&ADAM_PATH/adex.xpt";
data xpt.adex;
    set adex;
run;
libname xpt clear;

proc means data=adex n mean min max;
    class PARAM TRTA;
    var AVAL;
    title "Exposure Summary by Treatment";
run;
