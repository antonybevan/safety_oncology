/******************************************************************************
 * Program:      cp.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Cell Phenotype (CP) domain placeholder
 * Author:       Professional Regulatory Lead
 * Date:         2026-02-08
 * SAS Version:  9.4
 * Note:         This domain captures CAR-T expansion and persistence data 
 *               (e.g., Flow Cytometry results). Standard practice in CAR-T.
 ******************************************************************************/

/* Environment assumed to be set by 00_main.sas -> 00_config.sas */

/* 1. Define Structure (Shell) */
data cp_structure;
    length 
        STUDYID $20 DOMAIN $2 USUBJID $40 CPSEQ 8 CPGRP $40 CPTESTCD $8 CPTEST $40
        CPORRES $20 CPORRESU $20 CPSTRESC $20 CPSTRESN 8 CPSTRESU $20 
        CPSPEC $40 CPMETHOD $40 CPDTC $10 CPDY 8 VISIT $40
    ;
    stop;
run;

/* 2. Simulation Note: In a real trial, this would merge with specialized 
      Flow Cytometry lab transfers. Here we provide the structure for 
      submission readiness. */
data sdtm.cp;
    set cp_structure;
run;

/* 3. Export to XPT */
libname xpt xport "&SDTM_PATH/cp.xpt";
data xpt.cp;
    set sdtm.cp;
run;
libname xpt clear;

%put NOTE: ✅ SDTM.CP (Cell Phenotype) Domain Structure Created;
