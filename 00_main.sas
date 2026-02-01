/******************************************************************************
 * Master Gateway: 00_main.sas
 * Purpose:       Execute the full Clinical Pipeline from Root
 ******************************************************************************/
%macro run_master;
    %local path;
    %if %symexist(_SASPROGRAMFILE) %then %do;
        %let path = %sysfunc(prxchange(s/(.*)[\/\\].*$/$1/, 1, &_SASPROGRAMFILE));
    %end;
    %else %let path = .;

    %if %sysfunc(fileexist(&path/03_programs/00_main.sas)) %then %do;
        %include "&path/03_programs/00_main.sas";
    %end;
    %else %do;
        %put ERROR: Master Driver not found in sub-folder. Check directory structure.;
    %end;
%mend;
%run_master;
