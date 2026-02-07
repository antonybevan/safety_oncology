/******************************************************************************
 * Program:      t_aesi_duration.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Table 3.3: Summary of Onset and Duration for All AESIs
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 * SAP Reference: Table 12 (3.3), §8.2.2
 *
 * Input:        adam.adae
 * Output:       Table 3.3 — AESI Onset and Duration Summary
 *
 * Note:         Per SAP: "Onset and duration are related to max grade 
 *               of each type of AE"
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* ============================================================================
   AESI ONSET AND DURATION SUMMARY (SAP Table 12: 3.3, §8.2.2)
   QC Level: 3 (Primary endpoint related)
   
   Per SAP §8.2.2:
   - Duration of AESI (days) = Date of Resolution – Date of Onset + 1
   - Time to AESI onset (days) = Date of AE onset – Day 0 Date + 1
   - For ongoing: use data cutoff date for duration calculation
   ============================================================================ */

/* 1. Get AESI data with onset/duration */
data aesi_detail;
    set adam.adae;
    where AESIFL = 'Y' and TRTEMFL = 'Y';
    
    /* Calculate onset from CAR-T (Day 0) */
    /* ASTDY should already be study day, but recalculate if needed */
    if ASTDY ne . then ONSET_DAYS = ASTDY;
    else ONSET_DAYS = .;
    
    /* Calculate duration per SAP §8.2.2 */
    if not missing(AENDT) and not missing(ASTDT) then 
        DURATION_DAYS = AENDT - ASTDT + 1;
    else if missing(AENDT) then do;
        /* Ongoing - use data cutoff */
        DURATION_DAYS = today() - ASTDT + 1;
        ONGOING_FL = 'Y';
    end;
    
    /* AESI Category labels */
    length AESI_TYPE $20;
    if AESICAT = 'CRS' then AESI_TYPE = 'CRS';
    else if AESICAT = 'ICANS' then AESI_TYPE = 'ICANS';
    else if AESICAT = 'GVHD' then AESI_TYPE = 'GvHD';
    else if INFFL = 'Y' then AESI_TYPE = 'Infection';
    else AESI_TYPE = 'Other AESI';
run;

/* 2. Summarize by AESI type and max grade */
proc sql;
    create table aesi_summary as
    select AESI_TYPE,
           ARMCD,
           max(AETOXGRN) as MAX_GRADE,
           count(distinct USUBJID) as N_SUBJECTS,
           count(*) as N_EVENTS,
           /* Onset statistics */
           median(ONSET_DAYS) as ONSET_MEDIAN,
           min(ONSET_DAYS) as ONSET_MIN,
           max(ONSET_DAYS) as ONSET_MAX,
           /* Duration statistics */
           median(DURATION_DAYS) as DUR_MEDIAN,
           min(DURATION_DAYS) as DUR_MIN,
           max(DURATION_DAYS) as DUR_MAX,
           sum(case when ONGOING_FL = 'Y' then 1 else 0 end) as N_ONGOING
    from aesi_detail
    group by AESI_TYPE, ARMCD;
quit;

/* 3. Format for display */
data aesi_report;
    set aesi_summary;
    
    length Onset_Display Duration_Display $50;
    
    /* Format: Median (Min - Max) */
    Onset_Display = catx(' ', put(ONSET_MEDIAN, 5.1), 
                         cats('(', put(ONSET_MIN, 3.), '-', put(ONSET_MAX, 3.), ')'));
    Duration_Display = catx(' ', put(DUR_MEDIAN, 5.1),
                           cats('(', put(DUR_MIN, 3.), '-', put(DUR_MAX, 3.), ')'));
    
    /* Add ongoing indicator */
    if N_ONGOING > 0 then 
        Duration_Display = catx(' ', Duration_Display, cats('[', put(N_ONGOING, 2.), ' ongoing]'));
    
    label AESI_TYPE = "AESI Type"
          N_SUBJECTS = "N Subjects"
          N_EVENTS = "N Events"
          Onset_Display = "Onset, days*Median (Range)"
          Duration_Display = "Duration, days*Median (Range)";
run;

/* 4. Generate Table */
proc report data=aesi_report nowd split='*';
    column AESI_TYPE ARMCD N_SUBJECTS N_EVENTS MAX_GRADE Onset_Display Duration_Display;
    define AESI_TYPE / group "AESI Type" left;
    define ARMCD / display "Dose*Level" center;
    define N_SUBJECTS / display "N" center;
    define N_EVENTS / display "Events" center;
    define MAX_GRADE / display "Max*Grade" center;
    define Onset_Display / display "Time to Onset (days)*Median (Range)" center;
    define Duration_Display / display "Duration (days)*Median (Range)" center;
    
    title1 "Table 3.3: Summary of Onset and Duration for Adverse Events of Special Interest";
    title2 "BV-CAR20-P1 Phase 1 — Safety Population";
    footnote1 "Time to onset = Date of AE onset – Day 0 (CAR-T infusion) + 1.";
    footnote2 "Duration = Date of resolution – Date of onset + 1.";
    footnote3 "For ongoing AESIs, duration calculated to data cutoff date.";
    footnote4 "AESI: CRS, ICANS, GvHD, Infections per SAP §8.2.2.";
run;

/* 5. Detailed by AESI category and grade (supplementary) */
proc tabulate data=aesi_detail format=8.1;
    class AESI_TYPE ARMCD AETOXGRN;
    var ONSET_DAYS DURATION_DAYS;
    table AESI_TYPE * AETOXGRN,
          ARMCD * (ONSET_DAYS='Onset (days)' * (median min max)
                   DURATION_DAYS='Duration (days)' * (median min max));
    title1 "Table 3.3a: AESI Onset and Duration by Type and Grade (Supplementary)";
run;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ AESI ONSET/DURATION TABLE GENERATED;
%put NOTE: ----------------------------------------------------;
