/******************************************************************************
 * Program:      GIT_RECOVERY.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Download Latest Repository from GitHub
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 * SAS Version:  9.4+ / SAS OnDemand (Linux)
 *
 * Description:  Downloads the entire repository as a ZIP file.
 *               Works in SAS OnDemand without PROC GIT.
 ******************************************************************************/

/*=============================================================================
  CONFIGURATION - Edit these values for your setup
=============================================================================*/
%let github_user = antonybevan;
%let repo_name   = safety_oncology;
%let branch      = main;
%let home        = /home/u63849890;

/*=============================================================================
  DERIVED PATHS - Do not edit
=============================================================================*/
%let zip_url  = https://github.com/&github_user/&repo_name/archive/refs/heads/&branch..zip;
%let zip_file = &home/&repo_name..zip;

/*=============================================================================
  DOWNLOAD REPOSITORY AS ZIP
=============================================================================*/
%put NOTE: ======================================================================;
%put NOTE: DOWNLOADING REPOSITORY;
%put NOTE: Source: &zip_url;
%put NOTE: Target: &zip_file;
%put NOTE: ======================================================================;

filename src URL "&zip_url" recfm=s;
filename dst "&zip_file" recfm=n;

data _null_;
    rc = fcopy('src', 'dst');
    if rc = 0 then do;
        put "NOTE: ";
        put "NOTE: ======================================================================";
        put "NOTE: SUCCESS! Downloaded: &zip_file";
        put "NOTE: ======================================================================";
        put "NOTE: ";
        put "NOTE: NEXT STEPS:";
        put "NOTE:   1. In the Files pane (left side), find &repo_name..zip";
        put "NOTE:   2. Right-click the ZIP file";
        put "NOTE:   3. Select 'Extract All'";
        put "NOTE:   4. Open the extracted folder: &repo_name.-&branch";
        put "NOTE:   5. Run 03_programs/00_config.sas";
        put "NOTE: ";
        put "NOTE: ======================================================================";
    end;
    else do;
        put "ERROR: Download failed (RC=" rc ").";
        put "ERROR: Check your network connection.";
    end;
run;

filename src clear;
filename dst clear;

%put NOTE: RECOVERY COMPLETE;
