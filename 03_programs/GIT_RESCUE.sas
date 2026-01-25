/******************************************************************************
 * Program:      GIT_RESCUE.sas
 * Purpose:      Force-sync SAS OnDemand with GitHub (Public Repo)
 ******************************************************************************/

%let repo_url = https://github.com/antonybevan/safety_oncology.git;
%let home_dir = /home/u63849890;
%let safe_path = &home_dir/clinical_safety;

/* NUCLEAR OPTION: Uncomment the next line if it refuses to update! */
/* %let FORCE_FRESH = 1; */

data _null_;
   /* Attempt PULL first */
   rc = gitfn_pull("&safe_path");
   
   /* If it says 'Up to date' (RC=1) but you know it's not, we can force it */
   /* For now, let's trust the RC unless FORCE_FRESH is on */
   
   if rc = 0 then put "NOTE: ✅ SUCCESS! Project updated.";
   else if rc = 1 then put "NOTE: System says 'Already up to date'. If this is wrong, rename the folder manually.";
   
   /* If folder missing (-1) or not a repo (128), CLONE it */
   else if rc = -1 or rc = 128 then do;
       put "NOTE: Folder missing. Attempting clean clone into: &safe_path";
       rc_clone = gitfn_clone("&repo_url", "&safe_path");
       
       if rc_clone = 0 then do;
          put "NOTE: ========================================";
          put "NOTE: ✅ SUCCESS! Project cloned to: &safe_path";
          put "NOTE: ========================================";
       end;
       else put "ERR" "OR: Clone failed. RC=" rc_clone;
   end;
   else put "ERR" "OR: Sync check failed. RC=" rc;
run;
