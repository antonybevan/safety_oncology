/******************************************************************************
 * Program:      GIT_PUSH.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      GitHub Push via API for SAS OnDemand
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 * SAS Version:  9.4+ / SAS OnDemand compatible
 *
 * LIMITATION:   Direct push from SAS ODA is not possible without PROC GIT.
 *               This program provides the closest workaround via GitHub API.
 *
 * WORKAROUND:   Uses PROC HTTP to update files via the GitHub Contents API.
 *               Requires a GitHub Personal Access Token (PAT) with 'repo' scope.
 ******************************************************************************/

/*=============================================================================
  USER CONFIGURATION - EDIT THIS SECTION
=============================================================================*/

/* 1. YOUR GITHUB PAT (Required - Keep this SECRET!) */
/* Generate at: https://github.com/settings/tokens */
/* Required scope: 'repo' (Full control of private repositories) */
%let my_pat = ;  /* <-- PASTE YOUR TOKEN HERE */

/* 2. REPOSITORY DETAILS */
%let github_user = antonybevan;
%let repo_name   = safety_oncology;
%let branch      = main;

/* 3. LOCAL PATH */
%let home_dir    = /home/u63849890;
%let local_path  = &home_dir/safety_oncology;

/* 4. COMMIT MESSAGE */
%let commit_msg = Pipeline update from SAS OnDemand;

/*=============================================================================
  MACRO: PUSH_FILE
  Pushes a single file to GitHub using the Contents API
=============================================================================*/
%macro push_file(local_file, remote_path);
    %if %length(&my_pat) = 0 %then %do;
        %put ERROR: GitHub PAT not configured. Edit this file and set my_pat.;
        %return;
    %end;
    
    /* Read file content and encode to Base64 */
    filename infile "&local_file";
    filename b64out temp;
    
    /* Step 1: Read file content */
    data _null_;
        length line $32767 content $1000000;
        retain content '';
        infile infile lrecl=32767 end=eof;
        input line $char32767.;
        content = catx('0A'x, content, line);
        if eof then call symputx('file_content', content);
    run;
    
    /* Step 2: Get current file SHA (required for updates) */
    filename resp temp;
    proc http 
        url="https://api.github.com/repos/&github_user/&repo_name/contents/&remote_path"
        method="GET"
        out=resp;
        headers 
            "Authorization"="Bearer &my_pat"
            "Accept"="application/vnd.github.v3+json"
            "User-Agent"="SAS-OnDemand";
    run;
    
    /* Parse SHA from response */
    data _null_;
        infile resp lrecl=32767;
        input line $char32767.;
        if index(line, '"sha"') > 0 then do;
            sha_start = index(line, '"sha":"') + 7;
            sha_end = index(substr(line, sha_start), '"') - 1;
            sha = substr(line, sha_start, sha_end);
            call symputx('file_sha', sha);
        end;
    run;
    
    /* Step 3: Push updated content */
    filename req temp;
    data _null_;
        file req;
        put '{"message":"&commit_msg",';
        put '"content":"' "&file_content" '",';
        put '"sha":"' "&file_sha" '",';
        put '"branch":"&branch"}';
    run;
    
    proc http 
        url="https://api.github.com/repos/&github_user/&repo_name/contents/&remote_path"
        method="PUT"
        in=req
        out=resp;
        headers 
            "Authorization"="Bearer &my_pat"
            "Accept"="application/vnd.github.v3+json"
            "User-Agent"="SAS-OnDemand";
    run;
    
    %if &SYS_PROCHTTP_STATUS_CODE = 200 or &SYS_PROCHTTP_STATUS_CODE = 201 %then %do;
        %put NOTE: Pushed: &remote_path;
    %end;
    %else %do;
        %put WARNING: Failed to push &remote_path (HTTP &SYS_PROCHTTP_STATUS_CODE);
    %end;
    
    filename infile clear;
    filename resp clear;
    filename req clear;
%mend;

/*=============================================================================
  MAIN EXECUTION: PUSH MODIFIED FILES
=============================================================================*/
%put NOTE: ======================================================================;
%put NOTE: GITHUB PUSH VIA API - SAS ONDEMAND COMPATIBLE;
%put NOTE: Repository: &github_user/&repo_name;
%put NOTE: ======================================================================;

%if %length(&my_pat) = 0 %then %do;
    %put ERROR: ======================================================================;
    %put ERROR: GitHub Personal Access Token (PAT) not configured!;
    %put ERROR: ======================================================================;
    %put ERROR: 1. Go to: https://github.com/settings/tokens;
    %put ERROR: 2. Generate a new token with 'repo' scope.;
    %put ERROR: 3. Edit this file and paste your token in the my_pat variable.;
    %put ERROR: ======================================================================;
%end;
%else %do;
    /* Example: Push specific files */
    /* Uncomment and modify the lines below for files you want to push */
    /* %push_file(&local_path/03_programs/00_config.sas, 03_programs/00_config.sas); */
    /* %push_file(&local_path/03_programs/analysis/adsl.sas, 03_programs/analysis/adsl.sas); */
    
    %put NOTE: ======================================================================;
    %put NOTE: To push files, uncomment the push_file calls above.;
    %put NOTE: Example: push_file(local_file_path, remote_github_path);
    %put NOTE: ======================================================================;
%end;

OPTIONS NOTES STIMER SOURCE SYNTAXCHECK;
