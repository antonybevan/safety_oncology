/******************************************************************************
 * Program:      00_main.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Master Driver for the Clinical Data Pipeline
 ******************************************************************************/

/* 1. Configuration and Library Setup */
%include "00_config.sas";

/* 2. Execute Data Generation */
%include "data_gen/generate_data.sas";

/* 3. Execute SDTM Tabulations */
%include "tabulations/dm.sas";
%include "tabulations/ex.sas";
%include "tabulations/ae.sas";
%include "tabulations/rs.sas";
%include "tabulations/suppae.sas";

/* 4. Execute ADaM Analysis Datasets */
%include "analysis/adsl.sas";
%include "analysis/adae.sas";
%include "analysis/adrs.sas";

/* 5. Execute Tables, Listings, and Figures (TLFs) */
%include "reporting/t_ae_summ.sas";

/* 6. Final Integrity Cross-Check (Auditor View) */
title "BV-CAR20-P1: End-to-End Pipeline Integrity Audit";
proc sql;
   select 'SDTM.DM' as Table, count(*) as Records from sdtm.dm
   union all select 'SDTM.AE', count(*) from sdtm.ae
   union all select 'ADAM.ADSL', count(*) from adam.adsl
   union all select 'ADAM.ADAE', count(*) from adam.adae
   union all select 'ADAM.ADRS', count(*) from adam.adrs;
quit;

%put NOTE: --------------------------------------------------;
%put NOTE: ✅ FULL PIPELINE EXECUTION COMPLETE;
%put NOTE: --------------------------------------------------;
