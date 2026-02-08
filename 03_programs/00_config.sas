/******************************************************************************
 * Program:      00_config.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Auto-detect project root and configure library paths
 * Author:       Clinical Programming Lead
 * Date:         2026-02-08
 * SAS Version:  9.4+, SAS OnDemand compatible
 ******************************************************************************/

%global IS_CLOUD PROJ_ROOT PROG_PATH LEGACY_PATH SDTM_PATH ADAM_PATH STUDYID CONFIG_LOADED DATA_CUTOFF;
%let CONFIG_LOADED = 1;

%macro _init_study_env;
    /* Define project-wide study identifier in one place */
    %if not %symexist(STUDYID) or %superq(STUDYID)= %then %let STUDYID = BV-CAR20-P1;

    /* Data cutoff date for time-to-event and ongoing durations (override as needed) */
    %if not %symexist(DATA_CUTOFF) or %superq(DATA_CUTOFF)= %then %let DATA_CUTOFF = %sysfunc(today(), yymmdd10.);
%mend _init_study_env;
%_init_study_env;

%macro _derive_root_from_path(path_value);
    %local _path_literal;
    %let _path_literal = %superq(path_value);

    data _null_;
        length p dir root $1024;
        p = symget('_path_literal');
        if missing(p) then stop;

        dir = tranwrd(strip(p), '\\', '/');

        /* Remove filename if a file path was provided */
        if index(scan(dir, -1, '/'), '.') > 0 then do;
            _pos_last = findc(dir, '/', 'b');
            if _pos_last > 0 then dir = substr(dir, 1, _pos_last - 1);
        end;

        _prog_pos = index(lowcase(dir), '/03_programs');
        if _prog_pos > 0 then root = substr(dir, 1, _prog_pos - 1);
        else root = dir;

        /* Trim trailing slash for clean concatenation */
        if length(root) > 1 and substr(root, length(root), 1) = '/' then
            root = substr(root, 1, length(root) - 1);

        call symputx('PROJ_ROOT', strip(root), 'G');
    run;
%mend;

/* 1. Detect environment and root dynamically */
%macro set_proj_root;
    %let PROJ_ROOT =;
    %let IS_CLOUD = 0;

    /* Environment flag */
    %if %sysfunc(find(%upcase(&SYSSCP), LIN)) > 0 %then %let IS_CLOUD = 1;

    /* Priority 1: _SASPROGRAMFILE */
    %if %superq(PROJ_ROOT)= and %symexist(_SASPROGRAMFILE) and %superq(_SASPROGRAMFILE) ne %then %do;
        %_derive_root_from_path(%superq(_SASPROGRAMFILE));
        %if %superq(PROJ_ROOT) ne %then %put NOTE: Config priority 1: _SASPROGRAMFILE used.;
    %end;

    /* Priority 2: SYSIN (batch) */
    %if %superq(PROJ_ROOT)= %then %do;
        %let _sysin = %sysfunc(getoption(SYSIN));
        %if %superq(_sysin) ne and %upcase(%superq(_sysin)) ne DMS %then %do;
            %_derive_root_from_path(%superq(_sysin));
            %if %superq(PROJ_ROOT) ne %then %put NOTE: Config priority 2: SYSIN used.;
        %end;
    %end;

    /* Priority 3: Relative probing from current working directory */
    %if %superq(PROJ_ROOT)= %then %do;
        %if %sysfunc(fileexist(03_programs/00_config.sas)) %then %let PROJ_ROOT = .;
        %else %if %sysfunc(fileexist(./03_programs/00_config.sas)) %then %let PROJ_ROOT = .;
        %else %if %sysfunc(fileexist(00_config.sas)) %then %let PROJ_ROOT = ..;
        %else %if %sysfunc(fileexist(../03_programs/00_config.sas)) %then %let PROJ_ROOT = ..;
        %else %if %sysfunc(fileexist(../../03_programs/00_config.sas)) %then %let PROJ_ROOT = ../..;
        %if %superq(PROJ_ROOT) ne %then %put NOTE: Config priority 3: Relative probing used.;
    %end;

    /* Final fallback: WORK path (with warning) */
    %if %superq(PROJ_ROOT)= %then %do;
        %let PROJ_ROOT = %sysfunc(pathname(work));
        %put WARNING: Project root could not be inferred from program location. Using WORK path as fallback: &PROJ_ROOT;
    %end;

    %let PROG_PATH = &PROJ_ROOT/03_programs;

    %put NOTE: --------------------------------------------------;
    %put NOTE: PROJ_ROOT DETECTED AS: &PROJ_ROOT;
    %put NOTE: PROGRAM PATH SET TO: &PROG_PATH;
    %put NOTE: --------------------------------------------------;
%mend;
%set_proj_root;

/* 2. Setup paths */
%macro set_paths;
    /* Standard CDISC folder structure detection */
    %if %sysfunc(fileexist(&PROJ_ROOT/02_datasets/legacy)) %then %do;
        %let LEGACY_PATH = &PROJ_ROOT/02_datasets/legacy;
        %let SDTM_PATH   = &PROJ_ROOT/02_datasets/tabulations;
        %let ADAM_PATH   = &PROJ_ROOT/02_datasets/analysis;
        %let OUT_PATH    = &PROJ_ROOT/04_outputs;
    %end;
    %else %do;
        %let LEGACY_PATH = &PROJ_ROOT;
        %let SDTM_PATH   = &PROJ_ROOT;
        %let ADAM_PATH   = &PROJ_ROOT;
        %let OUT_PATH    = &PROJ_ROOT;
    %end;

    /* Define output sub-sections */
    %global OUT_TABLES OUT_LISTINGS OUT_FIGURES OUT_META OUTPUT_PATH;
    %let OUT_TABLES   = &OUT_PATH/tables;
    %let OUT_LISTINGS = &OUT_PATH/listings;
    %let OUT_FIGURES  = &OUT_PATH/figures;
    %let OUT_META     = &OUT_PATH/metadata;
    %let OUTPUT_PATH  = &OUT_PATH;

    /* Assign libraries with directory creation protection */
    data _null_;
       length path $1024;
       array paths[2] $1024 ("&SDTM_PATH", "&ADAM_PATH");
       do i = 1 to 2;
          path = paths[i];
          if not fileexist(path) then do;
             rc = dcreate(scan(path, -1, '/'), substr(path, 1, find(path, scan(path, -1, '/'))-2));
             put "NOTE: Creating directory " path " RC=" rc;
          end;
       end;
    run;

    libname raw  "&LEGACY_PATH" access=readonly;
    libname sdtm "&SDTM_PATH";
    libname adam "&ADAM_PATH";

    /* Configure macro library (SASAUTOS) */
    %let MACRO_PATH = &PROJ_ROOT/03_programs/macros;
    options sasautos = (sasautos "&MACRO_PATH") mautosource;

    %put NOTE: --------------------------------------------------;
    %put NOTE: &STUDYID PROJECT CONFIGURATION;
    %put NOTE: Root:   &PROJ_ROOT;
    %put NOTE: Legacy: &LEGACY_PATH;
    %put NOTE: SDTM:   &SDTM_PATH;
    %put NOTE: ADAM:   &ADAM_PATH;
    %put NOTE: --------------------------------------------------;
%mend;
%set_paths;
