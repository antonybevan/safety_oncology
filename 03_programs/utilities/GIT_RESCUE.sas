/******************************************************************************
 * Program:      GIT_RESCUE.sas
 * Purpose:      Force-sync local repository with remote
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(03_programs/00_config.sas)) %then %include "03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
   %else %if %sysfunc(fileexist(../03_programs/00_config.sas)) %then %include "../03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../../00_config.sas)) %then %include "../../00_config.sas";
   %else %if %sysfunc(fileexist(../../03_programs/00_config.sas)) %then %include "../../03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../../../00_config.sas)) %then %include "../../../00_config.sas";
   %else %if %sysfunc(fileexist(../../../03_programs/00_config.sas)) %then %include "../../../03_programs/00_config.sas";
   %else %do;
      %put ERROR: Unable to locate 00_config.sas from current working directory.;
      %abort cancel;
   %end;
%mend;
%load_config;

%if not %symexist(GIT_REPO_PATH) or %superq(GIT_REPO_PATH)= %then %let GIT_REPO_PATH = &PROJ_ROOT;
%if not %symexist(GIT_REMOTE_URL) or %superq(GIT_REMOTE_URL)= %then %let GIT_REMOTE_URL = %sysget(GIT_REMOTE_URL);

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
   put "NOTE: Starting GIT RESCUE operation...";
   put "NOTE: Repo Path: &GIT_REPO_PATH";

   rc = gitfn_pull("&GIT_REPO_PATH");
   put "NOTE: gitfn_pull returned RC=" rc;

   if rc = 0 then put "NOTE: Pull completed.";
   else if rc = 1 then put "NOTE: Repository already up to date.";
   else do;
       put "NOTE: Pull failed. Initiating fresh-clone protocol...";

       call execute('%force_clean(&GIT_REPO_PATH)');

       %if %length(%superq(GIT_REMOTE_URL)) > 0 %then %do;
           put "NOTE: Cloning from &GIT_REMOTE_URL...";
           rc_clone = gitfn_clone("&GIT_REMOTE_URL", "&GIT_REPO_PATH");

           if rc_clone = 0 then put "NOTE: Fresh clone completed.";
           else put "ERROR: Clone failed. RC=" rc_clone;
       %end;
       %else %do;
           put "ERROR: Missing remote URL. Set GIT_REMOTE_URL macro var or environment variable before rescue clone.";
       %end;
   end;

   put "NOTE: --------------------------------------------------";
run;

