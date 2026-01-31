/******************************************************************************
 * Program:      ex.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Exposure (EX) domain from raw EDC extract
 * Author:       Clinical Programming Lead
 * Date:         2026-01-22
 * SAS Version:  9.4
 * SDTM Version: 1.7 / IG v3.4
 *
 * Input:        &LEGACY_PATH/raw_ex.csv
 * Output:       &SDTM_PATH/ex.xpt
 *
 * Notes:        Per SAP Section 1.3, creates separate records for:
 *               - Fludarabine (LD)
 *               - Cyclophosphamide (LD)
 *               - BV-CAR20 (Study Drug)
 ******************************************************************************/

%macro load_config;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %include "../00_config.sas";
%mend;
%load_config;


proc import datafile="&LEGACY_PATH/raw_ex.csv"
    out=raw_ex
    dbms=csv
    replace;
    getnames=yes;
run;

data ex;
    length 
        STUDYID $20
        DOMAIN $2
        USUBJID $40
        EXSEQ 8
        EXTRT $200
        EXDOSE 8
        EXDOSU $20
        EXDOSFRM $20
        EXROUTE $20
        EXSTDTC $10
        EXENDTC $10
        EXSTDY 8
        EXENDY 8
    ;

    set raw_ex;

    /* Standard Variables */
    STUDYID = "&STUDYID";
    DOMAIN = "EX";
    USUBJID = strip(USUBJID);
    
    /* Treatment Info */
    EXTRT = strip(EXTRT);
    EXDOSE = EXDOSE;
    EXDOSU = strip(EXDOSU);
    EXDOSFRM = "STEADY STATE";
    if upcase(EXTRT) = 'BV-CAR20' then EXROUTE = "INTRAVENOUS";
    else EXROUTE = "INTRAVENOUS"; /* Both LD and CAR-T are IV */
    
    /* Dates */
    EXSTDTC = strip(EXSTDTC);
    EXENDTC = strip(EXENDTC);
    
    /* Study Days will be derived in a separate step */
    EXSTDY = .;
    EXENDY = .;
    
    keep STUDYID DOMAIN USUBJID EXTRT EXDOSE EXDOSU EXDOSFRM EXROUTE 
         EXSTDTC EXENDTC EXSTDY EXENDY;
run;

/* Assign sequence numbers */
proc sort data=ex;
    by USUBJID EXSTDTC EXTRT;
run;

/* Create permanent SAS dataset for ADaM use */
data sdtm.ex;
    set ex;
run;

data ex;
    set ex;
    by USUBJID;
    
    retain EXSEQ;
    if first.USUBJID then EXSEQ = 0;
    EXSEQ + 1;
run;

/* Create XPT */
libname xpt xport "&SDTM_PATH/ex.xpt";
data xpt.ex;
    set ex;
run;
libname xpt clear;

proc print data=ex(obs=10);
    title "SDTM EX Domain - First 10 Records";
run;

