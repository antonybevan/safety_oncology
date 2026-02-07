/******************************************************************************
 * Program:      GIT_RECOVERY.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Git Integration Instructions for SAS OnDemand
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 *
 * NOTE: PROC GIT is not available in SAS OnDemand for Academics.
 *       Use the SAS Studio UI instead (see instructions below).
 ******************************************************************************/

%put NOTE: =====================================================;
%put NOTE: GIT INTEGRATION - SAS ONDEMAND FOR ACADEMICS;
%put NOTE: =====================================================;
%put NOTE: ;
%put NOTE: PROC GIT is NOT licensed for SAS OnDemand.;
%put NOTE: Use the SAS Studio web interface instead:;
%put NOTE: ;
%put NOTE: === INITIAL SETUP (One Time) ===;
%put NOTE: 1. Click: Options (top menu) > Manage Git Connections;
%put NOTE: 2. Click: Profiles > Add Git Profile;
%put NOTE: 3. Enter your GitHub username and email;
%put NOTE: 4. For Authentication: Select HTTPS;
%put NOTE: 5. Create a Personal Access Token at:;
%put NOTE:    https://github.com/settings/tokens;
%put NOTE: 6. Paste the token in the Password field;
%put NOTE: ;
%put NOTE: === CLONE REPOSITORY ===;
%put NOTE: 1. In the Git Repositories pane (left sidebar);
%put NOTE: 2. Click the Clone icon (folder with arrow);
%put NOTE: 3. Enter: https://github.com/antonybevan/safety_oncology.git;
%put NOTE: 4. Select target folder: /home/u63849890/safety_oncology;
%put NOTE: ;
%put NOTE: === PULL CHANGES ===;
%put NOTE: 1. Right-click the repository in Git Repositories pane;
%put NOTE: 2. Select: Pull;
%put NOTE: ;
%put NOTE: === PUSH CHANGES ===;
%put NOTE: 1. Right-click the repository in Git Repositories pane;
%put NOTE: 2. Select: Commit;
%put NOTE: 3. Enter commit message and click Commit;
%put NOTE: 4. Right-click again and select: Push;
%put NOTE: ;
%put NOTE: =====================================================;
