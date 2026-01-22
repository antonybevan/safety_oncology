/******************************************************************************
 * Program:      suppae.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Supplemental AE (SUPPAE) domain for ASTCT grading
 * Author:       Clinical Programming Lead
 * Date:         2026-01-22
 * SAS Version:  9.4
 * SDTM Version: 1.7 / IG v3.4
 *
 * Input:        &LEGACY_PATH/raw_ae.csv
 * Output:       &SDTM_PATH/suppae.xpt
 *
 * Notes:        ASTCT 2019 grading for CRS/ICANS stored as supplemental qualifiers
 *               per SAP Section 8.2.2 and CDISC SDTM IG v3.4
 ******************************************************************************/


proc import datafile="&LEGACY_PATH/raw_ae.csv"
    out=raw_ae
    dbms=csv
    replace;
    getnames=yes;
run;

/* First, ensure we have the actual SDTM AE domain to get the real AESEQ */
/* Note: In a real environment, AE would be run before SUPPAE */
data ae_map;
    set sdtm.ae(keep=USUBJID AETERM AESTDTC AESEQ);
run;

/* Filter raw data to AESI only and join with AE map */
proc sort data=raw_ae; by USUBJID AETERM AESTDTC; run;
proc sort data=ae_map; by USUBJID AETERM AESTDTC; run;

data aesi;
    merge raw_ae(where=(AESI_FL='Y') in=a) ae_map(in=b);
    by USUBJID AETERM AESTDTC;
    if a and b;
run;

/* Create SUPPAE for ASTCT grading */
data suppae;
    length 
        STUDYID $20
        RDOMAIN $2
        USUBJID $40
        IDVAR $8
        IDVARVAL $40
        QNAM $20
        QLABEL $40
        QVAL $200
        QORIG $20
        QEVAL $20
    ;

    set aesi;

    /* Standard Variables */
    STUDYID = "BV-CAR20-P1";
    RDOMAIN = "AE";
    USUBJID = strip(USUBJID);
    IDVAR = "AESEQ";
    IDVARVAL = strip(put(AESEQ, 8.));
    QORIG = "CRF";
    QEVAL = "";
    
    /* ASTCT Grade */
    QNAM = "ASTCTGR";
    QLABEL = "ASTCT 2019 Grade";
    
    /* Map AEDECOD to ASTCT grading system */
    if upcase(AEDECOD) contains 'CYTOKINE RELEASE' then do;
        QVAL = strip(put(AETOXGR, 1.));  /* CRS uses ASTCT 1-4 */
        output;
    end;
    else if upcase(AEDECOD) contains 'NEUROTOXICITY' then do;
        QVAL = strip(put(AETOXGR, 1.));  /* ICANS uses ASTCT 1-4 */
        output;
    end;
    else if upcase(AEDECOD) contains 'GRAFT' then do;
        QVAL = strip(put(AETOXGR, 1.));  /* GvHD grading */
        output;
    end;
    
    keep STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM QLABEL QVAL QORIG QEVAL;
run;

proc sort data=suppae;
    by USUBJID IDVARVAL;
run;

/* Create XPT */
libname xpt xport "&SDTM_PATH/suppae.xpt";
data xpt.suppae;
    set suppae;
run;
libname xpt clear;

proc print data=suppae;
    title "SDTM SUPPAE Domain - ASTCT Grading for AESI";
run;

