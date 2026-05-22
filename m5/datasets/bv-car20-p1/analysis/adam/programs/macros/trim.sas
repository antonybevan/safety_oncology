/******************************************************************************
 * Program:      trim.sas
 * Purpose:      Unified strip macro to remove leading and trailing blanks
 *               Dual-compatible utility for clinical pipelines
 ******************************************************************************/

%macro trim(val);
    %sysfunc(strip(&val))
%mend trim;
