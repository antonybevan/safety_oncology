/******************************************************************************
 * Macro:        iso_to_sas
 * Purpose:      Convert ISO 8601 character dates to SAS numeric dates
 * Parameters:   iso_var - Input character variable
 *               sas_var - Output numeric variable
 ******************************************************************************/

%macro iso_to_sas(iso_var=, sas_var=);
    if not missing(&iso_var) then do;
        if length(strip(scan(&iso_var, 1, 'T'))) = 10 then &sas_var = input(strip(scan(&iso_var, 1, 'T')), yymmdd10.);
        else if length(strip(scan(&iso_var, 1, 'T'))) = 7 then &sas_var = input(cats(strip(scan(&iso_var, 1, 'T')), "-01"), yymmdd10.);
        else if length(strip(scan(&iso_var, 1, 'T'))) = 4 then &sas_var = input(cats(strip(scan(&iso_var, 1, 'T')), "-01-01"), yymmdd10.);
        else &sas_var = .;
    end;
    else &sas_var = .;
%mend iso_to_sas;
