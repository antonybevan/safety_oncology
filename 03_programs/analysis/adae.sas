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
 *
 *---------------------------------------------------------------------------
 * MODIFICATION HISTORY
 *---------------------------------------------------------------------------
 * Date        Author              Description
 * ----------  ------------------  -----------------------------------------
 * 2026-01-25  Programming Lead    Initial development
 * 2026-02-01  Programming Lead    Added DLT logic per SAP Section 8.3
 * 2026-02-05  Programming Lead    Enhanced ASTCT grading integration
 * 2026-02-08  Programming Lead    Path standardization, AESICAT derivation
 *
 *---------------------------------------------------------------------------
 * QC LOG
 *---------------------------------------------------------------------------
 * QC Level: 3 (Independent Programming)
 * QC Date:  2026-02-08
 * QC By:    Senior Programmer
 * Status:   PASS - DLT and AESI logic verified
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(03_programs/00_config.sas)) %then %include "03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
   %else %if %sysfunc(fileexist(../03_programs/00_config.sas)) %then %include "../03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../../00_config.sas)) %then %include "../../00_config.sas";
   %else %if %sysfunc(fileexist(../../03_programs/00_config.sas)) %then %include "../../03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../../../00_config.sas)) %then %include "../../../00_config.sas";
   %else %if %sysfunc(fileexist(../../../03_programs/00_config.sas)) %then %include "../../../03_programs/00_config.sas";
   %else %do;
      %put ERROR: Unable to locate 00_config.sas from current working directory.;
      %abort cancel;
   %end;
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
    length AEOUT AECONTRT $100;
    set sdtm.ae(drop=LDSTDT);
    
    /* Join ADSL variables */
    length TRT01A $200;
    if _n_ = 1 then do;
        if 0 then set adam.adsl(keep=USUBJID TRTSDT CARTDT LDSTDT TRT01A TRT01AN ARM ARMCD);
        declare hash a(dataset:'adam.adsl');
        a.defineKey('USUBJID');
        a.defineData('TRTSDT', 'CARTDT', 'LDSTDT', 'TRT01A', 'TRT01AN', 'ARM', 'ARMCD');
        a.defineDone();
    end;
    
    if a.find() ne 0 then do;
        TRTSDT = .; CARTDT = .; LDSTDT = .; TRT01A = ""; TRT01AN = .;
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
    
    /* MNC Traceability Variables (CDISC ADaM IG v1.3) */
    length SRCDOM $8 SRCVAR $20;
    SRCDOM = "AE";
    SRCVAR = "AEDECOD";
    SRCSEQ = AESEQ;
    
    /* Map AESOC and AEREL from SDTM AE */
    AESOC = strip(AESOC);
    AEREL = strip(AEREL);

    /* Study Day for AE start */
    if not missing(ASTDT) and not missing(TRTSDT) then 
        ASTDY = ASTDT - TRTSDT + (ASTDT >= TRTSDT);

    /* Treatment Emergent Flag (SAP Section 8.2.1: On/After first lymphodepletion dose) */
    if not missing(ASTDT) and not missing(LDSTDT) then do;
        if ASTDT >= LDSTDT then TRTEMFL = "Y";
        else TRTEMFL = "N";
    end;
    else TRTEMFL = "N";

    /* Lymphodepletion AE Flag (SAP §8.2.1: After LD start but before CAR-T) */
    if not missing(ASTDT) and not missing(LDSTDT) and not missing(CARTDT) then do;
        if ASTDT >= LDSTDT and ASTDT < CARTDT then LDAEFL = "Y";
        else LDAEFL = "N";
    end;
    else LDAEFL = "N";

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
    length AESICAT $10;
    AESICAT = "";
    
    if index(upcase(AEDECOD), 'CYTOKINE RELEASE') > 0 then do;
        AESIFL = "Y";
        AESICAT = "CRS";
    end;
    else if index(upcase(AEDECOD), 'NEUROTOXICITY') > 0 or
            index(upcase(AEDECOD), 'IMMUNE EFFECTOR') > 0 then do;
        AESIFL = "Y";
        AESICAT = "ICANS";
    end;
    else if index(upcase(AEDECOD), 'GRAFT') > 0 then do;
        AESIFL = "Y";
        AESICAT = "GVHD";
    end;

    /* Infection Flag (SAP §8.2.2 requirement) */
    if index(upcase(AEDECOD), 'INFECT') > 0 or 
       index(upcase(AEDECOD), 'SEPSIS') > 0 or 
       index(upcase(AEDECOD), 'PNEUMONIA') > 0 then INFFL = "Y";
    else INFFL = "N";

    /* ========================================================================
       DLT DERIVATION LOGIC (Per Protocol Section 3.8)
       Complex duration-dependent rules: 72h, 7d, 14d, 42d windows
       ======================================================================== */
    DLTFL = "N";
    length DLTREAS $100;
    DLTREAS = "";
    
    /* Calculate event duration (days) */
    if not missing(ASTDT) and not missing(AENDT) then 
        AEDUR = AENDT - ASTDT + 1;
    else AEDUR = .;
    
    /* DLT Window Check: Day 0 to Day 28 from CAR-T infusion */
    if not missing(ASTDT) and not missing(CARTDT) then do;
        DLTWINDY = ASTDT - CARTDT;
        if DLTWINDY >= 0 and DLTWINDY <= 28 then DLTWINFL = "Y";
        else DLTWINFL = "N";
    end;
    else DLTWINFL = "N";
    
    /* Only derive DLT if within DLT window */
    if DLTWINFL = "Y" then do;
        
        /* --- AESI-Specific DLT Rules --- */
        /* CRS Grade 4: Immediate DLT */
        if AESICAT = "CRS" and AETOXGRN = 4 then do;
            DLTFL = "Y";
            DLTREAS = "CRS Grade 4 (Immediate DLT)";
        end;
        /* CRS Grade 3: DLT if not resolved to Gr<=2 within 72h */
        else if AESICAT = "CRS" and AETOXGRN = 3 then do;
            if AEDUR > 3 then do;
                DLTFL = "Y";
                DLTREAS = "CRS Grade 3 not resolved within 72h";
            end;
        end;
        /* ICANS Grade 3+: DLT if not resolved to Gr<=2 within 72h */
        else if AESICAT = "ICANS" and AETOXGRN >= 3 then do;
            if AEDUR > 3 then do;
                DLTFL = "Y";
                DLTREAS = "ICANS Grade 3+ not resolved within 72h";
            end;
        end;
        /* GvHD Grade 2+: DLT if not resolved within 14 days */
        else if AESICAT = "GVHD" and AETOXGRN >= 2 then do;
            if AEDUR > 14 then do;
                DLTFL = "Y";
                DLTREAS = "GvHD Grade 2+ not resolved within 14 days";
            end;
        end;
        
        /* --- General Toxicity DLT Rules --- */
        /* Cardiac/Respiratory Grade 3: Immediate DLT */
        else if AESOC in ('Cardiac disorders', 'Respiratory, thoracic and mediastinal disorders') 
                and AETOXGRN = 3 then do;
            DLTFL = "Y";
            DLTREAS = "Cardiac/Respiratory Grade 3 (Immediate DLT)";
        end;
        /* Non-Hematologic Grade 4: Immediate DLT */
        else if AETOXGRN = 4 and AESOC not in 
                ('Blood and lymphatic system disorders', 'Investigations') then do;
            DLTFL = "Y";
            DLTREAS = "Non-Hematologic Grade 4 (Immediate DLT)";
        end;
        /* Hematologic Grade 4 (excl Lymphopenia): DLT if not resolved within 42 days */
        else if AETOXGRN = 4 and AESOC in ('Blood and lymphatic system disorders', 'Investigations')
                and upcase(AEDECOD) not in ('LYMPHOCYTE COUNT DECREASED', 'LYMPHOPENIA') then do;
            if AEDUR > 42 then do;
                DLTFL = "Y";
                DLTREAS = "Hematologic Grade 4 not resolved within 42 days";
            end;
        end;
        /* Renal/Hepatic Grade 3: DLT if not resolved within 7 days */
        else if AESOC in ('Renal and urinary disorders', 'Hepatobiliary disorders') 
                and AETOXGRN = 3 then do;
            if AEDUR > 7 then do;
                DLTFL = "Y";
                DLTREAS = "Renal/Hepatic Grade 3 not resolved within 7 days";
            end;
        end;
        /* Seizure (Any Grade): Immediate DLT */
        else if upcase(AEDECOD) in ('SEIZURE', 'CONVULSION', 'EPILEPSY') then do;
            DLTFL = "Y";
            DLTREAS = "Seizure (Any Grade - Immediate DLT)";
        end;
        /* Other Organ Grade 3: DLT if not resolved within 72h */
        else if AETOXGRN = 3 and AESIFL = "N" then do;
            if AEDUR > 3 then do;
                DLTFL = "Y";
                DLTREAS = "Other Grade 3 not resolved within 72h";
            end;
        end;
        /* Death (Grade 5): DLT if not due to underlying malignancy */
        else if AETOXGRN = 5 and AEREL not in ('NOT RELATED') then do;
            DLTFL = "Y";
            DLTREAS = "Grade 5 (Death) related to treatment";
        end;
    end;

    /* Labels */
    label 
        ASTDT    = "Analysis Start Date"
        AENDT    = "Analysis End Date"
        ASTDY    = "Analysis Relative Day"
        TRTA     = "Actual Treatment"
        TRTAN    = "Actual Treatment (N)"
        TRTEMFL  = "Trt Emergent Analysis Flag (Regimen)"
        PSTCARFL = "Post-CAR-T Infusion Flag"
        AETOXGRN = "Analysis Toxicity Grade (N)"
        AESIFL   = "Adverse Event of Special Interest Flag"
        AESICAT  = "AESI Category"
        ASTCTGR  = "ASTCT 2019 Grade"
        DLTFL    = "Dose-Limiting Toxicity Flag"
        DLTREAS  = "DLT Reason"
        DLTWINFL = "DLT Window Flag (Day 0-28)"
        AEDUR    = "Event Duration (Days)"
        INFFL    = "Infection Flag"
        AESOC    = "Primary System Organ Class"
        AEREL    = "Analysis Causality"
        AEOUT    = "Outcome of Adverse Event"
        AECONTRT = "Concomitant or Additional Therapy Given"
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


