/******************************************************************************
 * Program:      GIT_PUSH.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Push Changes to GitHub (SAS OnDemand Info)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 * SAS Version:  9.4+ / SAS OnDemand (Linux)
 *
 * LIMITATION:   Direct push from SAS OnDemand is not supported.
 *               SAS ODA does not have Git CLI or PROC GIT.
 ******************************************************************************/

%put NOTE: ======================================================================;
%put NOTE: GIT PUSH - SAS ONDEMAND LIMITATION;
%put NOTE: ======================================================================;
%put NOTE: ;
%put NOTE: SAS OnDemand does not support direct Git push.;
%put NOTE: ;
%put NOTE: TO PUSH YOUR CHANGES:;
%put NOTE: ;
%put NOTE:   1. Right-click your project folder in the Files pane;
%put NOTE:   2. Select "Download as Zip File";
%put NOTE:   3. On your local machine, extract and commit using Git:;
%put NOTE:      git add .;
%put NOTE:      git commit -m "Update from SAS OnDemand";
%put NOTE:      git push;
%put NOTE: ;
%put NOTE: OR use GitHub web interface:;
%put NOTE:   1. Go to github.com/antonybevan/safety_oncology;
%put NOTE:   2. Click "Add file" -> "Upload files";
%put NOTE:   3. Drag your modified files and commit;
%put NOTE: ;
%put NOTE: ======================================================================;
