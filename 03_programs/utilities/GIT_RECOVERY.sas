/******************************************************************************
 * Program:      GIT_RECOVERY.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Full Environment Reset for SAS OnDemand (No PROC GIT Required)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 * SAS Version:  9.4+ / SAS OnDemand compatible
 *
 * Description:  Performs a clean re-download of all repository files.
 *               Uses filename URL to bypass the PROC GIT limitation.
 ******************************************************************************/

OPTIONS NONOTES NOSTIMER NOSOURCE NOSYNTAXCHECK;

/*=============================================================================
  USER CONFIGURATION
=============================================================================*/
%let github_user = antonybevan;
%let repo_name   = safety_oncology;
%let branch      = main;
%let home_dir    = /home/u63849890;
%let target_dir  = &home_dir/safety_oncology;

%let raw_base = https://raw.githubusercontent.com/&github_user/&repo_name/&branch;

/*=============================================================================
  MACRO: CREATE_DIR
=============================================================================*/
%macro create_dir(path);
    options dlcreatedir;
    libname _tmp_ "&path";
    libname _tmp_ clear;
%mend;

/*=============================================================================
  MACRO: DOWNLOAD_FILE
=============================================================================*/
%macro download_file(remote_path, local_path);
    filename src URL "&raw_base/&remote_path";
    filename dest "&local_path";
    
    data _null_;
        length line $32767;
        infile src lrecl=32767 truncover end=eof;
        file dest lrecl=32767;
        input line $char32767.;
        put line $char32767.;
    run;
    
    %if &syserr = 0 %then %put NOTE: Synced: &remote_path;
    %else %put WARNING: Failed: &remote_path;
    
    filename src clear;
    filename dest clear;
%mend;

/*=============================================================================
  MACRO: DELETE_FILE
=============================================================================*/
%macro delete_file(filepath);
    data _null_;
        rc = filename("del", "&filepath");
        rc = fdelete("del");
        rc = filename("del");
    run;
%mend;

/*=============================================================================
  MAIN EXECUTION: FULL REPOSITORY SYNC
=============================================================================*/
%put NOTE: ======================================================================;
%put NOTE: FULL ENVIRONMENT RECOVERY - GITHUB DIRECT SYNC;
%put NOTE: Repository: &github_user/&repo_name;
%put NOTE: Target: &target_dir;
%put NOTE: ======================================================================;
%put NOTE: This will overwrite all local files with the latest from GitHub.;
%put NOTE: ======================================================================;

/* Create full directory structure */
%create_dir(&target_dir);
%create_dir(&target_dir/01_documentation);
%create_dir(&target_dir/02_datasets);
%create_dir(&target_dir/02_datasets/legacy);
%create_dir(&target_dir/02_datasets/tabulations);
%create_dir(&target_dir/02_datasets/analysis);
%create_dir(&target_dir/03_programs);
%create_dir(&target_dir/03_programs/tabulations);
%create_dir(&target_dir/03_programs/analysis);
%create_dir(&target_dir/03_programs/reporting);
%create_dir(&target_dir/03_programs/utilities);
%create_dir(&target_dir/03_programs/macros);
%create_dir(&target_dir/04_outputs);
%create_dir(&target_dir/04_outputs/tables);
%create_dir(&target_dir/04_outputs/figures);
%create_dir(&target_dir/04_outputs/listings);

/* Download Core Config */
%download_file(03_programs/00_config.sas, &target_dir/03_programs/00_config.sas);
%download_file(03_programs/00_main.sas, &target_dir/03_programs/00_main.sas);
%download_file(03_programs/00_phase2a_full_driver.sas, &target_dir/03_programs/00_phase2a_full_driver.sas);

/* Download SDTM Programs */
%download_file(03_programs/tabulations/dm.sas, &target_dir/03_programs/tabulations/dm.sas);
%download_file(03_programs/tabulations/ae.sas, &target_dir/03_programs/tabulations/ae.sas);
%download_file(03_programs/tabulations/suppae.sas, &target_dir/03_programs/tabulations/suppae.sas);
%download_file(03_programs/tabulations/ex.sas, &target_dir/03_programs/tabulations/ex.sas);
%download_file(03_programs/tabulations/lb.sas, &target_dir/03_programs/tabulations/lb.sas);
%download_file(03_programs/tabulations/rs.sas, &target_dir/03_programs/tabulations/rs.sas);
%download_file(03_programs/tabulations/ts.sas, &target_dir/03_programs/tabulations/ts.sas);
%download_file(03_programs/tabulations/ta.sas, &target_dir/03_programs/tabulations/ta.sas);
%download_file(03_programs/tabulations/te.sas, &target_dir/03_programs/tabulations/te.sas);
%download_file(03_programs/tabulations/su.sas, &target_dir/03_programs/tabulations/su.sas);
%download_file(03_programs/tabulations/cp.sas, &target_dir/03_programs/tabulations/cp.sas);
%download_file(03_programs/tabulations/is.sas, &target_dir/03_programs/tabulations/is.sas);

/* Download ADaM Programs */
%download_file(03_programs/analysis/adsl.sas, &target_dir/03_programs/analysis/adsl.sas);
%download_file(03_programs/analysis/adae.sas, &target_dir/03_programs/analysis/adae.sas);
%download_file(03_programs/analysis/adlb.sas, &target_dir/03_programs/analysis/adlb.sas);
%download_file(03_programs/analysis/adrs.sas, &target_dir/03_programs/analysis/adrs.sas);
%download_file(03_programs/analysis/adex.sas, &target_dir/03_programs/analysis/adex.sas);
%download_file(03_programs/analysis/adtte.sas, &target_dir/03_programs/analysis/adtte.sas);
%download_file(03_programs/analysis/gen_metadata.sas, &target_dir/03_programs/analysis/gen_metadata.sas);

/* Download Reporting Programs */
%download_file(03_programs/reporting/t_dm.sas, &target_dir/03_programs/reporting/t_dm.sas);
%download_file(03_programs/reporting/t_eff.sas, &target_dir/03_programs/reporting/t_eff.sas);
%download_file(03_programs/reporting/t_ae_summ.sas, &target_dir/03_programs/reporting/t_ae_summ.sas);
%download_file(03_programs/reporting/t_ae_aesi.sas, &target_dir/03_programs/reporting/t_ae_aesi.sas);
%download_file(03_programs/reporting/t_lb_grad.sas, &target_dir/03_programs/reporting/t_lb_grad.sas);

/* Download Utilities */
%download_file(03_programs/utilities/generate_synthetic_data.sas, &target_dir/03_programs/utilities/generate_synthetic_data.sas);
%download_file(03_programs/utilities/GIT_PULL.sas, &target_dir/03_programs/utilities/GIT_PULL.sas);
%download_file(03_programs/utilities/GIT_PUSH.sas, &target_dir/03_programs/utilities/GIT_PUSH.sas);

%put NOTE: ======================================================================;
%put NOTE: RECOVERY COMPLETE - All files synced to: &target_dir;
%put NOTE: ======================================================================;
%put NOTE: Next Step: Run 00_config.sas to initialize the environment.;
%put NOTE: ======================================================================;

OPTIONS NOTES STIMER SOURCE SYNTAXCHECK;
