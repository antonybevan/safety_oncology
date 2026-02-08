/******************************************************************************
 * Program:      dm.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Demographics (DM) domain from raw EDC extract
 * Author:       Clinical Programming Lead
 * Date:         2026-01-31
 * SAS Version:  9.4
 ******************************************************************************/

/* Environment assumed to be set by 00_main.sas -> 00_config.sas */

* Read raw demographics data;
data raw_dm;
    infile "&LEGACY_PATH/raw_dm.csv" dlm=',' dsd firstobs=2;
    /* Aligned with DM specs */
    length STUDYID $20 USUBJID $40 ARM $200 SEX $1 RACE $100 DISEASE $5 RFSTDTC TRTSDT LDSTDT $10
           SAFFL ITTFL EFFFL $1
           dose_level i subid AGE dt 8;
    input STUDYID $ USUBJID $ ARM $ SEX $ RACE $ DISEASE $ RFSTDTC $ TRTSDT $ LDSTDT $ SAFFL $ ITTFL $ EFFFL $ 
          dose_level i subid AGE dt;
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
        SAFFL ITTFL EFFFL $1
    ;

    set raw_dm;

    /* Standard SDTM Variables */
    STUDYID = "&STUDYID";
    DOMAIN = "DM";
    USUBJID = strip(USUBJID);
    SUBJID = scan(USUBJID, -1, '-');  /* Extract subject number */
    SITEID = scan(USUBJID, 1, '-');   /* Extract site number */
    
    /* Dates: First Study Treatment Date is the start of the Regimen (LD or CAR-T) */
    RFSTDTC = strip(RFSTDTC);         /* Subject Reference Start Date */
    if not missing(LDSTDT) then RFXSTDTC = strip(LDSTDT);
    else RFXSTDTC = strip(TRTSDT);
    
    RFXENDTC = strip(TRTSDT);         /* Last Study Treatment Date (single dose infusion) */
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
    
    /* Derive BRTHDTC from AGE (CDISC requirement) */
    if not missing(AGE) and not missing(RFSTDTC) then do;
        _refdt = input(RFSTDTC, yymmdd10.);
        _birthyear = year(_refdt) - AGE;
        BRTHDTC = put(_birthyear, 4.);  /* Year only (partial date) */
    end;
    
    /* Treatment Arms */
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
    
    /* Population Flags */
    SAFFL = strip(SAFFL);
    ITTFL = strip(ITTFL);
    EFFFL = strip(EFFFL);
    
    keep STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC 
         RFICDTC RFPENDTC DTHDTC DTHFL SITEID AGE AGEU SEX RACE ETHNIC 
         ARMCD ARM COUNTRY SAFFL ITTFL EFFFL DISEASE;
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

