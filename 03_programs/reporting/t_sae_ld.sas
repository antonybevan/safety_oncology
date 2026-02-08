/******************************************************************************
 * Program:      t_sae_ld.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Table 3.8: Summary of Lymphodepletion-related SAEs by Max Grade
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 * SAP Reference: Table 12 (3.8)
 *
 * Input:        adam.adae, adam.adsl
 * Output:       Table 3.8 — SAE Summary (LD Related)
 *
 * Note:         Related = events attributed to Lymphodepletion chemotherapy
 *               (Fludarabine + Cyclophosphamide)
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
   SAE SUMMARY - LYMPHODEPLETION RELATED (SAP Table 12: 3.8)
   QC Level: 1
   
   Subset: SAEs occurring during LD period or attributed to LD chemo
   LD Period: Day -5 to Day -1 (before CAR-T infusion)
   ============================================================================ */

/* 1. Get Lymphodepletion-related SAEs */
proc sql;
    create table sae_ld as
    select a.*, 
           b.ARMCD, b.ARM, b.SAFFL,
           b.TRTSDT as LD_START,
           b.CARTDT
    from adam.adae a
    inner join adam.adsl b on a.USUBJID = b.USUBJID
    where a.AESER = 'Y'                      /* Serious */
      and a.TRTEMFL = 'Y'                    /* Treatment-emergent */
      and (
          /* Occurring during LD period */
          (a.ASTDT >= b.TRTSDT and a.ASTDT < coalesce(b.CARTDT, b.TRTSDT + 5))
          or
          /* Or explicitly attributed to LD chemotherapy */
          upcase(a.AECONTRT) contains 'FLUDARABINE'
          or upcase(a.AECONTRT) contains 'CYCLOPHOSPHAMIDE'
      )
      and b.SAFFL = 'Y';
quit;

/* 2. Get max grade per subject/PT */
proc sql;
    create table sae_ld_max as
    select USUBJID, ARMCD, AEDECOD, 
           max(AETOXGRN) as MAX_GRADE
    from sae_ld
    group by USUBJID, ARMCD, AEDECOD;
quit;

/* 3. Denominators by dose level (all who received LD) */
proc sql;
    create table denom_ld as
    select ARMCD, count(distinct USUBJID) as N
    from adam.adsl
    where SAFFL = 'Y'  /* All who started LD */
    group by ARMCD;
quit;

/* 4. Count SAEs by PT and Grade */
proc sql;
    create table sae_ld_counts as
    select a.ARMCD, a.AEDECOD,
           count(distinct case when MAX_GRADE = 1 then a.USUBJID end) as GR1,
           count(distinct case when MAX_GRADE = 2 then a.USUBJID end) as GR2,
           count(distinct case when MAX_GRADE = 3 then a.USUBJID end) as GR3,
           count(distinct case when MAX_GRADE = 4 then a.USUBJID end) as GR4,
           count(distinct case when MAX_GRADE = 5 then a.USUBJID end) as GR5,
           count(distinct a.USUBJID) as TOTAL,
           calculated TOTAL / d.N * 100 as PCT format=5.1
    from sae_ld_max a
    left join denom_ld d on a.ARMCD = d.ARMCD
    group by a.ARMCD, a.AEDECOD, d.N;
quit;

/* 5. Format for report */
data sae_ld_report;
    set sae_ld_counts;
    length Result $50;
    Result = catx(' ', put(TOTAL, 3.), cats('(', put(PCT, 5.1), '%)'));
run;

/* 6. Generate Table */
proc report data=sae_ld_report nowd split='*';
    column AEDECOD ARMCD, (GR1 GR2 GR3 GR4 GR5 Result);
    define AEDECOD / group "Preferred Term" left;
    define ARMCD / across "Dose Level";
    define GR1 / "Gr 1" center;
    define GR2 / "Gr 2" center;
    define GR3 / "Gr 3" center;
    define GR4 / "Gr 4" center;
    define GR5 / "Gr 5" center;
    define Result / "n (%)" center;
    
    title1 "Table 3.8: Summary of Lymphodepletion-Related Serious Adverse Events";
    title2 "By Maximum Toxicity Grade — Safety Population";
    footnote1 "Includes SAEs occurring during LD period (Days -5 to -1) or attributed to LD chemotherapy.";
    footnote2 "LD regimen: Fludarabine 30 mg/m2/day + Cyclophosphamide 500 mg/m2/day.";
    footnote3 "Percentages based on number of subjects receiving LD at each dose level.";
run;

/* 7. Overall Summary */
proc sql;
    select 'Lymphodepletion-related SAEs' as Category,
           count(distinct USUBJID) as N_Subjects,
           count(*) as N_Events
    from sae_ld;
quit;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ LYMPHODEPLETION-RELATED SAE TABLE GENERATED;
%put NOTE: ----------------------------------------------------;

