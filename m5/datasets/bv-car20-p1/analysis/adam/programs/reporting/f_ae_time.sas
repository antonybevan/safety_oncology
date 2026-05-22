/******************************************************************************
 * Program:      f_ae_time.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Figure 14.3.1 - Timeline of CAR-T Toxicity (CRS/ICANS)
 * Author:       Statistical Programmer
 * Date:         2026-02-01
 * SAS Version:  9.4
 ******************************************************************************/

%load_config;

/* 1. Extract AESI Timeline Data post-infusion */
data ae_timeline;
    set adam.adae;
    where AESIFL = 'Y' and not missing(CARTDT);
    
    /* Days post-infusion */
    if not missing(ASTDT) and not missing(CARTDT) then REL_START = ASTDT - CARTDT;
    else REL_START = .;

    if not missing(AENDT) and not missing(CARTDT) then REL_END = AENDT - CARTDT;
    else if not missing(CARTDT) then do;
        /* Dynamic cutoff-relative window end for ongoing events, capped at plot maximum (30 days) */
        REL_END = min(30, input("&DATA_CUTOFF", yymmdd10.) - CARTDT);
    end;
    else REL_END = .;
    
    length SUBJID_LBL $20;
    SUBJID_LBL = scan(USUBJID, -1, '-');
run;

proc sort data=ae_timeline;
    by REL_START;
run;

%ods_setup(type=GRAPH, gpath=&OUT_FIGURES, imgname=f_ae_time, imgw=8in, imgh=5in);

proc sgplot data=ae_timeline;
    highlow y=SUBJID_LBL low=REL_START high=REL_END / group=AEDECOD type=bar;
    xaxis label="Days Since CAR-T Infusion" min=-1 max=30;
    yaxis label="Subject ID" type=discrete discreteorder=data;
    keylegend / title="Adverse Event (PT)";
    title1 "Figure F-SAF1: Timeline of Adverse Events of Special Interest (AESI)";
    title2 "&STUDYID Phase 1 - Safety Population";
    footnote1 "AESIs are defined based on preferred terms for CRS, ICANS, and GVHD.";
    footnote2 "Ongoing events at data cutoff are capped at the maximum timeline window of 30 days.";
run;

%ods_close(type=GRAPH);


