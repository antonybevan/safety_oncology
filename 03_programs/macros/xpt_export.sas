/******************************************************************************
 * Macro:        xpt_export
 * Purpose:      Portable SAS XPT (XPORT) export helper.
 *               Wraps libname xport with forward-slash paths.
 *               Compatible with SAS 9.4 (Windows/Linux) and SAS OnDemand.
 *
 * Parameters:
 *   ds       — Source two-level dataset name (e.g. sdtm.ae, adam.adsl)
 *   xptpath  — Full path to output XPT file (use &SDTM_PATH or &ADAM_PATH)
 *   outname  — One-level output dataset name in the XPT file (<=8 chars)
 *
 * Notes:
 *   SAS XPORT engine creates V5 transport format by default in SAS 9.4.
 *   Variable names >8 chars are automatically truncated — pre-check labels.
 *   On SAS OnDemand, libname xport writes to the SAS server filesystem
 *   (accessible through the Files pane).
 *
 * Usage:
 *   %xpt_export(ds=sdtm.ae,  xptpath=&SDTM_PATH/ae.xpt,  outname=ae);
 *   %xpt_export(ds=adam.adsl, xptpath=&ADAM_PATH/adsl.xpt, outname=adsl);
 ******************************************************************************/

%macro xpt_export(ds=, xptpath=, outname=);
    %if %length(&ds) = 0 or %length(&xptpath) = 0 or %length(&outname) = 0 %then %do;
        %put ERROR: [XPT_EXPORT] Missing required parameter. ds=&ds xptpath=&xptpath outname=&outname;
        %return;
    %end;

    /* Verify source dataset exists before attempting export */
    %if not %sysfunc(exist(&ds)) %then %do;
        %put WARNING: [XPT_EXPORT] Source dataset &ds does not exist. Skipping XPT export.;
        %return;
    %end;

    libname _xpt_ xport "&xptpath";
    data _xpt_.&outname;
        set &ds;
    run;
    libname _xpt_ clear;
    %put NOTE: [XPT_EXPORT] Exported &ds to &xptpath;
%mend xpt_export;
