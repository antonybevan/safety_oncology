/******************************************************************************
 * Program:      RECOVERY_AND_CLONE.sas
 * Purpose:      Delete broken folders and clone into a safe path
 ******************************************************************************/

%let home_dir = /home/u63849890;
%let repo_url = https://github.com/antonybevan/safety_oncology.git;

/* 1. NUCLEAR CLEANUP: Deletes all folders starting with 'safety_oncology' or containing ':' */
filename oscmd pipe "rm -rf &home_dir/safety_oncology*";
data _null_;
   infile oscmd;
   input;
   put _infile_;
run;

/* 2. REFRESH SYNC: Wait for the file system to catch up */
data _null_;
   rc = sleep(3);
run;

/* 3. SAFE CLONE: Use a short name with NO special characters */
%let safe_path = &home_dir/clinical_safety;

data _null_;
   put "NOTE: Attempting clean clone into: &safe_path";
   rc = gitfn_clone("&repo_url", "&safe_path");
   
   if rc = 0 then do;
      put "NOTE: ========================================";
      put "NOTE: ✅ SUCCESS! Project cloned to: &safe_path";
      put "NOTE: ========================================";
   end;
   else put "ERR" "OR: Clone failed. RC=" rc;
run;
