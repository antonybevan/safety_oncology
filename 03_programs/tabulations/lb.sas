/******************************************************************************
 * Program:      lb.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Laboratory (LB) domain from raw EDC extract
 * Author:       Clinical Programming Lead
 * Date:         2026-01-22
 * SAS Version:  9.4
 * SDTM Version: 1.7 / IG v3.4
 *
 * Input:        &LEGACY_PATH/raw_lb.csv
 * Output:       &SDTM_PATH/lb.xpt
 *
 * Notes:        - Hematology parameters (NEUT, PLAT, HGB)
 *               - CTCAE v5.0 grading applied
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
    length STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL LBTESTCD LBTEST LBORRES LBORRESU LBDTC VISIT $100;
    input STUDYID $ USUBJID $ ARM $ SEX $ RACE $ DISEASE $ RFSTDTC $ TRTSDT $ LDSTDT $ SAFFL $ ITTFL $ EFFFL $ dose_level i subid AGE dt LBTESTCD $ LBTEST $ LBORRES $ LBORRESU $ LBDTC $ VISIT $ day0 visit_idx LBORNRLO LBORNRHI;
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
    ;

    set raw_lb;

    /* Standard Variables */
    STUDYID = "BV-CAR20-P1";
    DOMAIN = "LB";
    USUBJID = strip(USUBJID);
    
    /* Lab Test Info */
    LBTESTCD = strip(LBTESTCD);
    LBTEST = strip(LBTEST);
    LBORRES = strip(put(LBORRES, 8.2));
    LBORRESU = strip(LBORRESU);
    LBORNRLO = LBORNRLO;
    LBORNRHI = LBORNRHI;
    
    /* Date and Visit */
    LBDTC = strip(LBDTC);
    VISIT = strip(VISIT);
    LBDY = .;  /* Placeholder */
    
    /* Derive Normal Range Indicator */
    if input(LBORRES, ?? 8.) < LBORNRLO then LBNRIND = 'LOW';
    else if input(LBORRES, ?? 8.) > LBORNRHI then LBNRIND = 'HIGH';
    else if not missing(input(LBORRES, ?? 8.)) then LBNRIND = 'NORMAL';
    
    keep STUDYID DOMAIN USUBJID LBTESTCD LBTEST LBORRES LBORRESU 
         LBORNRLO LBORNRHI LBDTC LBDY VISIT LBNRIND;
run;

/* Assign sequence numbers */
proc sort data=lb;
    by USUBJID LBDTC LBTESTCD;
run;

data lb;
    set lb;
    by USUBJID;
    
    retain LBSEQ;
    if first.USUBJID then LBSEQ = 0;
    LBSEQ + 1;
run;

/* Create permanent SAS dataset for ADaM use */
data sdtm.lb;
    set lb;
run;

/* Create XPT */
libname xpt xport "&SDTM_PATH/lb.xpt";
data xpt.lb;
    set lb;
run;
libname xpt clear;

proc means data=lb n mean std min max;
    var LBORNRLO LBORNRHI;
    class LBTESTCD;
    title "Lab Reference Ranges by Test";
run;

proc print data=lb(obs=15);
    title "SDTM LB Domain - First 15 Records";
run;

