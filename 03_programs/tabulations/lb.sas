/******************************************************************************
 * Program:      lb.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Laboratory (LB) domain from raw EDC extract
 * Author:       Clinical Programming Lead
 * Date:         2026-01-31
 * SAS Version:  9.4
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

* Read raw LB data;
data raw_lb;
    infile "&LEGACY_PATH/raw_lb.csv" dlm=',' dsd firstobs=2;
    /* Aligned with generate_data.sas: raw_dm (17 vars) + LB specific (9 vars) */
    length STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL $100
           dose_level i subid AGE dt 8
           LBTESTCD $8 LBTEST $100 LBORRES LBORNRLO LBORNRHI $20 VISIT $20 LBDTC $10 day0 d 8;
    input STUDYID $ USUBJID $ ARM $ SEX $ RACE $ DISEASE $ RFSTDTC $ TRTSDT $ LDSTDT $ SAFFL $ ITTFL $ EFFFL $ 
          dose_level i subid AGE dt LBTESTCD $ LBTEST $ LBORRES $ LBORNRLO $ LBORNRHI $ VISIT $ LBDTC $ day0 d;
run;

data lb;
    length 
        STUDYID $20
        DOMAIN $2
        USUBJID $40
        LBSEQ 8
        LBTESTCD $8
        LBTEST $40
        LBORRES $20
        LBORRESU $20
        LBORNRLO 8
        LBORNRHI 8
        LBDTC $10
        LBDY 8
        VISIT $40
        LBNRIND $20
        TRTSDT_NUM 8.
    ;

    set raw_lb;

    /* Standard Variables */
    STUDYID = "&STUDYID";
    DOMAIN = "LB";
    USUBJID = strip(USUBJID);
    TRTSDT_NUM = input(TRTSDT, yymmdd10.);
    
    /* Lab Test Info */
    LBTESTCD = strip(LBTESTCD);
    LBTEST = strip(LBTEST);
    LBORRES = strip(LBORRES);
    
    /* Units and Ranges */
    if LBTESTCD = 'NEUT' then LBORRESU = '10^9/L';
    else if LBTESTCD = 'PLAT' then LBORRESU = '10^9/L';
    
    _lo = input(LBORNRLO, ?? 8.);
    _hi = input(LBORNRHI, ?? 8.);
    LBORNRLO = _lo;
    LBORNRHI = _hi;
    
    /* Date and Visit */
    LBDTC = strip(LBDTC);
    VISIT = strip(VISIT);
    
    /* Study Day */
    if not missing(LBDTC) and not missing(TRTSDT_NUM) then do;
        _lbdt = input(LBDTC, yymmdd10.);
        LBDY = _lbdt - TRTSDT_NUM + (_lbdt >= TRTSDT_NUM);
    end;
    
    /* Derive Normal Range Indicator */
    _val = input(LBORRES, ?? 8.);
    if not missing(_val) then do;
        if not missing(_lo) and _val < _lo then LBNRIND = 'LOW';
        else if not missing(_hi) and _val > _hi then LBNRIND = 'HIGH';
        else LBNRIND = 'NORMAL';
    end;
    
    keep STUDYID DOMAIN USUBJID LBTESTCD LBTEST LBORRES LBORRESU 
         LBORNRLO LBORNRHI LBDTC LBDY VISIT LBNRIND;
run;

/* Assign sequence numbers */
proc sort data=lb;
    by USUBJID LBDTC LBTESTCD;
run;

data sdtm.lb;
    set lb;
    by USUBJID;
    
    retain LBSEQ;
    if first.USUBJID then LBSEQ = 0;
    LBSEQ + 1;
run;

/* Create XPT */
libname xpt xport "&SDTM_PATH/lb.xpt";
data xpt.lb;
    set sdtm.lb;
run;
libname xpt clear;
