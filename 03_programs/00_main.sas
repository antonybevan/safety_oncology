/******************************************************************************
 * Program:      00_main.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Master Driver for the Clinical Data Pipeline
 ******************************************************************************/

/* 1. Detect Path for SAS Studio / Cloud Environment */
%macro include_all;
    %local path;
    %if %symexist(_SASPROGRAMFILE) %then %do;
        %let path = %sysfunc(prxchange(s/(.*)[\/\\].*$/$1/, 1, &_SASPROGRAMFILE));
    %end;
    %else %let path = .;

    /* Configuration and Library Setup */
    %include "&path/00_config.sas";

    /* Ensure Output Folders Exist */
    options noxwait;
    x "mkdir ""&OUT_TABLES"" 2>nul";
    x "mkdir ""&OUT_LISTINGS"" 2>nul";
    x "mkdir ""&OUT_FIGURES"" 2>nul";
    x "mkdir ""&OUT_META"" 2>nul";

    /* 2. Execute Data Generation */
    %include "&path/data_gen/generate_data.sas";

    /* 3. Execute SDTM Tabulations */
    %include "&path/tabulations/dm.sas";
    %include "&path/tabulations/ex.sas";
    %include "&path/tabulations/ae.sas";
    %include "&path/tabulations/rs.sas";
    %include "&path/tabulations/lb.sas";
    %include "&path/tabulations/suppae.sas";

    /* 4. Execute ADaM Analysis Datasets */
    %include "&path/analysis/adsl.sas";
    %include "&path/analysis/adae.sas";
    %include "&path/analysis/adrs.sas";
    %include "&path/analysis/adex.sas";
    %include "&path/analysis/adlb.sas";
    %include "&path/analysis/gen_metadata.sas";

    /* 5. Execute Tables, Listings, and Figures (TLFs) */
    %include "&path/reporting/t_dm.sas";
    %include "&path/reporting/t_eff.sas";
    %include "&path/reporting/t_ae_summ.sas";
    %include "&path/reporting/t_ae_aesi.sas";
    %include "&path/reporting/t_lb_grad.sas";
    %include "&path/reporting/l_dm.sas";
    %include "&path/reporting/l_ae_aesi.sas";
    %include "&path/reporting/l_lb_grad.sas";
    %include "&path/reporting/f_waterfall.sas";
    %include "&path/reporting/f_ae_time.sas";

    /* 6. Final Integrity Cross-Check (Auditor View) */
    title "BV-CAR20-P1: End-to-End Pipeline Integrity Audit";
    proc sql;
       select 'SDTM.DM' as Table, count(*) as Records from sdtm.dm
       union all select 'SDTM.AE', count(*) from sdtm.ae
       union all select 'SDTM.SUPPAE (Grades)', count(*) from sdtm.suppae where QNAM='ASTCTGR'
       union all select 'ADAM.ADSL', count(*) from adam.adsl
       union all select 'ADAM.ADAE', count(*) from adam.adae
       union all select 'ADAM.ADAE (AESIs)', count(*) from adam.adae where AESIFL='Y'
       union all select 'ADAM.ADRS', count(*) from adam.adrs;
    quit;
%mend;
%include_all;

%put NOTE: --------------------------------------------------;
%put NOTE: ✅ FULL PIPELINE EXECUTION COMPLETE;
%put NOTE: --------------------------------------------------;
