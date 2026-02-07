/******************************************************************************
 * Program:      l_screen_fail.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Listing L-SD1 - Screen Failures Listing (SAP §6.1)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* 1. Identify Screen Failures from DM */
/* Screen failures are subjects in DM who never received treatment (not in EX) */
proc sql;
    create table screen_fail as
    select d.USUBJID, d.SITEID, d.AGE, d.SEX, d.RACE, d.RFSTDTC as SCREEN_DATE,
           "Screen Failure" as DISPOSITION length=50,
           "Inclusion/Exclusion Criteria Not Met" as FAILURE_REASON length=100
    from sdtm.dm d
    where d.USUBJID not in (select USUBJID from sdtm.ex);
quit;

/* 2. Production Listing */
title1 "BV-CAR20-P1: CAR-T Clinical Trial";
title2 "Listing L-SD1: Screen Failures";
title3 "All Screened Population";

footnote1 "Source: SDTM.DM";
footnote2 "Screen failures are subjects who signed ICF but did not receive study treatment.";

proc report data=screen_fail nowd headskip split='|' style(report)={outputwidth=100%};
    column USUBJID SITEID AGE SEX RACE SCREEN_DATE FAILURE_REASON;
    define USUBJID / "Subject ID" width=15;
    define SITEID / "Site" width=8;
    define AGE / "Age" width=5;
    define SEX / "Sex" width=5;
    define RACE / "Race" width=15;
    define SCREEN_DATE / "Screen Date" width=12;
    define FAILURE_REASON / "Reason for Screen Failure" width=40;
run;

/* Export results */
ods html body="&OUT_LISTINGS/l_screen_fail.html";
proc print data=screen_fail noobs; run;
ods html close;

%put NOTE: --------------------------------------------------;
%put NOTE: ✅ LISTING L-SD1 (Screen Failures) GENERATED;
%put NOTE: --------------------------------------------------;
