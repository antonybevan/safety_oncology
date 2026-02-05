/******************************************************************************
 * Program:      generate_phase2a_full.sas
 * Protocol:     PBCAR20A-01 (Full Phase 2a per Original Protocol)
 * Purpose:      Generate Complete Phase 2a Synthetic Data per Protocol V5.0
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 *
 * Note:         Full implementation of ORIGINAL protocol before SAP descoped.
 *               Includes all 3 expansion arms (A, B, C) per Protocol Section 3.1.2
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* ============================================================================
   FULL PHASE 2A DATA GENERATION PER ORIGINAL PROTOCOL V5.0
   
   Arm Structure (Protocol Section 3.1.2):
   - Phase 1: 15 subjects (dose escalation)
   - Arm A: 15 subjects (r/r CLL/SLL on Ibrutinib, del17p/TP53)
   - Arm B: 15 subjects (r/r DLBCL post-R-CHOP with PR)
   - Arm C: 10 subjects (r/r High-grade NHL post-CAR-T)
   
   Total: ~55 subjects
   ============================================================================ */

%let SEED = 20260205;
%let RP2D = DL3;  /* Recommended Phase 2 Dose */

/* -------------------------------------------------------------------------
   1. ARM A: r/r CLL/SLL on Ibrutinib (del17p/TP53)
   Protocol: Must be on Ibrutinib >12 months, PR or SD, high-risk cytogenetics
   ------------------------------------------------------------------------- */
data dm_arm_a;
    length STUDYID $20 DOMAIN $2 USUBJID $40 SUBJID $10
           SITEID $10 AGE 8 SEX $1 RACE $50 ARM $100 ARMCD $10
           PHASE $3 COHORT $30 DISEASETYPE $20 PRIORLINES 8
           CYTOGENETICS $50 PRIORIBRUTINIB $1;
    
    STUDYID = "PBCAR20A-01";
    DOMAIN = "DM";
    PHASE = "2a";
    COHORT = "Arm A: CLL/SLL Ibrutinib";
    DISEASETYPE = "CLL/SLL";
    ARMCD = "&RP2D";
    ARM = "480x10^6 cells (RP2D)";
    
    call streaminit(&SEED + 1000);
    
    do i = 1 to 15;
        SUBJID = put(300 + i, z4.);
        USUBJID = catx('-', STUDYID, 'A', SUBJID);
        SITEID = 'A01';
        
        /* CLL patients tend to be older */
        AGE = round(rand('normal', 68, 8));
        if AGE < 45 then AGE = 45;
        if AGE > 85 then AGE = 85;
        
        if rand('uniform') < 0.62 then SEX = 'M'; else SEX = 'F';
        if rand('uniform') < 0.82 then RACE = 'WHITE'; else RACE = 'OTHER';
        
        /* All must have high-risk cytogenetics per eligibility */
        if rand('uniform') < 0.6 then CYTOGENETICS = 'del(17p)';
        else CYTOGENETICS = 'TP53 mutation';
        
        PRIORIBRUTINIB = 'Y';
        PRIORLINES = round(rand('uniform') * 3) + 2;
        
        output;
    end;
    drop i;
run;

/* -------------------------------------------------------------------------
   2. ARM B: r/r DLBCL post-R-CHOP with PR
   Protocol: Achieved PR (not CR) after upfront R-CHOP
   ------------------------------------------------------------------------- */
data dm_arm_b;
    length STUDYID $20 DOMAIN $2 USUBJID $40 SUBJID $10
           SITEID $10 AGE 8 SEX $1 RACE $50 ARM $100 ARMCD $10
           PHASE $3 COHORT $30 DISEASETYPE $20 PRIORLINES 8
           PRIORCHOP $1 PRIORCHOPRESPONSE $20;
    
    STUDYID = "PBCAR20A-01";
    DOMAIN = "DM";
    PHASE = "2a";
    COHORT = "Arm B: DLBCL post-R-CHOP";
    DISEASETYPE = "DLBCL";
    ARMCD = "&RP2D";
    ARM = "480x10^6 cells (RP2D)";
    
    call streaminit(&SEED + 2000);
    
    do i = 1 to 15;
        SUBJID = put(400 + i, z4.);
        USUBJID = catx('-', STUDYID, 'B', SUBJID);
        SITEID = 'B01';
        
        AGE = round(rand('normal', 62, 12));
        if AGE < 30 then AGE = 30;
        if AGE > 80 then AGE = 80;
        
        if rand('uniform') < 0.55 then SEX = 'M'; else SEX = 'F';
        if rand('uniform') < 0.75 then RACE = 'WHITE'; 
        else if rand('uniform') < 0.5 then RACE = 'BLACK OR AFRICAN AMERICAN';
        else RACE = 'ASIAN';
        
        PRIORCHOP = 'Y';
        PRIORCHOPRESPONSE = 'PR';  /* Must have achieved PR per eligibility */
        PRIORLINES = 1;
        
        output;
    end;
    drop i;
