/******************************************************************************
 * Program:      l_dm.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Listing 16.2.1 - Subject Disposition
 * Author:       Clinical Programming Lead
 * Date:         2026-02-01
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

/* 1. Prepare Disposition Data */
data disposition;
    set adam.adsl;
    
    length STATUS $40;
    if EFFFL = 'Y' then STATUS = "Completed Efficacy Eval";
    else if SAFFL = 'Y' then STATUS = "Safety Eval Only";
    else STATUS = "LD Only / Discontinued";
    
    format TRTSDT CARTDT date9.;
run;

proc sort data=disposition;
    by ARMCD USUBJID;
run;

/* 2. Format Listing */
title1 "&STUDYID: CAR-T Clinical Review";
title2 "Listing 16.2.1: Subject Disposition";
title3 "All Enrolled Subjects";

footnote1 "Note: TRTSDT = Start of Regimen (LD); CARTDT = Infusion of PBCAR20A.";
footnote2 "Status based on completion of Day 28 DLT/Efficacy window.";

proc report data=disposition nowd headskip split='|' style(report)={outputwidth=100%};
    column ARMCD USUBJID RFICDTC TRTSDT CARTDT ITTFL SAFFL EFFFL STATUS;
    define ARMCD    / "Dose Level" group width=12;
    define USUBJID  / "Subject ID" width=15;
    define RFICDTC  / "Informed Consent" width=15;
    define TRTSDT   / "Regimen Start" width=15;
    define CARTDT   / "CAR-T Infusion" width=15;
    define ITTFL    / "ITT?" width=5 center;
    define SAFFL    / "Saff?" width=5 center;
    define EFFFL    / "Eff?" width=5 center;
    define STATUS   / "Analysis Status" width=25;
run;

/* Export results */
ods html body="&OUT_LISTINGS/l_dm.html";
proc print data=disposition; run;
ods html close;


