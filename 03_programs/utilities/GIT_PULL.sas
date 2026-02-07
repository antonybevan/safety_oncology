/* GIT_PULL.sas: Download Full Repo as ZIP for SAS OnDemand */
OPTIONS NONOTES NOSTIMER NOSOURCE NOSYNTAXCHECK;

%let repo = https://github.com/antonybevan/safety_oncology/archive/refs/heads/main.zip;
%let zip  = /home/u63849890/safety_oncology.zip;

%put NOTE: Downloading &repo to &zip ...;

filename src URL "&repo" recfm=s;
filename dst "&zip" recfm=n;

data _null_;
   rc = fcopy('src', 'dst');
   if rc = 0 then put "NOTE: SUCCESS! Downloaded &zip.. Right-click -> Extract All.";
   else put "ERROR: Download failed (RC=" rc "). Check network.";
run;

filename src clear;
filename dst clear;
