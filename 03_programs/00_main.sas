/******************************************************************************
 * Program:      00_main.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Phase 1 (SAP-Compliant) Master Driver with Integrated Auditing
 * Author:       Statistical Programmer
 * Date:         2026-02-08
 ******************************************************************************/

/* 1. Environment Setup */
%macro _include_config;
    %local path;
    %if %symexist(_SASPROGRAMFILE) %then %do;
        %if %length(&_SASPROGRAMFILE) > 1 %then %do;
            /* Extract the folder path containing the current program file, supporting both Linux and Windows separators */
            %let path = %sysfunc(substr(&_SASPROGRAMFILE, 1, %sysfunc(findc(&_SASPROGRAMFILE, %str(/\), -200))));
            %if %sysfunc(fileexist(&path.00_config.sas)) %then %do;
                %include "&path.00_config.sas";
                %return;
            %end;
        %end;
    %end;
    /* Fallback: try relative or absolute defaults */
    %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
    %else %if %sysfunc(fileexist(03_programs/00_config.sas)) %then %include "03_programs/00_config.sas";
    %else %if %sysfunc(fileexist(/home/u63849890/safety_oncology/03_programs/00_config.sas)) %then %include "/home/u63849890/safety_oncology/03_programs/00_config.sas";
    %else %if %sysfunc(fileexist(d:/safety_oncology/03_programs/00_config.sas)) %then %include "d:/safety_oncology/03_programs/00_config.sas";
    %else %do;
        %put ERROR: [MAIN] Cannot locate 00_config.sas!;
        %abort cancel;
    %end;
%mend _include_config;
%_include_config;


%put NOTE: [MAIN] Starting Phase 1 Pipeline Execution...;

/* Pipeline Status and Error Trapping Macro */
%global PIPELINE_STATUS;
%let PIPELINE_STATUS = SUCCESS;

%macro check_err(prog);
    %if &syscc > 4 %then %do;
        %put ERROR: [PIPELINE] Execution of &prog. failed with SYSCC=&syscc.;
        %let PIPELINE_STATUS = FAILED;
        %let syscc = 0;
    %end;
    %else %do;
        %put NOTE: [PIPELINE] &prog. executed successfully (SYSCC=&syscc.).;
        %let syscc = 0;
    %end;
%mend check_err;

/* 2. Data Preparation Suite */
%put NOTE: [MAIN] Step 1: Simulating Raw Clinical Data...;
%include "&PROG_PATH/data_gen/generate_data.sas";
%check_err(generate_data.sas);

%put NOTE: [MAIN] Step 2: Mapping SDTM Domains...;
%include "&PROG_PATH/tabulations/gen_trial_design.sas";
%check_err(gen_trial_design.sas);

%include "&PROG_PATH/tabulations/dm.sas";
%check_err(dm.sas);

%include "&PROG_PATH/tabulations/ex.sas";
%check_err(ex.sas);

%include "&PROG_PATH/tabulations/ae.sas";
%check_err(ae.sas);

%include "&PROG_PATH/tabulations/suppae.sas";
%check_err(suppae.sas);

%include "&PROG_PATH/tabulations/lb.sas";
%check_err(lb.sas);

%include "&PROG_PATH/tabulations/rs.sas";
%check_err(rs.sas);

%include "&PROG_PATH/tabulations/cp.sas";
%check_err(cp.sas);

%include "&PROG_PATH/tabulations/gf.sas";
%check_err(gf.sas);

/* 3. ADaM Analysis Suite */
%put NOTE: [MAIN] Step 3: Deriving ADaM Analysis Datasets...;
%include "&PROG_PATH/analysis/adsl.sas";
%check_err(adsl.sas);

%include "&PROG_PATH/analysis/adae.sas";
%check_err(adae.sas);

%include "&PROG_PATH/analysis/adlb.sas";
%check_err(adlb.sas);

