/******************************************************************************
 * Program:      f_waterfall.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Figure 14.2.1 - Waterfall Plot of Best Tumor Response
 * Author:       Statistical Programmer
 * Date:         2026-02-08
 * SAS Version:  9.4
 ******************************************************************************/

%load_config;

/* ============================================================================
   WATERFALL PLOT SOURCE RESOLUTION
   Priority order (all exist() checks deferred inside macro — run after adrs.sas):
     1. adam.adtr  with CHG variable  (real tumor measurement change from baseline)
     2. adam.adtr  with AVAL + PARAMCD in (PCHG/TRCHG/SODPCHG/CHG)
     3. adam.adrs  with PARAMCD = 'PCHG'  (RECIST-aligned derived values)
     4. WORK.adrs_pchg  (same-session intermediate dataset from adrs.sas)
   ============================================================================ */

%let src_ready = 0;

%macro resolve_waterfall_source;

    /* ---- Source 1 & 2: ADTR ---- */
    %local has_adtr adtr_has_chg adtr_has_aval adtr_has_paramcd dsid rc;
    %let has_adtr = %sysfunc(exist(adam.adtr));

    %if &has_adtr %then %do;
        %let adtr_has_chg     = 0;
        %let adtr_has_aval    = 0;
        %let adtr_has_paramcd = 0;
        %let dsid = %sysfunc(open(adam.adtr));
        %if &dsid %then %do;
            %if %sysfunc(varnum(&dsid, CHG))     > 0 %then %let adtr_has_chg     = 1;
            %if %sysfunc(varnum(&dsid, AVAL))    > 0 %then %let adtr_has_aval    = 1;
            %if %sysfunc(varnum(&dsid, PARAMCD)) > 0 %then %let adtr_has_paramcd = 1;
            %let rc = %sysfunc(close(&dsid));
        %end;

        %if &adtr_has_chg > 0 %then %do;
            proc sql;
                create table waterfall_src as
                select a.USUBJID, b.ARMCD, b.ARM, a.CHG as PCHG
                from adam.adtr a
                inner join adam.adsl b on a.USUBJID = b.USUBJID
                where b.ITTFL = 'Y'
                  and not missing(a.CHG);
            quit;
            %let src_ready = 1;
        %end;
        %else %if (&adtr_has_aval > 0 and &adtr_has_paramcd > 0) %then %do;
            proc sql;
                create table waterfall_src as
                select a.USUBJID, b.ARMCD, b.ARM, a.AVAL as PCHG
                from adam.adtr a
                inner join adam.adsl b on a.USUBJID = b.USUBJID
                where b.ITTFL = 'Y'
                  and upcase(a.PARAMCD) in ('PCHG','TRCHG','SODPCHG','CHG')
                  and not missing(a.AVAL);
            quit;
            %let src_ready = 1;
        %end;
    %end;

    /* ---- Source 3: adam.adrs PCHG parameter ---- */
    %if &src_ready = 0 %then %do;
        %local has_adrs _pchg_cnt;
        %let has_adrs  = %sysfunc(exist(adam.adrs));
        %let _pchg_cnt = 0;
        %if &has_adrs %then %do;
            proc sql noprint;
                select count(*) into :_pchg_cnt trimmed
                from adam.adrs
                where upcase(PARAMCD) = 'PCHG'
                  and not missing(AVAL);
            quit;
            %if &_pchg_cnt > 0 %then %do;
                proc sql;
                    create table waterfall_src as
                    select a.USUBJID, b.ARMCD, b.ARM, a.AVAL as PCHG
                    from adam.adrs a
                    inner join adam.adsl b on a.USUBJID = b.USUBJID
                    where b.ITTFL = 'Y'
                      and upcase(a.PARAMCD) = 'PCHG'
                      and not missing(a.AVAL);
                quit;
                %let src_ready = 1;
            %end;
        %end;
    %end;

    /* ---- Source 4: WORK.adrs_pchg (same-session intermediate from adrs.sas) ---- */
    %if &src_ready = 0 %then %do;
        %local has_work_pchg _wpchg_cnt;
        %let has_work_pchg = %sysfunc(exist(work.adrs_pchg));
        %let _wpchg_cnt    = 0;
        %if &has_work_pchg %then %do;
            proc sql noprint;
                select count(*) into :_wpchg_cnt trimmed
                from work.adrs_pchg
                where not missing(AVAL);
            quit;
            %if &_wpchg_cnt > 0 %then %do;
                proc sql;
                    create table waterfall_src as
                    select a.USUBJID, b.ARMCD, b.ARM, a.AVAL as PCHG
                    from work.adrs_pchg a
                    inner join adam.adsl b on a.USUBJID = b.USUBJID
                    where b.ITTFL = 'Y'
                      and not missing(a.AVAL);
                quit;
                %let src_ready = 1;
            %end;
        %end;
    %end;

    /* ---- No source found: emit empty placeholder ---- */
    %if &src_ready = 0 %then %do;
        data waterfall_src;
            length USUBJID $40 ARMCD $20 ARM $200 PCHG 8;
            stop;
        run;
        %put WARNING: No percent-change source found (ADTR/ADRS/WORK.adrs_pchg). Waterfall figure will not be generated.;
    %end;

%mend resolve_waterfall_source;
%resolve_waterfall_source;

/* ============================================================================
   1. Prepare plotting data — rank by response, label by last 3 digits of USUBJID
   ============================================================================ */
data waterfall_data;
    set waterfall_src;
    if missing(PCHG) then delete;
    length SUBJID_LBL $20;
    SUBJID_LBL = scan(USUBJID, -1, '-');
run;

proc sort data=waterfall_data;
    by PCHG USUBJID;
run;

proc sql noprint;
    select count(*) into :N_WF trimmed
    from waterfall_data;
quit;

/* ============================================================================
   2. Render waterfall plot or emit a clean diagnostic message
   ============================================================================ */
%macro render_waterfall;
    %if %sysevalf(&N_WF > 0) %then %do;
        %ods_setup(type=GRAPH, imgname=f_waterfall, imgw=9in, imgh=5.5in);
        title1 "&STUDYID: CAR-T Efficacy Visualization";
        title2 "Figure 14.2.1: Waterfall Plot of Best Tumor Response";
        title3 "Intent-To-Treat (ITT) Population";

        footnote1 "Bars represent best percent change from baseline in target lesion burden.";
        footnote2 "Threshold lines show RECIST-like reference values (-30% and +20%).";

        proc sgplot data=waterfall_data;
            vbar SUBJID_LBL / response=PCHG group=ARMCD categoryorder=respasc;
            refline -30 / axis=y lineattrs=(thickness=1 color=gray pattern=dash) label="-30%";
            refline 20  / axis=y lineattrs=(thickness=1 color=gray pattern=dash) label="+20%";
            xaxis label="Subject ID (Ranked by Response)";
            yaxis label="Best % Change from Baseline";
            keylegend / title="Dose Level";
        run;
        %ods_close(type=GRAPH);
    %end;
    %else %do;
        data waterfall_missing;
            length Message $240;
            Message = "Waterfall figure not generated: no percent-change source dataset was available.";
        run;
        proc print data=waterfall_missing noobs;
            title1 "Figure 14.2.1: Waterfall Plot of Best Tumor Response";
        run;
    %end;
%mend render_waterfall;
%render_waterfall;
