/******************************************************************************
 * Program:      GIT_PULL.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Direct GitHub Pull for SAS OnDemand (No PROC GIT Required)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 * SAS Version:  9.4+ / SAS OnDemand compatible
 *
 * Description:  Uses filename URL to download files directly from GitHub.
 *               This bypasses the PROC GIT limitation in SAS ODA.
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

/* Base URL for raw GitHub content */
%let raw_base = https://raw.githubusercontent.com/&github_user/&repo_name/&branch;

/*=============================================================================
  MACRO: CREATE_DIR
  Creates a directory if it doesn't exist (ODA compatible)
=============================================================================*/
%macro create_dir(path);
    options dlcreatedir;
    libname _tmp_ "&path";
    libname _tmp_ clear;
%mend;

/*=============================================================================
  MACRO: DOWNLOAD_FILE
  Downloads a single file from GitHub raw content
=============================================================================*/
%macro download_file(remote_path, local_path);
    %local url;
    %let url = &raw_base/&remote_path;
    
    filename src URL "&url";
    filename dest "&local_path";
    
    data _null_;
        length line $32767;
        infile src lrecl=32767 truncover;
        file dest lrecl=32767;
        input line $char32767.;
        put line $char32767.;
    run;
    
    %if &syserr = 0 %then %do;
        %put NOTE: Downloaded: &remote_path;
    %end;
    %else %do;
        %put WARNING: Failed to download: &remote_path;
    %end;
    
    filename src clear;
    filename dest clear;
%mend;

/*=============================================================================
  MAIN EXECUTION: PULL CORE FILES
=============================================================================*/
%put NOTE: ======================================================================;
%put NOTE: GITHUB DIRECT PULL - SAS ONDEMAND COMPATIBLE;
%put NOTE: Repository: &github_user/&repo_name;
%put NOTE: Target: &target_dir;
%put NOTE: ======================================================================;

/* Create directory structure */
%create_dir(&target_dir);
%create_dir(&target_dir/03_programs);
%create_dir(&target_dir/03_programs/tabulations);
%create_dir(&target_dir/03_programs/analysis);
%create_dir(&target_dir/03_programs/reporting);
%create_dir(&target_dir/03_programs/utilities);
%create_dir(&target_dir/02_datasets);
%create_dir(&target_dir/02_datasets/legacy);
%create_dir(&target_dir/02_datasets/tabulations);
%create_dir(&target_dir/02_datasets/analysis);

/* Download Configuration */
%download_file(03_programs/00_config.sas, &target_dir/03_programs/00_config.sas);
%download_file(03_programs/00_main.sas, &target_dir/03_programs/00_main.sas);

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

/* Download ADaM Programs */
%download_file(03_programs/analysis/adsl.sas, &target_dir/03_programs/analysis/adsl.sas);
%download_file(03_programs/analysis/adae.sas, &target_dir/03_programs/analysis/adae.sas);
%download_file(03_programs/analysis/adlb.sas, &target_dir/03_programs/analysis/adlb.sas);
%download_file(03_programs/analysis/adrs.sas, &target_dir/03_programs/analysis/adrs.sas);
%download_file(03_programs/analysis/adex.sas, &target_dir/03_programs/analysis/adex.sas);
%download_file(03_programs/analysis/adtte.sas, &target_dir/03_programs/analysis/adtte.sas);

/* Download Data Generator */
%download_file(03_programs/utilities/generate_synthetic_data.sas, &target_dir/03_programs/utilities/generate_synthetic_data.sas);

%put NOTE: ======================================================================;
%put NOTE: PULL COMPLETE - Files synced to: &target_dir;
%put NOTE: ======================================================================;
%put NOTE: Next Step: Run 00_config.sas to initialize environment.;
%put NOTE: ======================================================================;

OPTIONS NOTES STIMER SOURCE SYNTAXCHECK;
