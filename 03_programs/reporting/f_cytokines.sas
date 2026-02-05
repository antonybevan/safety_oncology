/******************************************************************************
 * Program:      f_cytokines.sas
 * Protocol:     PBCAR20A-01 (Full Phase 2a per Original Protocol)
 * Purpose:      Cytokine Analysis Figures (IL-6, IFN-g, CRP)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 *
 * Per Protocol Section 2.3, 8.3: Serum cytokines analysis
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* ============================================================================
   CYTOKINE ANALYSIS (Protocol Section 2.3, 8.3)
   Key cytokines: IL-6, IFN-gamma, CRP
   Correlation with CRS events
   ============================================================================ */

/* 1. Summary statistics by timepoint */
proc means data=cytokines n mean std median min max;
    class VISIT;
    var IL6 IFNG CRP;
    title "Cytokine Summary by Timepoint";
run;

/* 2. Generate Cytokine Profile Figures */
ods graphics on / reset=all imagename="f_cytokines_il6" imagefmt=png width=8in height=6in;
ods listing gpath="&OUTPUT_PATH";

/* IL-6 Profile */
proc sgplot data=cytokines;
    vbox IL6 / category=VISIT;
    xaxis label="Timepoint" discreteorder=data;
    yaxis label="IL-6 (pg/mL)" type=log;
    refline 100 / axis=y lineattrs=(pattern=dash color=red) label="CRS Threshold";
    
    title1 "Figure F-BIO1: IL-6 Levels Over Time";
    title2 "PBCAR20A-01 Phase 1/2a — All Treated Subjects";
    footnote1 "Horizontal dashed line = typical threshold for severe CRS.";
run;

/* IFN-gamma Profile */
ods graphics on / imagename="f_cytokines_ifng" imagefmt=png width=8in height=6in;

proc sgplot data=cytokines;
    vbox IFNG / category=VISIT;
    xaxis label="Timepoint" discreteorder=data;
    yaxis label="IFN-gamma (pg/mL)" type=log;
    
    title1 "Figure F-BIO2: IFN-gamma Levels Over Time";
    title2 "PBCAR20A-01 Phase 1/2a — All Treated Subjects";
run;

/* CRP Profile */
ods graphics on / imagename="f_cytokines_crp" imagefmt=png width=8in height=6in;

proc sgplot data=cytokines;
    vbox CRP / category=VISIT;
    xaxis label="Timepoint" discreteorder=data;
    yaxis label="CRP (mg/L)";
    refline 50 / axis=y lineattrs=(pattern=dash color=orange) label="Elevated";
    
    title1 "Figure F-BIO3: CRP Levels Over Time";
    title2 "PBCAR20A-01 Phase 1/2a — All Treated Subjects";
run;

ods graphics off;

/* 3. Peak Cytokine Analysis */
proc sql;
    create table peak_cytokines as
    select USUBJID,
           max(IL6) as PEAK_IL6,
           max(IFNG) as PEAK_IFNG,
           max(CRP) as PEAK_CRP
    from cytokines
    group by USUBJID;
quit;

proc means data=peak_cytokines n mean std median q1 q3 max;
    var PEAK_IL6 PEAK_IFNG PEAK_CRP;
    title "Peak Cytokine Levels Summary";
run;

/* 4. Cytokine-CRS Correlation (if CRS data available) */
/* Note: Would merge with ADAE CRS events in full implementation */

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ CYTOKINE FIGURES GENERATED;
%put NOTE: ----------------------------------------------------;
