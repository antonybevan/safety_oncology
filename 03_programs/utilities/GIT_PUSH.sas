/******************************************************************************
 * Program:      GIT_PUSH.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Git Push Instructions for SAS OnDemand
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
%put NOTE: GIT PUSH UTILITY - MANUAL INSTRUCTIONS;
%put NOTE: ======================================================================;
%put NOTE: ;
%put NOTE: SAS OnDemand for Academics DOES NOT support PROC GIT or shell commands.;
%put NOTE: To push your changes back to GitHub, follow the steps below.;
%put NOTE: ;
%put NOTE: ======================================================================;
%put NOTE: STEP 1: DOWNLOAD YOUR WORK FROM SAS ONDEMAND;
%put NOTE: ======================================================================;
%put NOTE:   1. In SAS OnDemand Studio, open the "Files (Home)" tab.;
%put NOTE:   2. Right-click on your project folder (e.g., 'safety_oncology').;
%put NOTE:   3. Select "Download as Zip File".;
%put NOTE:   4. Save the ZIP file to your local computer.;
%put NOTE: ;
%put NOTE: ======================================================================;
%put NOTE: STEP 2: COMMIT USING YOUR LOCAL GIT CLIENT;
%put NOTE: ======================================================================;
%put NOTE:   1. Extract the downloaded ZIP to your local Git repository folder.;
%put NOTE:   2. Open a terminal (Git Bash, PowerShell, or CMD) in that folder.;
%put NOTE:   3. Run the following commands:;
%put NOTE: ;
%put NOTE:      git add .;
%put NOTE:      git commit -m "Pipeline update from SAS OnDemand";
%put NOTE:      git push origin main;
%put NOTE: ;
%put NOTE:   4. If prompted, enter your GitHub credentials or PAT.;
%put NOTE: ;
%put NOTE: ======================================================================;
%put NOTE: ALTERNATIVE: USE GITHUB WEB INTERFACE;
%put NOTE: ======================================================================;
%put NOTE:   1. Go to https://github.com/antonybevan/safety_oncology;
%put NOTE:   2. Click "Add file" -> "Upload files".;
%put NOTE:   3. Drag and drop your updated SAS programs.;
%put NOTE:   4. Add a commit message and click "Commit changes".;
%put NOTE: ;
%put NOTE: ======================================================================;
%put NOTE: PUSH INSTRUCTIONS COMPLETE;
%put NOTE: ======================================================================;
