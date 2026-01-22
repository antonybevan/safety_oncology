/******************************************************************************
 * Program:      00_config.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Auto-detect project root and configure library paths
 * Author:       Clinical Programming Lead
 * Date:         2026-01-22
 * SAS Version:  9.4+, SAS OnDemand compatible
 *
 * Usage:        ⭐ RUN THIS FIRST before any other SAS programs
 *
 * Instructions:
 * 1. If using SAS OnDemand: Just open and run (auto-detects ~/BV-CAR20-P1)
 * 2. If using local SAS 9.4: Update LOCAL_ROOT below
 ******************************************************************************/

/* Detect environment */
%let IS_CLOUD = %sysfunc(find(&SYSSCP, LIN));  /* Linux = SAS OnDemand */

%macro set_paths;
    %if &IS_CLOUD > 0 %then %do;
        /* SAS OnDemand (Linux) - Auto-detect home directory */
        %let PROJ_ROOT = %sysget(HOME)/BV-CAR20-P1;
        %put NOTE: Running on SAS OnDemand;
    %end;
    %else %do;
        /* Local Windows SAS 9.4 */
        %let PROJ_ROOT = d:\safety_oncology\BV-CAR20-P1;
        %put NOTE: Running on local SAS 9.4;
    %end;
    
    %put NOTE: Project Root = &PROJ_ROOT;
    
    /* Assign Libraries */
    libname raw "&PROJ_ROOT/02_datasets/legacy";
    libname sdtm "&PROJ_ROOT/02_datasets/tabulations";
    
    /* Create output directory if needed */
    %if %sysfunc(fileexist(&PROJ_ROOT/02_datasets/tabulations)) = 0 %then %do;
        %put NOTE: Creating tabulations directory;
        x "mkdir -p &PROJ_ROOT/02_datasets/tabulations";
    %end;
    
    /* Global macro for use in PROC IMPORT */
    %global LEGACY_PATH SDTM_PATH;
    %let LEGACY_PATH = &PROJ_ROOT/02_datasets/legacy;
    %let SDTM_PATH = &PROJ_ROOT/02_datasets/tabulations;
    
    /* Verify libraries */
    proc datasets library=raw nolist;
    quit;
    proc datasets library=sdtm nolist;
    quit;
    
    %put NOTE: ✅ Configuration complete. Libraries assigned:;
    %put NOTE:    RAW  = &PROJ_ROOT/02_datasets/legacy;
    %put NOTE:    SDTM = &PROJ_ROOT/02_datasets/tabulations;
%mend;

%set_paths;
