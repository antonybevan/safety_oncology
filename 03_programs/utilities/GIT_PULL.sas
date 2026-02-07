/* GIT_PULL.sas: Robust Download using PROC HTTP */
OPTIONS NONOTES NOSTIMER NOSOURCE NOSYNTAXCHECK;

%let repo_url = https://github.com/antonybevan/safety_oncology/archive/refs/heads/main.zip;
%let zip_file = /home/u63849890/safety_oncology.zip;

%put NOTE: Downloading via PROC HTTP...;

filename zipfile "&zip_file";

proc http 
   url="&repo_url" 
   method="GET" 
   ssl_verify_host=0
   ssl_verify_peer=0
   out=zipfile; 
run;

/* Check Download Status */
data _null_;
   if fexist('zipfile') then do;
       put "NOTE: SUCCESS! Downloaded to &zip_file";
       put "NOTE: Right-click the file and select 'Extract All'.";
   end;
   else put "ERROR: Download failed.";
run;

filename zipfile clear;
