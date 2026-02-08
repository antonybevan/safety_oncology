/******************************************************************************
 * Program:      ex.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Exposure (EX) domain from raw EDC extract
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

* Read raw EX data;
data raw_ex;
    infile "&LEGACY_PATH/raw_ex.csv" dlm=',' dsd firstobs=2;
    /* Aligned with EX specs */
    length STUDYID $20 USUBJID $40 ARM $200 SEX $1 RACE $100 DISEASE $5 RFSTDTC TRTSDT LDSTDT $10
           SAFFL ITTFL EFFFL $1
           EXTRT $100 EXDOSE 8 EXDOSU $20 EXSTDTC EXENDTC $10 EXADJ $20 day0 d 8;
    input STUDYID $ USUBJID $ ARM $ SEX $ RACE $ DISEASE $ RFSTDTC $ TRTSDT $ LDSTDT $ SAFFL $ ITTFL $ EFFFL $ 
          dose_level i subid AGE dt EXTRT $ EXDOSE EXDOSU $ EXSTDTC $ EXENDTC $ EXLOT $ EXADJ $ day0 d;
run;

data ex;
    length 
        STUDYID $20
        DOMAIN $2
        USUBJID $40
        EXTRT $200
        EXDOSE 8
        EXDOSU $20
        EXDOSFRM $20
        EXROUTE $20
        EXSTDTC $10
        EXENDTC $10
        EXSTDY 8
        EXENDY 8
        TRTSDT_NUM 8.
    ;

    set raw_ex;

    /* Standard Variables */
    STUDYID = "&STUDYID";
    DOMAIN = "EX";
    USUBJID = strip(USUBJID);
    TRTSDT_NUM = input(TRTSDT, yymmdd10.);
    
    /* Treatment Info */
    EXTRT = strip(EXTRT);
    EXDOSE = EXDOSE;
    EXDOSU = strip(EXDOSU);
    EXDOSFRM = "STEADY STATE";
    EXROUTE = "INTRAVENOUS";

    /* Dates */
    EXSTDTC = strip(EXSTDTC);
    EXENDTC = strip(EXENDTC);
    
    /* Study Days Calculation */
    if not missing(EXSTDTC) and not missing(TRTSDT_NUM) then do;
        _stdt = input(EXSTDTC, yymmdd10.);
        EXSTDY = _stdt - TRTSDT_NUM + (_stdt >= TRTSDT_NUM);
    end;
    if not missing(EXENDTC) and not missing(TRTSDT_NUM) then do;
        _endt = input(EXENDTC, yymmdd10.);
        EXENDY = _endt - TRTSDT_NUM + (_endt >= TRTSDT_NUM);
    end;
    
    keep STUDYID DOMAIN USUBJID EXTRT EXDOSE EXDOSU EXLOT EXADJ EXDOSFRM EXROUTE 
         EXSTDTC EXENDTC EXSTDY EXENDY;
run;

/* Assign sequence numbers */
proc sort data=ex;
    by USUBJID EXSTDTC EXTRT;
run;

data sdtm.ex;
    set ex;
    by USUBJID;
    
    retain EXSEQ;
    if first.USUBJID then EXSEQ = 0;
    EXSEQ + 1;
run;

/* Create XPT */
libname xpt xport "&SDTM_PATH/ex.xpt";
data xpt.ex;
    set sdtm.ex;
run;
libname xpt clear;

