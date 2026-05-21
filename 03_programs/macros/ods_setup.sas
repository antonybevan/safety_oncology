/******************************************************************************
 * Macro:        ods_setup / ods_close
 * Purpose:      Portable ODS output destination setup.
 *               Resolves the incompatibility between:
 *                 - SAS 9.4 local: ods rtf file=... works directly
 *                 - SAS OnDemand:  ods rtf file=... also works via server path
 *               Both environments support: ods rtf, ods html5, ods graphics
 *
 * COMPATIBILITY: SAS 9.4 (Windows/Linux) + SAS OnDemand for Academics
 *
 * Parameters (ods_setup):
 *   type     — output type: RTF (default) | HTML | LISTING
 *   outpath  — full output file path (e.g. &OUT_TABLES/t_ae_summ.rtf)
 *   style    — ODS style (default: journal)
 *   gpath    — path for ODS graphics images (default: &OUT_FIGURES)
 *   imgname  — base name for graphics image file (no extension)
 *   imgfmt   — image format: png (default) | svg | pdf
 *   imgw     — image width  (default: 8in)
 *   imgh     — image height (default: 6in)
 *
 * Usage (table output):
 *   %ods_setup(type=RTF, outpath=&OUT_TABLES/t_ae_summ.rtf);
 *   ... proc report ...
 *   %ods_close(type=RTF);
 *
 * Usage (figure output):
 *   %ods_setup(type=GRAPH, gpath=&OUT_FIGURES, imgname=f_km_os);
 *   ... proc sgplot / proc lifetest ...
 *   %ods_close(type=GRAPH);
 *
 * Usage (HTML output — visible in SAS ODA Results pane):
 *   %ods_setup(type=HTML, outpath=&OUT_TABLES/t_dm.html);
 *   ... proc report ...
 *   %ods_close(type=HTML);
 ******************************************************************************/

%macro ods_setup(type=RTF,
                 outpath=,
                 style=journal,
                 gpath=,
                 imgname=output,
                 imgfmt=png,
                 imgw=8in,
                 imgh=6in);

    %let type = %upcase(&type);

    /* Common options */
    options nodate nonumber ls=120 ps=60;

    %if &type = RTF %then %do;
        %if %length(&outpath) = 0 %then %do;
            %put ERROR: [ODS_SETUP] outpath is required for type=RTF.;
            %return;
        %end;
        ods rtf file="&outpath" style=&style;
    %end;
    %else %if &type = HTML or &type = HTML5 %then %do;
        %if %length(&outpath) = 0 %then %do;
            %put ERROR: [ODS_SETUP] outpath is required for type=HTML.;
            %return;
        %end;
        ods html5 body="&outpath" style=&style;
    %end;
    %else %if &type = GRAPH %then %do;
        %let _gpath = %sysfunc(coalescec(&gpath, &OUT_FIGURES));
        ods graphics on / reset=all
            imagefmt=&imgfmt
            imagename="&imgname"
            width=&imgw
            height=&imgh;
        ods listing image_dpi=200 gpath="&_gpath";
    %end;
    %else %if &type = LISTING %then %do;
        ods listing;
    %end;
    %else %do;
        %put WARNING: [ODS_SETUP] Unknown type=&type. No ODS destination opened.;
    %end;
%mend ods_setup;


%macro ods_close(type=RTF);
    %let type = %upcase(&type);
    %if &type = RTF %then %do;
        ods rtf close;
    %end;
    %else %if &type = HTML or &type = HTML5 %then %do;
        ods html5 close;
    %end;
    %else %if &type = GRAPH %then %do;
        ods graphics off;
        ods listing close;
    %end;
    %else %if &type = LISTING %then %do;
        ods listing close;
    %end;
%mend ods_close;
