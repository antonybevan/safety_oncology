/******************************************************************************
 * Program:      GIT_RECOVERY.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Environment Recovery Instructions for SAS OnDemand
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 * SAS Version:  9.4+ / SAS OnDemand compatible
 *
 * IMPORTANT:    PROC GIT and shell escapes are NOT available in SAS ODA.
 *               This program provides manual instructions instead.
 ******************************************************************************/

/*=============================================================================
  ENVIRONMENT DETECTION & INSTRUCTIONS
=============================================================================*/

%put NOTE: ======================================================================;
%put NOTE: ENVIRONMENT RECOVERY UTILITY - MANUAL INSTRUCTIONS;
%put NOTE: ======================================================================;
%put NOTE: ;
%put NOTE: SAS OnDemand for Academics DOES NOT support PROC GIT or shell commands.;
%put NOTE: Please follow the steps below to synchronize your environment.;
%put NOTE: ;
%put NOTE: ======================================================================;
%put NOTE: STEP 1: DOWNLOAD THE LATEST REPOSITORY;
%put NOTE: ======================================================================;
%put NOTE:   1. Open a web browser and navigate to:;
%put NOTE:      https://github.com/antonybevan/safety_oncology;
%put NOTE:   2. Click the green "< > Code" button.;
%put NOTE:   3. Select "Download ZIP".;
%put NOTE:   4. Save the file to your local computer.;
%put NOTE: ;
%put NOTE: ======================================================================;
%put NOTE: STEP 2: UPLOAD TO SAS ONDEMAND;
%put NOTE: ======================================================================;
%put NOTE:   1. In SAS OnDemand Studio, open the "Files (Home)" tab.;
%put NOTE:   2. Delete or rename any existing 'clinical_safety' or;
%put NOTE:      'safety_oncology' folder to avoid conflicts.;
%put NOTE:   3. Right-click inside the Files pane and select "Upload".;
%put NOTE:   4. Upload the ZIP file.;
%put NOTE:   5. Right-click the uploaded ZIP file and select "Extract All".;
%put NOTE: ;
%put NOTE: ======================================================================;
%put NOTE: STEP 3: CONFIGURE & RUN;
%put NOTE: ======================================================================;
%put NOTE:   1. Open 00_config.sas from the extracted folder.;
%put NOTE:   2. Run it (F3 or click Run) to set up library paths.;
%put NOTE:   3. Proceed with the main pipeline (00_main.sas).;
%put NOTE: ;
%put NOTE: ======================================================================;
%put NOTE: RECOVERY INSTRUCTIONS COMPLETE;
%put NOTE: ======================================================================;

/*=============================================================================
  OPTIONAL: QUICK DIRECTORY CLEANUP MACRO
  Uses SAS I/O functions, which ARE available in ODA.
=============================================================================*/
%macro oda_delete_folder(path);
    /* This macro attempts to delete a folder using SAS functions. */
    /* It will only work on EMPTY directories. Delete files first. */
    data _null_;
        rc = filename("del", "&path");
        rc = fdelete("del");
        if rc = 0 then put "NOTE: Successfully deleted folder: &path";
        else put "WARNING: Could not delete folder (may contain files): &path";
        rc = filename("del");
    run;
%mend;

/* Example: %oda_delete_folder(/home/u63849890/clinical_safety); */
