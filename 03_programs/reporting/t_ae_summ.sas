/******************************************************************************
 * Program:      t_ae_summ.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Table 14.3.1 - Overview of Treatment-Emergent Adverse Events
 * Author:       Clinical Programming Lead
 * Date:         2026-01-26
 *
 * Description:  This program produces a summary table of TEAEs, including
 *               maximum toxicity grade and events of special interest (CRS/ICANS).
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
   %else %if %sysfunc(fileexist(../../03_programs/00_config.sas)) %then %include "../../03_programs/00_config.sas";
%mend;
%load_config;

/* 1. Get Population Totals (Big N) from ADSL */
proc sql noprint;
    select count(*) into :n_total from adam.adsl where SAFFL='Y';
    select count(*) into :n_dl1 from adam.adsl where SAFFL='Y' and TRT01AN=1;
    select count(*) into :n_dl2 from adam.adsl where SAFFL='Y' and TRT01AN=2;
    select count(*) into :n_dl3 from adam.adsl where SAFFL='Y' and TRT01AN=3;
quit;

%let n_dl1 = %trim(&n_dl1);
%let n_dl2 = %trim(&n_dl2);
%let n_dl3 = %trim(&n_dl3);

/* 2. Process AE Data */
data ae_data;
    set adam.adae;
    where TRTEMFL = 'Y';
run;

/* 3. Define Categorization Logic */
proc format;
    value row_fmt
        1 = "Any Treatment-Emergent Adverse Event (TEAE)"
        2 = "Any TEAE with Grade 3 or 4"
        3 = "Any Serious TEAE"
        4 = "Cytokine Release Syndrome (CRS)"
        5 = "Any ICANS"
    ;
run;

/* 4. Subject Level Flags (Robust SQL Approach) */
proc sql;
    create table subj_flags as
    select a.USUBJID, a.TRT01AN,
           max(case when ae.USUBJID is not null then 1 else 0 end) as any_teae,
           max(case when ae.AETOXGRN >= 3 then 1 else 0 end) as any_g34,
           max(case when ae.AESER = 'Y' then 1 else 0 end) as any_ser,
           max(case when index(upcase(ae.AEDECOD), 'CYTOKINE RELEASE') > 0 then 1 else 0 end) as any_crs,
           max(case when index(upcase(ae.AEDECOD), 'NEUROTOXICITY') > 0 or 
                         index(upcase(ae.AEDECOD), 'IMMUNE EFFECTOR') > 0 then 1 else 0 end) as any_icans
    from adam.adsl a
    left join ae_data ae on a.USUBJID = ae.USUBJID
    where a.SAFFL = 'Y'
    group by a.USUBJID, a.TRT01AN;
quit;

proc transpose data=subj_flags out=trans_flags;
    by USUBJID TRT01AN;
    var any_teae any_g34 any_ser any_crs any_icans;
run;

data final_counts;
    set trans_flags;
    length row_label $100;
    if _NAME_ = "any_teae" then row = 1;
    else if _NAME_ = "any_g34" then row = 2;
    else if _NAME_ = "any_ser" then row = 3;
    else if _NAME_ = "any_crs" then row = 4;
    else if _NAME_ = "any_icans" then row = 5;
    
    row_label = put(row, row_fmt.);
run;

proc sql;
    create table table_out as
    select row, row_label, TRT01AN, sum(COL1) as count
    from final_counts
    group by row, row_label, TRT01AN;
quit;

/* Prepare for display */
data report;
    set table_out;
    length result $20;
    if TRT01AN = 1 then denom = &n_dl1;
    else if TRT01AN = 2 then denom = &n_dl2;
    else if TRT01AN = 3 then denom = &n_dl3;
    
    if denom > 0 then pct = (count / denom) * 100;
    else pct = 0;
    
    result = put(count, 3.) || " (" || put(pct, 5.1) || "%)";
run;

proc transpose data=report out=final_report(drop=_NAME_);
    by row row_label;
    id TRT01AN;
    var result;
run;

/* 4. Final Formatting & Output */
options nodate nonumber;
title1 "BV-CAR20-P1: CAR-T Safety Study";
title2 "Table 14.3.1: Overview of Treatment-Emergent Adverse Events";
title3 "Safety Population";

footnote1 "Note: Percentages are based on the number of subjects in the Safety Population (N).";
footnote2 "TEAE: Treatment-Emergent Adverse Event. CRS: Cytokine Release Syndrome.";

proc report data=final_report nowd headline headskip split='|';
    column row_label ("Dose Level 1|(N=&n_dl1)" _1) ("Dose Level 2|(N=&n_dl2)" _2) ("Dose Level 3|(N=&n_dl3)" _3);
    define row_label / "Adverse Event Category" width=50;
    define _1 / "n (%)" center width=15;
    define _2 / "n (%)" center width=15;
    define _3 / "n (%)" center width=15;
run;

/* Export results */
ods html body="&OUT_TABLES/t_ae_summ.html";
proc print data=final_report(obs=10); run;
ods html close;
