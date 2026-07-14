/******************************************************************************
 * Bundle:  t003_macro_iso_to_sas
 * Source:  m5/datasets/bv-car20-p1/analysis/adam/programs/macros/iso_to_sas.sas
 *
 * Exercises the repo's %iso_to_sas autocall macro, which converts ISO 8601
 * character dates (full, YYYY-MM, and YYYY partial dates) to SAS numeric
 * dates. The macro is copied verbatim from the repo; only a small caller with
 * mock EX-domain treatment dates is added so the conversion can run in
 * isolation.
 ******************************************************************************/

/* ---- macro copied verbatim from macros/iso_to_sas.sas ---- */
%macro iso_to_sas(iso_var=, sas_var=);
    if not missing(&iso_var) then do;
        /* Dynamic temporary variable to avoid collision on multiple macro invocations */
        _tmp_&sas_var = strip(scan(&iso_var, 1, 'T'));
        if length(strip(_tmp_&sas_var)) > 0 then do;
            if substr(strip(_tmp_&sas_var), length(strip(_tmp_&sas_var)), 1) = '-' then
                _tmp_&sas_var = substr(strip(_tmp_&sas_var), 1, length(strip(_tmp_&sas_var))-1);
        end;

        if length(strip(_tmp_&sas_var)) = 10 then &sas_var = input(strip(_tmp_&sas_var), yymmdd10.);
        else if length(strip(_tmp_&sas_var)) = 7 then &sas_var = input(cats(strip(_tmp_&sas_var), "-01"), yymmdd10.);
        else if length(strip(_tmp_&sas_var)) = 4 then &sas_var = input(cats(strip(_tmp_&sas_var), "-01-01"), yymmdd10.);
        else &sas_var = .;

        drop _tmp_&sas_var;
    end;
    else &sas_var = .;
%mend iso_to_sas;

/* ---- small mock EX-domain rows with ISO 8601 dates of varying precision ---- */
data ex;
    length USUBJID $12 EXTRT $16 EXSTDTC $19;
    input USUBJID $ EXTRT $ EXSTDTC $19.;
    datalines;
BV-01-001 BV-CAR20     2026-01-15
BV-01-002 FLUDARABINE  2026-02-03T09:30
BV-01-003 BV-CAR20     2026-03
BV-01-004 BV-CAR20     2026
BV-01-005 CYCLOPHOS    2026-04-20T14:00:00
BV-01-006 BV-CAR20     .
;
run;

/* ---- convert ISO treatment start dates to SAS dates via the repo macro ---- */
data ex_dates;
    set ex;
    format EXSTDT date9.;
    %iso_to_sas(iso_var=EXSTDTC, sas_var=EXSTDT);
    label EXSTDT = 'Exposure Start Date (SAS)';
run;

proc print data=ex_dates noobs label;
    title "ISO 8601 -> SAS date conversion (iso_to_sas macro)";
    var USUBJID EXTRT EXSTDTC EXSTDT;
run;
title;
