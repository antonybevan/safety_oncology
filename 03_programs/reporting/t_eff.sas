/******************************************************************************
 * Program:      t_eff.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Table 2.1 - Summary of Objective Response Rate by Initial Treatment
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

/* 1. Prepare Efficacy Data (Response Evaluable Population) */
data t_eff_data;
    set adam.adrs;
    where EFFFL = 'Y';
run;

/* 2. Calculate Big N per subgroup */
proc sql noprint;
    select count(*) into :N_DL1 from adam.adsl where EFFFL = 'Y' and ARMCD = 'DL1';
    select count(*) into :N_DL2 from adam.adsl where EFFFL = 'Y' and ARMCD = 'DL2';
    select count(*) into :N_DL3 from adam.adsl where EFFFL = 'Y' and ARMCD = 'DL3';
quit;

%let N_DL1 = %trim(&N_DL1);
%let N_DL2 = %trim(&N_DL2);
%let N_DL3 = %trim(&N_DL3);

/* 3. Summarize BOR Counts */
proc freq data=t_eff_data noprint;
    tables ARMCD * AVALC / out=bor_counts;
run;

/* 4. Calculate Objective Response Rate (ORR = CR + PR) */
data orr_data;
    set t_eff_data;
    if AVALC in ('CR', 'PR') then ORRFL = 1;
    else ORRFL = 0;
run;

proc sql;
    create table orr_summary as
    select ARMCD, sum(ORRFL) as orr_count, count(*) as n_subj
    from orr_data
    group by ARMCD;
quit;

/* 5. Production Reporting Logic */
title1 "BV-CAR20-P1: CAR-T Efficacy Summary";
title2 "Table 2.1: Summary of Objective Response Rate by Initial Treatment";
title3 "Response Evaluable (RE) Population";

footnote1 "Note: BOR is assessed via Lugano 2016 for NHL and iwCLL 2018 for CLL/SLL cohorts.";
footnote2 "ORR (Objective Response Rate) = CR + PR.";
footnote3 "Dose Level 2 was skipped per SRC recommendation (SAP Section 1.1).";

proc report data=bor_counts nowd headskip split='|' style(report)={outputwidth=100%};
    column ("Best Overall Response" AVALC) ARMCD, (COUNT);
    define AVALC / "Response Category" width=30;
    define ARMCD / across "Dose Level";
    define COUNT / "n" center;
    
    compute after _page_;
        line @1 "--------------------------------------------------------------------------------";
    endcomp;
run;

/* Summary Table for ORR */
title2 "Summary of Objective Response Rate (ORR)";
proc report data=orr_summary nowd headskip split='|';
    column ARMCD orr_count n_subj orr_pct;
    define ARMCD / "Dose Level" width=20;
    define orr_count / "ORR (n)" center display;
    define n_subj / "Number Evaluated (N)" center display;
    define orr_pct / computed "ORR (%)" format=6.1 center;
    
    compute orr_pct;
        if n_subj > 0 then orr_pct = (orr_count / n_subj) * 100;
        else orr_pct = 0;
    endcomp;
run;

/* Export results */
ods html body="&OUT_TABLES/t_eff.html";
proc print data=orr_summary; run;
ods html close;
