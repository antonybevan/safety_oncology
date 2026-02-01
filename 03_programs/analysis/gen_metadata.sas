/******************************************************************************
 * Program:      gen_metadata.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Metadata Skeleton for ADaM Datasets (Define.xml support)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-01
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* 1. Extract Variable Metadata from ADaM Library */
proc contents data=adam._all_ noprint out=adam_meta(keep=LIBNAME MEMNAME NAME TYPE LENGTH VARNUM LABEL);
run;

proc sort data=adam_meta;
    by MEMNAME VARNUM;
run;

/* 2. Format for Submission Readiness */
data define_metadata;
    set adam_meta;
    rename MEMNAME=Dataset NAME=Variable LABEL=Label;
    if TYPE=1 then DataType="Num"; else DataType="Char";
    drop TYPE;
run;

/* 3. Output to HTML for Reviewer Guide Support */
title "PBCAR20A-01: ADaM Metadata Repository (Define.xml Skeleton)";
ods html body="&OUT_META/adam_metadata.html";
proc report data=define_metadata nowd headskip split='|';
    column Dataset Variable Label DataType Length;
    define Dataset / group "Analysis Dataset";
    define Variable / "Variable Name";
    define Label / "Variable Label";
    define DataType / "Type";
    define Length / "Length";
run;
ods html close;

/* Export CSV for external Define.xml editors */
proc export data=define_metadata
    outfile="&OUT_META/adam_metadata.csv"
    dbms=csv replace;
run;
