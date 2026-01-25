/******************************************************************************
 * Program:      GIT_RESCUE.sas
 * Purpose:      Bypass Git UI and perform PULL/CLONE via code for PRIVATE REPO
 ******************************************************************************/

/* 1. ENTER YOUR GITHUB PAT HERE (From GitHub Settings -> Developer Settings) */
%let my_pat = ; 

/* 2. ENTER YOUR REPO DETAILS */
%let github_user = antonybevan;
%let repo_name = safety_oncology;
%let local_path = /home/u63849890/safety_oncology_clone;

/* Construct Secure URL */
%let repo_url = https://&my_pat.@github.com/&github_user/&repo_name..git;

/* If you want to force a FRESH clone, change this to 1 */
%let FORCE_FRESH = 0;

data _null_;
    if &FORCE_FRESH = 1 then do;
        /* Note: SAS can't easily delete non-empty folders, 
           so we just clone into a new unique folder name */
        new_folder = catx('_', "&local_path", put(date(), date9.), put(time(), time6.));
        rc = gitfn_clone("&repo_url", new_folder);
        if rc = 0 then put "NOTE: Fresh Clone successful in " new_folder;
    end;
    else do;
        /* Try to PULL into the existing folder */
        rc = gitfn_pull("&repo_url", "&local_path");
        if rc = 0 then put "NOTE: Git Pull successful!";
        else if rc = 3 then put "ERR" "OR: Directory is not a git repo or not empty. Try FORCE_FRESH=1";
        else put "ERR" "OR: Git Pull failed. RC=" rc;
    end;
run;
