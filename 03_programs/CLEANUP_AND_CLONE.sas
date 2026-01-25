/******************************************************************************
 * Program:      CLEANUP_AND_CLONE.sas
 * Purpose:      Delete broken folders and clone into a simple path
 ******************************************************************************/

%let repo_url = https://github.com/antonybevan/safety_oncology.git;
%let home_dir = /home/u63849890;

/* 1. CLEANUP: Delete the broken folders using Linux commands */
filename oscmd pipe "rm -rf &home_dir/safety_oncology_*";
data _null_;
   infile oscmd;
   input;
   put _infile_;
run;

/* 2. REFRESH: Wait a second for the server to sync */
data _null_;
   rc = sleep(2);
run;

/* 3. SIMPLIFIED CLONE: Use a short, simple name */
%let simple_path = &home_dir/project;

data _null_;
   put "NOTE: Attempting clean clone into: &simple_path";
   rc = gitfn_clone("&repo_url", "&simple_path");
   
   if rc = 0 then do;
      put "NOTE: ========================================";
      put "NOTE: ✅ SUCCESS! Project cloned to: &simple_path";
      put "NOTE: ========================================";
   end;
   else put "ERR" "OR: Clone failed. RC=" rc;
run;
