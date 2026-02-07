/******************************************************************************
 * Program:      GIT_PUSH.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Push Instructions for SAS OnDemand
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 * SAS Version:  9.4+ / SAS OnDemand (Linux)
 *
 * Note:         SAS OnDemand does not have Git CLI or PROC GIT.
 *               This program provides instructions for pushing your work.
 ******************************************************************************/

%put NOTE: ======================================================================;
%put NOTE: GIT PUSH - WORKAROUND FOR SAS ONDEMAND;
%put NOTE: ======================================================================;
%put NOTE: ;
%put NOTE: SAS OnDemand does not support Git push directly.;
%put NOTE: Use one of these methods to push your changes:;
%put NOTE: ;
%put NOTE: METHOD 1 - Download and Push Locally:;
%put NOTE:   1. Right-click your project folder in the Files pane;
%put NOTE:   2. Select "Download as Zip File";
%put NOTE:   3. Extract to your local Git repository;
%put NOTE:   4. Run: git add . && git commit -m "Update" && git push;
%put NOTE: ;
%put NOTE: METHOD 2 - GitHub Web Interface:;
%put NOTE:   1. Download individual modified files from Files pane;
%put NOTE:   2. Go to github.com/antonybevan/safety_oncology;
%put NOTE:   3. Navigate to the file location;
%put NOTE:   4. Click "Edit" (pencil icon) or "Add file" -> "Upload files";
%put NOTE:   5. Paste/upload your changes and commit;
%put NOTE: ;
%put NOTE: ======================================================================;
