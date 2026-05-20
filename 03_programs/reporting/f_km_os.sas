/******************************************************************************
 * Program:      f_km_os.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Kaplan-Meier Survival Curve for Overall Survival (OS)
 * Author:       Statistical Programmer
 * Date:         2026-02-05
 * SAS Version:  9.4
 ******************************************************************************/

%load_config;

/* 1. Derive OS Data from ADSL */
data os_data;
    set adam.adsl;
    where SAFFL = "Y"; /* Safety Population */
    
    /* Data cutoff for censoring */
    OS_CUTOFF = input("&DATA_CUTOFF", yymmdd10.);
    if missing(OS_CUTOFF) then OS_CUTOFF = coalesce(LSTALVDT, TRTEDT, TRTSDT);

    /* Derive OS time and event */
    if not missing(DTHDT) then do;
        OS_TIME = DTHDT - TRTSDT + 1;
        OS_CNSR = 0; /* Event (death) */
        OS_EVENT = "Death";
    end;
    else do;
        /* Censored at last known alive date or data cut */
        OS_LAST = coalesce(LSTALVDT, TRTEDT, TRTSDT, OS_CUTOFF);
        if OS_LAST > OS_CUTOFF then OS_LAST = OS_CUTOFF;
        OS_TIME = OS_LAST - TRTSDT + 1;
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
%ods_setup(type=GRAPH, imgname=f_km_os);

proc lifetest data=os_data method=KM 
    plots=survival(atrisk=0 to 24 by 6 outside(0.15) cb=hw);
    time OS_MONTHS * OS_CNSR(1);
    strata ARMCD / order=internal;
    title1 "Figure F-EFF2: Kaplan-Meier Curve for Overall Survival";
    title2 "&STUDYID Phase 1 - Safety Population";
    footnote1 "OS defined as time from Day 0 to death from any cause.";
    footnote2 "Subjects alive at data cut censored at last known alive date.";
    footnote3 "Tick marks indicate censored observations.";
run;

%ods_close(type=GRAPH);

/* 5. Summary Statistics */
proc print data=os_median noobs label;
    var ARMCD Median_OS;
    title "Median OS by Dose Level";
run;

/* 6. 6-Month and 12-Month Survival Rates (Step-Function Robust Approach) */
data os_landmarks_6;
    set os_km_est;
    where OS_MONTHS <= 6;
run;
proc sort data=os_landmarks_6; by Stratum descending OS_MONTHS; run;
data os_landmark_6;
    set os_landmarks_6;
    by Stratum;
    if first.Stratum;
    Landmark_Time = 6;
run;

data os_landmarks_12;
    set os_km_est;
    where OS_MONTHS <= 12;
run;
proc sort data=os_landmarks_12; by Stratum descending OS_MONTHS; run;
data os_landmark_12;
    set os_landmarks_12;
    by Stratum;
    if first.Stratum;
    Landmark_Time = 12;
run;

data os_landmarks;
    set os_landmark_6 os_landmark_12;
    Survival_Pct = put(Survival * 100, 5.1) || '%';
    label Landmark_Time = "Landmark Month"
          Survival_Pct = "Survival Rate (%)";
run;

proc print data=os_landmarks noobs label;
    var Stratum Landmark_Time Survival_Pct;
    title "Landmark Survival Rates";
run;

%put NOTE: ----------------------------------------------------;
%put NOTE: KM OS FIGURE GENERATED: f_km_os.png;
%put NOTE: ----------------------------------------------------;
