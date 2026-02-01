/******************************************************************************
 * Macro:        iso_to_sas
 * Purpose:      Convert ISO 8601 character dates to SAS numeric dates
 * Parameters:   iso_var - Input character variable
 *               sas_var - Output numeric variable
 ******************************************************************************/

%macro iso_to_sas(iso_var=, sas_var=);
    if not missing(&iso_var) then do;
        &sas_var = input(scan(&iso_var, 1, 'T'), yymmdd10.);
    end;
    else &sas_var = .;
%mend iso_to_sas;
