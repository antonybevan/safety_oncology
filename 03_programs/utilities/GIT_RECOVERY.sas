/******************************************************************************
 * Program:      GIT_RECOVERY.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Full Environment Reset from GitHub (SAS OnDemand Compatible)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 * SAS Version:  9.4+ / SAS OnDemand (Linux)
 *
 * Description:  Downloads the entire repository as a ZIP file from GitHub.
 *               Use this when you need to reset your local environment.
 ******************************************************************************/

/*=============================================================================
  CONFIGURATION
=============================================================================*/
%let github_user = antonybevan;
%let repo_name   = safety_oncology;
%let branch      = main;

%let zip_url = https://github.com/&github_user/&repo_name/archive/refs/heads/&branch..zip;
%let home = /home/u63849890;
%let zip_file = &home/&repo_name..zip;

/*=============================================================================
  DOWNLOAD THE REPOSITORY
=============================================================================*/
%put NOTE: ======================================================================;
%put NOTE: FULL ENVIRONMENT RECOVERY;
%put NOTE: Repository: &github_user/&repo_name;
%put NOTE: ======================================================================;

filename repo URL "&zip_url" recfm=s;
filename local "&zip_file" recfm=n;

data _null_;
    rc = fcopy('repo', 'local');
    if rc = 0 then do;
        put "NOTE: ======================================================================";
        put "NOTE: SUCCESS! Repository downloaded to: &zip_file";
        put "NOTE: ======================================================================";
        put "NOTE: ";
        put "NOTE: NEXT STEPS:";
        put "NOTE:   1. Delete or rename any existing '&repo_name-main' folder";
        put "NOTE:   2. Right-click &repo_name..zip -> Extract All";
        put "NOTE:   3. Rename extracted folder from '&repo_name-main' to '&repo_name'";
        put "NOTE:   4. Open 03_programs/00_config.sas and run it";
        put "NOTE: ";
        put "NOTE: ======================================================================";
    end;
    else do;
        put "ERROR: Download failed (RC=" rc "). Check network connection.";
    end;
run;

filename repo clear;
filename local clear;
