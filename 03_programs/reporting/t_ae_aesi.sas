/******************************************************************************
 * Program:      t_ae_aesi.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Table 14.3.2 - Summary of Adverse Events of Special Interest (AESI)
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
    where AESIFL = 'Y' and TRTEMFL = 'Y';
run;

/* 3. Categorize by AESI Type and Max ASTCT Grade */
proc sql;
    create table aesi_summary as
    select USUBJID, ARMCD, 
           max(case when index(upcase(AEDECOD), 'CYTOKINE RELEASE') > 0 then 1 else 0 end) as CRS_FL,
           max(case when index(upcase(AEDECOD), 'IMMUNE EFFECTOR') > 0 or 
                         index(upcase(AEDECOD), 'NEUROTOXICITY') > 0 then 1 else 0 end) as ICANS_FL,
           max(case when index(upcase(AEDECOD), 'GRAFT') > 0 then 1 else 0 end) as GVHD_FL,
           max(input(ASTCTGR, ?? 8.)) as MAX_ASTCT_GR
    from aesi_data
    group by USUBJID, ARMCD;
quit;

/* 4. Grouping and Counting */
proc freq data=aesi_summary noprint;
    tables ARMCD * CRS_FL / out=crs_counts;
    tables ARMCD * ICANS_FL / out=icans_counts;
    tables ARMCD * GVHD_FL / out=gvhd_counts;
run;

/* 5. Specialized Formatting for CAR-T Safety */
title1 "BV-CAR20-P1: CAR-T Safety Analysis";
title2 "Table 14.3.2: Summary of Adverse Events of Special Interest (AESI)";
title3 "Safety Population";

footnote1 "Note: CRS and ICANS are graded via ASTCT 2019 Consensus Criteria.";
footnote2 "GvHD is assessed via Protocol-specified organ grading.";

proc report data=aesi_summary nowd headskip split='|' style(report)={outputwidth=100%};
    column ("AESI Category" CRS_FL ICANS_FL GVHD_FL) ARMCD, (sum);
    define CRS_FL / "Subjects with CRS" sum center;
    define ICANS_FL / "Subjects with ICANS" sum center;
    define GVHD_FL / "Subjects with GvHD" sum center;
    define ARMCD / across "Dose Level";
    
    compute after _page_;
        line @1 "--------------------------------------------------------------------------------";
        line @1 "AESIs are defined as Treatment-Emergent events occurring after start of regimen.";
    endcomp;
run;

/* Export results */
ods html body="&OUT_TABLES/t_ae_aesi.html";
proc print data=aesi_summary(obs=10); run;
ods html close;
