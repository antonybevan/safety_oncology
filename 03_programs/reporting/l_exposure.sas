/******************************************************************************
 * Program:      l_exposure.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Listing L-TA1: Planned and Actual Treatment Administered
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 * SAP Reference: Table 12 (3.1/L-TA1)
 *
 * Input:        sdtm.ex, adam.adsl
 * Output:       Listing of all treatment administered
 *
 * Note:         Per SAP: "Including dose level, lot number, date and time,
 *               drug name, compliance, and total quantity administered"
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

/* ============================================================================
   EXPOSURE LISTING (SAP Table 12: L-TA1)
   QC Level: 1
   
   Required columns:
   - Dose level
   - Lot number
   - Date and time
   - Drug name
   - Compliance
   - Total quantity administered
   ============================================================================ */

/* 1. Get exposure data with ADSL info */
proc sql;
    create table exposure_list as
    select a.USUBJID,
           b.ARMCD as DOSE_LEVEL,
           b.ARM,
           a.EXTRT as DRUG_NAME,
           a.EXDOSE,
           a.EXDOSU,
           a.EXSTDTC as START_DATETIME,
           a.EXENDTC as END_DATETIME,
           a.EXLOT as LOT_NUMBER,
           a.EXROUTE as ROUTE,
           /* Derive treatment phase */
           case when upcase(a.EXTRT) in ('FLUDARABINE', 'CYCLOPHOSPHAMIDE') 
                then 'Lymphodepletion'
                when upcase(a.EXTRT) = 'BV-CAR20' then 'CAR-T Infusion'
                else 'Other' end as TREATMENT_PHASE,
           /* Calculate compliance */
           case when a.EXADJ = 'DOSE REDUCTION' then 'Reduced'
                when a.EXADJ = 'DOSE DELAY' then 'Delayed'
                when a.EXADJ = 'DOSE OMITTED' then 'Omitted'
                else 'Complete' end as COMPLIANCE
    from sdtm.ex a
    left join adam.adsl b on a.USUBJID = b.USUBJID
    where b.SAFFL = 'Y'
    order by a.USUBJID, a.EXSTDTC;
quit;

/* 2. Summarize total exposure by drug */
proc sql;
    create table exposure_summary as
    select USUBJID, 
           DOSE_LEVEL,
           DRUG_NAME,
           TREATMENT_PHASE,
           count(*) as N_DOSES,
           sum(EXDOSE) as TOTAL_DOSE,
           min(START_DATETIME) as FIRST_DOSE,
           max(START_DATETIME) as LAST_DOSE
    from exposure_list
    group by USUBJID, DOSE_LEVEL, DRUG_NAME, TREATMENT_PHASE;
quit;

/* 3. Generate Listing */
proc print data=exposure_list noobs label split='*';
    var USUBJID DOSE_LEVEL TREATMENT_PHASE DRUG_NAME 
        EXDOSE EXDOSU START_DATETIME END_DATETIME 
        LOT_NUMBER ROUTE COMPLIANCE;
    label USUBJID = "Subject ID"
          DOSE_LEVEL = "Dose*Level"
          TREATMENT_PHASE = "Treatment*Phase"
          DRUG_NAME = "Drug Name"
          EXDOSE = "Dose"
          EXDOSU = "Unit"
          START_DATETIME = "Start*Date/Time"
          END_DATETIME = "End*Date/Time"
          LOT_NUMBER = "Lot*Number"
          ROUTE = "Route"
          COMPLIANCE = "Compliance*Status";
    title1 "Listing L-TA1: Planned and Actual Treatment Administered";
    title2 "&STUDYID Phase 1 — Safety Population";
    footnote1 "Source: SDTM EX Domain";
    footnote2 "Lymphodepletion: Fludarabine 30 mg/m2/day + Cyclophosphamide 500 mg/m2/day (Days -5 to -3)";
    footnote3 "CAR-T: BV-CAR20 administered on Day 0";
run;

/* 4. Summary by dose level */
proc tabulate data=exposure_summary format=8.;
    class DOSE_LEVEL TREATMENT_PHASE;
    var TOTAL_DOSE N_DOSES;
    table DOSE_LEVEL * TREATMENT_PHASE,
          (N_DOSES='N Administrations' TOTAL_DOSE='Total Dose') * (sum='');
    title1 "Table 3.1: Summary of Extent of Exposure";
    title2 "Safety Population";
run;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ EXPOSURE LISTING GENERATED;
%put NOTE: ----------------------------------------------------;


