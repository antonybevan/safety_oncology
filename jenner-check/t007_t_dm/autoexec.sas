/* cap input rows for the captured run */
options obs=100;

/* ---------------------------------------------------------------------------
   Bundle-local stand-in for the repo's 00_config.sas environment.
   t_dm.sas opens with %load_config and writes through %ods_setup /
   %ods_close. For an isolated, file-free run we make those no-ops (routing
   ODS to LISTING) and stand up a small mock ADAM library (adsl) in WORK.
   The table body of t_dm.sas is unchanged.
--------------------------------------------------------------------------- */
%macro load_config; %mend load_config;
%macro ods_setup(type=, outpath=, style=); ods listing; %mend ods_setup;
%macro ods_close(type=); %mend ods_close;

%let OUT_TABLES = .;

libname adam (work);

/* Mock subject-level analysis dataset (ADSL) — Safety Population, DL1 & DL3 */
data adam.adsl;
    length USUBJID $12 ARMCD $20 SAFFL SEX $1 RACE $20 AGEGR1 $10 AGE 8;
    input USUBJID $ ARMCD $ SAFFL $ SEX $ RACE $ AGEGR1 $ AGE;
    datalines;
BV-01-001 DL1 Y M WHITE <65 58
BV-01-002 DL1 Y F ASIAN >=65 71
BV-01-003 DL1 Y M BLACK <65 44
BV-01-004 DL3 Y F WHITE <65 49
BV-01-005 DL3 Y M WHITE >=65 66
BV-01-006 DL3 Y F ASIAN <65 52
BV-01-007 DL3 Y M BLACK >=65 68
;
run;