%include "&PROG_PATH/analysis/adex.sas";
%check_err(adex.sas);

%include "&PROG_PATH/analysis/adrs.sas";
%check_err(adrs.sas);

%include "&PROG_PATH/analysis/gen_metadata.sas";
%check_err(gen_metadata.sas);

/* 4. Reporting & Figures Suite */
%put NOTE: [MAIN] Step 4: Generating Clinical Tables & Figures (TFLs)...;

/* Category 1: Demographics and Baseline Characteristics */
%include "&PROG_PATH/reporting/t_dm.sas";
%check_err(t_dm.sas);

%include "&PROG_PATH/reporting/t_prot_dev.sas";
%check_err(t_prot_dev.sas);

/* Category 2: Efficacy and Exploratory Endpoints */
%include "&PROG_PATH/reporting/t_eff.sas";
%check_err(t_eff.sas);

%include "&PROG_PATH/reporting/t_dor_by_arm.sas";
%check_err(t_dor_by_arm.sas);

%include "&PROG_PATH/reporting/t_mrd.sas";
%check_err(t_mrd.sas);

/* Category 3: Adverse Events Tables */
%include "&PROG_PATH/reporting/t_ae_summ.sas";
%check_err(t_ae_summ.sas);

%include "&PROG_PATH/reporting/t_ae_aesi.sas";
%check_err(t_ae_aesi.sas);

%include "&PROG_PATH/reporting/t_ae_cm.sas";
%check_err(t_ae_cm.sas);

%include "&PROG_PATH/reporting/t_aesi_duration.sas";
%check_err(t_aesi_duration.sas);

%include "&PROG_PATH/reporting/t_sae_cart.sas";
%check_err(t_sae_cart.sas);

%include "&PROG_PATH/reporting/t_sae_ld.sas";
%check_err(t_sae_ld.sas);

/* Category 4: Lab Toxicity Tables */
%include "&PROG_PATH/reporting/t_lb_grad.sas";
%check_err(t_lb_grad.sas);

/* Category 5: Patient Listings */
%include "&PROG_PATH/reporting/l_dm.sas";
%check_err(l_dm.sas);

%include "&PROG_PATH/reporting/l_screen_fail.sas";
%check_err(l_screen_fail.sas);

%include "&PROG_PATH/reporting/l_exposure.sas";
%check_err(l_exposure.sas);

%include "&PROG_PATH/reporting/l_ae_aesi.sas";
%check_err(l_ae_aesi.sas);

%include "&PROG_PATH/reporting/l_sae.sas";
%check_err(l_sae.sas);

%include "&PROG_PATH/reporting/l_deaths.sas";
%check_err(l_deaths.sas);

%include "&PROG_PATH/reporting/l_lb_grad.sas";
%check_err(l_lb_grad.sas);

/* Category 6: Figures */
%include "&PROG_PATH/reporting/f_ae_time.sas";
%check_err(f_ae_time.sas);

%include "&PROG_PATH/reporting/f_km_os.sas";
%check_err(f_km_os.sas);

%include "&PROG_PATH/reporting/f_km_pfs.sas";
%check_err(f_km_pfs.sas);

%include "&PROG_PATH/reporting/f_swimmer.sas";
%check_err(f_swimmer.sas);

%include "&PROG_PATH/reporting/f_waterfall.sas";
%check_err(f_waterfall.sas);

/* 5. Integrity Audit (Professional Grade) */
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

%put NOTE: ----------------------------------------------------;
%macro _pipeline_status_check;
    %if &PIPELINE_STATUS = SUCCESS %then %do;
        %put NOTE: ✅ [MAIN] Phase 1 Pipeline Execution Complete successfully!;
    %end;
    %else %do;
        %put ERROR: ❌ [MAIN] Phase 1 Pipeline Execution Complete with errors!;
    %end;
%mend _pipeline_status_check;
%_pipeline_status_check;
%put NOTE: ----------------------------------------------------;
