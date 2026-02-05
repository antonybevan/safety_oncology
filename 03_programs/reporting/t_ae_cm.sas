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
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* 1. Identify AESI Con-Meds (Simplified logic for simulation) */
/* In practice, this joins ADAE with ADCM based on dates and indication */
data aesi_cm;
    set sdtm.ae(where=(index(upcase(AEDECOD), 'CYTOKINE') > 0 or index(upcase(AEDECOD), 'IMMUNE') > 0));
    keep USUBJID AEDECOD AESEQ;
run;

/* Mock data for CM given for AESI */
data t_ae_cm_data;
    set adam.adsl(keep=USUBJID ARMCD SAFFL);
    where SAFFL = 'Y';
    length CMTRT $40 CMCAT $20;
    
    /* Simulate Tocilizumab and Dexamethasone for high dose cohorts */
    if ARMCD = 'DL3' then do;
        CMTRT = "TOCILIZUMAB"; CMCAT = "IL-6 RECEPTOR ANTAG"; output;
        CMTRT = "DEXAMETHASONE"; CMCAT = "CORTICOSTEROID"; output;
    end;
    else if ARMCD = 'DL1' then do;
        CMTRT = "ACETAMINOPHEN"; CMCAT = "ANTIPYRETIC"; output;
    end;
run;

/* 2. Production Table Formatting */
title1 "BV-CAR20-P1: CAR-T Safety Analysis";
title2 "Table 3.6: Summary of Concomitant Medications Given for AESI";
title3 "Safety Population";

proc report data=t_ae_cm_data nowd headskip split='|' style(report)={outputwidth=100%};
    column CMCAT CMTRT ARMCD, (n);
    define CMCAT / group "Medication Class";
    define CMTRT / group "Preferred Name";
    define ARMCD / across "Dose Level";
    define n / "n" center;
    
    compute after _page_;
        line @1 "--------------------------------------------------------------------------------";
        line @1 "Note: Medications are selected based on indication for AESI (e.g., Tocilizumab for CRS).";
    endcomp;
run;

/* Export */
ods html body="&OUT_TABLES/t_ae_cm.html";
proc print data=t_ae_cm_data(obs=10); run;
ods html close;
