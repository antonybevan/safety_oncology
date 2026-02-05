/******************************************************************************
 * Program:      f_swimmer.sas
 * Protocol:     PBCAR20A-01
 * Purpose:      Figure F-SW: Swimmer Plot for Progression-Free Survival
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 * SAP Reference: Table 11 (2.1/F-SW)
 *
 * Input:        adam.adrs (BOR, PFS), adam.adsl
 * Output:       Swimmer Plot showing response duration by subject
 *
 * Note:         Per SAP: "For retreatment subjects, combine initial 
 *               with retreatment data"
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* ============================================================================
   SWIMMER PLOT FOR PFS (SAP Table 11: F-SW)
   QC Level: 1
   
   Shows:
   - Duration on treatment for each subject
   - Response status (CR, PR, SD, PD)
   - Ongoing vs completed status
   ============================================================================ */

/* 1. Prepare swimmer data */
proc sql;
    create table swimmer_base as
    select a.USUBJID,
           a.ARMCD,
           a.ARM,
           a.TRTSDT,
           a.TRTEDT,
           a.CARTDT,
           coalesce(a.TRTEDT, today()) - a.TRTSDT + 1 as DURATION,
           b.AVALC as BOR,
           case when b.AVALC in ('CR', 'CRi') then 1
                when b.AVALC = 'PR' then 2
                when b.AVALC = 'SD' then 3
                when b.AVALC = 'PD' then 4
                else 5 end as BOR_ORDER,
           case when a.DTHDT ne . then 'Death'
                when c.CNSR = 0 then 'Progressed'
                else 'Ongoing' end as STATUS
    from adam.adsl a
    left join adam.adrs b on a.USUBJID = b.USUBJID and b.PARAMCD = 'BOR'
    left join adam.adrs c on a.USUBJID = c.USUBJID and c.PARAMCD = 'PFS'
    where a.SAFFL = 'Y'
    order by BOR_ORDER, calculated DURATION desc;
quit;

/* Assign subject order for plot */
data swimmer_plot;
    set swimmer_base;
    Subject_Order = _N_;
    
    /* Convert duration to weeks for display */
    Duration_Weeks = DURATION / 7;
    
    /* Response color coding */
    length Response_Color $20;
    select(BOR);
        when('CR', 'CRi') Response_Color = 'Green';
        when('PR') Response_Color = 'Blue';
        when('SD') Response_Color = 'Orange';
        when('PD') Response_Color = 'Red';
        otherwise Response_Color = 'Gray';
    end;
    
    /* Status marker */
    length Status_Symbol $10;
    select(STATUS);
        when('Death') Status_Symbol = 'X';
        when('Progressed') Status_Symbol = 'P';
        otherwise Status_Symbol = '>';
    end;
run;

/* 2. Create Swimmer Plot using SGPLOT */
ods graphics on / reset=all imagename="f_swimmer" imagefmt=png width=10in height=8in;
ods listing gpath="&OUTPUT_PATH";

proc sgplot data=swimmer_plot;
    /* Horizontal bars for duration */
    hbar Subject_Order / response=Duration_Weeks 
                         group=BOR
                         categoryorder=respdesc
                         barwidth=0.7
                         datalabel=BOR
                         datalabelpos=right;
    
    /* Reference lines for key timepoints */
    refline 4 / axis=x lineattrs=(pattern=dash color=gray) 
               label="Week 4 (Day 28)";
    refline 12 / axis=x lineattrs=(pattern=dash color=gray)
                label="Week 12";
    
    /* Axis settings */
    xaxis label="Duration (Weeks)" values=(0 to 52 by 4);
    yaxis label="Subject" display=(nolabel noticks);
    
    /* Legend */
    keylegend / title="Best Overall Response" position=bottom;
    
    /* Titles */
    title1 "Figure F-SW: Swimmer Plot — Duration of Response";
    title2 "PBCAR20A-01 Phase 1 — Safety Population";
    footnote1 "Each bar represents one subject. Bar length = duration on study.";
    footnote2 "X = Death; P = Progression; > = Ongoing at data cut.";
    footnote3 "Vertical dashed lines indicate Week 4 (DLT window) and Week 12.";
run;

ods graphics off;

/* 3. Summary table for swimmer data */
proc print data=swimmer_plot(obs=20) noobs label;
    var USUBJID ARMCD BOR Duration_Weeks STATUS;
    label USUBJID = "Subject"
          ARMCD = "Dose Level"
          BOR = "Best Response"
          Duration_Weeks = "Duration (Weeks)"
          STATUS = "Current Status";
    title "Swimmer Plot Data Summary";
run;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ SWIMMER PLOT GENERATED: f_swimmer.png;
%put NOTE: ----------------------------------------------------;
