/******************************************************************************
 * Program:      t_mrd.sas
 * Protocol:     PBCAR20A-01 (Phase 2a Expansion - Portfolio Extension)
 * Purpose:      Minimal Residual Disease (MRD) Analysis
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 *
 * Input:        adam.adsl_expanded, sdtm.lb_expanded
 * Output:       Table 2.4: MRD Negativity Rate
 *
 * Note:         MRD is key exploratory endpoint for CAR-T in hematologic
 *               malignancies (10^-4 or 10^-5 sensitivity)
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* ============================================================================
   MINIMAL RESIDUAL DISEASE (MRD) ANALYSIS
   
   MRD Assessment Methods:
   - Flow cytometry (10^-4 sensitivity)
   - Next-generation sequencing (10^-5 to 10^-6 sensitivity)
   
   MRD-negative: No detectable disease at specified sensitivity
   ============================================================================ */

/* 1. Generate synthetic MRD data */
data mrd_data;
    length STUDYID $20 USUBJID $40 MRDTEST $30 MRDMETHOD $30 
           MRDRESULT $20 MRDNEG 8 TIMEPOINT $20 DISEASE $10;
    
    call streaminit(20260205);
    
    set sdtm.dm_phase2a_full(keep=USUBJID DISEASETYPE COHORT ITTFL);
    rename DISEASETYPE=DISEASE;
    where ITTFL = 'Y';
    
    STUDYID = "PBCAR20A-01";
    
    /* MRD rates vary by disease and response */
    if DISEASE = 'NHL' then _mrd_neg_rate = 0.55;  /* 55% MRD-neg for NHL */
    else _mrd_neg_rate = 0.45;  /* 45% MRD-neg for CLL */
    
    /* Week 4 assessment */
    TIMEPOINT = "Week 4";
    MRDTEST = "MRD Assessment";
    MRDMETHOD = "Flow Cytometry (10^-4)";
    
    if rand('uniform') < _mrd_neg_rate * 0.8 then do;
        MRDRESULT = "Negative";
        MRDNEG = 1;
    end;
    else do;
        MRDRESULT = "Positive";
        MRDNEG = 0;
    end;
    output;
    
    /* Week 12 assessment - higher rates as more achieve deep remission */
    TIMEPOINT = "Week 12";
    if MRDRESULT = "Positive" and rand('uniform') < 0.3 then do;
        MRDRESULT = "Negative";
        MRDNEG = 1;
    end;
    else if MRDRESULT = "Negative" and rand('uniform') < 0.1 then do;
        MRDRESULT = "Positive";  /* Relapse */
        MRDNEG = 0;
    end;
    output;
    
    /* Week 24 assessment */
    TIMEPOINT = "Week 24";
    if MRDRESULT = "Positive" and rand('uniform') < 0.15 then do;
        MRDRESULT = "Negative";
        MRDNEG = 1;
    end;
    output;
    
    drop _mrd_neg_rate;
run;

/* 2. MRD Negativity Rate by Disease and Timepoint */
proc freq data=mrd_data;
    tables DISEASE * TIMEPOINT * MRDRESULT / nocum nopercent;
    title1 "Table 2.4: MRD Status by Disease and Timepoint";
    title2 "PBCAR20A-01 Phase 1/2a — Efficacy Evaluable Population";
run;

/* 3. Summary Table */
proc sql;
    create table mrd_summary as
    select DISEASE, TIMEPOINT,
           count(*) as N_Assessed,
           sum(MRDNEG) as N_Negative,
           sum(MRDNEG) / count(*) * 100 as MRD_Neg_Rate format=5.1
    from mrd_data
    group by DISEASE, TIMEPOINT
    order by DISEASE, TIMEPOINT;
quit;

proc print data=mrd_summary noobs label;
    label DISEASE = "Disease"
          TIMEPOINT = "Timepoint"
          N_Assessed = "N Assessed"
          N_Negative = "N MRD-Negative"
          MRD_Neg_Rate = "MRD Negativity Rate (%)";
    title "MRD Negativity Rate Summary";
run;

/* 4. MRD Rate Over Time - Line Plot */
ods graphics on / reset=all imagename="f_mrd_time" imagefmt=png width=8in height=6in;
ods listing gpath="&OUT_FIGURES";

proc sgplot data=mrd_summary;
    series x=TIMEPOINT y=MRD_Neg_Rate / group=DISEASE 
           markers markerattrs=(size=10);
    
    xaxis label="Assessment Timepoint" discreteorder=data;
    yaxis label="MRD Negativity Rate (%)" values=(0 to 100 by 20);
    
    keylegend / position=bottom title="Disease";
    
    title1 "Figure F-MRD1: MRD Negativity Rate Over Time";
    title2 "PBCAR20A-01 Phase 1/2a — Efficacy Evaluable Population";
    footnote1 "MRD assessed by flow cytometry at 10^-4 sensitivity.";
run;

ods graphics off;

/* 5. MRD and Response Correlation */
proc sql;
    create table mrd_response as
    select a.USUBJID, a.DISEASE, a.MRDRESULT, a.TIMEPOINT, b.AVALC as BOR
    from mrd_data a
    inner join sdtm.rs_phase2a_full b on a.USUBJID = b.USUBJID and b.PARAMCD = 'BOR'
    where a.TIMEPOINT = 'Week 12';
quit;

proc freq data=mrd_response;
    tables BOR * MRDRESULT / chisq;
    title "MRD Status vs Best Overall Response at Week 12";
run;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ MRD ANALYSIS COMPLETE;
%put NOTE: ----------------------------------------------------;
