/******************************************************************************
 * Program:      GIT_RESCUE.sas
 * Purpose:      Force-sync SAS OnDemand with GitHub (Public Repo)
 ******************************************************************************/

%let repo_url = https://github.com/antonybevan/safety_oncology.git;
%let home_dir = /home/u63849890;
%let safe_path = &home_dir/clinical_safety;

%let FORCE_FRESH = 0; /* Set to 1 to force a clean wipe and clone */

/* Helper to delete directory on SAS OnDemand */
%macro delete_dir(dir);
   data _null_;
      rc = filename('dir_t', "&dir");
      if rc = 0 then do;
         rc_del = fdelete('dir_t');
         put "NOTE: Attempted to delete &dir.. RC=" rc_del;
      end;
   run;
%mend;

data _null_;
   /* 1. Attempt PULL first */
   rc = gitfn_pull("&safe_path");
   
   if rc = 0 then put "NOTE: ✅ SUCCESS! Project updated from GitHub.";
   else if rc = 1 then put "NOTE: Repository is already up to date.";
   
   /* 2. Handle Conflicts (RC=22) or Forced Fresh */
   else if rc = 22 or &FORCE_FRESH = 1 then do;
       put "NOTE: Sync conflict (RC=22) or Force Fresh detected. Wiping local directory...";
       call execute('%delete_dir(&safe_path)');
       
       put "NOTE: Attempting clean clone into: &safe_path";
       rc_clone = gitfn_clone("&repo_url", "&safe_path");
       
       if rc_clone = 0 then put "NOTE: ✅ SUCCESS! Project reset and re-cloned.";
       else put "ERR" "OR: Re-clone failed. RC=" rc_clone;
   end;
   
   /* 3. Handle Missing Repo (-1 or 128) */
   else if rc = -1 or rc = 128 then do;
       put "NOTE: Folder missing or invalid. Attempting clean clone...";
       rc_clone = gitfn_clone("&repo_url", "&safe_path");
       if rc_clone = 0 then put "NOTE: ✅ SUCCESS! Project cloned.";
       else put "ERR" "OR: Clone failed. RC=" rc_clone;
   end;
   else put "ERR" "OR: Sync check failed. RC=" rc;
run;
