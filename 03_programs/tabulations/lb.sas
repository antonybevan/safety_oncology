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
    /* Aligned with LB specs */
    length STUDYID $20 USUBJID $40 ARM $200 SEX $1 RACE $100 DISEASE $5 RFSTDTC TRTSDT LDSTDT $10
           SAFFL ITTFL EFFFL $1
           dose_level i subid AGE dt 8
           LBTESTCD $8 LBTEST $100 LBORRES _LBORNRLO _LBORNRHI $20 VISIT $20 LBDTC $10 day0 d 8;
    input STUDYID $ USUBJID $ ARM $ SEX $ RACE $ DISEASE $ RFSTDTC $ TRTSDT $ LDSTDT $ SAFFL $ ITTFL $ EFFFL $ 
          dose_level i subid AGE dt LBTESTCD $ LBTEST $ LBORRES $ _LBORNRLO $ _LBORNRHI $ VISIT $ LBDTC $ day0 d;
run;

data lb;
    length 
        STUDYID $20
        DOMAIN $2
        USUBJID $40
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

    set raw_lb(rename=(LBTEST=_LBTEST));

    /* Standard Variables */
    STUDYID = "&STUDYID";
    DOMAIN = "LB";
    USUBJID = strip(USUBJID);
    TRTSDT_NUM = input(TRTSDT, yymmdd10.);
    
    /* Lab Test Info */
    LBTESTCD = strip(LBTESTCD);
    LBTEST = strip(_LBTEST);
    LBORRES = strip(LBORRES);
    
    /* Units and Ranges */
    if LBTESTCD = 'NEUT' then LBORRESU = '10^9/L';
    else if LBTESTCD = 'PLAT' then LBORRESU = '10^9/L';
    
    _lo = input(_LBORNRLO, ?? 8.);
    _hi = input(_LBORNRHI, ?? 8.);
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
