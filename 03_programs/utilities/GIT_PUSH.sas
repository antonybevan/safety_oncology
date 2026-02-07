/******************************************************************************
 * Program:      GIT_PUSH.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Git Push Utility
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4+
 ******************************************************************************/

OPTIONS NONOTES NOSTIMER NOSOURCE NOSYNTAXCHECK;

/*=============================================================================
  USER CONFIGURATION
=============================================================================*/
%let my_pat = ;  /* PASTE YOUR TOKEN HERE */
%let github_user = antonybevan;
%let repo_name   = safety_oncology;
%let home_dir    = /home/u63849890;
%let local_path  = &home_dir/clinical_safety;
%let commit_msg  = Pipeline update;
%let author_name = Clinical Programming Lead;
%let author_email = programmer@bioveris.com;

%let repo_url_auth = https://oauth2:&my_pat@github.com/&github_user/&repo_name..git;

/*=============================================================================
  MACRO: GIT_COMMIT_PUSH
=============================================================================*/
%macro git_commit_push;
    %if %length(&my_pat) = 0 %then %do;
        %put ERROR: PAT not configured.;
        %return;
    %end;
    
    proc git;
        add repo="&local_path" path="*";
    run;
    quit;

    proc git;
        commit 
            repo="&local_path"
            message="&commit_msg"
            author_name="&author_name"
            author_email="&author_email";
    run;
    quit;

    proc git;
        push repo="&local_path" url="&repo_url_auth";
    run;
    quit;
%mend;

%git_commit_push;

OPTIONS NOTES STIMER SOURCE SYNTAXCHECK;
