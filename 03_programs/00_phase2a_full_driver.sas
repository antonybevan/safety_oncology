/******************************************************************************
 * Program:      00_phase2a_full_driver.sas
 * Protocol:     BV-CAR20-P1 (Portfolio Extension)
 * Purpose:      Master Portfolio Orchestrator (Phase 1 + 2a Full)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-08
 ******************************************************************************/

/* 1. Integrated Environment */
%include "00_config.sas";

%put %str( );
%put NOTE: ****************************************************************;
%put NOTE: * PORTFOLIO MASTER: STARTING FULL PHASE 1/2A PIPELINE         *;
%put NOTE: ****************************************************************;

/* 2. Execute Base Phase 1 (SAP-Compliant Infrastructure) */
%include "00_main.sas";

/* 3. Execute Phase 2a Expansion Modules */
%put NOTE: [PORTFOLIO] Initiating Phase 2a Expansion Data...;
%include "&PROG_PATH/data_gen/generate_phase2a_full.sas";

%put NOTE: [PORTFOLIO] Generating Primary Efficacy Tables (By Arm)...;
%include "&PROG_PATH/reporting/t_eff_by_arm.sas";

%put NOTE: [PORTFOLIO] Generating Biomarker Exploratory Data...;
%include "&PROG_PATH/reporting/f_cart_kinetics.sas";
%include "&PROG_PATH/reporting/f_cytokines.sas";

/* 4. Multi-Phase Summary */
title "&STUDYID: Portfolio-Wide Implementation Summary";
proc sql;
    select 'Phase 1 Core subjects' as Group, count(distinct USUBJID) as N 
    from adam.adsl
    union all
    select 'Phase 2a Expansion subjects', count(distinct USUBJID)
    from sdtm.dm_phase2a_full;
quit;

%put NOTE: ****************************************************************;
%put NOTE: * PORTFOLIO MASTER: EXECUTION SUCCESSFUL                      *;
%put NOTE: ****************************************************************;
