/******************************************************************************
 * Program:      f_ae_time.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Figure 14.3.1 - Timeline of CAR-T Toxicity (CRS/ICANS)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-01
 * SAS Version:  9.4
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

/* 1. Extract AESI Timeline Data post-infusion */
data ae_timeline;
    set adam.adae;
    where AESIFL = 'Y' and not missing(CARTDT);
    
    /* Days post-infusion */
    REL_START = ASTDT - CARTDT;
    REL_END = AENDT - CARTDT;
    
    /* Handle ongoing events for plotting */
    if missing(REL_END) then REL_END = 30; /* Representative end of window */
    
    length SUBJID_LBL $20;
    SUBJID_LBL = scan(USUBJID, -1, '-');
run;

proc sort data=ae_timeline;
    by REL_START;
run;

/* 2. Generate Plot */
ods graphics / reset width=800px height=500px imagename="f_ae_time";
title1 "&STUDYID: CAR-T Safety Visualization";
title2 "Figure 14.3.1: Timeline of Post-Infusion AESI (CRS/ICANS)";
title3 "Safety Population";

footnote1 "Note: X-axis represents days relative to CAR-T infusion (Day 0).";
footnote2 "Horizontal bars represent the duration of the event.";

proc sgplot data=ae_timeline;
    highlow y=SUBJID_LBL low=REL_START high=REL_END / group=AEDECOD type=bar;
    xaxis label="Days Since CAR-T Infusion" min=-1 max=30;
    yaxis label="Subject ID";
    keylegend / title="Adverse Event (PT)";
run;

/* Export results */
ods html body="&OUT_FIGURES/f_ae_time.html";
proc print data=ae_timeline(obs=10); run;
ods html close;


