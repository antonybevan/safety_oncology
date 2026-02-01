/******************************************************************************
 * Program:      adae.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create ADaM Adverse Event Analysis Dataset (ADAE)
 * Author:       Clinical Programming Lead
 * Date:         2026-01-25
 * SAS Version:  9.4
 * ADaM Version: 2.1 / IG v1.3
 *
 * Input:        sdtm.ae, sdtm.suppae, adam.adsl
 * Output:       adam.adae.xpt
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* 1. Get ASTCT Grades from SUPPAE */
data suppae_grades;
    set sdtm.suppae;
    where QNAM = 'ASTCTGR';
    AESEQ = input(IDVARVAL, 8.);
    ASTCTGR = QVAL;
    keep USUBJID AESEQ ASTCTGR;
run;

/* 2. Setup ADAE */
data adae;
    set sdtm.ae;
    
    /* Join ADSL variables */
    length TRT01A $200;
    if _n_ = 1 then do;
        if 0 then set adam.adsl(keep=USUBJID TRTSDT CARTDT TRT01A TRT01AN ARM ARMCD);
        declare hash a(dataset:'adam.adsl');
        a.defineKey('USUBJID');
        a.defineData('TRTSDT', 'CARTDT', 'TRT01A', 'TRT01AN', 'ARM', 'ARMCD');
        a.defineDone();
    end;
    
    if a.find() ne 0 then do;
        TRTSDT = .; CARTDT = .; TRT01A = ""; TRT01AN = .;
    end;

    /* Join SUPPAE Grades */
    if _n_ = 1 then do;
        declare hash s(dataset:'suppae_grades');
        s.defineKey('USUBJID', 'AESEQ');
        s.defineData('ASTCTGR');
        s.defineDone();
    end;
    
    if s.find() ne 0 then ASTCTGR = "";

    /* Analysis Dates */
    %iso_to_sas(iso_var=AESTDTC, sas_var=ASTDT);
    %iso_to_sas(iso_var=AEENDTC, sas_var=AENDT);
    format ASTDT AENDT date9.;

    /* Actual Treatment */
    TRTA = TRT01A;
    TRTAN = TRT01AN;

    /* Treatment Emergent Flag (Regimen-based: On/After LD Start) */
    if not missing(ASTDT) and not missing(TRTSDT) then do;
        if ASTDT >= TRTSDT then TRTEMFL = "Y";
        else TRTEMFL = "N";
    end;
    else TRTEMFL = "N";

    /* Post CAR-T Flag (Specific to Infusion) */
    if not missing(ASTDT) and not missing(CARTDT) then do;
        if ASTDT >= CARTDT then PSTCARFL = "Y";
        else PSTCARFL = "N";
    end;
    else PSTCARFL = "N";

    /* Numeric Grading - Use Centralized Macro */
    %calc_astct(source_grade=AETOXGR, out_grade=AETOXGRN);

    /* AESI Flag and DLT logic */
    AESIFL = "N";
    DLTFL = "N";
    
    if index(upcase(AEDECOD), 'CYTOKINE RELEASE') > 0 or 
       index(upcase(AEDECOD), 'NEUROTOXICITY') > 0 or
       index(upcase(AEDECOD), 'IMMUNE EFFECTOR') > 0 or
       index(upcase(AEDECOD), 'GRAFT') > 0 then do;
        AESIFL = "Y";
        
        /* ICANS 72-hour DLT Rule */
        if index(upcase(AEDECOD), 'IMMUNE EFFECTOR') > 0 or index(upcase(AEDECOD), 'NEUROTOXICITY') > 0 then do;
            if not missing(ASTDT) and not missing(AENDT) then do;
                if (AENDT - ASTDT + 1) > 3 and AETOXGRN >= 3 then DLTFL = "Y";
            end;
        end;
    end;

    /* Labels */
    label 
        ASTDT    = "Analysis Start Date"
        AENDT    = "Analysis End Date"
        TRTA     = "Actual Treatment"
        TRTAN    = "Actual Treatment (N)"
        TRTEMFL  = "Trt Emergent Analysis Flag (Regimen)"
        PSTCARFL = "Post-CAR-T Infusion Flag"
        AETOXGRN = "Analysis Toxicity Grade (N)"
        AESIFL   = "Adverse Event of Special Interest Flag"
        ASTCTGR  = "ASTCT 2019 Grade"
        DLTFL    = "Dose-Limiting Toxicity Flag"
    ;
run;

/* 3. Assign AOCCPFL (First Primary Occurrence) */
proc sort data=adae;
    by USUBJID AEDECOD ASTDT AESEQ;
run;

data adae;
    set adae;
    by USUBJID AEDECOD;
    
    if TRTEMFL = 'Y' then do;
        if first.AEDECOD then AOCCPFL = "Y";
        else AOCCPFL = "N";
    end;
    else AOCCPFL = "N";
    
    label AOCCPFL = "1st Occurrence of Preferred Term Flag";
run;

/* Create permanent SAS dataset */
data adam.adae;
    set adae;
run;

/* 4. Export to XPT */
libname xpt xport "&ADAM_PATH/adae.xpt";
data xpt.adae;
    set adae;
run;
libname xpt clear;

proc freq data=adae;
    tables TRTEMFL * AESIFL / nopercent norow nocol;
    title "Treatment Emergence vs AESI Counts";
run;
