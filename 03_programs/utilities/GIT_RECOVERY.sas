/******************************************************************************
 * Program:      GIT_RECOVERY.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Download Repository from GitHub (SAS OnDemand Compatible)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 *
 * NOTE: SAS OnDemand does NOT have PROC GIT. This uses PROC HTTP instead.
 ******************************************************************************/

%let zip_url = https://github.com/antonybevan/safety_oncology/archive/refs/heads/main.zip;
%let zip_file = /home/u63849890/safety_oncology.zip;

filename out "&zip_file";

proc http url="&zip_url" method="GET" followloc out=out;
run;

data _null_;
    if fileexist("&zip_file") then put "SUCCESS: Downloaded. Right-click ZIP -> Extract All.";
    else put "ERROR: Download failed.";
run;

filename out clear;
