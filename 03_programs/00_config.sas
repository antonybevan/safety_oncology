/******************************************************************************
 * Program:      00_config.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Auto-detect project root and configure library paths
 * Author:       Clinical Programming Lead
 * Date:         2026-01-25
 * SAS Version:  9.4+, SAS OnDemand compatible
 *
 * Instructions: 
 * 1. Just upload this and your CSVs to ANY folder in SAS OnDemand.
 * 2. Run this program first.
 ******************************************************************************/

%global IS_CLOUD PROJ_ROOT LEGACY_PATH SDTM_PATH ADAM_PATH;

/* 1. Detect Environment and Root dynamically */
%macro set_proj_root;
    %if %sysfunc(find(&SYSSCP, LIN)) > 0 %then %do;
        %let IS_CLOUD = 1;
        /* Use the location of THIS config file to find the root */
        %if %symexist(_SASPROGRAMFILE) %then %do;
            %let this_path = %sysfunc(prxchange(s/(.*)[\/\\].*$/$1/, 1, &_SASPROGRAMFILE));
            /* If we are in '03_programs', root is one level up */
            %if %sysfunc(index(&this_path, 03_programs)) > 0 %then 
                %let PROJ_ROOT = %sysfunc(prxchange(s/(.*)[\/\\].*$/$1/, 1, &this_path));
            %else %let PROJ_ROOT = &this_path;
        %end;
        %else %let PROJ_ROOT = %sysget(HOME);
    %end;
    %else %do;
        %let PROJ_ROOT = d:\safety_oncology;
        %let IS_CLOUD = 0;
    %end;
%mend;
%set_proj_root;

/* 2. Setup Paths */
%macro set_paths;
    %if %sysfunc(fileexist(&PROJ_ROOT/02_datasets/legacy)) %then %do;
        %let LEGACY_PATH = &PROJ_ROOT/02_datasets/legacy;
        %let SDTM_PATH = &PROJ_ROOT/02_datasets/tabulations;
        %let ADAM_PATH = &PROJ_ROOT/02_datasets/analysis;
    %end;
    %else %do;
        %let LEGACY_PATH = &PROJ_ROOT;
        %let SDTM_PATH = &PROJ_ROOT;
        %let ADAM_PATH = &PROJ_ROOT;
    %end;

    /* Assign Libraries */
    libname raw "&LEGACY_PATH" access=readonly;
    libname sdtm "&SDTM_PATH";
    libname adam "&ADAM_PATH";
    
    %put NOTE: ========================================;
    %put NOTE: Project Root: &PROJ_ROOT;
    %put NOTE: Legacy Path: &LEGACY_PATH;
    %put NOTE: ========================================;
%mend;
%set_paths;

%set_paths;
