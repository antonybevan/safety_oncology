/******************************************************************************
 * Program:      f_km_pfs.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Kaplan-Meier Survival Curve for Progression-Free Survival (PFS)
 * Author:       Statistical Programmer
 * Date:         2026-02-05
 * SAS Version:  9.4
 * SAP Reference: Section 1.4, Section 7.1.2, Table 6
 *
 * Input:        adam.adrs (PFS parameter)
 * Output:       Figure F-EFF1: Kaplan-Meier Curve for PFS
 *
 * Note:  PFS defined as duration from Day 0 to progression or death.
 *        Censoring per SAP Table 6 and FDA Clinical Trial Endpoints Guidance.
 ******************************************************************************/

%load_config;

/* ============================================================================
   1. Extract PFS Data from ADRS
   ============================================================================ */
data pfs_data;
    set adam.adrs;
    where PARAMCD = "PFS";
    if CNSR = . then CNSR = 1;          /* Conservative: missing → censored */
    if AVAL <= 0 then AVAL = 0.5;       /* Minimum 0.5 days per FDA guidance */
    AVAL_MONTHS = AVAL / 30.4375;
    keep USUBJID ARMCD ARM AVAL AVAL_MONTHS CNSR EVNTDESC;
run;

proc sql noprint;
    select count(*) into :N_PFS trimmed from pfs_data;
quit;

%macro run_km_pfs;
%if %sysevalf(&N_PFS > 0) %then %do;

    /* ============================================================================
       2. Kaplan-Meier Analysis — capture ODS outputs by name
       ============================================================================ */
    ods output ProductLimitEstimates = km_pfs_est
               Quartiles             = km_pfs_quartiles;
    proc lifetest data=pfs_data method=KM;
        time AVAL_MONTHS * CNSR(1);
        strata ARMCD;
    run;
    ods output close;

    /* ============================================================================
       3. Median PFS with 95% CI — guard against missing km_pfs_quartiles
       ============================================================================ */
    %local has_q;
    %let has_q = %sysfunc(exist(work.km_pfs_quartiles));
    %if &has_q %then %do;
        data km_pfs_median;
            set km_pfs_quartiles;
            where Percent = 50;
            length Median_PFS $50;
            if Estimate ne . then
                Median_PFS = catx(' ', put(Estimate, 5.1),
                                  cats('(', put(LowerLimit, 5.1), '-',
                                            put(UpperLimit, 5.1), ')'));
            else Median_PFS = "NR (Not Reached)";
            label Median_PFS = "Median PFS, months (95% CI)";
        run;
    %end;
    %else %do;
        data km_pfs_median;
            length Stratum $20 Median_PFS $50;
            Stratum    = "Overall";
            Median_PFS = "NR (Not Reached)";
            label Median_PFS = "Median PFS, months (95% CI)";
        run;
    %end;

    /* ============================================================================
       4. KM Figure
       ============================================================================ */
    %ods_setup(type=GRAPH, imgname=f_km_pfs);
    ods graphics on / width=8in height=5in;

    proc lifetest data=pfs_data method=KM
        plots=survival(atrisk=0 to 12 by 3 outside(0.15) cb=hw test);
        time AVAL_MONTHS * CNSR(1);
        strata ARMCD / order=internal;
        title1 "Figure F-EFF1: Kaplan-Meier Curve for Progression-Free Survival";
        title2 "&STUDYID Phase 1 - Response Evaluable Population";
        footnote1 "PFS defined as time from Day 0 to disease progression or death.";
        footnote2 "Censoring per SAP Table 6 and FDA Clinical Trial Endpoints Guidance.";
        footnote3 "Tick marks indicate censored observations.";
    run;

    %ods_close(type=GRAPH);

    /* ============================================================================
       5. Summary Tables
       ============================================================================ */
    proc print data=km_pfs_median noobs label;
        var Stratum Median_PFS;
        title "Median PFS by Dose Level";
    run;

    /* Landmark survival rates at 3, 6, 12 months */
    proc sql;
        create table pfs_landmarks as
        select ARMCD,
               sum(case when CNSR = 0 and AVAL_MONTHS <= 3  then 1 else 0 end) as Evnt_3mo,
               sum(case when CNSR = 0 and AVAL_MONTHS <= 6  then 1 else 0 end) as Evnt_6mo,
               sum(case when CNSR = 0 and AVAL_MONTHS <= 12 then 1 else 0 end) as Evnt_12mo,
               count(*) as N_Total
        from pfs_data
        group by ARMCD;
    quit;

    data pfs_landmarks;
        set pfs_landmarks;
        Surv_3mo  = max(0, (N_Total - Evnt_3mo)  / N_Total * 100);
        Surv_6mo  = max(0, (N_Total - Evnt_6mo)  / N_Total * 100);
        Surv_12mo = max(0, (N_Total - Evnt_12mo) / N_Total * 100);
        format Surv_3mo Surv_6mo Surv_12mo 5.1;
        label ARMCD     = "Dose Level"
              Surv_3mo  = "3-Month Survival (%)"
              Surv_6mo  = "6-Month Survival (%)"
              Surv_12mo = "12-Month Survival (%)";
    run;

    proc print data=pfs_landmarks noobs label;
        var ARMCD Surv_3mo Surv_6mo Surv_12mo;
        title "PFS Landmark Survival Rates";
    run;

%end;
%else %do;
    data pfs_placeholder;
        length Message $200;
        Message = "No PFS data available for analysis.";
    run;
    proc print data=pfs_placeholder noobs;
        title "Figure F-EFF1: Kaplan-Meier Curve for Progression-Free Survival";
    run;
%end;
%mend run_km_pfs;
%run_km_pfs;

%put NOTE: --------------------------------------------------------;
%put NOTE: KM PFS ANALYSIS COMPLETE;
%put NOTE: --------------------------------------------------------;
