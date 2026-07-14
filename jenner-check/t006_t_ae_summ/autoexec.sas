/* cap input rows for the captured run */
options obs=100;

/* ---------------------------------------------------------------------------
   Bundle-local stand-in for the repo's 00_config.sas environment.
   t_ae_summ.sas opens with %load_config and writes through %ods_setup /
   %ods_close. For an isolated, file-free run we make those no-ops (routing
   ODS to LISTING), set &STUDYID, and stand up a small mock ADAM library
   (adsl, adae) in WORK. The table body of t_ae_summ.sas is unchanged.
--------------------------------------------------------------------------- */
%macro load_config; %mend load_config;
%macro ods_setup(type=, outpath=, style=); ods listing; %mend ods_setup;
%macro ods_close(type=); %mend ods_close;

%let STUDYID = BV-CAR20-P1;

libname adam (work);

/* Mock subject-level analysis dataset (ADSL) — Safety Population */
data adam.adsl;
    length USUBJID $12 ARMCD $20 SAFFL $1 TRT01AN 8;
    input USUBJID $ ARMCD $ SAFFL $ TRT01AN;
    datalines;
BV-01-001 DL1 Y 1
BV-01-002 DL1 Y 1
BV-01-003 DL1 Y 1
BV-01-004 DL3 Y 3
BV-01-005 DL3 Y 3
BV-01-006 DL3 Y 3
BV-01-007 DL3 Y 3
;
run;

/* Mock adverse-event analysis dataset (ADAE), treatment-emergent flagged */
data adam.adae;
    length USUBJID $12 ARMCD $20 TRTEMFL AESER $1 AETOXGRN 8 AESICAT $8;
    input USUBJID $ ARMCD $ TRTEMFL $ AESER $ AETOXGRN AESICAT $;
    datalines;
BV-01-001 DL1 Y N 2 CRS
BV-01-001 DL1 Y N 1 .
BV-01-002 DL1 Y Y 3 CRS
BV-01-003 DL1 Y N 1 ICANS
BV-01-004 DL3 Y Y 4 CRS
BV-01-004 DL3 Y N 3 ICANS
BV-01-005 DL3 Y N 2 .
BV-01-006 DL3 Y Y 3 CRS
BV-01-007 DL3 Y N 1 .
;
run;
