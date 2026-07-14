/******************************************************************************
 * Bundle:  t002_macro_calc_astct
 * Source:  m5/datasets/bv-car20-p1/analysis/adam/programs/macros/calc_astct.sas
 *
 * Exercises the repo's %calc_astct autocall macro, which centralizes ASTCT
 * 2019 CAR-T toxicity grading. The macro is copied verbatim from the repo;
 * only a small caller with mock CRS/ICANS adverse-event rows is added so the
 * grading logic can run in isolation.
 ******************************************************************************/

/* ---- macro copied verbatim from macros/calc_astct.sas ---- */
%macro calc_astct(source_grade=, out_grade=);
    /* Standard map: preserve numeric portion of "GRADE X", handle case-insensitivity without leaking temporary variables */
    if index(upcase(strip(&source_grade)), 'GRADE 5') or strip(&source_grade) = '5' then &out_grade = 5;
    else if index(upcase(strip(&source_grade)), 'GRADE 4') or strip(&source_grade) = '4' then &out_grade = 4;
    else if index(upcase(strip(&source_grade)), 'GRADE 3') or strip(&source_grade) = '3' then &out_grade = 3;
    else if index(upcase(strip(&source_grade)), 'GRADE 2') or strip(&source_grade) = '2' then &out_grade = 2;
    else if index(upcase(strip(&source_grade)), 'GRADE 1') or strip(&source_grade) = '1' then &out_grade = 1;
    else &out_grade = .;
%mend calc_astct;

/* ---- small mock AESI dataset (CRS / ICANS) in the shape the macro reads ---- */
data ae_aesi;
    length USUBJID $12 AESICAT $8 AESTOXGR $10;
    input USUBJID $ AESICAT $ AESTOXGR $30.;
    datalines;
BV-01-001 CRS   Grade 1
BV-01-002 CRS   Grade 3
BV-01-003 ICANS GRADE 2
BV-01-004 ICANS grade 4
BV-01-005 CRS   5
BV-01-006 ICANS 3
BV-01-007 CRS   Not Applicable
BV-01-008 ICANS Grade 1
;
run;

/* ---- apply the repo's grading macro ---- */
data ae_graded;
    set ae_aesi;
    length ASTCTGR 8;
    %calc_astct(source_grade=AESTOXGR, out_grade=ASTCTGR);
    label ASTCTGR = 'ASTCT 2019 Analysis Grade';
run;

proc print data=ae_graded noobs label;
    title "ASTCT-graded CRS / ICANS events (calc_astct macro)";
    var USUBJID AESICAT AESTOXGR ASTCTGR;
run;

proc freq data=ae_graded;
    title "Distribution of derived ASTCT analysis grades";
    tables AESICAT*ASTCTGR / norow nocol nopercent;
run;
title;
