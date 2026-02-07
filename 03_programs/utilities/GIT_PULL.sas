/* GIT_PULL.sas: Download Repository from GitHub */
OPTIONS NONOTES NOSTIMER NOSOURCE NOSYNTAXCHECK;

%let repo_url = https://github.com/antonybevan/safety_oncology/archive/refs/heads/main.zip;
%let zip_file = /home/u63849890/safety_oncology.zip;

%put NOTE: Downloading repository...;

filename zipfile "&zip_file";

proc http 
   url="&repo_url" 
   method="GET"
   followloc
   out=zipfile;
run;

data _null_;
   if fileexist("&zip_file") then do;
       put "NOTE: SUCCESS! Downloaded to &zip_file";
       put "NOTE: Right-click -> Extract All";
   end;
   else put "ERROR: Download failed.";
run;

filename zipfile clear;
