/******************************************************************************
 * Macro:        iso_to_sas
 * Purpose:      Convert ISO 8601 character dates to SAS numeric dates
 * Parameters:   iso_var - Input character variable
 *               sas_var - Output numeric variable
 ******************************************************************************/

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
