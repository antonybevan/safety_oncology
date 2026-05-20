/* QUOTE & MACRO KILLER BLOCK - Resets SAS state if previous errors left things open */
*';*";*/;QUIT;RUN;
%macro _null_; %mend;

/******************************************************************************
 * Program:      GIT_RESCUE.sas
 * Purpose:      Force-sync SAS OnDemand or SAS 9.4 with GitHub (Public Repo)
 * Compatibility: SAS 9.4 (Linux / Windows) + SAS OnDemand for Academics
 *
 * NOTES:
 *   - Locates project root dynamically, or defaults safely based on OS.
 *   - gitfn_pull / gitfn_clone require SAS Foundation 9.4 TS1M5+ or ODA.
 ******************************************************************************/

%let repo_url   = https://github.com/antonybevan/safety_oncology.git;

/* 1. Auto-detect project root (safe_path) */
%macro get_safe_path;
    %global safe_path;
    
    /* If PROJ_ROOT is already defined via 00_config.sas */
    %if %symexist(PROJ_ROOT) %then %do;
        %if %length(&PROJ_ROOT) > 1 %then %do;
            %let safe_path = &PROJ_ROOT;
            %return;
        %end;
    %end;

    /* Otherwise hunt for the repository signature file */
    %let SLSH = /;
    %let _sig = 03_programs&SLSH.00_config.sas;

    %if %sysfunc(fileexist(&_sig)) %then %let safe_path = %sysfunc(abspath(.));
    %else %if %sysfunc(fileexist(..&SLSH.&_sig)) %then %let safe_path = %sysfunc(abspath(..));
    %else %if %sysfunc(fileexist(..&SLSH..&SLSH.&_sig)) %then %let safe_path = %sysfunc(abspath(..&SLSH..));
    %else %if %sysfunc(fileexist(d:/safety_oncology/03_programs/00_config.sas)) %then %let safe_path = d:/safety_oncology;
    %else %do;
        /* OS-specific fallback */
        %let _home = %sysfunc(sysget(HOME));
        %if %length(&_home) = 0 %then %let _home = %sysfunc(sysget(USERPROFILE));
        
        %if %upcase(&SYSSCP) = WIN and %sysfunc(fileexist(d:/)) %then %let safe_path = d:/safety_oncology;
        %else %let safe_path = &_home/safety_oncology;
    %end;
%mend get_safe_path;
%get_safe_path;

%put NOTE: [GIT_RESCUE] Target Sync path: &safe_path;

/*
   NATIVE RECURSIVE DIRECTORY CLEANUP MACRO
   Does NOT use system shell escape (call system / 'rm -rf'), 
   making it 100% compatible with locked-down SAS OnDemand sessions.
*/
%macro clean_dir_native(dir);
    %macro _rmdir_rec(path);
        %local d_id rc member subpath fileref num_members i sub_fref is_dir f_delete dir_delete;
        
        %let rc = %sysfunc(filename(fileref, &path));
        %let d_id = %sysfunc(dopen(&fileref));
        
        %if &d_id > 0 %then %do;
            %let num_members = %sysfunc(dnum(&d_id));
            %do i = 1 %to &num_members;
                %let member = %sysfunc(dread(&d_id, &i));
                %let subpath = &path/&member;
                
                /* Check if subdirectory or file */
                %let rc = %sysfunc(filename(sub_fref, &subpath));
                %let is_dir = %sysfunc(dopen(&sub_fref));
                
                %if &is_dir > 0 %then %do;
                    %let rc = %sysfunc(dclose(&is_dir));
                    %let rc = %sysfunc(filename(sub_fref));
                    %_rmdir_rec(&subpath);
                %end;
                %else %do;
                    %let rc = %sysfunc(filename(sub_fref));
                    %let rc = %sysfunc(filename(f_delete, &subpath));
                    %let rc = %sysfunc(fdelete(&f_delete));
                    %let rc = %sysfunc(filename(f_delete));
                %end;
            %end;
            %let rc = %sysfunc(dclose(&d_id));
        %end;
        %let rc = %sysfunc(filename(fileref));
        
        /* Delete current empty directory */
        %let rc = %sysfunc(filename(dir_delete, &path));
        %let rc = %sysfunc(fdelete(&dir_delete));
        %let rc = %sysfunc(filename(dir_delete));
    %mend _rmdir_rec;

    %if %sysfunc(fileexist(&dir)) %then %do;
        %put NOTE: [GIT_RESCUE] Directory exists. Executing native recursive delete: &dir;
        %_rmdir_rec(&dir);
    %end;
    %else %do;
        %put NOTE: [GIT_RESCUE] Directory does not exist: &dir;
    %end;
%mend clean_dir_native;

data _null_;
    put "NOTE: --------------------------------------------------";
    put "NOTE: Starting GIT RESCUE Operation...";

    /* 1. Attempt PULL first */
    rc = gitfn_pull("&safe_path");
    put "NOTE: gitfn_pull returned RC=" rc;

    if rc = 0 then put "NOTE: SUCCESS! Project updated from GitHub.";
    else if rc = 1 then put "NOTE: Repository is already up to date.";

    /*
       Catch-all for failures:
       RC = 22  (Conflict)
       RC = -1  (Generic Failure / Repo missing)
       RC = 128 (Not a git repo)
    */
    else do;
        put "NOTE: Pull failed (Conflict or Missing). Initiating FRESH CLONE Protocol...";

        /* Nuke and re-clone */
        call execute('%clean_dir_native(&safe_path)');
        put "NOTE: Cloning from &repo_url...";
        rc_clone = gitfn_clone("&repo_url", "&safe_path");

        if rc_clone = 0 then put "NOTE: SUCCESS! Project reset and re-cloned.";
        else put "ERROR: Clone failed. RC=" rc_clone;
    end;

    put "NOTE: --------------------------------------------------";
run;
