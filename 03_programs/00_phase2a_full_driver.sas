/******************************************************************************
 * Program:      00_phase2a_full_driver.sas
 * Protocol:     PBCAR20A-01 (Full Phase 2a per Original Protocol V5.0)
 * Purpose:      Master Driver for COMPLETE Phase 2a Implementation
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 *
 * Note:         Full implementation of Phase 2a as ORIGINALLY planned in
 *               Protocol V5.0 (before SAP descoped to Phase 1 only).
 *               This demonstrates complete Phase 1/2a portfolio capability.
 ******************************************************************************/

%macro include_phase2a_full;
    %local path;
    %if %symexist(_SASPROGRAMFILE) %then %do;
        %let path = %sysfunc(prxchange(s/(.*)[\\/\\].*$/$1/, 1, &_SASPROGRAMFILE));
    %end;
    %else %let path = .;

    /* Configuration */
    %include "&path/00_config.sas";
    
    title "PBCAR20A-01: FULL Phase 1/2a Implementation per Protocol V5.0";
    
    %put NOTE: ==================================================;
    %put NOTE: FULL PROTOCOL V5.0 IMPLEMENTATION;
    %put NOTE: (SAP descoped to Phase 1 only - this is full portfolio);
    %put NOTE: ==================================================;
    
    /* =========================================================================
       SECTION 1: PHASE 1 (SAP-COMPLIANT)
       ========================================================================= */
    %put NOTE: --- Running Phase 1 (SAP-Compliant) ---;
    %include "&path/00_main.sas";
    
    /* =========================================================================
       SECTION 2: PHASE 2A FULL DATA GENERATION
       ========================================================================= */
    %put NOTE: --- Generating Full Phase 2a Data ---;
    %include "&path/data_gen/generate_phase2a_full.sas";
    
    /* =========================================================================
       SECTION 3: PHASE 2A PRIMARY EFFICACY BY ARM
       Per Protocol Section 2.1.2:
       - Arm A (CLL/SLL): CR Rate per iwCLL 2018
       - Arm B (DLBCL): CR Rate per Lugano 2016
       - Arm C (High-grade NHL): ORR per Lugano 2016
       ========================================================================= */
    %put NOTE: --- Phase 2a Primary Efficacy by Arm ---;
    %include "&path/reporting/t_eff_by_arm.sas";
    
    /* =========================================================================
       SECTION 4: PHASE 2A SECONDARY EFFICACY
       Per Protocol Section 2.2.2:
       - Duration of Response (DoR)
       - PFS/OS by arm
       ========================================================================= */
    %put NOTE: --- Phase 2a Secondary Efficacy ---;
    %include "&path/reporting/t_dor_by_arm.sas";
    /* Note: t_dor.sas and t_eff_subgroup.sas are optional extensions */
    
    /* =========================================================================
       SECTION 5: EXPLORATORY BIOMARKERS
       Per Protocol Section 2.3, 8.3:
       - CAR-T Cellular Kinetics (VCN, Persistence)
       - Cytokines (IL-6, IFN-g, CRP)
       - MRD Analysis
       ========================================================================= */
    %put NOTE: --- Exploratory Biomarkers ---;
    %include "&path/reporting/f_cart_kinetics.sas";
    %include "&path/reporting/f_cytokines.sas";
    %include "&path/reporting/t_mrd.sas";
    
    /* =========================================================================
       SECTION 6: INTERIM ANALYSIS FRAMEWORK
       ========================================================================= */
    %put NOTE: --- Interim Analysis Framework ---;
    %include "&path/analysis/interim_analysis.sas";
    
    /* =========================================================================
       SUMMARY
       ========================================================================= */
    proc sql;
        create table full_implementation_summary as
        select 'Phase 1 Subjects' as Category length=50, 
               count(distinct case when PHASE='1' then USUBJID end) as N from sdtm.dm_phase2a_full
        union all
        select 'Phase 2a Arm A (CLL/SLL)', count(distinct case when COHORT='Arm A: CLL/SLL Ibrutinib' then USUBJID end) from sdtm.dm_phase2a_full
        union all
        select 'Phase 2a Arm B (DLBCL)', count(distinct case when COHORT='Arm B: DLBCL post-R-CHOP' then USUBJID end) from sdtm.dm_phase2a_full
        union all
        select 'Phase 2a Arm C (High-grade NHL)', count(distinct case when COHORT='Arm C: High-grade NHL post-CAR-T' then USUBJID end) from sdtm.dm_phase2a_full
        union all
        select 'TOTAL SUBJECTS', count(distinct USUBJID) from sdtm.dm_phase2a_full;
    quit;
    
    proc print data=full_implementation_summary noobs;
        title "Full Phase 1/2a Implementation Summary";
    run;
    
    %put NOTE: ==================================================;
    %put NOTE: FULL PHASE 1/2A IMPLEMENTATION COMPLETE;
    %put NOTE: ==================================================;
    %put NOTE:;
    %put NOTE: Phase 1 (SAP-Compliant):;
    %put NOTE:   - All TFLs per SAP Section 11;
    %put NOTE:   - DLT/MTD Analysis;
    %put NOTE:   - ORR, PFS, OS;
    %put NOTE:;
    %put NOTE: Phase 2a (Original Protocol V5.0):;
    %put NOTE:   - Arm A: CLL/SLL on Ibrutinib (del17p/TP53);
    %put NOTE:   - Arm B: DLBCL post-R-CHOP;
    %put NOTE:   - Arm C: High-grade NHL post-CAR-T;
    %put NOTE:   - Primary: CR Rate (A/B), ORR (C);
    %put NOTE:   - Secondary: DoR, PFS by Arm;
    %put NOTE:   - Exploratory: CAR-T Kinetics, Cytokines, MRD;
    %put NOTE: ==================================================;
    
%mend;
%include_phase2a_full;
