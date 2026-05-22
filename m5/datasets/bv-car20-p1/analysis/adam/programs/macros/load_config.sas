/******************************************************************************
 * Macro:        load_config
 * Purpose:      Portable config loader — resolves 00_config.sas from any
 *               working directory and on any platform (SAS 9.4 / ODA).
 *
 * COMPATIBILITY: SAS 9.4 (Windows & Linux) + SAS OnDemand for Academics
 *
 * Usage:        %load_config;
 *   Call at the top of every standalone program before using any path
 *   macros (&OUT_TABLES, &ADAM_PATH, etc.).
 ******************************************************************************/

%macro load_config;
    /* Skip if already loaded in this session */
    %if %symexist(CONFIG_LOADED) %then %do;
        %if &CONFIG_LOADED = 1 %then %return;
    %end;

    /* -----------------------------------------------------------------------
       Search relative paths — covers running from:
         project root  (./m5/datasets/bv-car20-p1/analysis/adam/programs/00_config.sas)
         programs/     (./00_config.sas)
         sub-folder    (../00_config.sas)
         sub-sub       (../../00_config.sas)
       Forward slashes work on both Windows SAS 9.4 and ODA/Linux.
    ----------------------------------------------------------------------- */
    %if      %sysfunc(fileexist(00_config.sas))
        %then %include "00_config.sas";
    %else %if %sysfunc(fileexist(m5/datasets/bv-car20-p1/analysis/adam/programs/00_config.sas))
        %then %include "m5/datasets/bv-car20-p1/analysis/adam/programs/00_config.sas";
    %else %if %sysfunc(fileexist(../../m5/datasets/bv-car20-p1/analysis/adam/programs/00_config.sas))
        %then %include "../../m5/datasets/bv-car20-p1/analysis/adam/programs/00_config.sas";
    %else %if %sysfunc(fileexist(../00_config.sas))
        %then %include "../00_config.sas";
    %else %if %sysfunc(fileexist(../../analysis/adam/programs/00_config.sas))
        %then %include "../../analysis/adam/programs/00_config.sas";
    %else %if %sysfunc(fileexist(../../00_config.sas))
        %then %include "../../00_config.sas";
    %else %if %sysfunc(fileexist(../../../analysis/adam/programs/00_config.sas))
        %then %include "../../../analysis/adam/programs/00_config.sas";
    %else %if %sysfunc(fileexist(../../../00_config.sas))
        %then %include "../../../00_config.sas";
    %else %do;
        /* Last resort: check OS-specific defaults */
        %let _home = %sysfunc(sysget(HOME));
        %if %length(&_home) = 0 %then %let _home = %sysfunc(sysget(USERPROFILE));

        %if %upcase(&SYSSCP) = WIN and %sysfunc(fileexist(d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/00_config.sas)) %then 
            %include "d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/00_config.sas";
        %else %if %sysfunc(fileexist(&_home/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/00_config.sas)) %then 
            %include "&_home/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/00_config.sas";
        %else %do;
            %put ERROR: [LOAD_CONFIG] Cannot locate 00_config.sas.;
            %put ERROR: [LOAD_CONFIG] Set PROJ_ROOT manually or run from the project root.;
            %abort cancel;
        %end;
    %end;
%mend load_config;
