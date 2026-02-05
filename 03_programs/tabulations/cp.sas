/******************************************************************************
 * Program:      cp.sas
 * Protocol:     PBCAR20A-01
 * Purpose:      Create SDTM Cell Phenotype Domain (CP) for CAR-T Cellular Kinetics
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 * SDTM Version: 3.4
 *
 * Input:        raw.car_expansion, raw.car_persistence
 * Output:       sdtm.cp.xpt
 *
 * Regulatory:   FDA requires CP domain for CAR-T cellular kinetics (NOT in LB)
 *               Per CDISC TAUG-Cell Therapy and FDA Study Data Technical Guide
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* ============================================================================
   CP Domain: Cell Phenotype Findings
   Required for CAR-T submissions per FDA Technical Conformance Guide
   
   Key Variables:
   - CPTESTCD: Test Short Name (CARTEXP, CARTPER, TRANSEFF, CD4CD8)
   - CPTEST:   Test Name
   - CPCAT:    Category (CAR-T CELLULAR KINETICS)
   - CPMETHOD: Flow Cytometry / qPCR
   - CPSTRESN: Numeric Result
   - CPSTRESU: Result Unit (copies/μg DNA, cells/μL)
   ============================================================================ */

data cp;
    length STUDYID $20 DOMAIN $2 USUBJID $40 CPSEQ 8 CPSPID $40 
           CPCAT $50 CPTESTCD $8 CPTEST $40 CPORRES $200 CPORRESU $20 
           CPSTRESC $200 CPSTRESN 8 CPSTRESU $20 CPMETHOD $40 
           CPBLFL $1 VISITNUM 8 VISIT $40 CPDTC $20 CPDY 8;
    
    STUDYID = "PBCAR20A-01";
    DOMAIN = "CP";
    
    /* -------------------------------------------------------------------------
       Mock Data Generation (Replace with actual raw data mapping)
       In production: map from raw.car_expansion and raw.car_persistence
       ------------------------------------------------------------------------- */
    
    /* Subject 1: Complete expansion and persistence data */
    USUBJID = "PBCAR20A-01-001-0001"; CPSEQ = 1;
    CPCAT = "CAR-T CELLULAR KINETICS"; CPTESTCD = "CARTEXP"; 
    CPTEST = "CAR-T Cell Expansion (Peak)";
    CPORRES = "125000"; CPORRESU = "copies/μg DNA";
    CPSTRESC = "125000"; CPSTRESN = 125000; CPSTRESU = "copies/μg DNA";
    CPMETHOD = "qPCR"; CPBLFL = ""; VISITNUM = 101; VISIT = "DAY 7";
    CPDTC = "2026-01-15"; CPDY = 7; output;
    
    CPSEQ = 2; CPTESTCD = "CARTPER"; CPTEST = "CAR-T Cell Persistence";
    CPORRES = "85000"; CPSTRESN = 85000; VISITNUM = 102; VISIT = "DAY 14";
    CPDTC = "2026-01-22"; CPDY = 14; output;
    
    CPSEQ = 3; CPTESTCD = "CARTPER"; 
    CPORRES = "42000"; CPSTRESN = 42000; VISITNUM = 103; VISIT = "DAY 28";
    CPDTC = "2026-02-05"; CPDY = 28; output;
    
    CPSEQ = 4; CPTESTCD = "TRANSEFF"; CPTEST = "Transduction Efficiency";
    CPORRES = "45"; CPORRESU = "%"; CPSTRESC = "45"; CPSTRESN = 45; CPSTRESU = "%";
    CPMETHOD = "Flow Cytometry"; VISITNUM = 1; VISIT = "BASELINE";
    CPDTC = "2026-01-08"; CPDY = 0; CPBLFL = "Y"; output;
    
    CPSEQ = 5; CPTESTCD = "CD4CD8"; CPTEST = "CD4:CD8 Ratio";
    CPORRES = "2.1"; CPORRESU = "RATIO"; CPSTRESC = "2.1"; CPSTRESN = 2.1; CPSTRESU = "RATIO";
    VISITNUM = 1; CPDTC = "2026-01-08"; CPDY = 0; CPBLFL = "Y"; output;
    
    /* Subject 2: Lower expansion */
    USUBJID = "PBCAR20A-01-001-0002"; CPSEQ = 1; CPBLFL = "";
    CPTESTCD = "CARTEXP"; CPTEST = "CAR-T Cell Expansion (Peak)";
    CPORRES = "75000"; CPSTRESN = 75000; CPORRESU = "copies/μg DNA"; CPSTRESU = "copies/μg DNA";
    CPMETHOD = "qPCR"; VISITNUM = 101; VISIT = "DAY 7";
    CPDTC = "2026-01-16"; CPDY = 7; output;
    
    CPSEQ = 2; CPTESTCD = "CARTPER"; CPTEST = "CAR-T Cell Persistence";
    CPORRES = "35000"; CPSTRESN = 35000; VISITNUM = 103; VISIT = "DAY 28";
    CPDTC = "2026-02-06"; CPDY = 28; output;
    
    /* Labels per CDISC */
    label 
        STUDYID  = "Study Identifier"
        DOMAIN   = "Domain Abbreviation"
        USUBJID  = "Unique Subject Identifier"
        CPSEQ    = "Sequence Number"
        CPSPID   = "Sponsor-Defined Identifier"
        CPCAT    = "Category for Cell Phenotype"
        CPTESTCD = "Cell Phenotype Test Short Name"
        CPTEST   = "Cell Phenotype Test Name"
        CPORRES  = "Result or Finding in Original Units"
        CPORRESU = "Original Units"
        CPSTRESC = "Character Result/Finding in Std Format"
        CPSTRESN = "Numeric Result/Finding in Std Units"
        CPSTRESU = "Standard Units"
        CPMETHOD = "Method of Test or Examination"
        CPBLFL   = "Baseline Flag"
        VISITNUM = "Visit Number"
        VISIT    = "Visit Name"
        CPDTC    = "Date/Time of Collection"
        CPDY     = "Study Day of Collection"
    ;
run;

/* Create permanent SAS dataset */
data sdtm.cp;
    set cp;
run;

/* Export to XPT */
libname xpt xport "&SDTM_PATH/cp.xpt";
data xpt.cp;
    set cp;
run;
libname xpt clear;

proc print data=cp(obs=10);
    title "SDTM CP Domain - Cell Phenotype (CAR-T Cellular Kinetics)";
run;

proc freq data=cp;
    tables CPTESTCD * VISIT / nopercent norow nocol;
    title "CP Test by Visit Distribution";
run;
