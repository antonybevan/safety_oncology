/******************************************************************************
 * Program:      suppae.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Supplemental AE (SUPPAE) domain for ASTCT grading
 * Author:       Clinical Programming Lead
 * Date:         2026-01-22
 * SAS Version:  9.4
 * SDTM Version: 1.7 / IG v3.4
 *
 * Input:        &LEGACY_PATH/raw_ae.csv
 * Output:       &SDTM_PATH/suppae.xpt
 *
 * Notes:        ASTCT 2019 grading for CRS/ICANS stored as supplemental qualifiers
 *               per SAP Section 8.2.2 and CDISC SDTM IG v3.4
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

* Read raw AE data for supplemental mapping;
data raw_ae;
    infile "&LEGACY_PATH/raw_ae.csv" dlm=',' dsd firstobs=2;
    length STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL AETERM AEDECOD AESTDTC AEENDTC AETOXGR AESER $100;
    input STUDYID $ USUBJID $ ARM $ SEX $ RACE $ DISEASE $ RFSTDTC $ TRTSDT $ LDSTDT $ SAFFL $ ITTFL $ EFFFL $ dose_level i subid AGE AETERM $ AEDECOD $ AESTDTC $ AEENDTC $ day0 AETOXGR_NUM AETOXGR $ AESER $;
run;

/* First, ensure we have the actual SDTM AE domain to get the real AESEQ */
/* Note: In a real environment, AE would be run before SUPPAE */
data ae_map;
    set sdtm.ae(keep=USUBJID AETERM AESTDTC AESEQ);
run;

/* Filter raw data to AESI only and join with AE map */
proc sort data=raw_ae; by USUBJID AETERM AESTDTC; run;

/* Check if AESI_FL exists, if not, assume standard keywords identify AESIs */
data raw_ae_rev;
    set raw_ae;
    _term = upcase(AETERM);
    if index(_term, 'SYNDROME') > 0 or 
       index(_term, 'NEURO') > 0 or 
       index(_term, 'GRAFT') > 0 then _aesi = 'Y';
    else _aesi = 'N';
run;

proc sort data=ae_map; by USUBJID AETERM AESTDTC; run;

data aesi;
    merge raw_ae_rev(in=a) ae_map(in=b);
    by USUBJID AETERM AESTDTC;
    if a and b;
run;

/* Create SUPPAE for ASTCT grading */
data suppae;
    length 
        STUDYID $20
        RDOMAIN $2
        USUBJID $40
        IDVAR $8
        IDVARVAL $40
        QNAM $20
        QLABEL $40
        QVAL $200
        QORIG $20
        QEVAL $20
    ;

    set aesi;

    /* Standard Variables */
    STUDYID = "&STUDYID";
    RDOMAIN = "AE";
    USUBJID = strip(USUBJID);
    IDVAR = "AESEQ";
    IDVARVAL = strip(put(AESEQ, 8.));
    QORIG = "CRF";
    QEVAL = "";
    
    /* ASTCT Grade */
    QNAM = "ASTCTGR";
    QLABEL = "ASTCT 2019 Grade";
    
    /* Map AEDECOD to ASTCT grading system using index() instead of contains */
    _term = upcase(strip(AEDECOD));
    if index(_term, 'CYTOKINE RELEASE') > 0 or 
       index(_term, 'NEUROTOXICITY') > 0 or 
       index(_term, 'IMMUNE EFFECTOR') > 0 or
       index(_term, 'GRAFT') > 0 then do;
        QVAL = strip(put(AETOXGR, 1.));  /* Map Grade */
        output;
    end;
    
    keep STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM QLABEL QVAL QORIG QEVAL;
run;

proc sort data=suppae;
    by USUBJID IDVARVAL;
run;

/* Create permanent SAS dataset for ADaM use */
data sdtm.suppae;
    set suppae;
run;

/* Create XPT */
libname xpt xport "&SDTM_PATH/suppae.xpt";
data xpt.suppae;
    set suppae;
run;
libname xpt clear;

proc print data=suppae;
    title "SDTM SUPPAE Domain - ASTCT Grading for AESI";
run;

