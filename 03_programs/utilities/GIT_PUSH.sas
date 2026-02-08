/******************************************************************************
 * Program:      GIT_PUSH.sas
 * Purpose:      Push changes to Git from SAS
 * Note:         Uses gitfn_* kernel functions (not PROC GIT)
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
%if not %symexist(GIT_COMMIT_MSG) or %superq(GIT_COMMIT_MSG)= %then %let GIT_COMMIT_MSG = Pipeline update from SAS;
%if not %symexist(GIT_AUTHOR) or %superq(GIT_AUTHOR)= %then %let GIT_AUTHOR = %sysget(GIT_AUTHOR);
%if not %symexist(GIT_EMAIL) or %superq(GIT_EMAIL)= %then %let GIT_EMAIL = %sysget(GIT_EMAIL);
%if %superq(GIT_AUTHOR)= %then %let GIT_AUTHOR = Clinical Programming Lead;
%if %superq(GIT_EMAIL)= %then %let GIT_EMAIL = programmer@bioveris.com;
%if not %symexist(GITHUB_USER) or %superq(GITHUB_USER)= %then %let GITHUB_USER = %sysget(GITHUB_USER);
%if not %symexist(GITHUB_PAT) or %superq(GITHUB_PAT)= %then %let GITHUB_PAT = %sysget(GITHUB_PAT);

data _null_;
   put "NOTE: --------------------------------------------------";
   put "NOTE: GIT PUSH - Commit and Push";
   put "NOTE: Repo Path: &GIT_REPO_PATH";
   put "NOTE: --------------------------------------------------";

   rc_add = gitfn_add("&GIT_REPO_PATH", "*");
   put "NOTE: gitfn_add RC=" rc_add;

   rc_commit = gitfn_commit("&GIT_REPO_PATH", "&GIT_COMMIT_MSG", "&GIT_AUTHOR", "&GIT_EMAIL");
   put "NOTE: gitfn_commit RC=" rc_commit;

   %if %length(%superq(GITHUB_PAT)) > 0 and %length(%superq(GITHUB_USER)) > 0 %then %do;
      /* Mask credentials in log */
      options nonotes nosource;
      rc_push = gitfn_push("&GIT_REPO_PATH", "&GITHUB_USER", "&GITHUB_PAT");
      options notes source;
      put "NOTE: gitfn_push RC=" rc_push;
      if rc_push = 0 then put "NOTE: Push completed.";
      else put "ERROR: Push failed. Check credentials and remote access.";
   %end;
   %else %do;
      put "ERROR: Missing Git credentials. Set GITHUB_USER and GITHUB_PAT macro vars or environment variables.";
   %end;

   put "NOTE: --------------------------------------------------";
run;

