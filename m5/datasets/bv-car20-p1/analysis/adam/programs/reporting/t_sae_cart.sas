/******************************************************************************
 * Program:      t_sae_cart.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Table 3.7: Summary of PBCAR20A-related SAEs by Max Toxicity Grade
 * Author:       Statistical Programmer
 * Date:         2026-02-05
 * SAS Version:  9.4
 * SAP Reference: Table 12 (3.7)
 *
 * Input:        adam.adae, adam.adsl
 * Output:       Table 3.7 — SAE Summary (CAR-T Related)
 *
 * Note:         Related = events attributed to PBCAR20A (CAR-T) product
 ******************************************************************************/

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
    select a.USUBJID, a.AEDECOD, a.AETERM, a.AETOXGR, a.AETOXGRN,
           a.AESOC, a.AEREL, a.AESER, a.AESIFL, a.TRTEMFL,
           a.ASTDT, a.AENDT, a.AEOUT, a.AESEQ,
           b.ARMCD, b.ARM, b.SAFFL, b.CARTDT
    from adam.adae a
    inner join adam.adsl b on a.USUBJID = b.USUBJID
    where a.AESER = 'Y'                       /* Serious */
      and a.TRTEMFL = 'Y'                     /* Treatment-emergent */
      and a.AEREL in ('RELATED', 'POSSIBLY RELATED', 'PROBABLY RELATED')
      and a.ASTDT >= b.CARTDT                 /* On/after CAR-T infusion */
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
           coalesce(count(distinct case when MAX_GRADE = 1 then a.USUBJID else null end), 0) as GR1,
           coalesce(count(distinct case when MAX_GRADE = 2 then a.USUBJID else null end), 0) as GR2,
           coalesce(count(distinct case when MAX_GRADE = 3 then a.USUBJID else null end), 0) as GR3,
           coalesce(count(distinct case when MAX_GRADE = 4 then a.USUBJID else null end), 0) as GR4,
           coalesce(count(distinct case when MAX_GRADE = 5 then a.USUBJID else null end), 0) as GR5,
           coalesce(count(distinct a.USUBJID), 0) as TOTAL,
           calculated TOTAL / d.N * 100 as PCT format=5.1
    from sae_cart_max a
    left join denom d on a.ARMCD = d.ARMCD
    group by a.ARMCD, a.AEDECOD, d.N;
quit;

/* 6. Pre-pivot for readable table layout */
proc sql;
    create table sae_report_wide as
    select a.AEDECOD,
           a.ARMCD,
           a.GR1, a.GR2, a.GR3, a.GR4, a.GR5,
           a.TOTAL,
           a.PCT,
           catx(' ', put(a.TOTAL, 3.), cats('(', put(a.PCT, 5.1), '%)')) as Result
    from sae_counts a
    order by a.ARMCD, a.AEDECOD;
quit;

%ods_setup(type=RTF, outpath=&OUT_TABLES/t_sae_cart.rtf);

proc print data=sae_report_wide noobs label;
    var ARMCD AEDECOD GR1 GR2 GR3 GR4 GR5 Result;
    label ARMCD   = "Dose Level"
          AEDECOD = "Preferred Term"
          GR1     = "Grade 1"
          GR2     = "Grade 2"
          GR3     = "Grade 3"
          GR4     = "Grade 4"
          GR5     = "Grade 5"
          Result  = "Total n (%)";
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

%ods_close(type=RTF);

%put NOTE: ----------------------------------------------------;
%put NOTE: CAR-T RELATED SAE TABLE GENERATED;
%put NOTE: ----------------------------------------------------;

