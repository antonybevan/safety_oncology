/******************************************************************************
 * Bundle:  t007_t_dm
 * Source:  m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_dm.sas
 *
 * Table 1.3 - Demographics and Baseline Characteristics. The table body below
 * is the repo's t_dm.sas unchanged: PROC SQL big-N by arm, PROC MEANS with a
 * CLASS statement for age summary, categorical counts, a combine/sort/
 * PROC TRANSPOSE to a wide one-column-per-arm layout, and a PROC PRINT whose
 * columns are chosen by conditional macro logic. The ADAM library (adsl) is
 * supplied as a small in-memory mock by the bundle autoexec so the whole
 * table runs in isolation.
 ******************************************************************************/


%load_config;

/* Initialize dose counter macro variables to prevent uninitialized string resolution */
%let N_DL1 = 0;
%let N_DL2 = 0;
%let N_DL3 = 0;

/* ============================================================================
   1. Safety Population
   ============================================================================ */
data t_dm_data;
    set adam.adsl;
    where SAFFL = 'Y';
run;

/* Big N by arm */
proc sql noprint;
    select count(*) into :N_DL1 trimmed from t_dm_data where ARMCD = 'DL1';
    select count(*) into :N_DL2 trimmed from t_dm_data where ARMCD = 'DL2';
    select count(*) into :N_DL3 trimmed from t_dm_data where ARMCD = 'DL3';
    select count(*) into :N_TOT trimmed from t_dm_data;
quit;

/* ============================================================================
   2. Age Summary by Arm
   ============================================================================ */
proc means data=t_dm_data n mean std median min max noprint;
    class ARMCD;
    var AGE;
    output out=age_stats(where=(_TYPE_>0)) n=N mean=Mean std=Std median=Median min=Min max=Max;
run;

data age_long;
    set age_stats;
    length Category $30 Statistic $40 ValueC $20;
    Category  = 'Age (Years)';
    Statistic = 'N';       ValueC = strip(put(N,      6.  )); output;
    Statistic = 'Mean';    ValueC = strip(put(Mean,   6.1 )); output;
    Statistic = 'SD';      ValueC = strip(put(Std,    6.1 )); output;
    Statistic = 'Median';  ValueC = strip(put(Median, 6.1 )); output;
    Statistic = 'Min';     ValueC = strip(put(Min,    6.1 )); output;
    Statistic = 'Max';     ValueC = strip(put(Max,    6.1 )); output;
    keep Category Statistic ARMCD ValueC;
run;

/* ============================================================================
   3. Categorical Counts by Arm
   ============================================================================ */
data cat_input;
    set t_dm_data;
    length Category $30 Statistic $40;
    Category = 'Sex';       Statistic = coalescec(strip(SEX),    'Unknown'); output;
    Category = 'Race';      Statistic = coalescec(strip(RACE),   'Unknown'); output;
    Category = 'Age Group'; Statistic = coalescec(strip(AGEGR1), 'Unknown'); output;
    keep Category Statistic ARMCD;
run;

proc sql;
    create table cat_counts as
    select Category, Statistic, ARMCD,
           strip(put(count(*), 6.)) as ValueC
    from cat_input
    group by Category, Statistic, ARMCD;
quit;

/* ============================================================================
   4. Combine and Transpose to Wide Format (one column per arm)
   ============================================================================ */
data all_stats;
    set age_long cat_counts;
run;

proc sort data=all_stats; by Category Statistic; run;

/* Transpose: one row per Category/Statistic, columns DL1 DL2 DL3 */
proc transpose data=all_stats out=dm_wide(drop=_NAME_) prefix=ARM_;
    by Category Statistic;
    id ARMCD;
    var ValueC;
run;

/* ============================================================================
   5. Produce Table
   ============================================================================ */
%macro generate_t_dm;
%ods_setup(type=RTF, outpath=&OUT_TABLES/t_dm.rtf);

title  "Table 1.3: Summary of Demographics and Baseline Characteristics";
title2 "Safety Population";
%if &N_DL2 = 0 %then %do;
footnote1 "Note: Dose Level 2 (3x10^6 cells/kg) was skipped per Protocol V4; escalation proceeded DL1 -> DL3.";
%end;

proc print data=dm_wide noobs label;
    var Category Statistic
        %if &N_DL1 > 0 %then ARM_DL1;
        %if &N_DL2 > 0 %then ARM_DL2;
        %if &N_DL3 > 0 %then ARM_DL3;
    ;
    label Category  = "Characteristic"
          Statistic = "Category / Statistic"
          %if &N_DL1 > 0 %then ARM_DL1   = "DL1 (N=&N_DL1)";
          %if &N_DL2 > 0 %then ARM_DL2   = "DL2 (N=&N_DL2)";
          %if &N_DL3 > 0 %then ARM_DL3   = "DL3 (N=&N_DL3)";
    ;
run;

title; footnote;
%ods_close(type=RTF);
%mend generate_t_dm;
%generate_t_dm;

