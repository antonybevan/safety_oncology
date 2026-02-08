/******************************************************************************
 * Program:      suppae.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Supplemental AE (SUPPAE) domain for ASTCT grading
 * Author:       Clinical Programming Lead
 * Date:         2026-01-31
 * SAS Version:  9.4
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(03_programs/00_config.sas)) %then %include "03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
   %else %if %sysfunc(fileexist(../03_programs/00_config.sas)) %then %include "../03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../../00_config.sas)) %then %include "../../00_config.sas";
   %else %if %sysfunc(fileexist(../../03_programs/00_config.sas)) %then %include "../../03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../../../00_config.sas)) %then %include "../../../00_config.sas";
   %else %if %sysfunc(fileexist(../../../03_programs/00_config.sas)) %then %include "../../../03_programs/00_config.sas";
   %else %do;
      %put ERROR: Unable to locate 00_config.sas from current working directory.;
      %abort cancel;
   %end;
%mend;
%load_config;

* Read raw AE data for supplemental mapping;
data raw_ae;
    infile "&LEGACY_PATH/raw_ae.csv" dlm=',' dsd firstobs=2;
    /* Aligned with AE specs */
    length STUDYID $20 USUBJID $40 ARM $100 SEX $1 RACE $40 DISEASE $5 RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL $100
           dose_level i subid AGE dt 8
           AEDECOD AETERM AETOXGR AESOC AEREL $100 AESTDTC AEENDTC $10 AESER $1 AESID 8 day0 8;
    input STUDYID $ USUBJID $ ARM $ SEX $ RACE $ DISEASE $ RFSTDTC $ TRTSDT $ LDSTDT $ SAFFL $ ITTFL $ EFFFL $ 
          dose_level i subid AGE dt AEDECOD $ AETERM $ AETOXGR $ AESOC $ AEREL $ AESTDTC $ AEENDTC $ AESER $ AESID day0;
run;

/* First, ensure we have the actual SDTM AE domain to get the real AESEQ */
data ae_map;
    length AETERM $200;
    set sdtm.ae(keep=USUBJID AETERM AESTDTC AESEQ AESID);
run;

proc sort data=raw_ae; by USUBJID AETERM AESTDTC AESID; run;
proc sort data=ae_map; by USUBJID AETERM AESTDTC AESID; run;

data aesi;
    length AETERM $200;
    merge raw_ae(in=a) ae_map(in=b);
    by USUBJID AETERM AESTDTC AESID;
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
    
    /* ASTCT Grade mapping */
    QNAM = "ASTCTGR";
    QLABEL = "ASTCT 2019 Grade";
    
    _term = upcase(strip(AEDECOD));
    if index(_term, 'CYTOKINE RELEASE') > 0 or 
       index(_term, 'NEUROTOXICITY') > 0 or 
       index(_term, 'IMMUNE EFFECTOR') > 0 then do;
        /* Extract only the digit from GRADE X */
        QVAL = compress(AETOXGR, , 'kd');
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

