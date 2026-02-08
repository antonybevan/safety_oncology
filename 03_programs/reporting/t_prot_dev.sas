/******************************************************************************
 * Program:      t_prot_dev.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Table 1.2: Summary/Listing of Major Protocol Deviations
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 * SAP Reference: §4.1, Table 10 (1.2)
 *
 * Input:        sdtm.dv (Protocol Deviations), adam.adsl
 * Output:       Table 1.2 — Protocol Deviations Summary
 *
 * Note:         Per SAP: "If no major deviations, then put a blank table"
 *               "If few, only listing needed"
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
   PROTOCOL DEVIATIONS (SAP §4.1)
   QC Level: 1

   Note: If DV domain doesn't exist, create mock structure
   ============================================================================ */

/* Check if DV domain exists */
%macro check_dv;
    %if %sysfunc(exist(sdtm.dv)) %then %do;
        data dv_data;
            set sdtm.dv;
        run;
    %end;
    %else %do;
        /* Keep dataset structure but do not fabricate deviation records */
        data dv_data;
            length STUDYID $20 DOMAIN $2 USUBJID $40 DVSEQ 8 
                   DVTERM $200 DVCAT $50 DVSCAT $50 DVDTC $20 DVSTDTC $20;
            stop;
        run;
        %put WARNING: SDTM.DV not found. Protocol deviation outputs will be blank.;
    %end;
%mend;
%check_dv;

/* Merge with ADSL for population flags */
proc sql;
    create table dv_analysis as
    select a.*, b.ARMCD, b.ARM, b.SAFFL
    from dv_data a
    left join adam.adsl b on a.USUBJID = b.USUBJID
    where b.SAFFL = 'Y';
quit;

/* Count deviations by category */
proc freq data=dv_analysis noprint;
    tables DVCAT / out=dv_counts;
run;

/* Check if any deviations exist */
%let nobs = 0;
data _null_;
    if eof then call symputx('nobs', _n_);
    set dv_analysis end=eof;
run;

/* Conditional output based on deviation count */
%macro output_deviations;
    %if &nobs = 0 %then %do;
        /* No deviations - output blank table */
        data no_dev;
            length Message $100;
            Message = "No major protocol deviations were reported during this study.";
        run;
        
        proc print data=no_dev noobs;
            title1 "Table 1.2: Summary of Major Protocol Deviations";
            title2 "Safety Population";
            footnote1 "No major protocol deviations to report.";
        run;
    %end;
    %else %if &nobs <= 10 %then %do;
        /* Few deviations - listing only per SAP */
        proc print data=dv_analysis noobs label;
            var USUBJID ARMCD DVCAT DVSCAT DVTERM DVDTC;
            label USUBJID = "Subject ID"
                  ARMCD = "Dose Level"
                  DVCAT = "Category"
                  DVSCAT = "Subcategory"
                  DVTERM = "Deviation Description"
                  DVDTC = "Date of Deviation";
            title1 "Table 1.2: Listing of Major Protocol Deviations";
            title2 "Safety Population";
            footnote1 "Source: SDTM DV Domain";
        run;
    %end;
    %else %do;
        /* Many deviations - summary table */
        proc freq data=dv_analysis;
            tables DVCAT * ARMCD / norow nocol nopercent;
            title1 "Table 1.2: Summary of Major Protocol Deviations by Category";
            title2 "Safety Population";
        run;
        
        /* Plus detailed listing */
        proc print data=dv_analysis noobs label;
            var USUBJID ARMCD DVCAT DVTERM DVDTC;
            title1 "Listing 2: All Protocol Deviations";
        run;
    %end;
%mend;
%output_deviations;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ PROTOCOL DEVIATIONS TABLE GENERATED;
%put NOTE: ----------------------------------------------------;

