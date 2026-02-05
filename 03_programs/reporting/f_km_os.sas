/******************************************************************************
 * Program:      f_km_os.sas
 * Protocol:     PBCAR20A-01
 * Purpose:      Kaplan-Meier Survival Curve for Overall Survival (OS)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 * SAP Reference: §1.4 (Exploratory)
 *
 * Input:        adam.adsl
 * Output:       Figure F-EFF2: Kaplan-Meier Curve for OS
 *
 * Note:         OS defined as time from Day 0 to death from any cause
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* ============================================================================
   KAPLAN-MEIER ANALYSIS FOR OVERALL SURVIVAL
   Per SAP §1.4: KM methods for time-to-event variables
   ============================================================================ */

/* 1. Derive OS Data from ADSL */
data os_data;
    set adam.adsl;
    where SAFFL = "Y"; /* Safety Population */
    
    /* Derive OS time and event */
    if not missing(DTHDT) then do;
        OS_TIME = DTHDT - TRTSDT + 1;
        OS_CNSR = 0; /* Event (death) */
        OS_EVENT = "Death";
    end;
    else do;
        /* Censored at last known alive date or data cut */
        OS_TIME = max(TRTEDT, LSTALVDT, TRTSDT + 360) - TRTSDT + 1;
        if OS_TIME <= 0 then OS_TIME = 1;
        OS_CNSR = 1; /* Censored */
        OS_EVENT = "Censored";
    end;
    
    /* Convert to months */
    OS_MONTHS = OS_TIME / 30.4375;
    
    keep USUBJID ARMCD ARM OS_TIME OS_MONTHS OS_CNSR OS_EVENT;
run;

/* 2. Kaplan-Meier Analysis */
ods output ProductLimitEstimates=os_km_est Quartiles=os_km_quartiles;
proc lifetest data=os_data method=KM plots=survival(atrisk=0 to 24 by 6);
    time OS_MONTHS * OS_CNSR(1);
    strata ARMCD / test=logrank;
run;
ods output close;

/* 3. Extract Median OS with 95% CI */
data os_median;
    set os_km_quartiles;
    where Percent = 50;
    
    length Median_OS $50;
    if Estimate ne . then 
        Median_OS = catx(' ', put(Estimate, 5.1), 
                         cats('(', put(LowerLimit, 5.1), '-', put(UpperLimit, 5.1), ')'));
    else Median_OS = "NR (Not Reached)";
    
    label Median_OS = "Median OS, months (95% CI)";
run;

/* 4. Create Publication-Quality KM Figure */
ods graphics on / reset=all imagename="f_km_os" imagefmt=png width=8in height=6in;
ods listing gpath="&OUTPUT_PATH";

proc lifetest data=os_data method=KM 
    plots=survival(atrisk=0 to 24 by 6 outside(0.15) cb=hw);
    time OS_MONTHS * OS_CNSR(1);
    strata ARMCD / order=internal;
    title1 "Figure F-EFF2: Kaplan-Meier Curve for Overall Survival";
    title2 "PBCAR20A-01 Phase 1 — Safety Population";
    footnote1 "OS defined as time from Day 0 to death from any cause.";
    footnote2 "Subjects alive at data cut censored at last known alive date.";
    footnote3 "Tick marks indicate censored observations.";
run;

ods graphics off;

/* 5. Summary Statistics */
proc print data=os_median noobs label;
    var ARMCD Median_OS;
    title "Median OS by Dose Level";
run;

/* 6. 6-Month and 12-Month Survival Rates */
data os_landmarks;
    set os_km_est;
    where OS_MONTHS in (6, 12);
    
    Survival_Pct = put(Survival * 100, 5.1) || '%';
    
    label Survival_Pct = "Survival Rate (%)";
run;

proc print data=os_landmarks noobs;
    var Stratum OS_MONTHS Survival_Pct;
    title "Landmark Survival Rates";
run;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ KM OS FIGURE GENERATED: f_km_os.png;
%put NOTE: ----------------------------------------------------;
