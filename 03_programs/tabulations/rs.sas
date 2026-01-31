/******************************************************************************
 * Program:      rs.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Disease Response (RS) domain from raw EDC extract
 * Author:       Clinical Programming Lead
 * Date:         2026-01-31
 * SAS Version:  9.4
 * SDTM Version: 1.7 / IG v3.4
 *
 * Input:        &LEGACY_PATH/raw_rs.csv
 * Output:       &SDTM_PATH/rs.xpt
 *
 * Notes:        Best Overall Response per SAP Section 7.1.1
 *               - NHL: Lugano 2016 criteria
 *               - CLL/SLL: iwCLL 2018 guidelines
 ******************************************************************************/

%macro load_config;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %include "../00_config.sas";
%mend;
%load_config;
proc import datafile="&LEGACY_PATH/raw_rs.csv"
    out=raw_rs
    dbms=csv
    replace;
    getnames=yes;
run;

data rs;
    length 
        STUDYID $20
        DOMAIN $2
        USUBJID $40
        RSSEQ 8
        RSTESTCD $8
        RSTEST $40
        RSORRES $20
        RSSTRESC $20
        RSDTC $10
        RSDY 8
        RSEVAL $20
        RSEVALID $20
        RSCAT $40
    ;

    set raw_rs;

    /* Standard Variables */
    STUDYID = "&STUDYID";
    DOMAIN = "RS";
    USUBJID = strip(USUBJID);
    
    /* Test Info */
    RSTESTCD = strip(RSTESTCD);
    RSTEST = strip(RSTEST);
    if missing(RSTEST) then do;
        if RSTESTCD = 'BOR' then RSTEST = 'Best Overall Response';
        else if RSTESTCD = 'OVRLRESP' then RSTEST = 'Overall Response';
    end;
    
    /* Response Result */
    RSORRES = strip(RSORRES);
    RSSTRESC = strip(RSORRES);  /* Standardized = Original for CR/PR/SD/PD */
    
    /* Date */
    RSDTC = strip(RSDTC);
    RSDY = .;  /* Placeholder */
    
    /* Evaluator */
    RSEVAL = "INVESTIGATOR";
    RSEVALID = "";
    
    /* Category */
    RSCAT = "DISEASE ASSESSMENT";
    
    keep STUDYID DOMAIN USUBJID RSTESTCD RSTEST RSORRES RSSTRESC 
         RSDTC RSDY RSEVAL RSEVALID RSCAT;
run;

/* Assign sequence numbers */
proc sort data=rs;
    by USUBJID RSDTC;
run;

data rs;
    set rs;
    by USUBJID;
    
    retain RSSEQ;
    if first.USUBJID then RSSEQ = 0;
    RSSEQ + 1;
run;

/* Create permanent SAS dataset for ADaM use */
data sdtm.rs;
    set rs;
run;

/* Create XPT */
libname xpt xport "&SDTM_PATH/rs.xpt";
data xpt.rs;
    set rs;
run;
libname xpt clear;

proc freq data=rs;
    tables RSORRES / nocum;
    title "Best Overall Response Frequencies";
run;

proc print data=rs;
    title "SDTM RS Domain - Disease Response";
run;

