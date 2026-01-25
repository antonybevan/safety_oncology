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

/* 1. Detect Environment and Root */
%macro set_proj_root;
    %if %sysfunc(find(&SYSSCP, LIN)) > 0 %then %do;
        %let HOME = %sysget(HOME);
        /* Check for multiple possible root names to be safe */
        %if %sysfunc(fileexist(&HOME/safety_oncology)) %then %let PROJ_ROOT = &HOME/safety_oncology;
        %else %if %sysfunc(fileexist(&HOME/safety_oncology_git)) %then %let PROJ_ROOT = &HOME/safety_oncology_git;
        %else %let PROJ_ROOT = &HOME;
        %let IS_CLOUD = 1;
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
