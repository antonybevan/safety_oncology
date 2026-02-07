/* GIT_RECOVERY.sas: Robust Recovery using PROC HTTP */
OPTIONS NONOTES NOSTIMER NOSOURCE NOSYNTAXCHECK;

%let repo_url = https://github.com/antonybevan/safety_oncology/archive/refs/heads/main.zip;
%let zip_file = /home/u63849890/safety_oncology.zip;

%put NOTE: Downloading via PROC HTTP...;

filename zipfile "&zip_file";

proc http 
   url="&repo_url" 
   method="GET" 
   out=zipfile; 
run;

/* Check Download Status */
data _null_;
   if fexist('zipfile') then do;
       put "NOTE: SUCCESS! Downloaded to &zip_file";
       put "NOTE: ";
       put "NOTE: 1. Delete old folder.";
       put "NOTE: 2. Right-click ZIP -> Extract All.";
       put "NOTE: 3. Run config.";
   end;
   else put "ERROR: Download failed.";
run;

filename zipfile clear;
