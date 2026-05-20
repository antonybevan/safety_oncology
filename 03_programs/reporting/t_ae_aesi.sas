/******************************************************************************
 * Program:      t_ae_aesi.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Table 3.5 - Summary of AEs of Special Interest and Infections by Max Toxicity Grade and Dose
 * Author:       Statistical Programmer
 * Date:         2026-02-01
 * SAS Version:  9.4 / SAS OnDemand compatible
 ******************************************************************************/

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

/* 2. Process AESI Data */
data aesi_data;
    set adam.adae;
    where (AESIFL = 'Y' or INFFL = 'Y') and TRTEMFL = 'Y';
run;

/* 3. Categorize by AESI Type and Max ASTCT Grade */
proc sql;
    create table aesi_summary as
    select USUBJID, ARMCD, 
           max(case when AESICAT = 'CRS' then 1 else 0 end) as CRS_FL,
           max(case when AESICAT = 'ICANS' then 1 else 0 end) as ICANS_FL,
           max(case when AESICAT = 'GVHD' then 1 else 0 end) as GVHD_FL,
           max(case when INFFL = 'Y' then 1 else 0 end) as INF_FL,
           max(AETOXGRN) as MAX_ASTCT_GR
    from aesi_data
    group by USUBJID, ARMCD;
quit;

/* 4. Subject Level Flags & Summarization */
proc sql;
    create table aesi_counts as
    select ARMCD,
           sum(CRS_FL) as crs_count,
           sum(ICANS_FL) as icans_count,
           sum(GVHD_FL) as gvhd_count,
           sum(INF_FL) as inf_count
    from aesi_summary
    group by ARMCD;
quit;

/* Transpose to have one row per parameter */
proc transpose data=aesi_counts out=trans_aesi;
    by ARMCD;
    var crs_count icans_count gvhd_count inf_count;
run;

/* Sort by parameter so we can transpose by parameter and have columns as treatment */
proc sort data=trans_aesi;
    by _NAME_ ARMCD;
run;

data shell;
    length _NAME_ $32 ARMCD $20;
    do _NAME_ = 'crs_count', 'icans_count', 'gvhd_count', 'inf_count';
        do ARMCD = 'DL1', 'DL2', 'DL3';
            COL1 = 0;
            output;
        end;
    end;
run;

proc sort data=shell;
    by _NAME_ ARMCD;
run;

data trans_aesi_all;
    merge shell(in=s) trans_aesi(in=a);
    by _NAME_ ARMCD;
    if COL1 = . then COL1 = 0;
run;

data report_aesi;
    set trans_aesi_all;
    length row_label $100 result $20;
    
    if _NAME_ = 'crs_count' then row_label = "Cytokine Release Syndrome (CRS)";
    else if _NAME_ = 'icans_count' then row_label = "Immune Effector Cell-Associated Neurotoxicity Syndrome (ICANS)";
    else if _NAME_ = 'gvhd_count' then row_label = "Graft-versus-Host Disease (GvHD)";
    else if _NAME_ = 'inf_count' then row_label = "Any Infections";
    
    if ARMCD = 'DL1' then denom = input("&N_DL1", 8.);
    else if ARMCD = 'DL2' then denom = input("&N_DL2", 8.);
    else if ARMCD = 'DL3' then denom = input("&N_DL3", 8.);
    else denom = 0;
    
    if not missing(denom) and denom > 0 then pct = (COL1 / denom) * 100;
    else pct = 0;
    
    result = put(COL1, 3.) || " (" || put(pct, 5.1) || "%)";
run;

proc transpose data=report_aesi out=final_aesi(drop=_NAME_);
    by _NAME_ row_label;
    id ARMCD;
    var result;
run;

/* Order parameters logically */
data final_aesi;
    set final_aesi;
    if index(row_label, 'Cytokine') > 0 then ord = 1;
    else if index(row_label, 'Neurotoxicity') > 0 then ord = 2;
    else if index(row_label, 'Graft') > 0 then ord = 3;
    else ord = 4;
run;

proc sort data=final_aesi; by ord; run;

/* 5. Production Table Formatting using Portable ODS Macros */
title1 "&STUDYID: CAR-T Safety Analysis";
title2 "Table 3.5: Summary of AEs of Special Interest and Infections by Max Toxicity Grade and Dose";
title3 "Safety Population";

footnote1 "Note: CRS and ICANS are graded via ASTCT 2019 Consensus Criteria.";
footnote2 "GvHD is assessed via Protocol-specified organ grading.";

%ods_setup(type=RTF, outpath=&OUT_TABLES/t_ae_aesi.rtf);

proc report data=final_aesi nowd headline headskip split='|' style(report)={outputwidth=100%};
    column row_label ("Dose Level 1|(N=&N_DL1)" DL1) ("Dose Level 2|(N=&N_DL2)" DL2) ("Dose Level 3|(N=&N_DL3)" DL3);
    define row_label / "AE of Special Interest / Infection" width=60;
    define DL1 / "n (%)" center width=15;
    define DL2 / "n (%)" center width=15;
    define DL3 / "n (%)" center width=15;
run;

%ods_close(type=RTF);
