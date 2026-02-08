/******************************************************************************
 * Program:      cp.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Create SDTM Cell Phenotype Domain (CP)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-08
 * SAS Version:  9.4
 * SDTM Version: 3.4
 *
 * Input:        sdtm.cart_kinetics (preferred source)
 * Output:       sdtm.cp.xpt
 *
 * Regulatory:   CP is used for CAR-T cellular kinetics reporting.
 *               This program does not fabricate subject records.
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(03_programs/00_config.sas)) %then %include "03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
   %else %if %sysfunc(fileexist(../03_programs/00_config.sas)) %then %include "../03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../../00_config.sas)) %then %include "../../00_config.sas";
   %else %if %sysfunc(fileexist(../../03_programs/00_config.sas)) %then %include "../../03_programs/00_config.sas";
   %else %if %sysfunc(fileexist(../../../00_config.sas)) %then %include "../../../00_config.sas";
   %else %if %sysfunc(fileexist(../../../03_programs/00_config.sas)) %then %include "../../../03_programs/00_config.sas";
   %else %do;
      %put ERROR: Unable to locate 00_config.sas from current working directory.;
      %abort cancel;
   %end;
%mend;
%load_config;

%let has_ck = %sysfunc(exist(sdtm.cart_kinetics));
%let ck_has_usubjid = 0;
%let ck_has_ady = 0;
%let ck_has_vcn = 0;
%let ck_has_visit = 0;

%if &has_ck %then %do;
    proc sql noprint;
        select count(*) into :ck_has_usubjid trimmed
        from dictionary.columns
        where libname='SDTM' and memname='CART_KINETICS' and upcase(name)='USUBJID';

        select count(*) into :ck_has_ady trimmed
        from dictionary.columns
        where libname='SDTM' and memname='CART_KINETICS' and upcase(name)='ADY';

        select count(*) into :ck_has_vcn trimmed
        from dictionary.columns
        where libname='SDTM' and memname='CART_KINETICS' and upcase(name)='VCN';

        select count(*) into :ck_has_visit trimmed
        from dictionary.columns
        where libname='SDTM' and memname='CART_KINETICS' and upcase(name)='VISIT';
    quit;
%end;

/* Build CP from source kinetics data only */
%macro build_cp;
    %if (&has_ck and &ck_has_usubjid>0 and &ck_has_ady>0 and &ck_has_vcn>0) %then %do;
        data cp;
            length STUDYID $20 DOMAIN $2 USUBJID $40 CPSEQ 8 CPSPID $40
                   CPCAT $50 CPTESTCD $8 CPTEST $40 CPORRES $200 CPORRESU $20
                   CPSTRESC $200 CPSTRESN 8 CPSTRESU $20 CPMETHOD $40
                   CPBLFL $1 VISITNUM 8 VISIT $40 CPDTC $20 CPDY 8;

            set sdtm.cart_kinetics(keep=USUBJID ADY VCN
                                    %if &ck_has_visit>0 %then VISIT;);

            if missing(USUBJID) or missing(VCN) then delete;

            if _n_ = 1 then do;
                declare hash h(dataset:'sdtm.ex(where=(upcase(EXTRT)="BV-CAR20"))');
                h.defineKey('USUBJID');
                h.defineData('EXSTDTC');
                h.defineDone();
            end;

            STUDYID = "&STUDYID";
            DOMAIN = "CP";
            CPCAT = "CAR-T CELLULAR KINETICS";
            CPTESTCD = "CARTVCN";
            CPTEST = "CAR-T Vector Copy Number";
            CPMETHOD = "qPCR";

            CPSTRESN = VCN;
            CPSTRESC = strip(put(CPSTRESN, best.));
            CPORRES = CPSTRESC;
            CPORRESU = "copies/ug DNA";
            CPSTRESU = "copies/ug DNA";

            CPDY = ADY;
            VISITNUM = ADY;
            %if &ck_has_visit>0 %then %do;
                VISIT = strip(VISIT);
            %end;
            %else %do;
                VISIT = cats('DAY ', put(ADY, best.));
            %end;

            if ADY <= 0 then CPBLFL = "Y";
            else CPBLFL = "";

            CPSPID = cats(CPTESTCD, '-', put(ADY, best.));

            EXSTDTC = "";
            if h.find() = 0 and not missing(EXSTDTC) then do;
                _d0 = input(EXSTDTC, yymmdd10.);
                if not missing(_d0) then CPDTC = put(_d0 + ADY, yymmdd10.);
            end;

            label
                STUDYID  = "Study Identifier"
                DOMAIN   = "Domain Abbreviation"
                USUBJID  = "Unique Subject Identifier"
                CPSEQ    = "Sequence Number"
                CPSPID   = "Sponsor-Defined Identifier"
                CPCAT    = "Category for Cell Phenotype"
                CPTESTCD = "Cell Phenotype Test Short Name"
                CPTEST   = "Cell Phenotype Test Name"
                CPORRES  = "Result or Finding in Original Units"
                CPORRESU = "Original Units"
                CPSTRESC = "Character Result/Finding in Std Format"
                CPSTRESN = "Numeric Result/Finding in Std Units"
                CPSTRESU = "Standard Units"
                CPMETHOD = "Method of Test or Examination"
                CPBLFL   = "Baseline Flag"
                VISITNUM = "Visit Number"
                VISIT    = "Visit Name"
                CPDTC    = "Date/Time of Collection"
                CPDY     = "Study Day of Collection";

            drop ADY VCN EXSTDTC _d0;
        run;

        proc sort data=cp;
            by USUBJID CPDY CPTESTCD;
        run;

        data cp;
            set cp;
            by USUBJID;
            retain CPSEQ;
            if first.USUBJID then CPSEQ = 0;
            CPSEQ + 1;
        run;
    %end;
    %else %do;
        data cp;
            length STUDYID $20 DOMAIN $2 USUBJID $40 CPSEQ 8 CPSPID $40
                   CPCAT $50 CPTESTCD $8 CPTEST $40 CPORRES $200 CPORRESU $20
                   CPSTRESC $200 CPSTRESN 8 CPSTRESU $20 CPMETHOD $40
                   CPBLFL $1 VISITNUM 8 VISIT $40 CPDTC $20 CPDY 8;
            stop;
        run;
        %put WARNING: CP source data not available (sdtm.cart_kinetics with USUBJID/ADY/VCN). SDTM.CP created as empty shell.;
    %end;
%mend;
%build_cp;

/* Create permanent SAS dataset */
data sdtm.cp;
    set cp;
run;

/* Export to XPT */
libname xpt xport "&SDTM_PATH/cp.xpt";
data xpt.cp;
    set cp;
run;
libname xpt clear;

proc print data=cp(obs=10);
    title "SDTM CP Domain - Cell Phenotype";
run;

proc freq data=cp;
    tables CPTESTCD * VISIT / nopercent norow nocol;
    title "CP Test by Visit Distribution";
run;

