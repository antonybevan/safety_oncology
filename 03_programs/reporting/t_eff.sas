/******************************************************************************
 * Program:      t_eff.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Table 2.1 - Summary of Objective Response Rate by Initial Treatment
 * Author:       Statistical Programmer
 * Date:         2026-02-01
 * SAS Version:  9.4
 ******************************************************************************/

%load_config;

/* 1. Prepare Efficacy Data (Response Evaluable Population) */
data t_eff_data;
    set adam.adrs;
    where EFFFL = 'Y' and PARAMCD = 'OVR'; /* Longitudinal overall responses */
run;

/* Get the derived BOR from adrs */
data t_bor_data;
    set adam.adrs;
    where EFFFL = 'Y' and PARAMCD = 'BOR';
run;

/* 2. Calculate Big N per subgroup */
%let N_DL1 = 0;
%let N_DL2 = 0;
%let N_DL3 = 0;

proc sql noprint;
    select count(*) into :N_DL1 from adam.adsl where EFFFL = 'Y' and ARMCD = 'DL1';
    select count(*) into :N_DL2 from adam.adsl where EFFFL = 'Y' and ARMCD = 'DL2';
    select count(*) into :N_DL3 from adam.adsl where EFFFL = 'Y' and ARMCD = 'DL3';
quit;

%let N_DL1 = %trim(&N_DL1);
%let N_DL2 = %trim(&N_DL2);
%let N_DL3 = %trim(&N_DL3);

/* 3. Summarize BOR Counts */
proc freq data=t_bor_data noprint;
    tables ARMCD * AVALC / out=bor_counts;
run;

data bor_shell;
    length AVALC $20 ARMCD $20;
    do AVALC = 'CR', 'PR', 'SD', 'PD', 'NE';
        do ARMCD = 'DL1', 'DL2', 'DL3';
            count = 0;
            output;
        end;
    end;
run;

proc sort data=bor_counts; by AVALC ARMCD; run;
proc sort data=bor_shell; by AVALC ARMCD; run;

data bor_final_report;
    merge bor_shell(in=s) bor_counts(in=c);
    by AVALC ARMCD;
    if count = . then count = 0;
run;

/* 4. Calculate Objective Response Rate (ORR = CR + PR) */
data orr_data;
    set t_bor_data;
    if AVALC in ('CR', 'PR') then ORRFL = 1;
    else ORRFL = 0;
run;

proc sql;
    create table orr_summary as
    select ARMCD, sum(ORRFL) as orr_count, count(*) as n_subj
    from orr_data
    group by ARMCD;
quit;

/* Ensure all arms are in summary */
data arm_shell;
    length ARMCD $20;
    do ARMCD = 'DL1', 'DL2', 'DL3';
        orr_count = 0;
        n_subj = 0;
        output;
    end;
run;

proc sort data=orr_summary; by ARMCD; run;
proc sort data=arm_shell; by ARMCD; run;

data orr_summary_all;
    merge arm_shell(in=s) orr_summary(in=a);
    by ARMCD;
run;

/* 5. Calculate Clopper-Pearson Exact 95% CI (SAP §7.1.1) */
data orr_final;
    set orr_summary_all;
    
    if n_subj > 0 then do;
        orr_pct = (orr_count / n_subj) * 100;
        
        /* Clopper-Pearson CI calculation (mathematically robust & fail-safe) */
        alpha = 0.05;
        if orr_count = 0 then LCL = 0;
        else LCL = betainv(alpha/2, orr_count, n_subj - orr_count + 1);
        
        if orr_count = n_subj then UCL = 1;
        else UCL = betainv(1 - alpha/2, orr_count + 1, n_subj - orr_count);
        
        LCL_pct = LCL * 100;
        UCL_pct = UCL * 100;
        CI_RANGE = put(LCL_pct, 5.1) || ", " || put(UCL_pct, 5.1);
    end;
    else do;
        orr_pct = 0;
        LCL = .;
        UCL = .;
        CI_RANGE = "N/A";
    end;
run;

/* 6. Production Reporting Logic */
options nodate nonumber ls=120 ps=60;
title1 "&STUDYID: CAR-T Efficacy Summary";
title2 "Table 2.1: Summary of Objective Response Rate by Initial Treatment";
title3 "Response Evaluable (RE) Population";

footnote1 "Note: BOR is assessed via Lugano 2016 for NHL and iwCLL 2018 for CLL/SLL cohorts.";
footnote2 "ORR (Objective Response Rate) = CR + PR.";
footnote3 "95% CI calculated using Clopper-Pearson Exact binomial method (SAP §7.1.1).";

%ods_setup(type=RTF, outpath=&OUT_TABLES/t_eff.rtf);

proc report data=bor_final_report nowd headskip split='|' style(report)={outputwidth=100%};
    column AVALC ARMCD, (COUNT);
    define AVALC / group "Response Category" width=30;
    define ARMCD / across "Dose Level";
    define COUNT / "n" center;
run;

/* Summary Table for ORR with CI */
title2 "Summary of Objective Response Rate (ORR)";
proc report data=orr_final nowd headskip split='|' style(report)={outputwidth=100%};
    column ARMCD n_subj orr_count orr_pct CI_RANGE;
    define ARMCD / "Dose Level" width=20;
    define n_subj / "N" center;
    define orr_count / "ORR (n)" center;
    define orr_pct / "ORR (%)" format=6.1 center;
    define CI_RANGE / "95% CI (%)" center width=25;
run;

%ods_close(type=RTF);
