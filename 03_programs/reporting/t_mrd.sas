/******************************************************************************
 * Program:      t_mrd.sas
 * Protocol:     BV-CAR20-P1 (Phase 2a Expansion - Portfolio Extension)
 * Purpose:      Minimal Residual Disease (MRD) Analysis
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 *
 * Input:        sdtm.mrd_phase2a_full, sdtm.rs_phase2a_full
 * Output:       Table 2.4: MRD Negativity Rate
 *
 * Note:         MRD is key exploratory endpoint for CAR-T in hematologic
 *               malignancies (10^-4 or 10^-5 sensitivity)
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
   MINIMAL RESIDUAL DISEASE (MRD) ANALYSIS
   
   MRD Assessment Methods:
   - Flow cytometry (10^-4 sensitivity)
   - Next-generation sequencing (10^-5 to 10^-6 sensitivity)
   
   MRD-negative: No detectable disease at specified sensitivity
   ============================================================================ */

/* 1. Fetch MRD data from persisted SDTM */
data mrd_data;
    set sdtm.mrd_phase2a_full;
    /* Map disease names if needed */
run;

/* 2. MRD Negativity Rate by Disease and Timepoint */
proc freq data=mrd_data;
    tables DISEASE * TIMEPOINT * MRDRESULT / nocum nopercent;
    title1 "Table 2.4: MRD Status by Disease and Timepoint";
    title2 "&STUDYID Phase 1/2a — Efficacy Evaluable Population";
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
    title2 "&STUDYID Phase 1/2a — Efficacy Evaluable Population";
    footnote1 "MRD assessed by flow cytometry at 10^-4 sensitivity.";
run;

ods graphics off;

/* 5. MRD and Response Correlation */
proc sql;
    create table mrd_response as
    select a.USUBJID, a.DISEASE, a.MRDRESULT, a.TIMEPOINT, b.AVALC as BOR
    from mrd_data a
    inner join sdtm.rs_phase2a_full b on a.USUBJID = b.USUBJID and b.RSTESTCD = 'OVRLRESP'
    where a.TIMEPOINT = 'Week 12';
quit;

proc freq data=mrd_response;
    tables BOR * MRDRESULT / chisq;
    title "MRD Status vs Best Overall Response at Week 12";
run;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ MRD ANALYSIS COMPLETE;
%put NOTE: ----------------------------------------------------;


