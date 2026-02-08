/******************************************************************************
 * Program:      t_dm.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Table 1.3 - Summary of Demographics and Baseline Characteristics
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

/* 1. Prepare Data */
data t_dm_data;
    set adam.adsl;
    where SAFFL = 'Y';
run;

/* 2. Calculate Big N */
proc sql noprint;
    select count(*) into :N_DL1 from t_dm_data where ARMCD = 'DL1';
    select count(*) into :N_DL2 from t_dm_data where ARMCD = 'DL2';
    select count(*) into :N_DL3 from t_dm_data where ARMCD = 'DL3';
    select count(*) into :N_TOT from t_dm_data;
quit;

%let N_DL1 = %trim(&N_DL1);
%let N_DL2 = %trim(&N_DL2);
%let N_DL3 = %trim(&N_DL3);

/* 3. Age Summary */
proc means data=t_dm_data n mean std median min max noprint;
    class ARMCD;
    var AGE;
    output out=age_stats n=N mean=Mean std=Std median=Median min=Min max=Max;
run;

data age_long;
    set age_stats;
    where _TYPE_ > 0;
    length Category $20 Level $40 ValueC $20;
    Category = "Age (Years)";
    Level = "N";      ValueC = strip(put(N, 6.));   output;
    Level = "Mean";   ValueC = strip(put(Mean, 6.1)); output;
    Level = "SD";     ValueC = strip(put(Std, 6.1));  output;
    Level = "Median"; ValueC = strip(put(Median, 6.1)); output;
    Level = "Min";    ValueC = strip(put(Min, 6.1)); output;
    Level = "Max";    ValueC = strip(put(Max, 6.1)); output;
    keep Category Level ARMCD ValueC;
run;

/* 4. Categorical Summaries */
data cat_long;
    set t_dm_data;
    length Category $20 Level $40 ValueC $20;
    Category = "Sex";       Level = coalescec(SEX, "");    ValueC = "1"; output;
    Category = "Race";      Level = coalescec(RACE, "");   ValueC = "1"; output;
    Category = "Age Group"; Level = coalescec(AGEGR1, ""); ValueC = "1"; output;
    keep Category Level ARMCD ValueC;
run;

proc sql;
    create table cat_counts as
    select Category, Level, ARMCD, strip(put(count(*), 6.)) as ValueC length=20
    from cat_long
    group by Category, Level, ARMCD;
quit;

data summary_long;
    set age_long cat_counts;
run;

proc sort data=summary_long;
    by Category Level;
run;

/* 5. Production Table */
title "Table 1.3: Summary of Demographics and Baseline Characteristics";
title2 "Safety Population";

/* Handle the DL2 "Skipped" note per SAP Section 1.1 when intermediate level is absent */
%macro check_dl2;
    %if &N_DL2 = 0 %then %do;
        %put NOTE: Dose Level 2 (3x10^6 cells/kg; ~240x10^6 flat equivalent) was SKIPPED per Protocol V4 amendments.;
    %end;
%mend;
%check_dl2;

proc report data=summary_long nowd headskip split='|' style(report)={outputwidth=100%};
    column Category Level ARMCD, ValueC;
    define Category / group "Characteristic";
    define Level / group "Category/Statistic";
    define ARMCD / across "Dose Level";
    define ValueC / display "Value" center;
    
    compute after _page_;
        line @1 "--------------------------------------------------------------------------------";
        %if &N_DL2 = 0 %then %do;
        line @1 "Note: Dose Level 2 (3x10^6 cells/kg; ~240x10^6 flat equivalent) was skipped per SAP Section 1.1;";
        line @1 "directly from Level 1 to Level 3 based on SRC recommendation.";
        %end;
    endcomp;
run;

/* Export results to a safe location */
ods html body="&OUT_TABLES/t_dm.html";
proc print data=summary_long(obs=10); run;
ods html close;

