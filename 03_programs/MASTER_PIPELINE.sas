/******************************************************************************
 * Program:      MASTER_PIPELINE.sas
 * Purpose:      Execute full project flow (SDTM -> ADaM) in one click
 ******************************************************************************/

%macro load_config;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
   %else %if %symexist(_SASPROGRAMFILE) %then %do;
      %let path = %sysfunc(prxchange(s/(.*)[\/\\].*$/$1/, 1, &_SASPROGRAMFILE));
      %if %sysfunc(fileexist(&path/00_config.sas)) %then %include "&path/00_config.sas";
      %else %if %sysfunc(fileexist(&path/../00_config.sas)) %then %include "&path/../00_config.sas";
   %end;
%mend;
%load_config;

%put NOTE: Starting Master Pipeline in &PROJ_ROOT;

/* 0. Generate Raw Data (SAS Native) */
%include "&PROJ_ROOT/03_programs/data_gen/generate_data.sas";

/* 1. Force-Import SDTM Baseline */
%macro import_csv(domain);
   proc import datafile="&LEGACY_PATH/raw_&domain..csv"
               out=sdtm.&domain
               dbms=csv replace;
               getnames=yes;
   run;
%mend;

%import_csv(dm);
%import_csv(ex);
%import_csv(ae);
%import_csv(lb);
%import_csv(rs);
%import_csv(suppae);

/* 2. Execute ADaM Analysis */
%include "&PROJ_ROOT/03_programs/analysis/adsl.sas";
%include "&PROJ_ROOT/03_programs/analysis/adex.sas";
%include "&PROJ_ROOT/03_programs/analysis/adae.sas";
%include "&PROJ_ROOT/03_programs/analysis/adlb.sas";
%include "&PROJ_ROOT/03_programs/analysis/adrs.sas";

/* 3. Validation Audit */
proc sql;
   title "BV-CAR20-P1: Final Data Integrity Audit";
   select 'SDTM.DM' as Table, count(*) as Records from sdtm.dm
   union select 'ADaM.ADSL', count(*) from adam.adsl
   union select 'ADaM.ADAE', count(*) from adam.adae
   union select 'ADaM.ADLB', count(*) from adam.adlb;
quit;
