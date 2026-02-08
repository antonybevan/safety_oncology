/******************************************************************************
 * Program:      gf.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Genomics Findings (GF) domain placeholder
 * Author:       Professional Regulatory Lead
 * Date:         2026-02-08
 * SAS Version:  9.4
 * Note:         This domain captures Vector Copy Number (VCN) analysis 
 *               via qPCR/ddPCR. Standard practice in CAR-T trials.
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(03_programs/00_config.sas)) %then %include "03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
   %else %if %sysfunc(fileexist(../03_programs/00_config.sas)) %then %include "../03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../../00_config.sas)) %then %include "../../00_config.sas";
   %else %if %sysfunc(fileexist(../../03_programs/00_config.sas)) %then %include "../../03_programs/00_config.sas";
   %else %do;
      %put ERROR: Unable to locate 00_config.sas.;
      %abort cancel;
   %end;
%mend;
%load_config;

/* 1. Define Structure (Shell) */
data gf_structure;
    length 
        STUDYID $20 DOMAIN $2 USUBJID $40 GFSEQ 8 GFGRP $40 GFTESTCD $8 GFTEST $40
        GFORRES $20 GFORRESU $20 GFSTRESC $20 GFSTRESN 8 GFSTRESU $20 
        GFSPEC $40 GFMETHOD $40 GFDTC $10 GFDY 8 VISIT $40
    ;
    stop;
run;

/* 2. Simulation Note: In a real trial, this would merge with specialized 
      VCN qPCR lab transfers. Here we provide the structure for 
      submission readiness per SDTM IG v3.4. */
data sdtm.gf;
    set gf_structure;
run;

/* 3. Export to XPT */
libname xpt xport "&SDTM_PATH/gf.xpt";
data xpt.gf;
    set sdtm.gf;
run;
libname xpt clear;

%put NOTE: ✅ SDTM.GF (Genomics Findings) Domain Structure Created;
