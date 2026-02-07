/******************************************************************************
 * Program:      GIT_PULL.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Download Full Repository from GitHub (SAS OnDemand Compatible)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 * SAS Version:  9.4+ / SAS OnDemand (Linux)
 *
 * Description:  Downloads the entire repository as a ZIP file from GitHub.
 *               After running, right-click the ZIP in Files and "Extract All".
 ******************************************************************************/

/*=============================================================================
  CONFIGURATION
=============================================================================*/
%let github_user = antonybevan;
%let repo_name   = safety_oncology;
%let branch      = main;

/* GitHub ZIP download URL */
%let zip_url = https://github.com/&github_user/&repo_name/archive/refs/heads/&branch..zip;

/* Download location (your SAS OnDemand home) */
%let home = /home/u63849890;
%let zip_file = &home/&repo_name..zip;

/*=============================================================================
  DOWNLOAD THE REPOSITORY
=============================================================================*/
%put NOTE: ======================================================================;
%put NOTE: Downloading repository: &github_user/&repo_name;
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
        put "NOTE: NEXT STEP:";
        put "NOTE:   1. In the Files pane, find &repo_name..zip";
        put "NOTE:   2. Right-click -> Extract All";
        put "NOTE:   3. Open the extracted folder and run 00_config.sas";
        put "NOTE: ";
        put "NOTE: ======================================================================";
    end;
    else do;
        put "ERROR: Download failed. Check network connection.";
    end;
run;

filename repo clear;
filename local clear;
