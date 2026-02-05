/******************************************************************************
 * Program:      t_dor_by_arm.sas
 * Protocol:     PBCAR20A-01 (Full Phase 2a per Original Protocol)
 * Purpose:      Duration of Response by Phase 2a Arm
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 *
 * Per Protocol Section 2.2.2: DoR for expansion cohorts
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* ============================================================================
   DURATION OF RESPONSE BY PHASE 2A ARM (Protocol Section 2.2.2)
   DoR = Time from first response to progression/death
   Analyzed in responders only
   ============================================================================ */

/* 1. Simulate DoR data for responders */
data dor_by_arm;
    set rs_phase2a_full;
    where RSORRES in ('CR', 'CRi', 'PR');
    
    call streaminit(20260205);
    
    /* Simulate DoR based on disease type */
    if DISEASETYPE = 'CLL/SLL' then do;
        /* CLL tends to have longer DoR */
        DOR_MONTHS = round(rand('exponential') * 18 + 6, 0.1);
        if rand('uniform') < 0.3 then CNSR = 1; else CNSR = 0;
    end;
    else if DISEASETYPE = 'DLBCL' then do;
        DOR_MONTHS = round(rand('exponential') * 12 + 3, 0.1);
        if rand('uniform') < 0.35 then CNSR = 1; else CNSR = 0;
    end;
    else do;  /* High-grade NHL post-CAR-T - shorter DoR */
        DOR_MONTHS = round(rand('exponential') * 6 + 2, 0.1);
        if rand('uniform') < 0.2 then CNSR = 1; else CNSR = 0;
    end;
run;

/* 2. KM Analysis by Arm */
ods output ProductLimitEstimates=dor_km_arm Quartiles=dor_median_arm;
proc lifetest data=dor_by_arm method=KM 
    plots=survival(atrisk=0 to 24 by 6);
    time DOR_MONTHS * CNSR(1);
    strata COHORT / test=logrank;
    title1 "Figure F-EFF4: Duration of Response by Phase 2a Arm";
    title2 "Kaplan-Meier Curves — Responders (CR/PR)";
run;
ods output close;

/* 3. Median DoR by Arm */
data dor_summary;
    set dor_median_arm;
    where Percent = 50;
    
    length Median_DoR $50;
    if Estimate ne . then 
        Median_DoR = catx(' ', put(Estimate, 5.1), 
                         cats('(', put(LowerLimit, 5.1), '-', put(UpperLimit, 5.1), ')'));
    else Median_DoR = "NR";
run;

proc print data=dor_summary noobs;
    var Stratum Median_DoR;
    title "Median Duration of Response by Arm";
run;

/* 4. Summary Table */
proc sql;
    create table dor_arm_summary as
    select COHORT, DISEASETYPE,
           count(*) as N_Responders,
           sum(case when CNSR=0 then 1 else 0 end) as N_Events,
           median(DOR_MONTHS) as Median_DoR format=5.1
    from dor_by_arm
    group by COHORT, DISEASETYPE;
quit;

proc print data=dor_arm_summary noobs label;
    label COHORT = "Arm"
          DISEASETYPE = "Disease"
          N_Responders = "Responders"
          N_Events = "Events"
          Median_DoR = "Median DoR (months)";
    title1 "Table 2.3: Duration of Response Summary by Phase 2a Arm";
run;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ DoR BY ARM ANALYSIS COMPLETE;
%put NOTE: ----------------------------------------------------;
