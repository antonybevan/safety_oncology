/******************************************************************************
 * Program:      f_cart_kinetics.sas
 * Protocol:     BV-CAR20-P1 (Full Phase 2a per Original Protocol)
 * Purpose:      CAR-T Cellular Kinetics Figures (VCN, Persistence)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 *
 * Per Protocol Sections 2.2.1, 2.3: CAR-T expansion and persistence
 ******************************************************************************/

/* Environment assumed to be set by 00_phase2a_full_driver.sas -> 00_config.sas */

/* ============================================================================
           mean=VCN_MEAN CELLS_MEAN
           std=VCN_STD CELLS_STD
           median=VCN_MEDIAN CELLS_MEDIAN;
    title "CAR-T Kinetics Summary by Timepoint";
run;

/* 2. Peak Expansion Analysis */
proc sql;
    create table peak_expansion as
    select USUBJID,
           max(VCN) as PEAK_VCN,
           max(CARTT_CELLS) as PEAK_CELLS
    from sdtm.cart_kinetics
    group by USUBJID;
quit;

proc means data=peak_expansion n mean std median q1 q3;
    var PEAK_VCN PEAK_CELLS;
    title "Peak CAR-T Expansion Summary";
run;

/* 3. Generate Kinetics Figure */
ods graphics on / reset=all imagename="f_cart_kinetics" imagefmt=png width=10in height=6in;
ods listing gpath="&OUT_FIGURES";

proc sgpanel data=sdtm.cart_kinetics;
    panelby VISIT / columns=7 novarname;
    histogram VCN / scale=count;
    title1 "Figure F-PK1: CAR-T Cell Kinetics (VCN) Over Time";
    title2 "&STUDYID Phase 1/2a — All Treated Subjects";
run;

/* 4. Spaghetti Plot - Individual Trajectories */
ods graphics on / imagename="f_cart_spaghetti" imagefmt=png width=10in height=6in;

proc sgplot data=sdtm.cart_kinetics;
    series x=ADY y=VCN / group=USUBJID lineattrs=(thickness=1) transparency=0.5;
    loess x=ADY y=VCN / lineattrs=(thickness=3 color=red);
    
    xaxis label="Study Day" values=(0 to 180 by 30);
    yaxis label="Vector Copy Number (VCN)" type=log;
    
    title1 "Figure F-PK2: Individual CAR-T Expansion Profiles";
    title2 "&STUDYID Phase 1/2a — All Treated Subjects";
    footnote1 "Red line = LOESS smooth of population trend.";
run;

ods graphics off;

/* 5. Persistence at Key Timepoints */
proc sql;
    create table persistence as
    select VISIT, ADY,
           count(distinct USUBJID) as N_Assessed,
           count(distinct case when VCN > 0 then USUBJID end) as N_Detectable,
           calculated N_Detectable / calculated N_Assessed * 100 as Persist_Rate format=5.1
    from sdtm.cart_kinetics
    group by VISIT, ADY
    order by ADY;
quit;

proc print data=persistence noobs label;
    label VISIT = "Timepoint"
          N_Assessed = "N Assessed"
          N_Detectable = "N with Detectable CAR-T"
          Persist_Rate = "Persistence Rate (%)";
    title1 "Table PK-1: CAR-T Persistence by Timepoint";
run;

%put NOTE: ----------------------------------------------------;
%put NOTE: ✅ CAR-T KINETICS FIGURES GENERATED;
%put NOTE: ----------------------------------------------------;


