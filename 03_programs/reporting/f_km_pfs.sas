/******************************************************************************
 * Program:      f_km_pfs.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Kaplan-Meier Survival Curve for Progression-Free Survival (PFS)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 * SAP Reference: §1.4, §7.1.2, Table 6
 *
 * Input:        adam.adrs (PFS parameter)
 * Output:       Figure F-EFF1: Kaplan-Meier Curve for PFS
 *
 * Note:         PFS defined as duration from Day 0 to progression or death
 *               Censoring per SAP Table 6 and FDA guidance
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* ============================================================================
   KAPLAN-MEIER ANALYSIS FOR PFS
   Per SAP §1.4: "Time-to-event variables will be summarized using 
   Kaplan-Meier methods and figures for the estimated median time"
   ============================================================================ */

/* 1. Extract PFS Data */
data pfs_data;
    set adam.adrs;
    where PARAMCD = "PFS";
    
    /* Ensure proper event/censor coding */
    /* CNSR = 0 for events, CNSR = 1 for censored */
    if CNSR = . then CNSR = 0; /* Assume event if missing */
    
    /* Time in days (AVAL) */
    if AVAL <= 0 then AVAL = 0.5; /* Handle zero/negative times */
    
    /* Convert to months for display */
    AVAL_MONTHS = AVAL / 30.4375;
    
    keep USUBJID ARMCD ARM AVAL AVAL_MONTHS CNSR EVNTDESC;
run;

/* 2. Kaplan-Meier Analysis */
ods output ProductLimitEstimates=km_est Quartiles=km_quartiles;
proc lifetest data=pfs_data method=KM plots=survival(atrisk=0 to 12 by 3);
    time AVAL_MONTHS * CNSR(1);
    strata ARMCD / test=logrank;
run;
ods output close;

/* 3. Extract Median PFS with 95% CI */
data km_median;
    set km_quartiles;
    where Percent = 50;
    
    /* Format for display */
    length Median_PFS $50;
    if Estimate ne . then 
        Median_PFS = catx(' ', put(Estimate, 5.1), 
                          cats('(', put(LowerLimit, 5.1), '-', put(UpperLimit, 5.1), ')'));
    else Median_PFS = "NR (Not Reached)";
    
    label Median_PFS = "Median PFS, months (95% CI)";
run;

/* 4. Create Publication-Quality KM Figure */
ods graphics on / reset=all imagename="f_km_pfs" imagefmt=png width=8in height=6in;
ods listing gpath="&OUT_FIGURES";

proc lifetest data=pfs_data method=KM 
    plots=survival(atrisk=0 to 12 by 3 outside(0.15) cb=hw test);
    time AVAL_MONTHS * CNSR(1);
    strata ARMCD / order=internal;
    title1 "Figure F-EFF1: Kaplan-Meier Curve for Progression-Free Survival";
    title2 "BV-CAR20-P1 Phase 1 — Response Evaluable Population";
    footnote1 "PFS defined as time from Day 0 to disease progression or death.";
    footnote2 "Censoring per SAP Table 6 and FDA Clinical Trial Endpoints Guidance.";
    footnote3 "Tick marks indicate censored observations.";
run;

ods graphics off;

/* 5. Summary Statistics Table */
proc print data=km_median noobs label;
    var ARMCD Median_PFS;
    title "Median PFS by Dose Level";
run;

/* 6. Detailed Survival Estimates */
proc print data=km_est(obs=20) noobs;
    var Stratum AVAL_MONTHS Survival Failed Left;
    title "PFS Survival Probability at Key Timepoints";
run;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ KM PFS FIGURE GENERATED: f_km_pfs.png;
%put NOTE: ----------------------------------------------------;
