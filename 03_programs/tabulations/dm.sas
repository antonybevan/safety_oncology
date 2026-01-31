/******************************************************************************
 * Program:      dm.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Demographics (DM) domain from raw EDC extract
 * Author:       Clinical Programming Lead
 * Date:         2026-01-22
 * SAS Version:  9.4
 * SDTM Version: 1.7 / IG v3.4
 *
 * Input:        &LEGACY_PATH/raw_dm.csv
 * Output:       &SDTM_PATH/dm.xpt
 *
 * Modifications:
 * Date       Programmer    Description
 * ---------- ------------- ------------------------------------------------
 * 2026-01-22 Clinical Programming Lead   Initial version
 ******************************************************************************/

%macro load_config;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %include "../00_config.sas";
%mend;
%load_config;

* Read raw demographics data;
proc import datafile="&LEGACY_PATH/raw_dm.csv"
    out=raw_dm
    dbms=csv
    replace;
    getnames=yes;
run;

* Create DM domain per SDTM IG v3.4;
data dm;
    length 
        STUDYID $20
        DOMAIN $2
        USUBJID $40
        SUBJID $20
        RFSTDTC $10
        RFENDTC $10
        RFXSTDTC $10
        RFXENDTC $10
        RFICDTC $10
        RFPENDTC $10
        DTHDTC $10
        DTHFL $1
        SITEID $10
        AGE 8
        AGEU $10
        SEX $1
        RACE $100
        ETHNIC $100
        ARMCD $20
        ARM $200
        COUNTRY $3
    ;

    set raw_dm;

    /* Standard SDTM Variables */
    STUDYID = "&STUDYID";
    DOMAIN = "DM";
    USUBJID = strip(USUBJID);
    SUBJID = scan(USUBJID, -1, '-');  /* Extract subject number */
    SITEID = scan(USUBJID, 1, '-');   /* Extract site number */
    
    /* Dates */
    RFSTDTC = strip(RFSTDTC);         /* Subject Reference Start Date */
    RFXSTDTC = strip(TRTSDT);         /* First Study Treatment Date */
    RFXENDTC = strip(TRTSDT);         /* Last Study Treatment Date (single dose) */
    RFENDTC = "";                     /* Reference End Date (ongoing) */
    RFICDTC = strip(RFSTDTC);         /* Informed Consent Date */
    RFPENDTC = "";                    /* End of Participation (ongoing) */
    DTHDTC = "";                      /* Death Date */
    DTHFL = "";                       /* Death Flag */
    
    /* Demographics */
    AGE = AGE;
    AGEU = "YEARS";
    SEX = strip(SEX);
    RACE = strip(RACE);
    ETHNIC = "NOT HISPANIC OR LATINO";  /* Default for US trial */
    COUNTRY = "USA";
    
    /* Treatment Arms - Per SAP Section 5.3 */
    if DOSE_LEVEL = 1 then do;
        ARMCD = "DL1";
        ARM = "DL1: 1x10E6 cells/kg";
    end;
    else if DOSE_LEVEL = 2 then do;
        ARMCD = "DL2";
        ARM = "DL2: 3x10E6 cells/kg";
    end;
    else if DOSE_LEVEL = 3 then do;
        ARMCD = "DL3";
        ARM = "DL3: 480x10E6 cells";
    end;
    
    /* Additional Planned Variables (not in raw data) */
    ACTARMCD = ARMCD;  /* Actual Arm = Planned Arm (single dose study) */
    ACTARM = ARM;
    
    /* Population Flags from raw data */
    SAFFL = strip(SAFFL);
    ITTFL = strip(ITTFL);
    EFFFL = strip(EFFFL);
    
    keep STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC 
         RFICDTC RFPENDTC DTHDTC DTHFL SITEID AGE AGEU SEX RACE ETHNIC 
         ARMCD ARM COUNTRY SAFFL ITTFL EFFFL;
run;

* Sort by USUBJID;
proc sort data=dm;
    by USUBJID;
run;

/* Create permanent SAS dataset for ADaM use */
data sdtm.dm;
    set dm;
run;

/* Create XPT */
libname xpt xport "&SDTM_PATH/dm.xpt";
data xpt.dm;
    set dm;
run;
libname xpt clear;

* Print first 5 records for QC;
proc print data=dm(obs=5);
    title "SDTM DM Domain - First 5 Records";
run;

* Generate basic statistics;
proc freq data=dm;
    tables ARMCD ARM SEX RACE / nocum;
    title "Demographics Frequencies";
run;

proc means data=dm n mean std min max;
    var AGE;
    class ARMCD;
    title "Age Statistics by Dose Level";
run;

