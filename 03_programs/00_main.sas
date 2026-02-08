/******************************************************************************
 * Program:      00_main.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Phase 1 (SAP-Compliant) Master Driver
 * Author:       Clinical Programming Lead
 * Date:         2026-02-08
 ******************************************************************************/

/* 1. Environment Setup */
%include "00_config.sas";

%put NOTE: [MAIN] Starting Phase 1 Pipeline Execution...;

/* 2. Data Preparation Suite */
%put NOTE: [MAIN] Step 1: Generating Synthetic Raw Data...;
%include "&PROG_PATH/data_gen/generate_data.sas";

%put NOTE: [MAIN] Step 2: Mapping SDTM Domains...;
%include "&PROG_PATH/tabulations/gen_trial_design.sas";
%include "&PROG_PATH/tabulations/dm.sas";
%include "&PROG_PATH/tabulations/ex.sas";
%include "&PROG_PATH/tabulations/ae.sas";
%include "&PROG_PATH/tabulations/suppae.sas";
%include "&PROG_PATH/tabulations/lb.sas";
%include "&PROG_PATH/tabulations/rs.sas";

/* 3. ADaM Analysis Suite */
%put NOTE: [MAIN] Step 3: Deriving ADaM Analysis Datasets...;
%include "&PROG_PATH/analysis/adsl.sas";
%include "&PROG_PATH/analysis/adae.sas";
%include "&PROG_PATH/analysis/adlb.sas";
%include "&PROG_PATH/analysis/adex.sas";
%include "&PROG_PATH/analysis/adrs.sas";

/* 4. Integrity Audit (Professional Grade) */
%put NOTE: [MAIN] Running Pipeline Integrity Audit...;

proc sql;
    title "&STUDYID: Pipeline Integrity Audit Summary";
    create table integrity_summary as
    select 'SDTM.DM (Subjects)' as Metric, count(*) as Value from sdtm.dm
    union all select 'SDTM.AE (Events)', count(*) from sdtm.ae
    union all select 'SDTM.LB (Records)', count(*) from sdtm.lb
    union all select 'ADaM.ADSL (Subjects)', count(*) from adam.adsl
    union all select 'Safety Pop (SAFFL=Y)', count(*) from adam.adsl where SAFFL='Y'
    union all select 'Efficacy Pop (EFFFL=Y)', count(*) from adam.adsl where EFFFL='Y';
quit;

proc print data=integrity_summary noobs;
run;

%put NOTE: [MAIN] Phase 1 Pipeline Execution Complete.;
