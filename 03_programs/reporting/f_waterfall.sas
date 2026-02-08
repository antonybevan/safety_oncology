/******************************************************************************
 * Program:      f_waterfall.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Figure 14.2.1 - Waterfall Plot of Best Tumor Response
 * Author:       Clinical Programming Lead
 * Date:         2026-02-08
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

/* ============================================================================
   WATERFALL PLOT SOURCE RESOLUTION
   Preferred source: ADTR with percent change variable.
   Fallback source: ADRS only if a percent-change analysis parameter exists.
   No simulated values are generated.
   ============================================================================ */

%let has_adtr = %sysfunc(exist(adam.adtr));
%let has_adrs = %sysfunc(exist(adam.adrs));
%let has_adrs_expanded = %sysfunc(exist(adam.adrs_expanded));
%let has_adsl_expanded = %sysfunc(exist(adam.adsl_expanded));
%let src_ready = 0;
%let adsl_src = adam.adsl;
%let adrs_src = adam.adrs;

%if &has_adsl_expanded %then %let adsl_src = adam.adsl_expanded;
%if &has_adrs_expanded %then %let adrs_src = adam.adrs_expanded;

%macro resolve_waterfall_source;
    %if &has_adtr %then %do;
        %let adtr_has_chg = 0;
        %let adtr_has_aval = 0;
        %let adtr_has_paramcd = 0;

        proc sql noprint;
            select count(*) into :adtr_has_chg trimmed
            from dictionary.columns
            where libname='ADAM' and memname='ADTR' and upcase(name)='CHG';

            select count(*) into :adtr_has_aval trimmed
            from dictionary.columns
            where libname='ADAM' and memname='ADTR' and upcase(name)='AVAL';

            select count(*) into :adtr_has_paramcd trimmed
            from dictionary.columns
            where libname='ADAM' and memname='ADTR' and upcase(name)='PARAMCD';
        quit;

        %if &adtr_has_chg > 0 %then %do;
            proc sql;
                create table waterfall_src as
                select a.USUBJID,
                       b.ARMCD,
                       b.ARM,
                       a.CHG as PCHG
                from adam.adtr a
                inner join &adsl_src b
                    on a.USUBJID = b.USUBJID
                where b.ITTFL = 'Y'
                  and not missing(a.CHG);
            quit;
            %let src_ready = 1;
        %end;
        %else %if (&adtr_has_aval > 0 and &adtr_has_paramcd > 0) %then %do;
            proc sql;
                create table waterfall_src as
                select a.USUBJID,
                       b.ARMCD,
                       b.ARM,
                       a.AVAL as PCHG
                from adam.adtr a
                inner join &adsl_src b
                    on a.USUBJID = b.USUBJID
                where b.ITTFL = 'Y'
                  and upcase(a.PARAMCD) in ('PCHG', 'TRCHG', 'SODPCHG', 'CHG')
                  and not missing(a.AVAL);
            quit;
            %let src_ready = 1;
        %end;
    %end;

    %if &src_ready = 0 and (&has_adrs or &has_adrs_expanded) %then %do;
        %let adrs_has_aval = 0;
        %let adrs_has_paramcd = 0;

        proc sql noprint;
            select count(*) into :adrs_has_aval trimmed
            from dictionary.columns
            where libname='ADAM'
              and memname=%upcase("%scan(&adrs_src,2,.)")
              and upcase(name)='AVAL';

            select count(*) into :adrs_has_paramcd trimmed
            from dictionary.columns
            where libname='ADAM'
              and memname=%upcase("%scan(&adrs_src,2,.)")
              and upcase(name)='PARAMCD';
        quit;

        %if (&adrs_has_aval > 0 and &adrs_has_paramcd > 0) %then %do;
            proc sql;
                create table waterfall_src as
                select a.USUBJID,
                       b.ARMCD,
                       b.ARM,
                       a.AVAL as PCHG
                from &adrs_src a
                inner join &adsl_src b
                    on a.USUBJID = b.USUBJID
                where b.ITTFL = 'Y'
                  and upcase(a.PARAMCD) in ('PCHG', 'TRCHG', 'SODPCHG', 'CHG')
                  and not missing(a.AVAL);
            quit;
            %let src_ready = 1;
        %end;
    %end;

    %if &src_ready = 0 %then %do;
        data waterfall_src;
            length USUBJID $40 ARMCD $20 ARM $200 PCHG 8;
            stop;
        run;
        %put WARNING: No non-simulated percent-change source found (ADTR/ADRS). Waterfall figure will not be generated.;
    %end;
%mend;
%resolve_waterfall_source;

/* 1. Prepare plotting data */
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

/* 2. Generate plot when source exists */
%macro render_waterfall;
    %if %sysevalf(&N_WF > 0) %then %do;
        ods graphics / reset width=900px height=550px imagename="f_waterfall";
        title1 "&STUDYID: CAR-T Efficacy Visualization";
        title2 "Figure 14.2.1: Waterfall Plot of Best Tumor Response";
        title3 "Intent-To-Treat (ITT) Population";

        footnote1 "Bars represent best percent change from baseline in target lesion burden.";
        footnote2 "Threshold lines show RECIST-like reference values (-30% and +20%).";

        proc sgplot data=waterfall_data;
            vbar SUBJID_LBL / response=PCHG group=ARMCD categoryorder=respasc;
            refline -30 / axis=y lineattrs=(thickness=1 color=gray pattern=dash) label="-30%";
            refline 20 / axis=y lineattrs=(thickness=1 color=gray pattern=dash) label="+20%";
            xaxis label="Subject ID (Ranked by Response)";
            yaxis label="Best % Change from Baseline";
            keylegend / title="Dose Level";
        run;

        ods html body="&OUT_FIGURES/f_waterfall.html";
        proc print data=waterfall_data(obs=10);
        run;
        ods html close;
    %end;
    %else %do;
        data waterfall_missing;
            length Message $240;
            Message = "Waterfall figure not generated: no source dataset with non-simulated percent-change values was available.";
        run;

        proc print data=waterfall_missing noobs;
            title1 "Figure 14.2.1: Waterfall Plot of Best Tumor Response";
        run;
    %end;
%mend;
%render_waterfall;


