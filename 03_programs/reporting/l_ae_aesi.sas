/******************************************************************************
 * Program:      l_ae_aesi.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Listing 16.2.7 - Adverse Events of Special Interest (AESI)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-01
 * SAS Version:  9.4
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* 1. Extract AESI Records */
data aesi_listing;
    set adam.adae;
    where AESIFL = 'Y';
    
    /* Calculate Duration */
    if not missing(ASTDT) and not missing(AENDT) then 
        ADUR = AENDT - ASTDT + 1;
run;

proc sort data=aesi_listing;
    by TRTA USUBJID ASTDT;
run;

/* 2. Format for Clinical Review */
title1 "BV-CAR20-P1: CAR-T Clinical Review";
title2 "Listing 16.2.7: Adverse Events of Special Interest (AESI)";
title3 "Safety Population";

footnote1 "Note: DLTFL='Y' indicates a Dose-Limiting Toxicity (Grade 3+ persisting > 72 hours).";
footnote2 "ASTCTGR: ASTCT 2019 Consensus Grading for CRS and ICANS.";

proc report data=aesi_listing nowd headskip split='|' style(report)={outputwidth=100%};
    column TRTA USUBJID AEDECOD ASTDT AENDT ADUR ASTCTGR AEREL DLTFL;
    define TRTA     / "Actual Treatment" group width=15;
    define USUBJID  / "Subject ID" group width=20;
    define AEDECOD  / "Preferred Term" width=30;
    define ASTDT    / "Start Date" format=date9. width=12;
    define AENDT    / "End Date" format=date9. width=12;
    define ADUR     / "Dur (Days)" width=10;
    define ASTCTGR  / "ASTCT Grade" width=12 center;
    define AEREL    / "Relation" width=15;
    define DLTFL    / "DLT?" width=8 center;
    
    break after USUBJID / skip;
run;

/* Export results */
ods html body="&OUT_LISTINGS/l_ae_aesi.html";
proc print data=aesi_listing; run;
ods html close;
