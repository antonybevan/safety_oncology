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
    else if not missing(CARTDT) then REL_END = 30; /* Representative end of window for ongoing */
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
    yaxis label="Subject ID";
    keylegend / title="Adverse Event (PT)";
run;

%ods_close(type=GRAPH);


