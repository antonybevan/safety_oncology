/******************************************************************************
 * Program:      t_ae_cm.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Table 3.6 - Summary of Concomitant Medications Given for AESI
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
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

/* 1. Identify interventions associated with AESI from ADAE */
proc sql;
    create table t_ae_cm_data as
    select a.USUBJID,
           b.ARMCD,
           upcase(strip(a.AECONTRT)) as CMTRT length=40,
           case
               when index(upcase(a.AECONTRT), 'TOCILIZUMAB') > 0 then 'IL-6 RECEPTOR ANTAG'
               when index(upcase(a.AECONTRT), 'DEXAMETHASONE') > 0 then 'CORTICOSTEROID'
               when index(upcase(a.AECONTRT), 'ACETAMINOPHEN') > 0 then 'ANTIPYRETIC'
               else 'THERAPEUTIC INTERVENTION'
           end as CMCAT length=30
    from adam.adae a
    inner join adam.adsl b
        on a.USUBJID = b.USUBJID
    where b.SAFFL = 'Y'
      and a.TRTEMFL = 'Y'
      and (a.AESIFL = 'Y' or a.INFFL = 'Y')
      and not missing(a.AECONTRT);
quit;

/* 2. Production Table Formatting */
title1 "&STUDYID: CAR-T Safety Analysis";
title2 "Table 3.6: Summary of Concomitant Medications Given for AESI";
title3 "Safety Population";

/* Summarize counts by medication and arm */
proc sql;
    create table t_ae_cm_summary as
    select CMCAT, CMTRT, ARMCD, count(*) as N
    from t_ae_cm_data
    group by CMCAT, CMTRT, ARMCD;
quit;

proc report data=t_ae_cm_summary nowd headskip split='|' style(report)={outputwidth=100%};
    column CMCAT CMTRT ARMCD, N;
    define CMCAT / group "Medication Class";
    define CMTRT / group "Preferred Name";
    define ARMCD / across "Dose Level";
    define N / analysis sum "n" center;
    
    compute after _page_;
        line @1 "--------------------------------------------------------------------------------";
        line @1 "Note: Medications are selected based on indication for AESI (e.g., Tocilizumab for CRS).";
    endcomp;
run;

/* Export */
ods html body="&OUT_TABLES/t_ae_cm.html";
proc print data=t_ae_cm_data(obs=10); run;
ods html close;


