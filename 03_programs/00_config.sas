/******************************************************************************
 * Program:      00_config.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Auto-detect project root and configure library paths
 * Author:       Clinical Programming Lead
 * Date:         2026-01-31
 * SAS Version:  9.4+, SAS OnDemand compatible
 ******************************************************************************/

%global IS_CLOUD PROJ_ROOT LEGACY_PATH SDTM_PATH ADAM_PATH STUDYID CONFIG_LOADED;
%let CONFIG_LOADED = 1;

/* Define Project-wide Study Identifier */
%let STUDYID = BV-CAR20-P1;

/* 1. Detect Environment and Root dynamically */
%macro set_proj_root;
    /* 1a. Detect if running in SAS OnDemand (Linux) */
    %if %sysfunc(find(&SYSSCP, LIN)) > 0 %then %do;
        %let IS_CLOUD = 1;
        /* Direct path for SAS OnDemand */
        %if %sysfunc(fileexist(/home/u63849890/clinical_safety/03_programs/00_config.sas)) %then %do;
            %let PROJ_ROOT = /home/u63849890/clinical_safety;
        %end;
        %else %if %symexist(_SASPROGRAMFILE) %then %do;
            data _null_;
                length dir $500;
                dir = "&_SASPROGRAMFILE";
                pos = max(findc(dir, '/', 'b'), findc(dir, '\', 'b'));
                if pos > 0 then dir = substr(dir, 1, pos-1);
                prog_pos = index(dir, '03_programs');
                if prog_pos > 0 then dir = substr(dir, 1, prog_pos-2);
                call symputx('PROJ_ROOT', strip(dir), 'G');
            run;
        %end;
        %else %let PROJ_ROOT = %sysget(HOME);
    %end;
    /* 1b. Local Windows Environment */
    %else %do;
        %let IS_CLOUD = 0;
        %if %symexist(_SASPROGRAMFILE) %then %do;
            data _null_;
                length dir $500;
                dir = "&_SASPROGRAMFILE";
                pos = max(findc(dir, '/', 'b'), findc(dir, '\', 'b'));
                if pos > 0 then dir = substr(dir, 1, pos-1);
                prog_pos = index(dir, '03_programs');
                if prog_pos > 0 then dir = substr(dir, 1, prog_pos-2);
                call symputx('PROJ_ROOT', strip(dir), 'G');
            run;
        %end;
        %else %do;
            /* Fallback for local Windows if _SASPROGRAMFILE is not populated */
            %let PROJ_ROOT = d:\safety_oncology;
        %end;
    %end;
    
    %put NOTE: --------------------------------------------------;
    %put NOTE: PROJ_ROOT DETECTED AS: &PROJ_ROOT;
    %put NOTE: --------------------------------------------------;
%mend;
%set_proj_root;

/* 2. Setup Paths */
%macro set_paths;
    /* Standard CDISC Folder Structure detection */
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

    /* Define Output Sub-sections */
    %global OUT_TABLES OUT_LISTINGS OUT_FIGURES OUT_META OUTPUT_PATH;
    %let OUT_TABLES   = &OUT_PATH/tables;
    %let OUT_LISTINGS = &OUT_PATH/listings;
    %let OUT_FIGURES  = &OUT_PATH/figures;
    %let OUT_META     = &OUT_PATH/metadata;
    %let OUTPUT_PATH  = &OUT_PATH;

    /* Assign Libraries */
    libname raw  "&LEGACY_PATH" access=readonly;
    libname sdtm "&SDTM_PATH";
    libname adam "&ADAM_PATH";
    
    /* 3. Configure Macro Library (SASAUTOS) */
    %let MACRO_PATH = &PROJ_ROOT/03_programs/macros;
    options sasautos = (sasautos "&MACRO_PATH") mautosource;

    %put NOTE: --------------------------------------------------;
    %put NOTE: &STUDYID PROJECT CONFIGURATION;
    %put NOTE: Root:   &PROJ_ROOT;
    %put NOTE: Legacy: &LEGACY_PATH;
    %put NOTE: --------------------------------------------------;
%mend;
%set_paths;
