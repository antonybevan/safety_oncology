/******************************************************************************
 * Program:      ts.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Trial Summary (TS) domain
 * Author:       Professional Regulatory Lead
 * Date:         2026-02-08
 * SAS Version:  9.4
 ******************************************************************************/

/* Environment assumed to be set by 00_main.sas -> 00_config.sas */

/* 1. Get Study Start Date from DM */
proc sql noprint;
    select min(RFSTDTC) into :SSTDTC trimmed 
    from sdtm.dm;
quit;

%put NOTE: Minimum Study Start Date detected as &SSTDTC;

/* 2. Define Trial Summary Records */
data ts_list;
    length TSPARMCD $8 TSPARM $100 TSVAL $200;
    
    TSPARMCD = "SSTDTC";  TSPARM = "Study Start Date";         TSVAL = "&SSTDTC"; output;
    TSPARMCD = "STUDYID"; TSPARM = "Study Identifier";         TSVAL = "&STUDYID"; output;
    TSPARMCD = "NCTID";   TSPARM = "NCT Identifier";           TSVAL = "NCT04561234"; output;
    TSPARMCD = "STTITLE"; TSPARM = "Study Title";              TSVAL = "A Phase 1 Dose-escalation Study of PBCAR20A in NHL or CLL/SLL"; output;
    TSPARMCD = "SSTYP";   TSPARM = "Study Type";                TSVAL = "INTERVENTIONAL"; output;
    TSPARMCD = "PHASE";   TSPARM = "Study Phase";              TSVAL = "PHASE 1"; output;
    TSPARMCD = "INDIC";   TSPARM = "Indication";               TSVAL = "RELAPSED/REFRACTORY NHL OR CLL/SLL"; output;
    TSPARMCD = "TRT";     TSPARM = "Investigational Therapy";  TSVAL = "PBCAR20A"; output;
    TSPARMCD = "TDIGRP";  TSPARM = "Therapeutic Area";         TSVAL = "ONCOLOGY"; output;
    TSPARMCD = "CTAUG";   TSPARM = "Therapeutic Area User Guide"; TSVAL = "ONCOLOGY"; output;
    TSPARMCD = "CTAUG";   TSPARM = "Therapeutic Area User Guide"; TSVAL = "CELL AND GENE THERAPY"; output;
run;

/* 3. Final TS Domain */
data sdtm.ts;
    set ts_list;
    STUDYID = "&STUDYID";
    DOMAIN  = "TS";
    TSSEQ   = _n_;
    
    /* Variables required by SDTM IG */
    length TSGRPID $1 TSVALNF $1 TSVALCD $1;
    TSGRPID = "";
    TSVALNF = "";
    TSVALCD = "";
    
    label 
        STUDYID = "Study Identifier"
        DOMAIN  = "Domain Abbreviation"
        TSSEQ   = "Sequence Number"
        TSGRPID = "Group ID"
        TSPARMCD= "Trial Summary Parameter Short Name"
        TSPARM  = "Trial Summary Parameter"
        TSVAL   = "Parameter Value"
        TSVALNF = "Parameter Value Null Flavor"
        TSVALCD = "Parameter Value Code"
    ;
run;

/* 4. Export to XPT */
libname xpt xport "&SDTM_PATH/ts.xpt";
data xpt.ts;
    set sdtm.ts;
run;
libname xpt clear;

%put NOTE: ✅ SDTM.TS (Trial Summary) Domain Created;
