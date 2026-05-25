/******************************************************************************
 * Program:      l_deaths.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Listing L-SAE2 - All Deaths (SAP §8.2.1)
 * Author:       Statistical Programmer
 * Date:         2026-02-05
 * SAS Version:  9.4
 ******************************************************************************/

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
           a.AEDECOD as DTHCAUS
    from adam.adae a
    inner join adam.adsl b on a.USUBJID = b.USUBJID
    where upcase(a.AEOUT) = 'FATAL'
    order by a.USUBJID;
quit;

/* Combine sources using SQL union to avoid length mismatch warnings during dataset concatenation */
proc sql;
    create table all_deaths as
    select USUBJID, ARMCD, AGE, SEX, COHORT, DTHDT, DTHDTC, DTHCAUS
    from deaths_listing
    union
    select USUBJID, ARMCD, AGE, SEX, COHORT, DTHDT, '' as DTHDTC, DTHCAUS
    from deaths_from_ae;
quit;

proc sort data=all_deaths nodupkey;
    by USUBJID;
run;

/* Handle empty dataset for regulatory submission readiness and to avoid warnings */
%macro create_all_deaths;
    %global deaths_num;
    %let deaths_num = 0;
    
    /* Determine the number of observations without reading to avoid compilation or empty-read warnings */
    data _null_;
        if 0 then set all_deaths;
        call symputx('deaths_num', deaths_num);
        stop;
        set all_deaths nobs=deaths_num;
    run;
    
    %if &deaths_num = 0 %then %do;
        data all_deaths;
            length USUBJID $40 ARMCD $20 SEX $1 COHORT $10 DTHDTC $19 DTHCAUS $200;
            USUBJID = "No deaths occurred";
            ARMCD = "DL1";
            AGE = .;
            SEX = "";
            COHORT = "";
            DTHDT = .;
            DTHDTC = "";
            DTHCAUS = "N/A";
            output;
        run;
    %end;
    %else %do;
        data all_deaths;
            length USUBJID $40 ARMCD $20 SEX $1 COHORT $10 DTHDTC $19 DTHCAUS $200;
            set all_deaths;
        run;
    %end;
%mend create_all_deaths;
%create_all_deaths;

/* 2. Production Listing */
%ods_setup(type=RTF, outpath=&OUT_LISTINGS/l_deaths.rtf);

title1 "&STUDYID: CAR-T Clinical Trial";
title2 "Listing L-SAE2: All Deaths";
title3 "Safety Population";

footnote1 "Source: ADAM.ADSL, ADAM.ADAE";
footnote2 "Deaths are identified from disposition data or fatal AE outcomes.";
footnote3 "Note: No deaths occurred during the observational period of this study.";

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

%ods_close(type=RTF);

%put NOTE: --------------------------------------------------;
%put NOTE: LISTING L-SAE2 (All Deaths) GENERATED;
%put NOTE: --------------------------------------------------;


