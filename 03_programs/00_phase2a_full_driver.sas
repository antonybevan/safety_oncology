/******************************************************************************
 * Program:      00_phase2a_full_driver.sas
 * Protocol:     BV-CAR20-P1 (Full Phase 2a per Original Protocol V5.0)
 * Purpose:      Master Driver for COMPLETE Phase 2a Implementation
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

%macro include_phase2a_full;
    %local path;

    %if %symexist(PROG_PATH) and %superq(PROG_PATH) ne %then %let path = &PROG_PATH;
    %else %let path = 03_programs;

    title "&STUDYID: FULL Phase 1/2a Implementation per Protocol V5.0";

    %put NOTE: ==================================================;
    %put NOTE: FULL PROTOCOL V5.0 IMPLEMENTATION;
    %put NOTE: (SAP descoped to Phase 1 only - this is full portfolio);
    %put NOTE: ==================================================;

    /* Phase 1 (SAP-compliant) */
    %put NOTE: --- Running Phase 1 (SAP-Compliant) ---;
    %include "&path/00_main.sas";

    /* Phase 2a full data generation */
    %put NOTE: --- Generating Full Phase 2a Data ---;
    %include "&path/data_gen/generate_phase2a_full.sas";

    /* Phase 2a primary efficacy by arm */
    %put NOTE: --- Phase 2a Primary Efficacy by Arm ---;
    %include "&path/reporting/t_eff_by_arm.sas";

    /* Phase 2a secondary efficacy */
    %put NOTE: --- Phase 2a Secondary Efficacy ---;
    %include "&path/reporting/t_dor_by_arm.sas";

    /* Exploratory biomarkers */
    %put NOTE: --- Exploratory Biomarkers ---;
    %include "&path/reporting/f_cart_kinetics.sas";
    %include "&path/reporting/f_cytokines.sas";
    %include "&path/reporting/t_mrd.sas";

    /* Interim analysis framework */
    %put NOTE: --- Interim Analysis Framework ---;
    %include "&path/analysis/interim_analysis.sas";

    proc sql;
        create table full_implementation_summary as
        select 'Phase 1 Subjects' as Category length=50,
               count(distinct USUBJID) as N
        from adam.adsl_expanded
        where PHASE = '1'
        union all
        select 'Phase 2a Subjects', count(distinct USUBJID)
        from adam.adsl_expanded
        where PHASE = '2a'
        union all
        select 'Phase 2a Arm A (CLL/SLL)', count(distinct case when COHORT='Arm A: CLL/SLL Ibrutinib' then USUBJID end)
        from sdtm.dm_phase2a_full
        union all
        select 'Phase 2a Arm B (DLBCL)', count(distinct case when COHORT='Arm B: DLBCL post-R-CHOP' then USUBJID end)
        from sdtm.dm_phase2a_full
        union all
        select 'Phase 2a Arm C (High-grade NHL)', count(distinct case when COHORT='Arm C: High-grade NHL post-CAR-T' then USUBJID end)
        from sdtm.dm_phase2a_full
        union all
        select 'TOTAL SUBJECTS', count(distinct USUBJID)
        from adam.adsl_expanded;
    quit;

    proc print data=full_implementation_summary noobs;
        title "Full Phase 1/2a Implementation Summary";
    run;

    %put NOTE: ==================================================;
    %put NOTE: FULL PHASE 1/2A IMPLEMENTATION COMPLETE;
    %put NOTE: ==================================================;
%mend;
%include_phase2a_full;

