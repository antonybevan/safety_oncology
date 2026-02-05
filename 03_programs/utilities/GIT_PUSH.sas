/******************************************************************************
 * Program:      GIT_PUSH.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Git Rescue and Push for SAS OnDemand for Academics
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4+ / SAS OnDemand compatible
 *
 * Description:  This program provides a complete Git workflow for SAS ODA:
 *               1. PULL - Sync remote changes first
 *               2. ADD  - Stage all local changes
 *               3. COMMIT - Create a versioned snapshot
 *               4. PUSH - Upload to GitHub
 *
 * Requirements: GitHub Personal Access Token (PAT) with 'repo' scope
 *               Token: Settings > Developer Settings > Personal Access Tokens
 ******************************************************************************/

OPTIONS NONOTES NOSTIMER NOSOURCE NOSYNTAXCHECK;

/*=============================================================================
  USER CONFIGURATION - EDIT THIS SECTION
=============================================================================*/

/* 1. YOUR GITHUB PAT (Required for Push - Keep this SECRET!) */
/* Generate at: https://github.com/settings/tokens */
/* Required scope: 'repo' (Full control of private repositories) */
%let my_pat = ;  /* <-- PASTE YOUR TOKEN HERE */

/* 2. REPOSITORY DETAILS */
%let github_user = antonybevan;
%let repo_name   = safety_oncology;

/* 3. LOCAL PATH (SAS OnDemand home directory structure) */
%let home_dir    = /home/u63849890;
%let local_path  = &home_dir/clinical_safety;

/* 4. COMMIT METADATA */
%let commit_msg  = Pipeline update - Triple Diamond certified;
%let author_name = Clinical Programming Lead;
%let author_email = programmer@bioveris.com;

/*=============================================================================
  DERIVED VARIABLES - DO NOT EDIT
=============================================================================*/
%let repo_url_public = https://github.com/&github_user/&repo_name..git;
%let repo_url_auth   = https://oauth2:&my_pat@github.com/&github_user/&repo_name..git;

/*=============================================================================
  MACRO: CHECK_REPO_EXISTS
  Verify the local repository exists before operations
=============================================================================*/
%macro check_repo_exists;
    %global REPO_EXISTS;
    %let REPO_EXISTS = 0;
    
    data _null_;
        rc = filename("repo", "&local_path/.git");
        exists = fileexist("&local_path/.git");
        if exists then call symputx('REPO_EXISTS', '1');
        else call symputx('REPO_EXISTS', '0');
    run;
    
    %if &REPO_EXISTS = 0 %then %do;
        %put NOTE: ----------------------------------------------------;
        %put NOTE: Repository not found at &local_path;
        %put NOTE: Attempting initial clone...;
        %put NOTE: ----------------------------------------------------;
        
        proc git;
            clone url="&repo_url_public" out="&local_path";
        run;
        
        %let REPO_EXISTS = 1;
    %end;
%mend;

/*=============================================================================
  MACRO: GIT_PULL_SAFE
  Pull with conflict detection
=============================================================================*/
%macro git_pull_safe;
    %put NOTE: ==================================================;
    %put NOTE: STEP 1: Pulling latest changes from remote...;
    %put NOTE: ==================================================;
    
    data _null_;
        rc = gitfn_pull("&local_path");
        
        if rc = 0 then do;
            put "NOTE: ✅ Pull successful - local repo updated.";
            call symputx('PULL_STATUS', 'OK');
        end;
        else if rc = 1 then do;
            put "NOTE: ✓ Already up to date.";
            call symputx('PULL_STATUS', 'OK');
        end;
        else do;
            put "WARNING: ⚠️ Pull conflict detected (RC=" rc ").";
            put "WARNING: Run GIT_RESCUE.sas to force-sync.";
            call symputx('PULL_STATUS', 'CONFLICT');
        end;
    run;
%mend;

/*=============================================================================
  MACRO: GIT_COMMIT_PUSH
  Stage, commit, and push all changes
=============================================================================*/
%macro git_commit_push;
    %if &PULL_STATUS = CONFLICT %then %do;
        %put ERR%str(OR): Cannot push due to unresolved conflicts.;
        %put ERR%str(OR): Run GIT_RESCUE.sas first to reset local state.;
        %return;
    %end;
    
    %if %length(&my_pat) = 0 %then %do;
        %put ERR%str(OR): GitHub PAT not configured!;
        %put ERR%str(OR): Edit this file and set my_pat = your_token;
        %return;
    %end;
    
    %put NOTE: ==================================================;
    %put NOTE: STEP 2: Staging all changes...;
    %put NOTE: ==================================================;
    
    proc git;
        add 
            repo="&local_path"
            path="*"
        ;
    run;
    
    %put NOTE: ==================================================;
    %put NOTE: STEP 3: Committing changes...;
    %put NOTE: Message: &commit_msg;
    %put NOTE: ==================================================;
    
    proc git;
        commit 
            repo="&local_path"
            message="&commit_msg"
            author_name="&author_name"
            author_email="&author_email"
        ;
    run;
    
    %put NOTE: ==================================================;
    %put NOTE: STEP 4: Pushing to GitHub...;
    %put NOTE: Remote: github.com/&github_user/&repo_name;
    %put NOTE: ==================================================;
    
    proc git;
        push 
            repo="&local_path"
            url="&repo_url_auth"
        ;
    run;
    
    %put NOTE: ==================================================;
    %put NOTE: ✅ GIT PUSH COMPLETE;
    %put NOTE: Check: https://github.com/&github_user/&repo_name;
    %put NOTE: ==================================================;
%mend;

/*=============================================================================
  MACRO: GIT_STATUS
  Display current repository status
=============================================================================*/
%macro git_status;
    %put NOTE: ==================================================;
    %put NOTE: REPOSITORY STATUS;
    %put NOTE: ==================================================;
    
    data _null_;
        length branch $200;
        rc = gitfn_status("&local_path", branch);
        put "NOTE: Local Path: &local_path";
        put "NOTE: Current Branch: " branch;
        if rc = 0 then put "NOTE: Status: Clean (no uncommitted changes)";
        else put "NOTE: Status: Changes pending (uncommitted)";
    run;
%mend;

/*=============================================================================
  MAIN EXECUTION
=============================================================================*/
%check_repo_exists;
%git_status;
%git_pull_safe;
%git_commit_push;

OPTIONS NOTES STIMER SOURCE SYNTAXCHECK;