run;

/* -------------------------------------------------------------------------
   3. ARM C: r/r High-grade NHL post-CAR-T
   Protocol: Prior CD19 CAR-T with progression
   ------------------------------------------------------------------------- */
data dm_arm_c;
    length STUDYID $20 DOMAIN $2 USUBJID $40 SUBJID $10
           SITEID $10 AGE 8 SEX $1 RACE $50 ARM $100 ARMCD $10
           PHASE $3 COHORT $30 DISEASETYPE $20 PRIORLINES 8
           PRIORCART $1 PRIORCARTPRODUCT $30;
    
    STUDYID = "PBCAR20A-01";
    DOMAIN = "DM";
    PHASE = "2a";
    COHORT = "Arm C: High-grade NHL post-CAR-T";
    DISEASETYPE = "High-grade B-NHL";
    ARMCD = "&RP2D";
    ARM = "480x10^6 cells (RP2D)";
    
    call streaminit(&SEED + 3000);
    
    do i = 1 to 10;
        SUBJID = put(500 + i, z4.);
        USUBJID = catx('-', STUDYID, 'C', SUBJID);
        SITEID = 'C01';
        
        AGE = round(rand('normal', 55, 12));
        if AGE < 25 then AGE = 25;
        if AGE > 75 then AGE = 75;
        
        if rand('uniform') < 0.58 then SEX = 'M'; else SEX = 'F';
        if rand('uniform') < 0.70 then RACE = 'WHITE'; else RACE = 'OTHER';
        
        PRIORCART = 'Y';
        _cart = int(rand('uniform') * 3) + 1;
        select(_cart);
            when(1) PRIORCARTPRODUCT = 'Axicabtagene ciloleucel';
            when(2) PRIORCARTPRODUCT = 'Tisagenlecleucel';
            otherwise PRIORCARTPRODUCT = 'Lisocabtagene maraleucel';
        end;
        PRIORLINES = round(rand('uniform') * 2) + 3;
        
        output;
    end;
    drop i _cart;
run;

/* -------------------------------------------------------------------------
   4. COMBINE ALL PHASE 2A ARMS
   ------------------------------------------------------------------------- */
data dm_phase2a_full;
    set dm_arm_a dm_arm_b dm_arm_c;
run;

/* -------------------------------------------------------------------------
   5. GENERATE TUMOR RESPONSE BY ARM (Primary Endpoints)
   - Calibrated with ZUMA-1 (Yescarta) and JULIET (Kymriah) benchmarks
   ------------------------------------------------------------------------- */
