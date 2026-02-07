/******************************************************************************
 * Program:      GIT_RESCUE.sas
 * Purpose:      Force-sync SAS OnDemand with GitHub (Public Repo)
 ******************************************************************************/

%let repo_url = https://github.com/antonybevan/safety_oncology.git;
%let home_dir = /home/u63849890;
%let safe_path = &home_dir/clinical_safety;

/* 
   ROBUST CLEANUP MACRO 
   Uses Linux 'rm -rf' via SYSTEM call to ensure non-empty dirs are gone.
*/
%macro force_clean(dir);
   data _null_;
      fname = "tempfile";
      rc = filename(fname, "&dir");
      if fexist(fname) or fileexist("&dir") then do;
          put "NOTE: Directory exists. Executing recursive delete on: &dir";
          call system("rm -rf &dir");
      end;
      else put "NOTE: Directory does not exist, nothing to clean.";
   run;
%mend;

data _null_;
   put "NOTE: --------------------------------------------------";
   put "NOTE: Starting GIT RESCUE Operation...";
   
   /* 1. Attempt PULL first */
   rc = gitfn_pull("&safe_path");
   put "NOTE: gitfn_pull returned RC=" rc;
   
   if rc = 0 then put "NOTE: Γ£à SUCCESS! Project updated from GitHub.";
   else if rc = 1 then put "NOTE: Repository is already up to date.";
   
   /* 
      Catch-all for failures:
      RC = 22 (Conflict)
      RC = -1 (Generic Failure / Repo missing)
      RC = 128 (Not a repo)
   */
   else do; 
       put "NOTE: Pull failed (Conflict or Missing). Initiating FRESH CLONE Protocol...";
       
       /* Nuke it from orbit */
       call execute('%force_clean(&safe_path)');
       
       /* Clone fresh */
       put "NOTE: Cloning from &repo_url...";
       rc_clone = gitfn_clone("&repo_url", "&safe_path");
       
       if rc_clone = 0 then put "NOTE: Γ£à SUCCESS! Project reset and re-cloned.";
       else put "ERR" "OR: Clone failed. RC=" rc_clone;
   end;
   
   put "NOTE: --------------------------------------------------";
run;
