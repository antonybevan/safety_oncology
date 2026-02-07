/******************************************************************************
 * Program:      gen_metadata.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Million-Dollar Define.xml Metadata (Enhanced)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* 1. Extract Variable Metadata from ADaM Library */
proc contents data=adam._all_ noprint out=adam_meta_raw(keep=LIBNAME MEMNAME NAME TYPE LENGTH VARNUM LABEL);
run;

proc sort data=adam_meta_raw out=adam_meta;
    by MEMNAME VARNUM;
run;

/* 2. Format for Submission Readiness with Origin/Method/Role */
data define_metadata;
    set adam_meta;
    length Variable $8 Label $40 Dataset $8 DataType $4 Origin $15 Method $200 Role $15;
    
    Variable = NAME;
    Label    = LABEL;
    Dataset  = MEMNAME;
    if TYPE=1 then DataType="Num"; else DataType="Char";

    /* Default Origin & Role */
    Origin = "Derived";
    Role   = "Analysis";

    /* Specific Variable Logic (Regulatory Hardening) */
    if Variable in ('USUBJID', 'STUDYID', 'SITEID', 'SUBJID') then do;
        Origin = "Predecessor";
        Role   = "Identifier";
        Method = "Direct map from SDTM.DM";
    end;
    else if Variable in ('ARM', 'ARMCD', 'AGE', 'SEX', 'RACE') then do;
        Origin = "Predecessor";
        Method = "Direct map from SDTM.DM";
    end;
    else if Variable in ('TRTSDT', 'TRTEDT', 'CARTDT', 'LDSTDT') then do;
        Method = "Derived from first/last exposure in SDTM.EX";
    end;
    else if Variable = 'DLTEVALFL' then do;
        Method = "Y if SAFFL='Y' and (Treatment Duration >= 28 days or DLT reported)";
    end;
    else if Variable = 'COHORT' then do;
        Method = "NHL if SDTM.DM.DISEASE='NHL'; CLL if DISEASE in ('CLL', 'SLL')";
    end;
    else if Variable = 'EVALCRIT' then do;
        Method = "LUGANO 2016 for NHL; iwCLL 2018 for CLL";
    end;
    else if Variable = 'AGEGR1' then do;
        Method = "Pooled Age Group 1 (<65 vs >=65) per SAP §6.2";
    end;
    else if Variable = 'AESIFL' then do;
        Method = "Y if Preferred Term matches CRS, ICANS, or GVHD clusters";
    end;
    else if Variable = 'AESICAT' then do;
        Method = "Targeted category: CRS, ICANS, or GVHD";
    end;
    else if Variable = 'ASTCTGR' then do;
        Origin = "Predecessor";
        Method = "Map from SDTM.SUPPAE.QNAM='ASTCTGR'";
    end;
    else if Variable = 'TRTEMFL' then do;
        Method = "Y if Analysis Start Date >= Treatment Start Date (Regimen)";
    end;
    else if Variable = 'INFFL' then do;
        Method = "Y if Preferred Term indicates an Infection (SAP §8.2.2)";
    end;
    else if Variable = 'PARAMCD' and Dataset = 'ADRS' then do;
        Method = "BOR (Best Response) or PFS (Progression-Free Survival)";
    end;
    else if Variable = 'CNSR' then do;
        Method = "0 for PD event; 1 for Censoring per SAP Table 6";
    end;

    if missing(Method) then Method = "Per ADaM IG / Study SAP";

    drop LIBNAME NAME TYPE LABEL VARNUM;
run;

/* 3. Output to HTML for Reviewer Guide Support */
title "BV-CAR20-P1: Enhanced ADaM Metadata (Regulatory-Grade Submission Package)";
ods html body="&OUT_META/adam_metadata_enhanced.html";
proc report data=define_metadata nowd headskip split='|' style(report)={outputwidth=100%};
    column Dataset Variable Label DataType Role Origin Method;
    define Dataset  / group "Dataset" width=8;
    define Variable / "Variable" width=8;
    define Label    / "Label" width=25;
    define Role     / "Role" width=10;
    define Origin   / "Origin" width=10;
    define Method   / "Derivation / Method" width=40 flow;
run;
ods html close;

/* Export CSV for External Define.xml Editors */
proc export data=define_metadata
    outfile="&OUT_META/adam_metadata_v2.csv"
    dbms=csv replace;
run;

%put NOTE: --------------------------------------------------;
%put NOTE: ✅ ENHANCED METADATA GENERATION COMPLETE;
%put NOTE: --------------------------------------------------;
