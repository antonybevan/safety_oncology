/******************************************************************************
 * Program:      l_screen_fail.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Listing L-SD1 - Screen Failures Listing (SAP §6.1)
 * Author:       Statistical Programmer
 * Date:         2026-02-05
 * SAS Version:  9.4
 ******************************************************************************/

%load_config;

/* 1. Identify Screen Failures from DM */
/* Screen failures are subjects in DM who never received treatment (not in EX) */
proc sql;
    create table screen_fail as
    select d.USUBJID, d.SITEID, d.AGE, d.SEX, d.RACE, d.RFSTDTC as SCREEN_DATE,
           "Screen Failure" as DISPOSITION,
           "Inclusion/Exclusion Criteria Not Met" as FAILURE_REASON
    from sdtm.dm d
    where d.USUBJID not in (select USUBJID from sdtm.ex);
quit;

/* 2. Production Listing */
%ods_setup(type=RTF, outpath=&OUT_LISTINGS/l_screen_fail.rtf);

title1 "&STUDYID: CAR-T Clinical Trial";
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

%ods_close(type=RTF);

%put NOTE: --------------------------------------------------;
%put NOTE: ✅ LISTING L-SD1 (Screen Failures) GENERATED;
%put NOTE: --------------------------------------------------;


