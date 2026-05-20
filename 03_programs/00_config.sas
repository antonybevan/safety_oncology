/******************************************************************************
 * Program:      00_config.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Master Configuration & Environment Setup
 *               Dual-Compatible: SAS 9.4 (Windows/Linux) & SAS OnDemand for Academics
 * Author:       Statistical Programmer
 * Date:         2026-05-19
 *
 * COMPATIBILITY NOTES:
 *   - OS detection via &SYSSCP (WIN vs LIN X6464) sets path separator automatically
 *   - Hardcoded ODA username removed; uses %sysfunc(sysget(HOME)) instead
 *   - VALIDMEMNAME=EXTEND omitted (not supported on SAS OnDemand)
 *   - All directory creation is guarded by fileexist() checks
 *   - ODS graphics output paths use filename fileref (portable, both environments)
 ******************************************************************************/

/* ============================================================================
   0. SESSION NEUTRALIZATION & PORTABLE OPTIONS
   ============================================================================ */
*';*";*/;QUIT;RUN;

OPTIONS VALIDVARNAME=ANY    /* Allow special characters in variable names  */
        NOTES               /* Show notes in log                            */
        STIMER              /* Statement timing in log                      */
        SOURCE              /* Echo submitted code to log                   */
        NOSYNTAXCHECK;      /* Do not abort on single-step syntax errors    */
/* NOTE: VALIDMEMNAME=EXTEND removed — unsupported on SAS OnDemand          */

/* ============================================================================
   1. OS & ENVIRONMENT DETECTION
   ============================================================================ */
%macro _detect_project_root;
    %global PROJ_ROOT PROG_PATH RAW_PATH SDTM_PATH ADAM_PATH OUTPUT_PATH LEGACY_PATH;
    %global OS_PLATFORM SLSH;

    /* Detect OS — SYSSCP = 'WIN' on Windows, 'LIN X6464' on Linux/ODA */
    %if %upcase(&SYSSCP) = WIN %then %do;
        %let OS_PLATFORM = WINDOWS;
        %let SLSH        = /;   /* SAS accepts forward slash on Windows too */
    %end;
    %else %do;
        %let OS_PLATFORM = LINUX;
        %let SLSH        = /;
    %end;

    /* -----------------------------------------------------------------------
       Project Root Resolution Order:
       1. If PROJ_ROOT already set externally (batch submission), honour it.
       2. Search for the repository signature file from common relative paths.
       3. SAS OnDemand: fall back to $HOME/safety_oncology.
       4. SAS 9.4 Windows: fall back to current working directory.
    ----------------------------------------------------------------------- */
    %if %symexist(PROJ_ROOT) %then %do;
        %if %length(&PROJ_ROOT) > 1 %then %do;
            %put NOTE: [CONFIG] PROJ_ROOT pre-set externally to: &PROJ_ROOT;
            %goto paths_done;
        %end;
    %end;

    /* Signature file: 03_programs/00_config.sas exists at project root */
    %let _sig = 03_programs&SLSH.00_config.sas;

    %if %sysfunc(fileexist(&_sig)) %then
        %let PROJ_ROOT = %sysfunc(abspath(.));
    %else %if %sysfunc(fileexist(..&SLSH.&_sig)) %then
        %let PROJ_ROOT = %sysfunc(abspath(..));
    %else %if %sysfunc(fileexist(..&SLSH..&SLSH.&_sig)) %then
        %let PROJ_ROOT = %sysfunc(abspath(..&SLSH..));
    %else %do;
        /* --- ODA fallback: HOME/safety_oncology --- */
        %let _home = %sysfunc(sysget(HOME));
        %if %length(&_home) > 1 and %sysfunc(fileexist(&_home/safety_oncology)) %then
            %let PROJ_ROOT = &_home/safety_oncology;
        /* --- SAS 9.4 Windows fallback --- */
        %else %if %sysfunc(fileexist(d:/safety_oncology/03_programs)) %then
            %let PROJ_ROOT = d:/safety_oncology;
        %else %do;
            %put ERROR: [CONFIG] Cannot locate project root. Set PROJ_ROOT manually before %nrstr(%include)ing 00_config.sas.;
            %abort cancel;
        %end;
    %end;

    %put NOTE: [CONFIG] OS Platform   : &OS_PLATFORM;
    %put NOTE: [CONFIG] Project Root  : &PROJ_ROOT;

    /* -----------------------------------------------------------------------
       Standard Sub-Directory Path Macros (always forward-slash — safe on all platforms)
    ----------------------------------------------------------------------- */
    %paths_done:
    %let PROG_PATH   = &PROJ_ROOT/03_programs;
    %let RAW_PATH    = &PROJ_ROOT/01_rawdata;
    %let SDTM_PATH   = &PROJ_ROOT/02_datasets/sdtm;
    %let ADAM_PATH   = &PROJ_ROOT/02_datasets/analysis;
    %let OUTPUT_PATH = &PROJ_ROOT/04_outputs;
    %let LEGACY_PATH = &PROJ_ROOT/05_legacy_data;

    %global OUT_TABLES OUT_FIGURES OUT_LISTINGS OUT_META;
    %let OUT_TABLES   = &OUTPUT_PATH/tables;
    %let OUT_FIGURES  = &OUTPUT_PATH/figures;
    %let OUT_LISTINGS = &OUTPUT_PATH/listings;
    %let OUT_META     = &OUTPUT_PATH/metadata;

    /* -----------------------------------------------------------------------
       Directory Creation (guarded — works on SAS 9.4 and ODA)
       dcreate() requires (child_name, parent_path) — use only for leaf dirs
    ----------------------------------------------------------------------- */
    %macro _mkdir(fullpath);
        %if not %sysfunc(fileexist(&fullpath)) %then %do;
            %let _parent = %sysfunc(substr(&fullpath, 1, %sysfunc(findc(&fullpath, /, -200))-1));
            %let _child  = %sysfunc(scan(&fullpath, -1, /));
            %if %length(&_parent) > 0 %then %do;
                %if not %sysfunc(fileexist(&_parent)) %then %_mkdir(&_parent);
                %let _rc = %sysfunc(dcreate(&_child, &_parent));
                %if %length(&_rc) = 0 %then %put WARNING: [CONFIG] Could not create directory: &fullpath;
                %else %put NOTE: [CONFIG] Created directory: &fullpath;
            %end;
        %end;
    %mend _mkdir;

    %_mkdir(&RAW_PATH);
    %_mkdir(&SDTM_PATH);
    %_mkdir(&ADAM_PATH);
    %_mkdir(&OUTPUT_PATH);
    %_mkdir(&OUT_TABLES);
    %_mkdir(&OUT_FIGURES);
    %_mkdir(&OUT_LISTINGS);
    %_mkdir(&OUT_META);
    %_mkdir(&LEGACY_PATH);

