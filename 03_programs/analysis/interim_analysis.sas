/******************************************************************************
 * Program:      interim_analysis.sas
 * Protocol:     BV-CAR20-P1 (Phase 2a Expansion - Portfolio Extension)
 * Purpose:      Interim Analysis Shell/Template
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 *
 * Output:       Interim Analysis Report with Efficacy Futility
 *
 * Note:         Demonstrates interim analysis methodology for portfolio
 *               Not used in actual study (terminated early)
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

/* ============================================================================
   INTERIM ANALYSIS FRAMEWORK
   
   This template demonstrates:
   1. Alpha spending function (O'Brien-Fleming)
   2. Conditional power calculation
   3. Futility stopping rules
   4. DMC-ready summary tables
   
   Per original protocol (before termination):
   - Planned interim at 50% information fraction
   - Early stopping for efficacy or futility
   ============================================================================ */

%let IA_DATE = 01JUN2026;
%let INFO_FRACTION = 0.50;  /* 50% of planned subjects */
%let ALPHA_OVERALL = 0.05;  /* Overall Type I error */

/* -------------------------------------------------------------------------
   1. ALPHA SPENDING FUNCTION (O'Brien-Fleming)
   ------------------------------------------------------------------------- */
data alpha_spent;
    length Analysis $20 Info_Fraction 8 Alpha_Spent 8 Cumulative_Alpha 8;
    
    /* O'Brien-Fleming boundaries */
    Analysis = "Interim";
    Info_Fraction = &INFO_FRACTION;
    Alpha_Spent = 0.0031;  /* O'Brien-Fleming at 50% */
    Cumulative_Alpha = 0.0031;
    output;
    
    Analysis = "Final";
    Info_Fraction = 1.00;
    Alpha_Spent = 0.0469;  /* Remaining alpha */
    Cumulative_Alpha = &ALPHA_OVERALL;
    output;
run;

proc print data=alpha_spent noobs;
    title1 "Table IA-1: Alpha Spending Function (O'Brien-Fleming)";
    title2 "&STUDYID Interim Analysis";
run;

/* -------------------------------------------------------------------------
   2. INTERIM EFFICACY SUMMARY
   ------------------------------------------------------------------------- */
proc sql;
    create table ia_efficacy as
    select COHORT,
           count(distinct USUBJID) as N_Enrolled,
           sum(case when EFFFL = 'Y' then 1 else 0 end) as N_Evaluable
    from adam.adsl_expanded
    group by COHORT;
quit;

/* Response rates at interim */
proc sql;
    create table ia_response as
    select a.COHORT, a.DISEASE,
           count(distinct a.USUBJID) as N,
           sum(case when b.AVALC in ('CR', 'CRi', 'PR') then 1 else 0 end) as N_Responders,
           calculated N_Responders / calculated N * 100 as ORR format=5.1
    from adam.adsl_expanded a
    left join adam.adrs_expanded b on a.USUBJID = b.USUBJID and b.PARAMCD = 'BOR'
    where a.EFFFL = 'Y'
    group by a.COHORT, a.DISEASE;
quit;

proc print data=ia_response noobs label;
    label COHORT = "Cohort"
          DISEASE = "Disease"
          N = "N Evaluable"
          N_Responders = "Responders"
          ORR = "ORR (%)";
    title1 "Table IA-2: Interim Efficacy Summary by Cohort";
    title2 "Data Cutoff: &IA_DATE";
run;

/* -------------------------------------------------------------------------
   3. CONDITIONAL POWER CALCULATION
   ------------------------------------------------------------------------- */
%macro conditional_power(observed_effect=, expected_effect=, info_frac=, alpha=);
    /* Simplified conditional power under current trend */
    data cp_calc;
        observed = &observed_effect;
        expected = &expected_effect;
        info_frac = &info_frac;
        alpha = &alpha;
        
        /* Z-score at interim */
        z_interim = probit(1 - alpha/2);
        
        /* Conditional power assuming trend continues */
        z_final = (observed / sqrt(info_frac) + expected * (1-info_frac) / sqrt(1-info_frac)) / sqrt(1);
        conditional_power = 1 - probnorm(z_final - z_interim);
        
        put "Conditional Power: " conditional_power percent8.1;
    run;
%mend;

/* Example: ORR = 65% observed vs 50% null */
data cp_summary;
    length Scenario $50 Conditional_Power 8;
    Scenario = "Current trend continues (ORR 65%)";
    Conditional_Power = 0.85; /* Illustrative */
    output;
    
    Scenario = "Effect diminishes (ORR 55%)";
    Conditional_Power = 0.52;
    output;
    
    Scenario = "Null hypothesis true (ORR 50%)";
    Conditional_Power = 0.25;
    output;
run;

proc print data=cp_summary noobs;
    title1 "Table IA-3: Conditional Power Under Various Scenarios";
    footnote1 "Based on O'Brien-Fleming boundary at 50% information fraction.";
run;

/* -------------------------------------------------------------------------
   4. FUTILITY ASSESSMENT
   ------------------------------------------------------------------------- */
data futility_check;
    length Assessment $100;
    
    /* Observed ORR */
    Observed_ORR = 0.65;
    Target_ORR = 0.50;
    
    /* Futility boundary (predictive probability < 10%) */
    Futility_Threshold = 0.10;
    
    if Observed_ORR >= Target_ORR then do;
        Assessment = "CONTINUE: Observed ORR exceeds target";
        Futility_Flag = 'N';
    end;
    else if Observed_ORR < Target_ORR - 0.15 then do;
        Assessment = "STOP FOR FUTILITY: Low probability of success";
        Futility_Flag = 'Y';
    end;
    else do;
        Assessment = "CONTINUE: Insufficient evidence for futility";
        Futility_Flag = 'N';
    end;
run;

proc print data=futility_check noobs;
    title1 "Interim Analysis Futility Assessment";
run;

/* -------------------------------------------------------------------------
   5. DMC SUMMARY TABLE
   ------------------------------------------------------------------------- */
proc sql;
    create table dmc_summary as
    select "Enrolled" as Metric length=50, count(distinct USUBJID) as Value from adam.adsl_expanded
    union all select "Safety Evaluable", count(distinct case when SAFFL='Y' then USUBJID end) from adam.adsl_expanded
    union all select "Efficacy Evaluable", count(distinct case when EFFFL='Y' then USUBJID end) from adam.adsl_expanded
    union all select "Deaths", count(distinct case when DTHDT ne . then USUBJID end) from adam.adsl_expanded
    union all select "SAEs", count(*) from adam.adae_expanded where AESER='Y';
quit;

proc print data=dmc_summary noobs;
    title1 "Data Monitoring Committee Summary";
    title2 "Interim Analysis - &IA_DATE";
run;

%put NOTE: ----------------------------------------------------;
%put NOTE: INTERIM ANALYSIS SHELL COMPLETE;
%put NOTE: ----------------------------------------------------;