data rs_phase2a_full;
    length STUDYID $20 DOMAIN $2 USUBJID $40 RSSEQ 8
           RSTESTCD $8 RSTEST $40 RSCAT $40 RSORRES $20 RSSTRESC $20
           RSDTC $10 RSDY 8 VISITNUM 8 VISIT $40
           RESPEVAL $30;
    
    set dm_phase2a_full(keep=USUBJID COHORT DISEASETYPE);
    
    STUDYID = "PBCAR20A-01";
    DOMAIN = "RS";
    RSSEQ = 1;
    RSTESTCD = "OVRLRESP";
    RSTEST = "Overall Response";
    
    call streaminit(&SEED + 4000);
    
    /* Calibrated Response Rates (Real-World Benchmarks) */
    if DISEASETYPE = 'DLBCL' then do;
        RSCAT = "Lugano 2016";
        RESPEVAL = "CR Rate (Primary)";
        /* ZUMA-1 Benchmark: ORR ~72%, CR ~50% */
        _rand = rand('uniform');
        if _rand < 0.48 then RSORRES = 'CR';
        else if _rand < 0.72 then RSORRES = 'PR';
        else if _rand < 0.85 then RSORRES = 'SD';
        else RSORRES = 'PD';
    end;
    else if DISEASETYPE = 'CLL/SLL' then do;
        RSCAT = "iwCLL 2018";
        RESPEVAL = "CR Rate (Primary)";
        /* Benchmarks for CLL: ORR ~60%, CR ~25% */
        _rand = rand('uniform');
        if _rand < 0.25 then RSORRES = 'CR';
        else if _rand < 0.60 then RSORRES = 'PR';
        else if _rand < 0.85 then RSORRES = 'SD';
        else RSORRES = 'PD';
    end;
    else do;  /* High-grade NHL post-CAR-T (Arm C) */
        RSCAT = "Lugano 2016";
        RESPEVAL = "ORR (Primary)";
        /* Challenging population: ORR ~35% */
        _rand = rand('uniform');
        if _rand < 0.15 then RSORRES = 'CR';
        else if _rand < 0.35 then RSORRES = 'PR';
        else if _rand < 0.65 then RSORRES = 'SD';
        else RSORRES = 'PD';
    end;
    
    RSSTRESC = RSORRES;
    VISITNUM = 12;
    VISIT = "WEEK 12";
    RSDY = 84;
run;

/* -------------------------------------------------------------------------
   6. GENERATE CAR-T CELLULAR KINETICS (VCN/Persistence)
   - Calibrated expansion (Peak Day 7-14)
   ------------------------------------------------------------------------- */
data cart_kinetics;
    length STUDYID $20 USUBJID $40 VISIT $20 ADY 8
           VCN 8 CARTT_CELLS 8 CARTT_PCT 8;
    
    set dm_phase2a_full(keep=USUBJID);
    
    STUDYID = "PBCAR20A-01";
    
    call streaminit(&SEED + 5000);
    
    /* Simulate CAR-T expansion curve (Peak around Day 7-10) */
    do VISIT = 'Day 0', 'Day 7', 'Day 10', 'Day 14', 'Day 28', 'Week 12', 'Month 6';
        select(VISIT);
            when('Day 0') do; ADY = 0; VCN = 0; end;
            when('Day 7') do; ADY = 7; VCN = rand('exponential') * 400 + 100; end; /* Near Peak */
            when('Day 10') do; ADY = 10; VCN = rand('exponential') * 600 + 200; end; /* Peak expansion */
            when('Day 14') do; ADY = 14; VCN = rand('exponential') * 300 + 100; end;
            when('Day 28') do; ADY = 28; VCN = rand('exponential') * 100; end;
            when('Week 12') do; ADY = 84; VCN = rand('exponential') * 30; end;
            when('Month 6') do; ADY = 180; VCN = rand('exponential') * 10; end;
            otherwise;
        end;
        
        CARTT_CELLS = VCN * 1000;
        CARTT_PCT = VCN / 100;
        
        output;
    end;
run;

/* -------------------------------------------------------------------------
   7. GENERATE CYTOKINE DATA (IL-6, IFN-g, CRP)
   - Severe peaks calibrated (>1000 pg/mL)
   ------------------------------------------------------------------------- */
data cytokines;
    length STUDYID $20 USUBJID $40 VISIT $20 ADY 8
           IL6 8 IFNG 8 CRP 8;
    
    set dm_phase2a_full(keep=USUBJID);
    
    STUDYID = "PBCAR20A-01";
    
    call streaminit(&SEED + 6000);
    
    do VISIT = 'Baseline', 'Day 1', 'Day 3', 'Day 7', 'Day 14';
        select(VISIT);
            when('Baseline') do; ADY = -5; IL6 = 5; IFNG = 10; CRP = 5; end;
            when('Day 1') do; ADY = 1; IL6 = 50; IFNG = 80; CRP = 15; end;
            when('Day 3') do; 
                ADY = 3; 
                /* 15% severe CRS subjects get high peaks */
                if rand('uniform') < 0.15 then IL6 = rand('exponential') * 1000 + 800;
                else IL6 = rand('exponential') * 200 + 50;
                IFNG = IL6 * 1.5;
                CRP = IL6 / 10 + rand('normal', 20, 10);
            end;
            when('Day 7') do; ADY = 7; IL6 = 80; IFNG = 100; CRP = 40; end;
            when('Day 14') do; ADY = 14; IL6 = 10; IFNG = 20; CRP = 12; end;
            otherwise;
        end;
        output;
    end;
