/******************************************************************************
 * Program:      t_sae_cart.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Table 3.7: Summary of PBCAR20A-related SAEs by Max Toxicity Grade
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 * SAP Reference: Table 12 (3.7)
 *
 * Input:        adam.adae, adam.adsl
 * Output:       Table 3.7 — SAE Summary (CAR-T Related)
 *
 * Note:         Related = events attributed to PBCAR20A (CAR-T) product
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
   SAE SUMMARY - PBCAR20A RELATED (SAP Table 12: 3.7)
   QC Level: 1
   
   Subset: SAEs that are related to PBCAR20A (CAR-T infusion)
   Excludes: SAEs related only to Lymphodepletion
   ============================================================================ */

/* 1. Get PBCAR20A-related SAEs */
proc sql;
    create table sae_cart as
    select a.*, 
           b.ARMCD, b.ARM, b.SAFFL,
           b.CARTDT
    from adam.adae a
    inner join adam.adsl b on a.USUBJID = b.USUBJID
    where a.AESER = 'Y'                      /* Serious */
      and a.TRTEMFL = 'Y'                    /* Treatment-emergent */
      and a.AEREL in ('RELATED', 'POSSIBLY RELATED', 'PROBABLY RELATED')  /* Related */
      and a.ASTDT >= b.CARTDT                /* On/after CAR-T infusion */
      and b.SAFFL = 'Y';
quit;

/* 2. Get max grade per subject/PT */
proc sql;
    create table sae_cart_max as
    select USUBJID, ARMCD, AEDECOD, 
           max(AETOXGRN) as MAX_GRADE,
           max(case when AESIFL = 'Y' then 1 else 0 end) as IS_AESI
    from sae_cart
    group by USUBJID, ARMCD, AEDECOD;
quit;

/* 3. Denominators by dose level */
proc sql;
    create table denom as
    select ARMCD, count(distinct USUBJID) as N
    from adam.adsl
    where SAFFL = 'Y' and CARTDT ne .
    group by ARMCD;
quit;

/* 4. Count SAEs by PT and Grade */
proc sql;
    create table sae_counts as
    select a.ARMCD, a.AEDECOD,
           count(distinct case when MAX_GRADE = 1 then a.USUBJID end) as GR1,
           count(distinct case when MAX_GRADE = 2 then a.USUBJID end) as GR2,
           count(distinct case when MAX_GRADE = 3 then a.USUBJID end) as GR3,
           count(distinct case when MAX_GRADE = 4 then a.USUBJID end) as GR4,
           count(distinct case when MAX_GRADE = 5 then a.USUBJID end) as GR5,
           count(distinct a.USUBJID) as TOTAL,
           calculated TOTAL / d.N * 100 as PCT format=5.1
    from sae_cart_max a
    left join denom d on a.ARMCD = d.ARMCD
    group by a.ARMCD, a.AEDECOD, d.N;
quit;

/* 5. Format for report */
data sae_report;
    set sae_counts;
    length Result $50;
    Result = catx(' ', put(TOTAL, 3.), cats('(', put(PCT, 5.1), '%)'));
run;

/* 6. Generate Table */
proc report data=sae_report nowd split='*';
    column AEDECOD ARMCD, (GR1 GR2 GR3 GR4 GR5 Result);
    define AEDECOD / group "Preferred Term" left;
    define ARMCD / across "Dose Level";
    define GR1 / "Gr 1" center;
    define GR2 / "Gr 2" center;
    define GR3 / "Gr 3" center;
    define GR4 / "Gr 4" center;
    define GR5 / "Gr 5" center;
    define Result / "n (%)" center;
    
    title1 "Table 3.7: Summary of PBCAR20A-Related Serious Adverse Events";
    title2 "By Maximum Toxicity Grade — Safety Population (CAR-T Recipients)";
    footnote1 "Includes SAEs occurring on/after CAR-T infusion attributed to PBCAR20A.";
    footnote2 "Percentages based on number of subjects receiving CAR-T at each dose level.";
    footnote3 "Subjects may be counted in multiple PTs but only once per PT at max grade.";
run;

/* 7. Overall Summary */
proc sql;
    select 'PBCAR20A-related SAEs' as Category,
           count(distinct USUBJID) as N_Subjects,
           count(*) as N_Events
    from sae_cart;
quit;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ CAR-T RELATED SAE TABLE GENERATED;
%put NOTE: ----------------------------------------------------;

