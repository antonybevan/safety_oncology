/******************************************************************************
 * Program:      gen_trial_design.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Trial Design Domains (TS, TA, TE)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
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

/* 1. Trial Summary (TS) - Mandatory Parameters */
data ts;
    length STUDYID $20 TSPARMCD $8 TSPARM $40 TSVAL $100 TSVALCD $40;
    STUDYID = "&STUDYID";

    /* Core Parameters */
    TSPARMCD="SSTDT";  TSPARM="Study Start Date"; TSVAL="2025-01-15"; TSVALCD=""; output;
    TSPARMCD="TITLE";  TSPARM="Trial Title"; TSVAL="Clinical Safety of CD20 CAR-T (PBCAR20A)"; output;
    TSPARMCD="PHASE";  TSPARM="Trial Phase"; TSVAL="PHASE I/IIA"; TSVALCD="PHASE I/IIA"; output;
    TSPARMCD="TRT";    TSPARM="Investigational Therapy"; TSVAL="PBCAR20A"; TSVALCD=""; output;
    TSPARMCD="INDIC";  TSPARM="Trial Indication"; TSVAL="NH Lymphoma and CLL/SLL"; TSVALCD=""; output;
run;

/* 2. Trial Elements (TE) */
data te;
    length STUDYID $20 ETCD $8 ELEMENT $40 TESTRL $100;
    STUDYID = "&STUDYID";
    
    ETCD="LD";     ELEMENT="Lymphodepletion"; TESTRL="Start of Fludarabine/Cyclophosphamide"; output;
    ETCD="CART";   ELEMENT="CAR-T Infusion";  TESTRL="Start of PBCAR20A Infusion"; output;
    ETCD="FU";     ELEMENT="Follow-Up";       TESTRL="End of CAR-T Infusion"; output;
run;

/* 3. Trial Arms (TA) */
data ta;
    length STUDYID $20 ARMCD $8 ARM $40 TAETORD 8 ETCD $8;
    STUDYID = "&STUDYID";

    /* Dose Level 1 Arm */
    ARMCD="DL1"; ARM="Dose Level 1"; TAETORD=1; ETCD="LD"; output;
    ARMCD="DL1"; ARM="Dose Level 1"; TAETORD=2; ETCD="CART"; output;
    ARMCD="DL1"; ARM="Dose Level 1"; TAETORD=3; ETCD="FU"; output;

    /* Dose Level 3 Arm (DL2 skipped) */
    ARMCD="DL3"; ARM="Dose Level 3"; TAETORD=1; ETCD="LD"; output;
    ARMCD="DL3"; ARM="Dose Level 3"; TAETORD=2; ETCD="CART"; output;
    ARMCD="DL3"; ARM="Dose Level 3"; TAETORD=3; ETCD="FU"; output;
run;

/* Export to SDTM library */
data sdtm.ts; set ts; run;
data sdtm.te; set te; run;
data sdtm.ta; set ta; run;

/* Export to XPT for submission package */
libname xpt xport "&SDTM_PATH/ts.xpt"; data xpt.ts; set ts; run; libname xpt clear;
libname xpt xport "&SDTM_PATH/te.xpt"; data xpt.te; set te; run; libname xpt clear;
libname xpt xport "&SDTM_PATH/ta.xpt"; data xpt.ta; set ta; run; libname xpt clear;

%put NOTE: --------------------------------------------------;
%put NOTE: ✅ TRIAL DESIGN DOMAINS (TS, TA, TE) GENERATED;
%put NOTE: --------------------------------------------------;


