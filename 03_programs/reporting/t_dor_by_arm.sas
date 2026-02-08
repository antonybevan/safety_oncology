/******************************************************************************
 * Program:      t_dor_by_arm.sas
 * Protocol:     BV-CAR20-P1 (Full Phase 2a per Original Protocol)
 * Purpose:      Duration of Response by Phase 2a Arm
 * Author:       Clinical Programming Lead
 * Date:         2026-02-08
 * SAS Version:  9.4
 *
 * Per Protocol Section 2.2.2: DoR for expansion cohorts
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

%let rs_src = sdtm.rs;
%if %sysfunc(exist(sdtm.rs_phase2a_full)) %then %let rs_src = sdtm.rs sdtm.rs_phase2a_full;

%let adsl_src = adam.adsl;
%if %sysfunc(exist(adam.adsl_expanded)) %then %let adsl_src = adam.adsl_expanded;

/* ============================================================================
   DURATION OF RESPONSE BY PHASE 2A ARM (Protocol Section 2.2.2)
   DoR = time from first response (CR/PR) to progression or death.
   Responders without event are censored at last tumor assessment.
   ============================================================================ */

/* 1. Prepare response assessment dates */
data rs_for_dor;
    set &rs_src;
    length RSRESP $10;
    RSRESP = upcase(strip(RSSTRESC));
    RSDT = input(RSDTC, yymmdd10.);
    format RSDT date9.;
    if missing(USUBJID) or missing(RSDT) then delete;
    keep USUBJID RSDT RSRESP;
run;

proc sort data=rs_for_dor;
    by USUBJID RSDT;
run;

/* First response date and last assessment date by subject */
data dor_anchor;
    set rs_for_dor;
    by USUBJID RSDT;
    retain RESPDT LASTRSDT;
    format RESPDT LASTRSDT date9.;

    if first.USUBJID then do;
        RESPDT = .;
        LASTRSDT = .;
    end;

    LASTRSDT = RSDT;

    if missing(RESPDT) and RSRESP in ('CR', 'CRI', 'PR', 'CMR', 'PMR') then RESPDT = RSDT;

    if last.USUBJID then output;
    keep USUBJID RESPDT LASTRSDT;
run;

/* First PD date on/after first response */
proc sql;
    create table prog_after_resp as
    select r.USUBJID,
           min(r.RSDT) as PROGDT format=date9.
    from rs_for_dor r
    inner join dor_anchor a
        on r.USUBJID = a.USUBJID
    where r.RSRESP in ('PD', 'PMD')
      and not missing(a.RESPDT)
      and r.RSDT >= a.RESPDT
    group by r.USUBJID;
quit;

/* 2. Build DoR analysis set from source data only */
proc sort data=dor_anchor; by USUBJID; run;
proc sort data=prog_after_resp; by USUBJID; run;
proc sort data=&adsl_src out=adsl_for_dor(keep=USUBJID ARMCD ARM COHORT DISEASE DTHDT EFFFL where=(EFFFL='Y')); by USUBJID; run;

data dor_by_arm;
    merge adsl_for_dor(in=a)
          dor_anchor(in=b)
          prog_after_resp(in=c);
    by USUBJID;
    if not a then delete;

    format ADT EVNTDT CUTOFFDT date9.;
    CUTOFFDT = input("&DATA_CUTOFF", yymmdd10.);

    /* DoR is defined only for responders */
    if missing(RESPDT) then delete;

    /* Event = earliest of progression or death on/after response */
    EVNTDT = .;
    if not missing(PROGDT) and PROGDT >= RESPDT then EVNTDT = PROGDT;
    if not missing(DTHDT) and DTHDT >= RESPDT then do;
        if missing(EVNTDT) then EVNTDT = DTHDT;
        else EVNTDT = min(EVNTDT, DTHDT);
    end;

    if not missing(EVNTDT) then do;
        ADT = EVNTDT;
        CNSR = 0;
        EVNTDESC = "Event";
    end;
    else do;
        ADT = LASTRSDT;
        if missing(ADT) then ADT = CUTOFFDT;
        if missing(ADT) then ADT = RESPDT;
        CNSR = 1;
        EVNTDESC = "Censored";
    end;

    if ADT < RESPDT then ADT = RESPDT;

    DOR_DAYS = ADT - RESPDT + 1;
    DOR_MONTHS = round(DOR_DAYS / 30.4375, 0.1);

    label DOR_MONTHS = "Duration of Response (Months)";
run;

/* 3. KM analysis only when DoR records exist */
proc sql noprint;
    select count(*) into :N_RESP trimmed
    from dor_by_arm;
quit;

%macro run_dor;
    %if %sysevalf(&N_RESP > 0) %then %do;
        ods output ProductLimitEstimates=dor_km_arm Quartiles=dor_median_arm;
        proc lifetest data=dor_by_arm method=KM plots=survival(atrisk=0 to 24 by 6);
            time DOR_MONTHS * CNSR(1);
            strata COHORT / test=logrank;
            title1 "Figure F-EFF4: Duration of Response by Phase 2a Arm";
            title2 "Kaplan-Meier Curves - Responders (CR/PR)";
        run;
        ods output close;

        data dor_summary;
            set dor_median_arm;
            where Percent = 50;

            length Median_DoR $50;
            if Estimate ne . then
                Median_DoR = catx(' ', put(Estimate, 5.1),
                                 cats('(', put(LowerLimit, 5.1), '-', put(UpperLimit, 5.1), ')'));
            else Median_DoR = "NR";
        run;

        proc print data=dor_summary noobs;
            var Stratum Median_DoR;
            title "Median Duration of Response by Arm";
        run;

        proc sql;
            create table dor_arm_summary as
            select ARMCD,
                   COHORT,
                   DISEASE,
                   count(*) as N_Responders,
                   sum(case when CNSR = 0 then 1 else 0 end) as N_Events,
                   median(DOR_MONTHS) as Median_DoR format=5.1
            from dor_by_arm
            group by ARMCD, COHORT, DISEASE;
        quit;

        proc print data=dor_arm_summary noobs label;
            label ARMCD = "Arm"
                  COHORT = "Cohort"
                  DISEASE = "Disease"
                  N_Responders = "Responders"
                  N_Events = "Events"
                  Median_DoR = "Median DoR (months)";
            title1 "Table 2.3: Duration of Response Summary by Phase 2a Arm";
        run;
    %end;
    %else %do;
        data dor_empty;
            length Message $200;
            Message = "No responders with evaluable DoR were found in source data.";
        run;

        proc print data=dor_empty noobs;
            title1 "Table 2.3: Duration of Response Summary by Phase 2a Arm";
        run;

        %put WARNING: No DoR analysis records were available. No KM output generated.;
    %end;
%mend;
%run_dor;

%put NOTE: ----------------------------------------------------;
%put NOTE: DOR BY ARM ANALYSIS COMPLETE;
%put NOTE: ----------------------------------------------------;

