/******************************************************************************
 * Program:      ae.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Adverse Events (AE) domain from raw EDC extract
 * Author:       Clinical Programming Lead
 * Date:         2026-01-31
 * SAS Version:  9.4
 * SDTM Version: 1.7 / IG v3.4
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

* Read raw AE data;
data raw_ae;
    infile "&LEGACY_PATH/raw_ae.csv" dlm=',' dsd firstobs=2;
    /* Aligned with generate_data.sas: raw_dm (17 vars) + AE specific (8 vars) */
    length STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL $100
           dose_level i subid AGE dt 8
           AEDECOD AETERM AETOXGR $100 AESTDTC AEENDTC $10 AESER $1 AESID 8 day0 8;
    input STUDYID $ USUBJID $ ARM $ SEX $ RACE $ DISEASE $ RFSTDTC $ TRTSDT $ LDSTDT $ SAFFL $ ITTFL $ EFFFL $ 
          dose_level i subid AGE dt AEDECOD $ AETERM $ AETOXGR $ AESTDTC $ AEENDTC $ AESER $ AESID day0;
run;

data ae;
    length 
        STUDYID $20
        DOMAIN $2
        USUBJID $40
        AESEQ 8
        AETERM $200
        AEDECOD $200
        AESTDTC $10
        AEENDTC $10
        AESTDY 8
        AEENDY 8
        AETOXGR $2
        AESER $1
        AESEV $20
        TRTSDT_NUM 8.
    ;

    set raw_ae;

    /* Standard Variables */
    STUDYID = "&STUDYID";
    DOMAIN = "AE";
    USUBJID = strip(USUBJID);
    
    /* Variable TRTSDT is character in input, convert to numeric for day calculation */
    TRTSDT_NUM = input(TRTSDT, yymmdd10.);
    
    /* Event Terms */
    AETERM = strip(AETERM);
    AEDECOD = strip(AEDECOD);  /* MedDRA PT */
    
    /* Dates */
    AESTDTC = strip(AESTDTC);
    AEENDTC = strip(AEENDTC);
    
    /* Severity/Grading - Extract numeric digit if Grade X */
    if index(upcase(AETOXGR), 'GRADE') > 0 then 
        AETOXGR = compress(AETOXGR, , 'kd');
    else AETOXGR = strip(AETOXGR);
    
    AESER = strip(AESER);
    
    /* Map Grade to Severity */
    if AETOXGR in ('1') then AESEV = 'MILD';
    else if AETOXGR in ('2') then AESEV = 'MODERATE';
    else if AETOXGR in ('3', '4') then AESEV = 'SEVERE';
    else if AETOXGR in ('5') then AESEV = 'DEATH';
    
    /* Study Days Calculation */
    if not missing(AESTDTC) and not missing(TRTSDT_NUM) then do;
        _stdt = input(AESTDTC, yymmdd10.);
        AESTDY = _stdt - TRTSDT_NUM + (_stdt >= TRTSDT_NUM);
    end;
    if not missing(AEENDTC) and not missing(TRTSDT_NUM) then do;
        _endt = input(AEENDTC, yymmdd10.);
        AEENDY = _endt - TRTSDT_NUM + (_endt >= TRTSDT_NUM);
    end;
    
    keep STUDYID DOMAIN USUBJID AETERM AEDECOD AESTDTC AEENDTC 
         AESTDY AEENDY AETOXGR AESER AESEV;
run;

/* Assign sequence numbers */
proc sort data=ae;
    by USUBJID AESTDTC AETERM;
run;

data sdtm.ae;
    set ae;
    by USUBJID;
    
    retain AESEQ;
    if first.USUBJID then AESEQ = 0;
    AESEQ + 1;
run;

/* Create XPT */
libname xpt xport "&SDTM_PATH/ae.xpt";
data xpt.ae;
    set sdtm.ae;
run;
libname xpt clear;

proc freq data=sdtm.ae;
    tables AEDECOD*AETOXGR / nocum;
    title "AE Frequencies by MedDRA PT and Grade";
run;

proc print data=sdtm.ae(obs=10);
    title "SDTM AE Domain - First 10 Records";
run;
