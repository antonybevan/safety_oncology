/******************************************************************************
 * Program:      t_mrd.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Minimal Residual Disease (MRD) Analysis
 * Author:       Statistical Programmer
 * Date:         2026-02-05
 * SAS Version:  9.4
 *
 * Input:        adam.adrs (MRD PARAMCD), sdtm.rs (fallback)
 * Output:       Table 2.4: MRD Negativity Rate
 *
 * Note:  MRD is a key exploratory endpoint for CAR-T in hematologic
 *        malignancies (10^-4 or 10^-5 sensitivity).
 *        Phase 2a extended datasets are optional — table is generated
 *        only when MRD source data exists.
 ******************************************************************************/

%load_config;

/* ============================================================================
   MRD SOURCE RESOLUTION
   1. Prefer sdtm.mrd_phase2a_full if available (phase 2a expansion dataset)
   2. Fall back to sdtm.rs filtered on RSTESTCD = 'MRD'
   3. If no source exists, emit a clean placeholder message
   ============================================================================ */
%let mrd_src_ready = 0;

%macro resolve_mrd_source;
    %local has_mrd_full has_rs_mrd _cnt;
    %let has_mrd_full = %sysfunc(exist(sdtm.mrd_phase2a_full));
    %let _cnt = 0;

    %if &has_mrd_full %then %do;
        data mrd_raw;
            set sdtm.mrd_phase2a_full;
        run;
        %let mrd_src_ready = 1;
    %end;
    %else %do;
        /* Check if MRD records exist in RS domain */
        %let has_rs_mrd = %sysfunc(exist(sdtm.rs));
        %if &has_rs_mrd %then %do;
            proc sql noprint;
                select count(*) into :_cnt trimmed
                from sdtm.rs
                where upcase(RSTESTCD) = 'MRD';
            quit;
            %if &_cnt > 0 %then %do;
                data mrd_raw;
                    set sdtm.rs;
                    where upcase(RSTESTCD) = 'MRD';
                    length DISEASE $10 TIMEPOINT $30 MRDRESULT $20;
                    /* Map from RS variables */
                    DISEASE  = 'UNKNOWN';  /* Domain RS does not carry DISEASE */
                    TIMEPOINT = coalescec(strip(VISIT), 'Unknown');
                    MRDRESULT = upcase(strip(RSSTRESC));
                    MRDNEG = (MRDRESULT in ('NEGATIVE','NEG','UNDETECTABLE','ND'));
                run;
                %let mrd_src_ready = 1;
            %end;
        %end;
    %end;

    %if &mrd_src_ready = 0 %then %do;
        data mrd_raw;
            length DISEASE $10 TIMEPOINT $30 MRDRESULT $20 MRDNEG 8 USUBJID $40;
            call missing(of _all_);
            stop;
        run;
        %put NOTE: No MRD source data found. MRD table will display placeholder.;
    %end;
%mend resolve_mrd_source;
%resolve_mrd_source;

/* ============================================================================
   RENDER MRD TABLE OR PLACEHOLDER
   ============================================================================ */
%macro render_mrd;

%ods_setup(type=RTF, outpath=&OUT_TABLES/t_mrd.rtf);

proc sql noprint;
    select count(*) into :_mrd_n trimmed from mrd_raw;
quit;

%if %sysevalf(&_mrd_n > 0) %then %do;

    /* 1. Merge with ADSL for arm info */
    proc sql;
        create table mrd_data as
        select r.*, a.ARMCD, a.COHORT,
               coalescec(a.COHORT, r.DISEASE) as DISEASE_LABEL
        from mrd_raw r
        left join adam.adsl a on r.USUBJID = a.USUBJID
        where a.EFFFL = 'Y' or missing(a.EFFFL);
    quit;

    /* 2. MRD Negativity Rate by Disease and Timepoint */
    proc freq data=mrd_data;
        tables DISEASE * TIMEPOINT * MRDRESULT / nocum nopercent;
        title1 "Table 2.4: MRD Status by Disease and Timepoint";
        title2 "&STUDYID Phase 1 — Efficacy Evaluable Population";
    run;

    /* 3. Summary Table */
    proc sql;
        create table mrd_summary as
        select DISEASE, TIMEPOINT,
               count(*) as N_Assessed,
               sum(MRDNEG) as N_Negative,
               case when count(*) > 0
                    then sum(MRDNEG) / count(*) * 100
                    else .
               end as MRD_Neg_Rate format=5.1
        from mrd_data
        group by DISEASE, TIMEPOINT
        order by DISEASE, TIMEPOINT;
    quit;

    proc print data=mrd_summary noobs label;
        label DISEASE        = "Disease"
              TIMEPOINT       = "Timepoint"
              N_Assessed      = "N Assessed"
              N_Negative      = "N MRD-Negative"
              MRD_Neg_Rate    = "MRD Negativity Rate (%)";
        title "MRD Negativity Rate Summary";
    run;

    /* 4. MRD Rate Over Time — Line Plot */
    %ods_close(type=RTF);
    %ods_setup(type=GRAPH, imgname=f_mrd_time, imgw=8in, imgh=6in);

    proc sgplot data=mrd_summary;
        series x=TIMEPOINT y=MRD_Neg_Rate / group=DISEASE
               markers markerattrs=(size=10);
        xaxis label="Assessment Timepoint" discreteorder=data;
        yaxis label="MRD Negativity Rate (%)" values=(0 to 100 by 20);
        keylegend / position=bottom title="Disease";
        title1 "Figure F-MRD1: MRD Negativity Rate Over Time";
        title2 "&STUDYID Phase 1 — Efficacy Evaluable Population";
        footnote1 "MRD assessed by flow cytometry at 10^-4 sensitivity.";
    run;

    %ods_close(type=GRAPH);

%end;
%else %do;

    data mrd_placeholder;
        length Message $200;
        Message = "MRD data not available for this study phase. Table 2.4 will be populated upon Phase 2a data availability.";
    run;

    proc print data=mrd_placeholder noobs;
        title1 "Table 2.4: MRD Status by Disease and Timepoint";
        title2 "Data Not Available — Phase 1 Only";
    run;

    %ods_close(type=RTF);

%end;

%mend render_mrd;
%render_mrd;

%put NOTE: ------------------------------------------------------;
%put NOTE: MRD ANALYSIS COMPLETE;
%put NOTE: ------------------------------------------------------;
