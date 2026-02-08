/* QUOTE & MACRO KILLER BLOCK - Resets SAS state if previous errors left things open */
*';*";*/;QUIT;RUN;
%macro _null_; %mend; 

/******************************************************************************
 * Program:      GIT_RESCUE.sas (Bootstrap Recovery Version)
 * Purpose:      Force-sync SAS OnDemand with GitHub (Public Repo)
 *               NO DEPENDENCIES - Direct System Call Clone
 ******************************************************************************/

%let repo_url = https://github.com/antonybevan/safety_oncology.git;
%let home_dir = /home/u63849890;
%let safe_path = &home_dir/clinical_safety;

options notes stimer source spool;

data _null_;
   put "NOTE: --------------------------------------------------";
   put "NOTE: STARTING BOOTSTRAP GIT RESCUE...";
   put "NOTE: Repository: &repo_url";
   put "NOTE: Target:     &safe_path";
   put "NOTE: --------------------------------------------------";

   /* Step 1: Force Clean via Linux System Call */
   put "NOTE: Cleaning local directory (Nuke from orbit)...";
   rc_rm = system("rm -rf &safe_path");
   put "NOTE: rm -rf returned RC=" rc_rm;
   
   /* Step 2: Fresh Clone */
   put "NOTE: Cloning fresh from GitHub... this may take 10-20 seconds.";
   rc_clone = system("git clone &repo_url &safe_path");
   
   if rc_clone = 0 then do;
       put "NOTE: --------------------------------------------------";
       put "NOTE: ✅ SUCCESS: Repository restored and updated.";
       put "NOTE: All fixes (including 00_config.sas) are now on the server.";
       put "NOTE: You can now run your programs normally.";
       put "NOTE: --------------------------------------------------";
   end;
   else do;
       put "NOTE: --------------------------------------------------";
       put "ERROR: Clone failed with RC=" rc_clone;
       put "NOTE: Check your internet connection or GitHub availability.";
       put "NOTE: --------------------------------------------------";
   end;
run;
