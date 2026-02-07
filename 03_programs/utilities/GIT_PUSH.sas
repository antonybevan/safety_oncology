/******************************************************************************
 * Program:      GIT_PUSH.sas
 * Purpose:      Push changes to GitHub from SAS OnDemand
 * Note:         Uses gitfn_* kernel functions (not PROC GIT)
 ******************************************************************************/

%let home_dir   = /home/u63849890;
%let local_path = &home_dir/clinical_safety;
%let commit_msg = Pipeline update from SAS OnDemand;
%let author     = Clinical Programming Lead;
%let email      = programmer@bioveris.com;

/* YOUR GITHUB PAT - Required for push */
%let github_user = antonybevan;
%let github_pat  = ;  /* <-- PASTE YOUR TOKEN HERE */

data _null_;
   put "NOTE: --------------------------------------------------";
   put "NOTE: GIT PUSH - Commit and Push to GitHub";
   put "NOTE: --------------------------------------------------";
   
   /* Step 1: Stage all changes */
   rc_add = gitfn_add("&local_path", "*");
   put "NOTE: gitfn_add RC=" rc_add;
   
   /* Step 2: Commit */
   rc_commit = gitfn_commit("&local_path", "&commit_msg", "&author", "&email");
   put "NOTE: gitfn_commit RC=" rc_commit;
   
   /* Step 3: Push (requires credentials) */
   %if %length(&github_pat) > 0 %then %do;
      rc_push = gitfn_push("&local_path", "&github_user", "&github_pat");
      put "NOTE: gitfn_push RC=" rc_push;
      if rc_push = 0 then put "NOTE: SUCCESS! Pushed to GitHub.";
      else put "ERROR: Push failed. Check PAT permissions.";
   %end;
   %else %do;
      put "ERROR: GitHub PAT not configured. Edit this file and set github_pat.";
   %end;
   
   put "NOTE: --------------------------------------------------";
run;
