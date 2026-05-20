/******************************************************************************
 * Program:      l_lb_grad.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Listing 16.2.8 - Grade 3/4 Laboratory Abnormalities
 * Author:       Statistical Programmer
 * Date:         2026-02-01
 * SAS Version:  9.4
 ******************************************************************************/

%load_config;

/* 1. Extract High Grade Lab Records */
data lb_grade_listing;
    set adam.adlb;
    where ATOXGRL >= 3 or ATOXGRH >= 3;
    
    length TOX_DIR $10;
    if ATOXGRL >= 3 then TOX_DIR = "LOW";
    else TOX_DIR = "HIGH";
    
    MAX_GRADE = max(ATOXGRL, ATOXGRH);
run;

proc sort data=lb_grade_listing;
    by TRTA USUBJID ADT PARAMCD;
run;

/* 2. Format Listing */
%ods_setup(type=RTF, outpath=&OUT_LISTINGS/l_lb_grad.rtf);

title1 "&STUDYID: CAR-T Clinical Review";
title2 "Listing 16.2.8: Grade 3 or 4 Laboratory Abnormalities";
title3 "Safety Population";

footnote1 "Note: Only records with NCI-CTCAE Grade 3 or 4 are displayed.";
footnote2 "ATOXGRL/H identifies the direction of the toxicity (Low/High).";

proc report data=lb_grade_listing nowd headskip split='|' style(report)={outputwidth=100%};
    column TRTA USUBJID PARAM ADT AVISIT AVAL TOX_DIR MAX_GRADE;
    define TRTA     / "Actual Treatment" group width=15;
    define USUBJID  / "Subject ID" group width=15;
    define PARAM    / "Laboratory Parameter" width=30;
    define ADT      / "Analysis Date" format=date9. width=12;
    define AVISIT   / "Visit" width=15;
    define AVAL     / "Value" width=10;
    define TOX_DIR  / "Direction" width=10 center;
    define MAX_GRADE / "Grade" width=8 center;
    
    break after USUBJID / skip;
run;

%ods_close(type=RTF);


