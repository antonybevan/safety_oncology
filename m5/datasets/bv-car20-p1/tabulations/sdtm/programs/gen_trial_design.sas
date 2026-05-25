/******************************************************************************
 * Program:      gen_trial_design.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Trial Design Domains (TS, TA, TE)
 * Author:       Statistical Programmer
 * Date:         2026-02-05
 ******************************************************************************/

/* Environment assumed to be set by 00_main.sas -> 00_config.sas */


/* 1. Trial Summary (TS) - Mandatory Parameters per CDISC SDTMIG v3.4 Appendix C1 */
data ts;
    length STUDYID $20 TSPARMCD $8 TSPARM $40 TSVAL $100 TSVALCD $40;
    STUDYID = "&STUDYID";

    /* Mandatory TS Parameters */
    TSPARMCD='SSTDT';   TSPARM='Study Start Date';           TSVAL='2025-01-15';                          TSVALCD=''; output;
    TSPARMCD='SENDTC';  TSPARM='Study Stop Date';            TSVAL='&DATA_CUTOFF';                        TSVALCD=''; output;
    TSPARMCD='TITLE';   TSPARM='Trial Title';                TSVAL='Clinical Safety Study of BVCAR20A';   TSVALCD=''; output;
    TSPARMCD='PHASE';   TSPARM='Trial Phase';                TSVAL='PHASE I';                  TSVALCD='C54689'; output;
    TSPARMCD='TRT';     TSPARM='Investigational Therapy';    TSVAL='BVCAR20A (BV-CAR20)';                 TSVALCD=''; output;
    TSPARMCD='INDIC';   TSPARM='Trial Indication';           TSVAL='Non-Hodgkin Lymphoma and CLL/SLL';    TSVALCD=''; output;
    TSPARMCD='OBJPRIM'; TSPARM='Trial Primary Objective';    TSVAL='Assess safety and determine MTD/RP2D of BVCAR20A'; TSVALCD=''; output;
    TSPARMCD='SPONSOR'; TSPARM='Clinical Study Sponsor';     TSVAL='BioVeRis Therapeutics';               TSVALCD=''; output;
    TSPARMCD='NARMS';   TSPARM='Planned Number of Arms';     TSVAL='3';                                   TSVALCD=''; output;
    TSPARMCD='STYPE';   TSPARM='Study Type';                 TSVAL='INTERVENTIONAL';          TSVALCD='C98388'; output;
run;

/* 2. Trial Elements (TE) */
data te;
    length STUDYID $20 ETCD $8 ELEMENT $40 TESTRL $100;
    STUDYID = "&STUDYID";
    
    ETCD="LD";     ELEMENT="Lymphodepletion"; TESTRL="Start of Fludarabine/Cyclophosphamide"; output;
    ETCD="CART";   ELEMENT="CAR-T Infusion";  TESTRL="Start of BVCAR20A Infusion"; output;
    ETCD="FU";     ELEMENT="Follow-Up";       TESTRL="End of CAR-T Infusion"; output;
run;

/* 3. Trial Arms (TA) — All 3 protocol arms must be listed (including DL2 even if skipped) */
data ta;
    length STUDYID $20 ARMCD $8 ARM $200 TAETORD 8 ETCD $8;
    STUDYID = "&STUDYID";

    /* Dose Level 1 */
    ARMCD='DL1'; ARM='DL1: 1x10E6 cells/kg';   TAETORD=1; ETCD='LD';   output;
    ARMCD='DL1'; ARM='DL1: 1x10E6 cells/kg';   TAETORD=2; ETCD='CART'; output;
    ARMCD='DL1'; ARM='DL1: 1x10E6 cells/kg';   TAETORD=3; ETCD='FU';   output;

    /* Dose Level 2 (skipped per SRC recommendation — must still appear in TA per SDTM IG) */
    ARMCD='DL2'; ARM='DL2: 3x10E6 cells/kg';   TAETORD=1; ETCD='LD';   output;
    ARMCD='DL2'; ARM='DL2: 3x10E6 cells/kg';   TAETORD=2; ETCD='CART'; output;
    ARMCD='DL2'; ARM='DL2: 3x10E6 cells/kg';   TAETORD=3; ETCD='FU';   output;

    /* Dose Level 3 */
    ARMCD='DL3'; ARM='DL3: 480x10E6 cells';    TAETORD=1; ETCD='LD';   output;
    ARMCD='DL3'; ARM='DL3: 480x10E6 cells';    TAETORD=2; ETCD='CART'; output;
    ARMCD='DL3'; ARM='DL3: 480x10E6 cells';    TAETORD=3; ETCD='FU';   output;
run;

/* Export to SDTM library */
data sdtm.ts; set ts; run;
data sdtm.te; set te; run;
data sdtm.ta; set ta; run;

/* Export to XPT for submission package */
%xpt_export(ds=ts, xptpath=&SDTM_PATH/ts.xpt, outname=ts);
%xpt_export(ds=te, xptpath=&SDTM_PATH/te.xpt, outname=te);
%xpt_export(ds=ta, xptpath=&SDTM_PATH/ta.xpt, outname=ta);

%put NOTE: --------------------------------------------------;
%put NOTE: TRIAL DESIGN DOMAINS (TS, TA, TE) GENERATED;
%put NOTE: --------------------------------------------------;