run;

/* -------------------------------------------------------------------------
   9. GENERATE AE DATA (CRS & ICANS CALIBRATION)
   - Calibrated with ZUMA-1: CRS 94% (13% Gr3+), ICANS 87% (31% Gr3+)
   - Median Onset: CRS=2d, ICANS=4d
   ------------------------------------------------------------------------- */
data ae_phase2a_full;
    length STUDYID $20 DOMAIN $2 USUBJID $40 AESEQ 8
           AEDECOD $100 AETERM $100 AESOC $100 AETOXGR $2 AETOXGRN 8
           AESTDTC $20 AEENDTC $20 ASTDT 8 AENDT 8
           TRTEMFL $1 CRSFL $1 ICANSFL $1 ASTCTGR $2;
    
    set dm_phase2a_full(keep=USUBJID COHORT DISEASETYPE);
    
    STUDYID = "PBCAR20A-01";
    DOMAIN = "AE";
    
    call streaminit(&SEED + 8000);
    
    /* 1. Generate CRS for ~94% of subjects (ZUMA-1 Benchmark) */
    if rand('uniform') < 0.94 then do;
        AESEQ = 1;
        AEDECOD = "Cytokine release syndrome";
        AETERM = AEDECOD;
        AESOC = "General disorders and administration site conditions";
        CRSFL = "Y";
        
        /* Grades: ~13% Grade 3+ */
        _g = rand('uniform');
        if _g < 0.13 then do; AETOXGRN = 3; ASTCTGR = "3"; end;
        else if _g < 0.40 then do; AETOXGRN = 2; ASTCTGR = "2"; end;
        else do; AETOXGRN = 1; ASTCTGR = "1"; end;
        AETOXGR = put(AETOXGRN, 1.);
        
        /* Onset: Median 2 days */
        _onset = round(rand('gamma', 2, 1));
        if _onset < 1 then _onset = 1;
        ASTDT = _onset;
        AENDT = ASTDT + round(rand('gamma', 7, 1)); /* Duration ~7d */
        
        output;
    end;
    
    /* 2. Generate ICANS for ~87% of subjects (ZUMA-1 Benchmark) */
    if rand('uniform') < 0.87 then do;
        AESEQ = (calculated AESEQ) + 1;
        AEDECOD = "Immune effector cell-associated neurotoxicity syndrome";
        AETERM = AEDECOD;
        AESOC = "Nervous system disorders";
        ICANSFL = "Y";
        
        /* Grades: ~31% Grade 3+ */
        _g = rand('uniform');
        if _g < 0.31 then do; AETOXGRN = 3; ASTCTGR = "3"; end;
        else if _g < 0.60 then do; AETOXGRN = 2; ASTCTGR = "2"; end;
        else do; AETOXGRN = 1; ASTCTGR = "1"; end;
        AETOXGR = put(AETOXGRN, 1.);
        
        /* Onset: Median 4 days */
        _onset = round(rand('gamma', 4, 1));
        if _onset < 1 then _onset = 1;
        ASTDT = _onset;
        AENDT = ASTDT + round(rand('gamma', 14, 1)); /* Duration ~17d */
        
        output;
    end;
run;

/* Combine with Phase 1 AE and save */
data sdtm.ae_phase2a_full;
    set sdtm.ae ae_phase2a_full;
run;

/* Save other domains */
data sdtm.dm_phase2a_full; set dm_phase2a_full; run;
data sdtm.rs_phase2a_full; set rs_phase2a_full; run;

%put NOTE: ==========================================================;
%put NOTE: ✅ DATA CALIBRATED WITH ZUMA-1 & JULIET BENCHMARKS;
%put NOTE:    DLBCL ORR ~72% (CR ~48%) | CLL ORR ~60% (CR ~25%);
%put NOTE:    CRS Rate ~94% (Med Onset 2d) | ICANS Rate ~87% (Med Onset 4d);
%put NOTE:    Cytokine Peaks Calibrated (>1000 pg/mL in severe cases);
%put NOTE: ==========================================================;
