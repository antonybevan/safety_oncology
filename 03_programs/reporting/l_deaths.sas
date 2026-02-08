/******************************************************************************
 * Program:      l_deaths.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Listing L-SAE2 - All Deaths (SAP §8.2.1)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
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

/* 1. Extract Deaths from ADSL */
data deaths_listing;
    set adam.adsl;
    where not missing(DTHDT) or DTHFL = 'Y';
    keep USUBJID ARMCD AGE SEX COHORT DTHDT DTHDTC DTHCAUS;
run;

/* If DTHDT/DTHDTC not available, derive from AE with fatal outcome */
proc sql;
    create table deaths_from_ae as
    select distinct a.USUBJID, a.ARMCD, b.AGE, b.SEX, b.COHORT,
           a.AENDT as DTHDT format=date9.,
           a.AEDECOD as DTHCAUS length=100
    from adam.adae a
    inner join adam.adsl b on a.USUBJID = b.USUBJID
    where upcase(a.AEOUT) = 'FATAL'
    order by a.USUBJID;
quit;

/* Combine sources */
data all_deaths;
    set deaths_listing deaths_from_ae;
run;

proc sort data=all_deaths nodupkey;
    by USUBJID;
run;

/* 2. Production Listing */
title1 "&STUDYID: CAR-T Clinical Trial";
title2 "Listing L-SAE2: All Deaths";
title3 "Safety Population";

footnote1 "Source: ADAM.ADSL, ADAM.ADAE";
footnote2 "Deaths are identified from disposition data or fatal AE outcomes.";

proc report data=all_deaths nowd headskip split='|' style(report)={outputwidth=100%};
    column USUBJID ARMCD AGE SEX COHORT DTHDT DTHCAUS;
    define USUBJID / "Subject ID" width=15;
    define ARMCD / "Dose Level" width=8;
    define AGE / "Age" width=5;
    define SEX / "Sex" width=5;
    define COHORT / "Disease" width=8;
    define DTHDT / "Death Date" width=12 format=date9.;
    define DTHCAUS / "Cause of Death" width=40;
run;

/* Export results */
ods html body="&OUT_LISTINGS/l_deaths.html";
proc print data=all_deaths noobs; run;
ods html close;

%put NOTE: --------------------------------------------------;
%put NOTE: ✅ LISTING L-SAE2 (All Deaths) GENERATED;
%put NOTE: --------------------------------------------------;


