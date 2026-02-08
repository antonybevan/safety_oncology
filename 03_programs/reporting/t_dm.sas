/******************************************************************************
 * Program:      t_dm.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Table 1.3 - Summary of Demographics and Baseline Characteristics
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

/* 1. Prepare Data */
data t_dm_data;
    set adam.adsl;
    where SAFFL = 'Y';
run;

/* 2. Calculate Big N */
proc sql noprint;
    select count(*) into :N_DL1 from t_dm_data where ARMCD = 'DL1';
    select count(*) into :N_DL2 from t_dm_data where ARMCD = 'DL2';
    select count(*) into :N_DL3 from t_dm_data where ARMCD = 'DL3';
    select count(*) into :N_TOT from t_dm_data;
quit;

/* 3. Summary Statistics for Age */
proc means data=t_dm_data n mean std median min max;
    class ARMCD;
    var AGE;
    output out=age_stats;
run;

/* 4. Categorical variables (Sex, Race) */
proc freq data=t_dm_data noprint;
    tables ARMCD * SEX / out=sex_freq;
    tables ARMCD * RACE / out=race_freq;
    tables ARMCD * AGEGR1 / out=agegr_freq;
run;

/* 5. Production Table Formatting (Mockup logic for Portfolio) */
title "Table 1.3: Summary of Demographics and Baseline Characteristics";
title2 "Safety Population";

/* Handle the DL2 "Skipped" note per SAP Section 1.1 when intermediate level is absent */
%macro check_dl2;
    %if &N_DL2 = 0 %then %do;
        %put NOTE: Dose Level 2 (3x10^6 cells/kg; ~240x10^6 flat equivalent) was SKIPPED per Protocol V4 amendments.;
    %end;
%mend;
%check_dl2;

proc report data=t_dm_data nowd headskip split='|' style(report)={outputwidth=100%};
    column ("Characteristic" AGE SEX RACE) ARMCD, (n);
    define AGE / "Age (Years)";
    define AGEGR1 / "Age Group";
    define SEX / "Gender";
    define RACE / "Race";
    define ARMCD / across "Dose Level";
    
    compute after _page_;
        line @1 "--------------------------------------------------------------------------------";
        %if &N_DL2 = 0 %then %do;
        line @1 "Note: Dose Level 2 (3x10^6 cells/kg; ~240x10^6 flat equivalent) was skipped per SAP Section 1.1;";
        line @1 "directly from Level 1 to Level 3 based on SRC recommendation.";
        %end;
    endcomp;
run;

/* Export results to a safe location */
ods html body="&OUT_TABLES/t_dm.html";
proc print data=t_dm_data(obs=10); run;
ods html close;
