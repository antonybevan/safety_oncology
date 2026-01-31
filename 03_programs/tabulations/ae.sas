/******************************************************************************
 * Program:      ae.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Adverse Events (AE) domain from raw EDC extract
 * Author:       Clinical Programming Lead
 * Date:         2026-01-22
 * SAS Version:  9.4
 * SDTM Version: 1.7 / IG v3.4
 *
 * Input:        &LEGACY_PATH/raw_ae.csv
 * Output:       &SDTM_PATH/ae.xpt
 *
 * Notes:        - MedDRA v22.1 coding already in raw data
 *               - CTCAE v5.0 grading in AETOXGR
 *               - AESI flagged per SAP Section 8.2.2
 ******************************************************************************/

%macro load_config;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %include "../00_config.sas";
%mend;
%load_config;

proc import datafile="&LEGACY_PATH/raw_ae.csv"
    out=raw_ae
    dbms=csv
    replace;
    getnames=yes;
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
        TRTSDT 8
    ;

    set raw_ae;

    /* Standard Variables */
    STUDYID = "BV-CAR20-P1";
    DOMAIN = "AE";
    USUBJID = strip(USUBJID);
    
    /* Fetch TRTSDT from DM for Study Day derivation */
    if _n_ = 1 then do;
        declare hash d(dataset:'sdtm.dm');
        d.defineKey('USUBJID');
        d.defineData('RFXSTDTC');
        d.defineDone();
    end;
    if d.find() = 0 then TRTSDT = input(RFXSTDTC, yymmdd10.);
    
    /* Event Terms */
    AETERM = strip(AETERM);
    AEDECOD = strip(AEDECOD);  /* MedDRA PT */
    
    /* Dates */
    AESTDTC = strip(AESTDTC);
    AEENDTC = strip(AEENDTC);
    
    /* Severity/Grading */
    AETOXGR = strip(put(AETOXGR, 1.));
    AESER = strip(AESER);
    
    /* Map Grade to Severity */
    if AETOXGR in ('1') then AESEV = 'MILD';
    else if AETOXGR in ('2') then AESEV = 'MODERATE';
    else if AETOXGR in ('3', '4') then AESEV = 'SEVERE';
    else if AETOXGR in ('5') then AESEV = 'DEATH';
    
    /* Study Days Calculation */
    if not missing(AESTDTC) and not missing(TRTSDT) then do;
        _stdt = input(AESTDTC, yymmdd10.);
        AESTDY = _stdt - TRTSDT + (_stdt >= TRTSDT);
    end;
    if not missing(AEENDTC) and not missing(TRTSDT) then do;
        _endt = input(AEENDTC, yymmdd10.);
        AEENDY = _endt - TRTSDT + (_endt >= TRTSDT);
    end;
    
    keep STUDYID DOMAIN USUBJID AETERM AEDECOD AESTDTC AEENDTC 
         AESTDY AEENDY AETOXGR AESER AESEV;
run;

/* Assign sequence numbers */
proc sort data=ae;
    by USUBJID AESTDTC AETERM;
run;

data ae;
    set ae;
    by USUBJID;
    
    retain AESEQ;
    if first.USUBJID then AESEQ = 0;
    AESEQ + 1;
run;

/* Create permanent SAS dataset for ADaM use */
data sdtm.ae;
    set ae;
run;

/* Create XPT */
libname xpt xport "&SDTM_PATH/ae.xpt";
data xpt.ae;
    set ae;
run;
libname xpt clear;

proc freq data=ae;
    tables AEDECOD*AETOXGR / nocum;
    title "AE Frequencies by MedDRA PT and Grade";
run;

proc print data=ae(obs=10);
    title "SDTM AE Domain - First 10 Records";
run;