%mend _detect_project_root;
%_detect_project_root;


/* ============================================================================
   2. LIBRARY ASSIGNMENTS
   ============================================================================ */
libname sdtm   "&SDTM_PATH";
libname adam   "&ADAM_PATH";
libname raw    "&RAW_PATH";
libname legacy "&LEGACY_PATH" access=readonly;


/* ============================================================================
   3. GLOBAL CONSTANTS & CONTROLLED FORMATS
   ============================================================================ */
%let STUDYID = BV-CAR20-P1;

%global DCUTDT DATA_CUTOFF;
%let DCUTDT      = '01JUN2026'd;   /* Fixed numeric SAS date — for data step arithmetic  */
%let DATA_CUTOFF = 2026-06-01;     /* Fixed ISO 8601 string  — for input("&DATA_CUTOFF", yymmdd10.) */

proc format;
    value dose_arm
        1 = "DL1: 1x10E6 cells/kg"
        2 = "DL2: 3x10E6 cells/kg"
        3 = "DL3: 480x10E6 cells";

    value $eff_fl
        "Y" = "Efficacy Evaluable"
        "N" = "Excl. Efficacy";

    value $arm_lbl
        "DL1" = "DL1: 1x10E6 cells/kg"
        "DL2" = "DL2: 3x10E6 cells/kg"
        "DL3" = "DL3: 480x10E6 cells";
run;


/* ============================================================================
   4. MACRO LIBRARY AUTOLOAD
   NOTE: sasautos appended — does not override existing SAS autocall library.
         Forward slash used in path — works on both Windows and Linux.
   ============================================================================ */
%macro _setup_mautos;
    %if %sysfunc(fileref(_mclib)) ne 0 %then %do;
        filename _mclib "&PROG_PATH/macros";
        options mautosource sasautos=(SASAUTOS _mclib);
    %end;
%mend _setup_mautos;
%_setup_mautos;

/* Force compilation of macros to prevent SAS session caching from using stale versions */
%include "&PROG_PATH/macros/calc_astct.sas";
%include "&PROG_PATH/macros/iso_to_sas.sas";
%include "&PROG_PATH/macros/load_config.sas";
%include "&PROG_PATH/macros/ods_setup.sas";
%include "&PROG_PATH/macros/trim.sas";
%include "&PROG_PATH/macros/xpt_export.sas";


/* ============================================================================
   5. PORTABLE ODS GRAPHICS OUTPUT SETUP
   - 'filename _fig' works on both ODA and SAS 9.4.
   - Each reporting program should set ODS destination at program start.
   ============================================================================ */
filename _tables  "&OUT_TABLES";
filename _figures "&OUT_FIGURES";
filename _lstngs "&OUT_LISTINGS";


%let CONFIG_LOADED = 1;
%put NOTE: [CONFIG] ============================================================;
%put NOTE: [CONFIG] BV-CAR20-P1 Environment Initialized Successfully.;
%put NOTE: [CONFIG]   Platform  : &OS_PLATFORM;
%put NOTE: [CONFIG]   Root      : &PROJ_ROOT;
%put NOTE: [CONFIG]   Data Cut  : &DATA_CUTOFF;
%put NOTE: [CONFIG] ============================================================;
