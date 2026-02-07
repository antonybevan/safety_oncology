/******************************************************************************
 * Program:      GIT_RESCUE.sas
 * Purpose:      Force-sync SAS OnDemand with GitHub (Public Repo)
 ******************************************************************************/

%let repo_url = https://github.com/antonybevan/safety_oncology.git;
%let home_dir = /home/u63849890;
%let safe_path = &home_dir/clinical_safety;

/* 
   RECURSIVE DELETE MACRO (Pure SAS - No Shell)
*/
%macro delete_file(f);
   data _null_; rc=filename("x","&f"); rc=fdelete("x"); rc=filename("x"); run;
%mend;

%macro delete_dir(d);
   data _null_; rc=filename("x","&d"); rc=fdelete("x"); rc=filename("x"); run;
%mend;

%macro force_clean(dir);
   data _null_;
      length name $256 path $512;
      rc = filename("d", "&dir");
      did = dopen("d");
      if did > 0 then do;
         num = dnum(did);
         do i = 1 to num;
            name = dread(did, i);
            path = catx("/", "&dir", name);
            rc2 = filename("t", path);
            did2 = dopen("t");
            if did2 > 0 then do;
               rc3 = dclose(did2);
               call execute('%force_clean(' || strip(path) || ')');
            end;
            else call execute('%delete_file(' || strip(path) || ')');
            rc2 = filename("t");
         end;
         rc = dclose(did);
      end;
      rc = filename("d");
      call execute('%delete_dir(' || strip("&dir") || ')');
   run;
%mend;

data _null_;
   put "NOTE: --------------------------------------------------";
   put "NOTE: Starting GIT RESCUE Operation...";
   
   /* 1. Attempt PULL first */
   rc = gitfn_pull("&safe_path");
   put "NOTE: gitfn_pull returned RC=" rc;
   
   if rc = 0 then put "NOTE: SUCCESS! Project updated from GitHub.";
   else if rc = 1 then put "NOTE: Repository is already up to date.";
   else do; 
       put "NOTE: Pull failed. Initiating FRESH CLONE...";
       call execute('%force_clean(&safe_path)');
       put "NOTE: Cloning from &repo_url...";
       rc_clone = gitfn_clone("&repo_url", "&safe_path");
       if rc_clone = 0 then put "NOTE: SUCCESS! Project reset and re-cloned.";
       else put "ERROR: Clone failed. RC=" rc_clone;
   end;
   
   put "NOTE: --------------------------------------------------";
run;
