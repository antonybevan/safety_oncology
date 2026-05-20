/******************************************************************************
 * Program:      t_ae_cm.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Generate Table 3.6 - Summary of Concomitant Medications Given for AESI
 * Author:       Statistical Programmer
 * Date:         2026-02-05
 * SAS Version:  9.4
 ******************************************************************************/

%load_config;

/* 1. Identify interventions associated with AESI from ADAE */
proc sql;
    create table t_ae_cm_data as
    select a.USUBJID,
           b.ARMCD,
           upcase(strip(a.AECONTRT)) length=40 as CMTRT,
           case
               when index(upcase(a.AECONTRT), 'TOCILIZUMAB') > 0 then 'IL-6 RECEPTOR ANTAG'
               when index(upcase(a.AECONTRT), 'DEXAMETHASONE') > 0 then 'CORTICOSTEROID'
               when index(upcase(a.AECONTRT), 'ACETAMINOPHEN') > 0 then 'ANTIPYRETIC'
               else 'THERAPEUTIC INTERVENTION'
           end length=30 as CMCAT
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

%ods_setup(type=RTF, outpath=&OUT_TABLES/t_ae_cm.rtf);

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

%ods_close(type=RTF);
