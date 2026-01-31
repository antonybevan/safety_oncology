/******************************************************************************
 * Program:      rs.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Disease Response (RS) domain from raw EDC extract
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

* Read raw RS data;
data raw_rs;
    infile "&LEGACY_PATH/raw_rs.csv" dlm=',' dsd firstobs=2;
    /* Aligned with RS specs */
    length STUDYID $20 USUBJID $40 ARM $100 SEX $1 RACE $40 DISEASE $5 RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL $100
           dose_level i subid AGE dt 8
           RSTESTCD $8 RSTEST $100 RSORRES RSSTRESC $20 RSDTC $10 VISIT $20 day0 r 8;
    input STUDYID $ USUBJID $ ARM $ SEX $ RACE $ DISEASE $ RFSTDTC $ TRTSDT $ LDSTDT $ SAFFL $ ITTFL $ EFFFL $ 
          dose_level i subid AGE dt RSTESTCD $ RSTEST $ RSORRES $ RSSTRESC $ RSDTC $ VISIT $ day0 r;
run;

data rs;
    length 
        STUDYID $20
        DOMAIN $2
        USUBJID $40
        RSTESTCD $8
        RSTEST $40
        RSORRES $20
        RSSTRESC $20
        RSDTC $10
        RSDY 8
        RSEVAL $20
        RSCAT $40
        TRTSDT_NUM 8.
    ;

    set raw_rs;

    /* Standard Variables */
    STUDYID = "&STUDYID";
    DOMAIN = "RS";
    USUBJID = strip(USUBJID);
    TRTSDT_NUM = input(TRTSDT, yymmdd10.);
    
    /* Test Info */
    RSTESTCD = strip(RSTESTCD);
    RSTEST = strip(RSTEST);
    
    /* Response Result */
    RSORRES = strip(RSORRES);
    RSSTRESC = strip(RSSTRESC);
    
    /* Date */
    RSDTC = strip(RSDTC);
    
    /* Study Day */
    if not missing(RSDTC) and not missing(TRTSDT_NUM) then do;
        _rsdt = input(RSDTC, yymmdd10.);
        RSDY = _rsdt - TRTSDT_NUM + (_rsdt >= TRTSDT_NUM);
    end;
    
    /* Evaluator and Category */
    RSEVAL = "INVESTIGATOR";
    RSCAT = "DISEASE ASSESSMENT";
    
    keep STUDYID DOMAIN USUBJID RSTESTCD RSTEST RSORRES RSSTRESC 
         RSDTC RSDY RSEVAL RSCAT;
run;

/* Assign sequence numbers */
proc sort data=rs;
    by USUBJID RSDTC;
run;

data sdtm.rs;
    set rs;
    by USUBJID;
    
    retain RSSEQ;
    if first.USUBJID then RSSEQ = 0;
    RSSEQ + 1;
run;

/* Create XPT */
libname xpt xport "&SDTM_PATH/rs.xpt";
data xpt.rs;
    set sdtm.rs;
run;
libname xpt clear;
