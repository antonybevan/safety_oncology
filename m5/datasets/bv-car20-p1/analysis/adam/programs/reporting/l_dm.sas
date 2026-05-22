/******************************************************************************
 * Program:      l_dm.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Listing 16.2.1 - Subject Disposition
 * Author:       Statistical Programmer
 * Date:         2026-02-01
 * SAS Version:  9.4
 ******************************************************************************/

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
%ods_setup(type=RTF, outpath=&OUT_LISTINGS/l_dm.rtf);

title1 "&STUDYID: CAR-T Clinical Review";
title2 "Listing 16.2.1: Subject Disposition";
title3 "All Enrolled Subjects";

footnote1 "Note: TRTSDT = Start of Regimen (LD); CARTDT = Infusion of PBCAR20A.";
footnote2 "Status based on completion of Day 28 DLT/Efficacy window.";

proc report data=disposition nowd headskip split='|' style(report)={outputwidth=100%};
    column ARMCD USUBJID RFICDTC TRTSDT CARTDT ITTFL SAFFL EFFFL STATUS;
    define ARMCD    / "Dose Level" order width=12;
    define USUBJID  / "Subject ID" width=15;
    define RFICDTC  / "Informed Consent" width=15;
    define TRTSDT   / "Regimen Start" width=15;
    define CARTDT   / "CAR-T Infusion" width=15;
    define ITTFL    / "ITT?" width=5 center;
    define SAFFL    / "Saff?" width=5 center;
    define EFFFL    / "Eff?" width=5 center;
    define STATUS   / "Analysis Status" width=25;
run;

%ods_close(type=RTF);


