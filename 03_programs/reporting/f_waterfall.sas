/******************************************************************************
 * Program:      f_waterfall.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Figure 14.2.1 - Waterfall Plot of Best Tumor Response
 * Author:       Clinical Programming Lead
 * Date:         2026-02-01
 * SAS Version:  9.4
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* 1. Prepare Plot Data from ADRS and ADTR (Simulated for Figure) */
/* In a real trial, we would join with ADTR to get % Change in Sum of Diameters */
data waterfall_data;
    set adam.adrs;
    where PARAMCD = 'BOR' and ITTFL = 'Y';
    
    /* Simulated % Change for visualization based on AVALC */
    length SUBJID_LBL $20;
    SUBJID_LBL = scan(USUBJID, -1, '-');
    
    if AVALC = 'CR' then CHG_SIM = -100;
    else if AVALC = 'PR' then CHG_SIM = -65 - (RANUNI(123)*20);
    else if AVALC = 'SD' then CHG_SIM = -10 + (RANUNI(123)*30);
    else if AVALC = 'PD' then CHG_SIM = 25 + (RANUNI(123)*50);
    else CHG_SIM = 0;
run;

proc sort data=waterfall_data;
    by CHG_SIM;
run;

/* 2. Generate Plot using SGPLOT */
ods graphics / reset width=800px height=500px imagename="f_waterfall";
title1 "BV-CAR20-P1: CAR-T Efficacy Visualization";
title2 "Figure 14.2.1: Waterfall Plot of Best Tumor Response";
title3 "Intent-To-Treat (ITT) Population";

footnote1 "Note: Bars represent the best percentage change from baseline in sum of diameters.";
footnote2 "Subjects with response category 'CR' are represented as -100%.";

proc sgplot data=waterfall_data;
    vbar SUBJID_LBL / response=CHG_SIM group=ARMCD categoryorder=respasc;
    refline -30 / axis=y lineattrs=(thickness=1 color=gray pattern=dash) label="-30% (PR threshold)";
    refline 20 / axis=y lineattrs=(thickness=1 color=gray pattern=dash) label="+20% (PD threshold)";
    xaxis label="Subject ID (Ranked by Response)";
    yaxis label="Best % Change from Baseline in Sum of Diameters" min=-100 max=100;
    keylegend / title="Dose Level";
run;

/* Export results */
ods html body="&OUT_FIGURES/f_waterfall.html";
proc print data=waterfall_data(obs=10); run;
ods html close;
