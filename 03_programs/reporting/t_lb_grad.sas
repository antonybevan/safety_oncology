/******************************************************************************
 * Program:      t_lb_grad.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Table 14.3.3 - Grade 3 or 4 Laboratory Toxicities
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

/* 1. Get Population Totals */
proc sql noprint;
    select count(*) into :N_DL1 from adam.adsl where SAFFL = 'Y' and ARMCD = 'DL1';
    select count(*) into :N_DL2 from adam.adsl where SAFFL = 'Y' and ARMCD = 'DL2';
    select count(*) into :N_DL3 from adam.adsl where SAFFL = 'Y' and ARMCD = 'DL3';
quit;

%let N_DL1 = %trim(&N_DL1);
%let N_DL2 = %trim(&N_DL2);
%let N_DL3 = %trim(&N_DL3);

/* 2. Process Lab Toxicity Data */
data lb_high_grade;
    set adam.adlb;
    where ATOXGRL >= 3 or ATOXGRH >= 3;
run;

/* 3. Categorize by Direction and Parameter */
data lb_summary_prep;
    set lb_high_grade;
    length TOX_LABEL $200;
    if ATOXGRL >= 3 then TOX_LABEL = strip(PARAM) || " (Grade " || strip(put(ATOXGRL, 1.)) || " Low)";
    if ATOXGRH >= 3 then TOX_LABEL = strip(PARAM) || " (Grade " || strip(put(ATOXGRH, 1.)) || " High)";
run;

/* 4. Subject Level Max Grade Summary */
proc sql;
    create table lb_subj_summ as
    select USUBJID, ARM, TOX_LABEL, count(*) as n_events
    from lb_summary_prep
    group by USUBJID, ARM, TOX_LABEL;
quit;

/* 5. Reporting */
title1 "BV-CAR20-P1: CAR-T Safety Analysis";
title2 "Table 14.3.3: Summary of Grade 3 or 4 Laboratory Toxicities";
title3 "Safety Population";

footnote1 "Note: Laboratory toxicities are graded via NCI-CTCAE v5.0.";
footnote2 "Bi-directional grading (Low/High) is used to capture metabolic and electrolyte imbalances.";

proc report data=lb_subj_summ nowd headskip split='|' style(report)={outputwidth=100%};
    column TOX_LABEL ARM, (n_events);
    define TOX_LABEL / "Laboratory Parameter (Direction)" width=50;
    define ARM / across "Dose Level";
    define n_events / "n" center;
    
    compute after _page_;
        line @1 "--------------------------------------------------------------------------------";
        line @1 "Grade 3: Severe or medically significant but not immediately life-threatening.";
        line @1 "Grade 4: Life-threatening consequences; urgent intervention indicated.";
    endcomp;
run;

/* Export results */
ods html body="&OUT_TABLES/t_lb_grad.html";
proc print data=lb_subj_summ(obs=10); run;
ods html close;
