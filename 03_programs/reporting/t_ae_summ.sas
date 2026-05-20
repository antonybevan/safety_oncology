/******************************************************************************
 * Program:      t_ae_summ.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Table 14.3.1 - Overview of Treatment-Emergent Adverse Events
 * Author:       Statistical Programmer
 * Date:         2026-01-26
 ******************************************************************************/

%load_config;

/* 1. Pre-initialize macro variables to 0 to prevent syntax errors */
%let n_total = 0;
%let n_dl1 = 0;
%let n_dl2 = 0;
%let n_dl3 = 0;

proc sql noprint;
    select count(*) into :n_total from adam.adsl where SAFFL='Y';
    select count(*) into :n_dl1 from adam.adsl where SAFFL='Y' and TRT01AN=1;
    select count(*) into :n_dl2 from adam.adsl where SAFFL='Y' and TRT01AN=2;
    select count(*) into :n_dl3 from adam.adsl where SAFFL='Y' and TRT01AN=3;
quit;

%let n_total = %trim(&n_total);
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
           max(case when ae.AESICAT = 'CRS' then 1 else 0 end) as any_crs,
           max(case when ae.AESICAT = 'ICANS' then 1 else 0 end) as any_icans
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

/* Create shell to guarantee all rows and treatment columns exist */
data shell;
    do row = 1 to 5;
        row_label = put(row, row_fmt.);
        do TRT01AN = 1 to 3;
            count = 0;
            output;
        end;
    end;
run;

proc sort data=table_out; by row TRT01AN; run;

data report_all;
    merge shell(in=s) table_out(in=a);
    by row TRT01AN;
    if count = . then count = 0;
run;

/* Prepare for display */
data report;
    set report_all;
    length result $20;
    
    if TRT01AN = 1 then denom = input("&n_dl1", 8.);
    else if TRT01AN = 2 then denom = input("&n_dl2", 8.);
    else if TRT01AN = 3 then denom = input("&n_dl3", 8.);
    else denom = 0;
    
    if not missing(denom) and denom > 0 then pct = (count / denom) * 100;
    else pct = 0;
    
    result = put(count, 3.) || " (" || put(pct, 5.1) || "%)";
run;

proc transpose data=report out=final_report(drop=_NAME_);
    by row row_label;
    id TRT01AN;
    var result;
run;

/* 5. Final Formatting & Output */
options nodate nonumber ls=120 ps=60;
title1 "&STUDYID: CAR-T Safety Study";
title2 "Table 14.3.1: Overview of Treatment-Emergent Adverse Events";
title3 "Safety Population";

footnote1 "Note: Percentages are based on the number of subjects in the Safety Population (N).";
footnote2 "TEAE: Treatment-Emergent Adverse Event. CRS: Cytokine Release Syndrome.";

%ods_setup(type=RTF, outpath=&OUT_TABLES/t_ae_summ.rtf);

proc report data=final_report nowd headline headskip split='|' style(report)={outputwidth=100%};
    column row_label ("Dose Level 1|(N=&n_dl1)" _1) ("Dose Level 2|(N=&n_dl2)" _2) ("Dose Level 3|(N=&n_dl3)" _3);
    define row_label / "Adverse Event Category" width=50;
    define _1 / "n (%)" center width=15;
    define _2 / "n (%)" center width=15;
    define _3 / "n (%)" center width=15;
run;

%ods_close(type=RTF);
