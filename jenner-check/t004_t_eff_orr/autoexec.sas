/* cap input rows for the captured run */
options obs=100;

/* ---------------------------------------------------------------------------
   Bundle-local stand-in for the repo's 00_config.sas environment.
   The upstream t_eff.sas opens with %load_config (which resolves project
   paths and assigns the ADAM library) and writes its table through
   %ods_setup / %ods_close. For an isolated, file-free run we:
     - define %load_config as a no-op,
     - point &STUDYID / &OUT_TABLES at harmless values,
     - route %ods_setup / %ods_close to the LISTING destination,
     - stand up a small mock ADAM library in WORK (adrs, adsl).
   The analytic body of t_eff.sas below is unchanged.
--------------------------------------------------------------------------- */
%macro load_config; %mend load_config;
%macro ods_setup(type=, outpath=, style=); ods listing; %mend ods_setup;
%macro ods_close(type=); %mend ods_close;

%let STUDYID    = BV-CAR20-P1;
%let OUT_TABLES = .;

libname adam (work);

/* Mock Best-Overall-Response and longitudinal response records (ADRS) */
data adam.adrs;
    length USUBJID $12 ARMCD $20 PARAMCD $8 AVALC $20 EFFFL $1;
    input USUBJID $ ARMCD $ PARAMCD $ AVALC $ EFFFL $;
    datalines;
BV-01-001 DL1 BOR CR Y
BV-01-002 DL1 BOR PR Y
BV-01-003 DL1 BOR SD Y
BV-01-004 DL3 BOR CR Y
BV-01-005 DL3 BOR CR Y
BV-01-006 DL3 BOR PR Y
BV-01-007 DL3 BOR PD Y
BV-01-008 DL3 BOR NE Y
BV-01-001 DL1 OVR PR Y
BV-01-004 DL3 OVR CR Y
;
run;

/* Mock subject-level analysis dataset (ADSL) matching the response subjects */
data adam.adsl;
    length USUBJID $12 ARMCD $20 EFFFL $1;
    input USUBJID $ ARMCD $ EFFFL $;
    datalines;
BV-01-001 DL1 Y
BV-01-002 DL1 Y
BV-01-003 DL1 Y
BV-01-004 DL3 Y
BV-01-005 DL3 Y
BV-01-006 DL3 Y
BV-01-007 DL3 Y
BV-01-008 DL3 Y
;
run;
