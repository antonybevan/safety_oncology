/******************************************************************************
 * Program:      00_config.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Master Configuration & Environment Setup
 * Author:       Clinical Programming Lead
 * Date:         2026-02-08
 * SAS Version:  9.4 (Optimized for SAS OnDemand)
 ******************************************************************************/

/* 1. Global Session Neutralization & Options */
*';*";*/;QUIT;RUN;
OPTIONS VALIDVARNAME=ANY 
        VALIDMEMNAME=EXTEND 
        DESC 
        NOTES 
        STIMER 
        SOURCE 
        NOSYNTAXCHECK;

/* 2. Professional Path Auto-Detector */
%macro _detect_project_root;
    %global PROJ_ROOT PROG_PATH RAW_PATH SDTM_PATH ADAM_PATH OUTPUT_PATH LEGACY_PATH;
    
    /* Determine Root via environment or relative search */
    %if %sysfunc(fileexist(/home/u63849890/clinical_safety)) %then 
        %let PROJ_ROOT = /home/u63849890/clinical_safety;
    %else %if %sysfunc(fileexist(03_programs/00_config.sas)) %then 
        %let PROJ_ROOT = %sysfunc(abspath(.));
    %else %let PROJ_ROOT = %sysfunc(abspath(..));

    /* Standard Subdirectories */
    %let PROG_PATH   = &PROJ_ROOT/03_programs;
    %let RAW_PATH    = &PROJ_ROOT/01_rawdata;
    %let SDTM_PATH   = &PROJ_ROOT/02_datasets/sdtm;
    %let ADAM_PATH   = &PROJ_ROOT/02_datasets/analysis;
    %let OUTPUT_PATH = &PROJ_ROOT/04_outputs;
    %let LEGACY_PATH = &PROJ_ROOT/05_legacy_data;

    /* Enforce Directory Existence */
    %local d;
    %let dirs = 01_rawdata 02_datasets/sdtm 02_datasets/analysis 03_programs 04_outputs 05_legacy_data;
    %do i = 1 %to %sysfunc(countw(&dirs));
        %let d = &PROJ_ROOT/%scan(&dirs, &i);
        %if not %sysfunc(fileexist(&d)) %then %let rc = %sysfunc(dcreate(%scan(&dirs, &i), &PROJ_ROOT));
    %end;

    %put NOTE: [CONFIG] Project Root set to: &PROJ_ROOT;
%mend _detect_project_root;
%_detect_project_root;

/* 3. Library Assignments */
libname sdtm  "&SDTM_PATH";
libname adam  "&ADAM_PATH";
libname raw   "&RAW_PATH";
libname legacy "&LEGACY_PATH" access=readonly;

/* 4. Global Constants & Formats */
%let STUDYID = BV-CAR20-P1;
%let DCUTDT  = %sysfunc(today()); /* Study Data Cutoff */

proc format;
    value dose_arm
        1 = "DL1: 50x10^6 cells"
        2 = "DL2: 150x10^6 cells"
        3 = "DL3: 450x10^6 cells";
    
    value $eff_fl
        "Y" = "Efficacy Evaluable"
        "N" = "Excl. Efficacy";
run;

/* 5. Utility Autoload */
filename funcs "&PROG_PATH/macros";
options mautosource sasautos=(SASAUTOS funcs);

%let CONFIG_LOADED = 1;
%put NOTE: [CONFIG] Environment Initialized Successfully.;
