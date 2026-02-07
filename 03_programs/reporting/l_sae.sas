/******************************************************************************
 * Program:      l_sae.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Listing L-SAE1 - All Treatment-Emergent SAEs (SAP §8.2.1)
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

/* 1. Extract TESAEs from ADAE */
data tesae_listing;
    set adam.adae;
    where TRTEMFL = 'Y' and AESER = 'Y';
    keep USUBJID ARMCD AEDECOD AESEV AETOXGRN AESER AEREL ASTDT AENDT AEOUT AESIFL DLTFL;
run;

/* 2. Sort for listing */
proc sort data=tesae_listing;
    by USUBJID ASTDT;
run;

/* 3. Production Listing */
title1 "BV-CAR20-P1: CAR-T Clinical Trial";
title2 "Listing L-SAE1: All Treatment-Emergent Serious Adverse Events";
title3 "Safety Population";

footnote1 "Source: ADAM.ADAE";
footnote2 "TESAEs are defined as SAEs occurring after start of study regimen.";

proc report data=tesae_listing nowd headskip split='|' style(report)={outputwidth=100%};
    column USUBJID ARMCD AEDECOD AETOXGRN AEREL ASTDT AENDT AEOUT AESIFL DLTFL;
    define USUBJID / "Subject ID" width=15;
    define ARMCD / "Dose Level" width=8;
    define AEDECOD / "Preferred Term" width=30;
    define AETOXGRN / "Grade" width=5;
    define AEREL / "Related" width=8;
    define ASTDT / "Start Date" width=10 format=date9.;
    define AENDT / "End Date" width=10 format=date9.;
    define AEOUT / "Outcome" width=15;
    define AESIFL / "AESI" width=5;
    define DLTFL / "DLT" width=5;
run;

/* Export results */
ods html body="&OUT_LISTINGS/l_sae.html";
proc print data=tesae_listing noobs; run;
ods html close;

%put NOTE: --------------------------------------------------;
%put NOTE: ✅ LISTING L-SAE1 (All TESAEs) GENERATED;
%put NOTE: --------------------------------------------------;
