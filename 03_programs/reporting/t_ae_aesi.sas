/******************************************************************************
 * Program:      t_ae_aesi.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Table 3.5 - Summary of AEs of Special Interest and Infections by Max Toxicity Grade and Dose
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

/* 1. Get Population Totals */
proc sql noprint;
    select count(*) into :N_DL1 from adam.adsl where SAFFL = 'Y' and ARMCD = 'DL1';
    select count(*) into :N_DL2 from adam.adsl where SAFFL = 'Y' and ARMCD = 'DL2';
    select count(*) into :N_DL3 from adam.adsl where SAFFL = 'Y' and ARMCD = 'DL3';
quit;

%let N_DL1 = %trim(&N_DL1);
%let N_DL2 = %trim(&N_DL2);
%let N_DL3 = %trim(&N_DL3);

/* 2. Process AESI Data */
data aesi_data;
    set adam.adae;
    where (AESIFL = 'Y' or INFFL = 'Y') and TRTEMFL = 'Y';
run;

/* 3. Categorize by AESI Type and Max ASTCT Grade */
proc sql;
    create table aesi_summary as
    select USUBJID, ARMCD, 
           max(case when AESICAT = 'CRS' then 1 else 0 end) as CRS_FL,
           max(case when AESICAT = 'ICANS' then 1 else 0 end) as ICANS_FL,
           max(case when AESICAT = 'GVHD' then 1 else 0 end) as GVHD_FL,
           max(case when INFFL = 'Y' then 1 else 0 end) as INF_FL,
           max(AETOXGRN) as MAX_ASTCT_GR
    from aesi_data
    group by USUBJID, ARMCD;
quit;

/* 4. Grouping and Counting */
proc freq data=aesi_summary noprint;
    tables ARMCD * CRS_FL / out=crs_counts;
    tables ARMCD * ICANS_FL / out=icans_counts;
    tables ARMCD * GVHD_FL / out=gvhd_counts;
    tables ARMCD * INF_FL / out=inf_counts;
run;

/* 5. Production Table Formatting (Mockup logic for Portfolio) */
title1 "&STUDYID: CAR-T Safety Analysis";
title2 "Table 3.5: Summary of AEs of Special Interest and Infections by Max Toxicity Grade and Dose";
%load_config;

/* 1. Get Population Totals */
proc sql noprint;
    select count(*) into :N_DL1 from adam.adsl where SAFFL = 'Y' and ARMCD = 'DL1';
    select count(*) into :N_DL2 from adam.adsl where SAFFL = 'Y' and ARMCD = 'DL2';
    select count(*) into :N_DL3 from adam.adsl where SAFFL = 'Y' and ARMCD = 'DL3';
quit;

%let N_DL1 = %trim(&N_DL1);
%let N_DL2 = %trim(&N_DL2);
%let N_DL3 = %trim(&N_DL3);

/* 2. Process AESI Data */
data aesi_data;
    set adam.adae;
    where (AESIFL = 'Y' or INFFL = 'Y') and TRTEMFL = 'Y';
run;

/* 3. Categorize by AESI Type and Max ASTCT Grade */
proc sql;
    create table aesi_summary as
    select USUBJID, ARMCD, 
           max(case when AESICAT = 'CRS' then 1 else 0 end) as CRS_FL,
           max(case when AESICAT = 'ICANS' then 1 else 0 end) as ICANS_FL,
           max(case when AESICAT = 'GVHD' then 1 else 0 end) as GVHD_FL,
           max(case when INFFL = 'Y' then 1 else 0 end) as INF_FL,
           max(AETOXGRN) as MAX_ASTCT_GR
    from aesi_data
    group by USUBJID, ARMCD;
quit;

/* 4. Grouping and Counting */
proc freq data=aesi_summary noprint;
    tables ARMCD * CRS_FL / out=crs_counts;
    tables ARMCD * ICANS_FL / out=icans_counts;
    tables ARMCD * GVHD_FL / out=gvhd_counts;
    tables ARMCD * INF_FL / out=inf_counts;
run;

/* 5. Production Table Formatting (Mockup logic for Portfolio) */
title1 "&STUDYID: CAR-T Safety Analysis";
title2 "Table 3.5: Summary of AEs of Special Interest and Infections by Max Toxicity Grade and Dose";
title3 "Safety Population";

footnote1 "Note: CRS and ICANS are graded via ASTCT 2019 Consensus Criteria.";
footnote2 "GvHD is assessed via Protocol-specified organ grading.";

proc report data=aesi_summary nowd headskip split='|' style(report)={outputwidth=100%};
    column ARMCD, (CRS_FL ICANS_FL GVHD_FL INF_FL);
    define ARMCD / across "Dose Level" ;
    define CRS_FL / analysis sum "Subjects with CRS" center;
    define ICANS_FL / analysis sum "Subjects with ICANS" center;
    define GVHD_FL / analysis sum "Subjects with GvHD" center;
    define INF_FL / analysis sum "Subjects with Infections" center;

