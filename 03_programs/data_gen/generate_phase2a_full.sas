/******************************************************************************
 * Program:      generate_phase2a_full.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Synthetic Data Generation for Phase 2a Expansion Arms
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4
 *
 * Scope:        Implementation of the expansion phase per Protocol Section 3.1.2.
 *               Includes Arms A (CLL/SLL), B (DLBCL), and C (NHL).
 ******************************************************************************/

/* Environment assumed to be set by 00_phase2a_full_driver.sas -> 00_config.sas */


/* ============================================================================
   SYNTHETIC DATA GENERATION: PHASE 2A EXPANSION
   
   Expansion Arm Structure (Protocol Section 3.1.2):
   - Phase 1: Dose Escalation (N=15)
   - Arm A: CLL/SLL on Ibrutinib (N=15)
   - Arm B: DLBCL post-R-CHOP with PR (N=15)
   - Arm C: High-grade NHL post-CAR-T (N=10)
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
    
    STUDYID = "&STUDYID";
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
    
    STUDYID = "&STUDYID";
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
   Protocol: Prior anti-CD19 CAR-T with progression (historical therapy)
   ------------------------------------------------------------------------- */
data dm_arm_c;
    length STUDYID $20 DOMAIN $2 USUBJID $40 SUBJID $10
           SITEID $10 AGE 8 SEX $1 RACE $50 ARM $100 ARMCD $10
           PHASE $3 COHORT $30 DISEASETYPE $20 PRIORLINES 8
           PRIORCART $1 PRIORCARTPRODUCT $30;
    
    STUDYID = "&STUDYID";
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
   4.1 SYNTHETIC REGIMEN TIMELINE (LD + CAR-T)
   ------------------------------------------------------------------------- */
data phase2a_timeline;
    set dm_phase2a_full;
    by USUBJID;
    retain _idx 0;
    _idx + 1;

    LDSTDT = '01MAR2025'd + (_idx - 1) * 3;
    CARTDT = LDSTDT + 5;
    TRTSDT = LDSTDT;
    TRTEDT = CARTDT + 28;

    format LDSTDT CARTDT TRTSDT TRTEDT date9.;
    keep STUDYID USUBJID LDSTDT CARTDT TRTSDT TRTEDT;
run;

/* -------------------------------------------------------------------------
   4.2 GENERATE EXPOSURE DATA (SDTM.EX) FOR PHASE 2A
   ------------------------------------------------------------------------- */
data ex_phase2a_full;
    length STUDYID $20 DOMAIN $2 USUBJID $40
           EXTRT $100 EXDOSE 8 EXDOSU $20
           EXSTDTC EXENDTC $10
           EXDOSFRM $20 EXROUTE $20;
    set phase2a_timeline;

    DOMAIN = "EX";
    EXDOSFRM = "STEADY STATE";
    EXROUTE = "INTRAVENOUS";

    EXTRT = "FLUDARABINE";
    EXDOSE = 30;
    EXDOSU = "MG/M2";
    EXSTDTC = put(LDSTDT, yymmdd10.);
    EXENDTC = put(LDSTDT + 2, yymmdd10.);
    output;

    EXTRT = "CYCLOPHOSPHAMIDE";
    EXDOSE = 500;
    EXDOSU = "MG/M2";
    EXSTDTC = put(LDSTDT, yymmdd10.);
    EXENDTC = put(LDSTDT + 2, yymmdd10.);
    output;

    EXTRT = "BV-CAR20";
    EXDOSE = 480;
    EXDOSU = "X10^6 CELLS";
    EXSTDTC = put(CARTDT, yymmdd10.);
    EXENDTC = put(CARTDT, yymmdd10.);
    output;

    keep STUDYID DOMAIN USUBJID EXTRT EXDOSE EXDOSU EXSTDTC EXENDTC EXDOSFRM EXROUTE;
run;

proc sort data=ex_phase2a_full;
    by USUBJID EXSTDTC EXTRT;
run;

data sdtm.ex_phase2a_full;
    set ex_phase2a_full;
    by USUBJID;
    retain EXSEQ;
    if first.USUBJID then EXSEQ = 0;
    EXSEQ + 1;
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
    
    STUDYID = "&STUDYID";
    DOMAIN = "RS";
    RSSEQ = 1;
    RSTESTCD = "OVRLRESP";
    RSTEST = "Overall Response";
    
    if _n_ = 1 then call streaminit(&SEED + 4000);
    
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
    
    STUDYID = "&STUDYID";
    
    if _n_ = 1 then call streaminit(&SEED + 5000);
    
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
    
    STUDYID = "&STUDYID";
    
    if _n_ = 1 then call streaminit(&SEED + 6000);
    
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
   8. GENERATE MRD DATA (Minimal Residual Disease)
   ------------------------------------------------------------------------- */
data mrd_phase2a_full;
    length STUDYID $20 USUBJID $40 MRDTEST $30 MRDMETHOD $30 
           MRDRESULT $20 MRDNEG 8 TIMEPOINT $20 DISEASE $10;
    
    if _n_ = 1 then call streaminit(&SEED + 7000);
    
    set dm_phase2a_full(keep=USUBJID DISEASETYPE COHORT);
    rename DISEASETYPE=DISEASE;
    
    STUDYID = "&STUDYID";
    
    /* MRD rates vary by disease and response */
    if DISEASE = 'NHL' then _mrd_neg_rate = 0.55;
    else _mrd_neg_rate = 0.45;
    
    /* Week 4 assessment */
    TIMEPOINT = "Week 4";
    MRDTEST = "MRD Assessment";
    MRDMETHOD = "Flow Cytometry (10^-4)";
    
    if rand('uniform') < _mrd_neg_rate * 0.8 then do;
        MRDRESULT = "Negative";
        MRDNEG = 1;
    end;
    else do;
        MRDRESULT = "Positive";
        MRDNEG = 0;
    end;
    output;
    
    /* Week 12 assessment */
    TIMEPOINT = "Week 12";
    if MRDRESULT = "Positive" and rand('uniform') < 0.3 then do;
        MRDRESULT = "Negative";
        MRDNEG = 1;
    end;
    else if MRDRESULT = "Negative" and rand('uniform') < 0.1 then do;
        MRDRESULT = "Positive";
        MRDNEG = 0;
    end;
    output;
    
    drop _mrd_neg_rate;
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
    
    STUDYID = "&STUDYID";
    DOMAIN = "AE";
    
    if _n_ = 1 then call streaminit(&SEED + 8000);
    
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
        if missing(AESEQ) then AESEQ = 1;
        else AESEQ = AESEQ + 1;
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

/* Save all datasets to libraries for persistence */
data sdtm.dm_phase2a_full; set dm_phase2a_full; run;
data sdtm.ae_phase2a_full; set ae_phase2a_full; run;
data sdtm.rs_phase2a_full; set rs_phase2a_full; run;
data sdtm.cart_kinetics; set cart_kinetics; run;
data sdtm.cytokines; set cytokines; run;
data sdtm.mrd_phase2a_full; set mrd_phase2a_full; run;

/* -------------------------------------------------------------------------
   Build Phase 2a ADSL records aligned to ADaM ADSL structure
   ------------------------------------------------------------------------- */
proc sort data=sdtm.ex_phase2a_full out=ex_p2_sorted;
    by USUBJID EXSTDTC;
run;

data car_dates_p2;
    set ex_p2_sorted;
    by USUBJID;

    retain TRTSDT TRTEDT CARTDT LDSTDT;
    format TRTSDT TRTEDT CARTDT LDSTDT date9.;

    if first.USUBJID then do;
        %iso_to_sas(iso_var=EXSTDTC, sas_var=TRTSDT);
        if upcase(EXTRT) in ('FLUDARABINE', 'CYCLOPHOSPHAMIDE') then LDSTDT = TRTSDT;
    end;

    if upcase(EXTRT) = 'BV-CAR20' and missing(CARTDT) then do;
        %iso_to_sas(iso_var=EXSTDTC, sas_var=CARTDT);
    end;

    if last.USUBJID then do;
        %iso_to_sas(iso_var=EXENDTC, sas_var=TRTEDT);
        output;
    end;

    keep USUBJID TRTSDT TRTEDT CARTDT LDSTDT;
run;

proc sort data=sdtm.rs_phase2a_full out=rs_subj_p2(keep=USUBJID) nodupkey;
    by USUBJID;
run;

proc sort data=sdtm.ae_phase2a_full(where=(AETOXGRN=5 or AETOXGR='5')) out=ae_death_phase2a;
    by USUBJID ASTDT;
run;

data ae_death_phase2a;
    set ae_death_phase2a;
    by USUBJID ASTDT;
    if first.USUBJID;
    keep USUBJID ASTDT AEDECOD;
    rename ASTDT=DEATHDY AEDECOD=DTHCAUS;
run;

proc sort data=dm_phase2a_full out=dm_phase2a_sorted;
    by USUBJID;
run;

data adsl_phase2a;
    if 0 then set adam.adsl;
    set dm_phase2a_sorted;
    by USUBJID;

    length DISEASE $5 COHORT $10 EVALCRIT $25 AGEGR1 $10 PHASE $3 DTHCAUS $100;
    format TRTSDT TRTEDT CARTDT LDSTDT DTHDT LSTALVDT date9.;

    if _n_ = 1 then do;
        declare hash h(dataset:'car_dates_p2');
        h.defineKey('USUBJID');
        h.defineData('TRTSDT', 'TRTEDT', 'CARTDT', 'LDSTDT');
        h.defineDone();

        declare hash e(dataset:'rs_subj_p2');
        e.defineKey('USUBJID');
        e.defineDone();

        declare hash dh(dataset:'ae_death_phase2a');
        dh.defineKey('USUBJID');
        dh.defineData('DEATHDY', 'DTHCAUS');
        dh.defineDone();
    end;

    if h.find() ne 0 then do;
        TRTSDT = .; TRTEDT = .; CARTDT = .; LDSTDT = .;
    end;

    TRTDUR = .;
    if not missing(TRTSDT) and not missing(TRTEDT) then TRTDUR = TRTEDT - TRTSDT + 1;

    RFSTDTC = put(LDSTDT - 7, yymmdd10.);
    RFICDTC = RFSTDTC;
    RFXSTDTC = put(LDSTDT, yymmdd10.);
    RFXENDTC = put(TRTEDT, yymmdd10.);
    RFENDTC = "";
    RFPENDTC = "";

    DOMAIN = "DM";
    AGEU = "YEARS";
    ETHNIC = "NOT HISPANIC OR LATINO";
    COUNTRY = "USA";

    ITTFL = "Y";
    if not missing(TRTSDT) then SAFFL = "Y";
    else SAFFL = "N";

    if SAFFL = "Y" and e.find() = 0 then EFFFL = "Y";
    else EFFFL = "N";

    if not missing(CARTDT) then DOSESCLFL = "Y";
    else DOSESCLFL = "N";

    if DOSESCLFL = "Y" and TRTDUR >= 28 then DLTEVLFL = "Y";
    else if DOSESCLFL = "Y" then DLTEVLFL = "N";
    else DLTEVLFL = "N";

    TRT01P = ARM;
    TRT01A = ARM;
    if ARMCD = 'DL1' then TRT01PN = 1;
    else if ARMCD = 'DL2' then TRT01PN = 2;
    else if ARMCD = 'DL3' then TRT01PN = 3;
    TRT01AN = TRT01PN;

    if DISEASETYPE = "CLL/SLL" then do;
        DISEASE = "CLL";
        COHORT = "CLL";
        EVALCRIT = "iwCLL 2018";
    end;
    else do;
        DISEASE = "NHL";
        COHORT = "NHL";
        EVALCRIT = "LUGANO 2016";
    end;

    if missing(AGE) then AGEGR1 = "";
    else if AGE < 65 then AGEGR1 = "<65";
    else AGEGR1 = ">=65";

    DTHDT = .;
    DTHDTC = "";
    DTHCAUS = "";
    DTHFL = "N";

    if dh.find() = 0 then do;
        if not missing(CARTDT) then DTHDT = CARTDT + DEATHDY;
        if not missing(DTHDT) then DTHDTC = put(DTHDT, yymmdd10.);
        DTHFL = "Y";
    end;

    if not missing(TRTEDT) then LSTALVDT = TRTEDT;
    else if not missing(TRTSDT) then LSTALVDT = TRTSDT;
    else LSTALVDT = .;

    PHASE = "2a";
    drop DEATHDY DISEASETYPE PRIORLINES CYTOGENETICS PRIORIBRUTINIB PRIORCHOP PRIORCHOPRESPONSE PRIORCART PRIORCARTPRODUCT;
run;

/* Create Expanded ADaM for Reports (Combine Phase 1 and 2a) */
data adam.adsl_expanded;
    length PHASE $3;
    set adam.adsl(in=ph1) adsl_phase2a(in=ph2);
    if ph1 then PHASE = '1';
    else if ph2 then PHASE = '2a';
run;

/* Build Phase 2a ADRS (BOR) aligned with ADaM structure */
proc sort data=rs_phase2a_full;
    by USUBJID;
run;

proc sort data=adsl_phase2a;
    by USUBJID;
run;

data adrs_phase2a;
    merge rs_phase2a_full(in=a) adsl_phase2a(in=b keep=USUBJID TRTSDT CARTDT TRT01A TRT01AN ITTFL SAFFL EFFFL DISEASE ARMCD ARM EVALCRIT);
    by USUBJID;
    if a;

    PARAMCD = "BOR";
    PARAM = "Best Overall Response";

    length CRIT1 PARCAT3 $100;
    if DISEASE = 'NHL' then CRIT1 = "Lugano 2016 (Metabolic)";
    else if DISEASE = 'CLL' then CRIT1 = "iwCLL 2018";
    PARCAT3 = EVALCRIT;

    SRCDOM = "RS";
    SRCVAR = "RSORRES";
    SRCSEQ = RSSEQ;

    AVALC = strip(upcase(RSSTRESC));
    if AVALC = "CR" or AVALC = "CMR" then do; AVAL = 1; AVALC = "CR"; end;
    else if AVALC = "PR" or AVALC = "PMR" then do; AVAL = 2; AVALC = "PR"; end;
    else if AVALC = "SD" or AVALC = "NMR" then do; AVAL = 3; AVALC = "SD"; end;
    else if AVALC = "PD" or AVALC = "PMD" then do; AVAL = 4; AVALC = "PD"; end;
    else AVAL = .;

    /* Use Week 12 (RSDY=84) anchored to CARTDT */
    if not missing(CARTDT) then ADT = CARTDT + coalesce(RSDY, 84);
    format ADT date9.;
    if not missing(ADT) and not missing(TRTSDT) then 
        ADY = ADT - TRTSDT + (ADT >= TRTSDT);

    ANL01FL = "Y";
run;

data adam.adrs_expanded;
    set adam.adrs(in=ph1) adrs_phase2a(in=ph2);
run;

/* Build Phase 2a ADAE aligned with ADaM structure */
proc sort data=sdtm.ae_phase2a_full out=ae_phase2a_sorted;
    by USUBJID AESEQ;
run;

data adae_phase2a;
    merge ae_phase2a_sorted(in=a) adsl_phase2a(in=b keep=USUBJID TRTSDT CARTDT LDSTDT TRT01A TRT01AN ARM ARMCD);
    by USUBJID;
    if a;

    length AESICAT $10 DLTREAS $100 AESEV $20 AEOUT AECONTRT $100;
    length TRTEMFL LDAEFL PSTCARFL DLTFL DLTWINFL INFFL AOCCPFL $1;

    /* Convert relative days to actual dates */
    if not missing(CARTDT) then do;
        ASTDT = CARTDT + ASTDT;
        AENDT = CARTDT + AENDT;
    end;
    format ASTDT AENDT date9.;

    TRTA = TRT01A;
    TRTAN = TRT01AN;

    SRCDOM = "AE";
    SRCVAR = "AEDECOD";
    SRCSEQ = AESEQ;

    AESOC = strip(AESOC);
    AEREL = "RELATED";
    AEOUT = "";
    AECONTRT = "";

    /* Map Grade to Severity */
    if AETOXGRN = 1 then AESEV = 'MILD';
    else if AETOXGRN = 2 then AESEV = 'MODERATE';
    else if AETOXGRN in (3, 4) then AESEV = 'SEVERE';
    else if AETOXGRN = 5 then AESEV = 'DEATH';

    if not missing(ASTDT) and not missing(LDSTDT) then do;
        if ASTDT >= LDSTDT then TRTEMFL = "Y";
        else TRTEMFL = "N";
    end;
    else TRTEMFL = "N";

    if not missing(ASTDT) and not missing(LDSTDT) and not missing(CARTDT) then do;
        if ASTDT >= LDSTDT and ASTDT < CARTDT then LDAEFL = "Y";
        else LDAEFL = "N";
    end;
    else LDAEFL = "N";

    if not missing(ASTDT) and not missing(CARTDT) then do;
        if ASTDT >= CARTDT then PSTCARFL = "Y";
        else PSTCARFL = "N";
    end;
    else PSTCARFL = "N";

    /* AETOXGRN is already populated in phase 2a AE generation */
    if missing(AETOXGRN) and not missing(AETOXGR) then AETOXGRN = input(AETOXGR, best.);

    AESIFL = "N";
    DLTFL = "N";
    AESICAT = "";

    if index(upcase(AEDECOD), 'CYTOKINE RELEASE') > 0 then do;
        AESIFL = "Y";
        AESICAT = "CRS";
    end;
    else if index(upcase(AEDECOD), 'NEUROTOXICITY') > 0 or
            index(upcase(AEDECOD), 'IMMUNE EFFECTOR') > 0 then do;
        AESIFL = "Y";
        AESICAT = "ICANS";
    end;

    if index(upcase(AEDECOD), 'INFECT') > 0 or 
       index(upcase(AEDECOD), 'SEPSIS') > 0 or 
       index(upcase(AEDECOD), 'PNEUMONIA') > 0 then INFFL = "Y";
    else INFFL = "N";

    if not missing(ASTDT) and not missing(AENDT) then AEDUR = AENDT - ASTDT + 1;
    else AEDUR = .;

    if not missing(ASTDT) and not missing(CARTDT) then do;
        DLTWINDY = ASTDT - CARTDT;
        if DLTWINDY >= 0 and DLTWINDY <= 28 then DLTWINFL = "Y";
        else DLTWINFL = "N";
    end;
    else DLTWINFL = "N";

    if DLTWINFL = "Y" then do;
        if AESICAT = "CRS" and AETOXGRN = 4 then do;
            DLTFL = "Y";
            DLTREAS = "CRS Grade 4 (Immediate DLT)";
        end;
        else if AESICAT = "CRS" and AETOXGRN = 3 then do;
            if AEDUR > 3 then do;
                DLTFL = "Y";
                DLTREAS = "CRS Grade 3 not resolved within 72h";
            end;
        end;
        else if AESICAT = "ICANS" and AETOXGRN >= 3 then do;
            if AEDUR > 3 then do;
                DLTFL = "Y";
                DLTREAS = "ICANS Grade 3+ not resolved within 72h";
            end;
        end;
    end;
run;

proc sort data=adae_phase2a;
    by USUBJID AEDECOD ASTDT AESEQ;
run;

data adae_phase2a;
    set adae_phase2a;
    by USUBJID AEDECOD;
    if TRTEMFL = 'Y' then do;
        if first.AEDECOD then AOCCPFL = "Y";
        else AOCCPFL = "N";
    end;
    else AOCCPFL = "N";
run;

data adam.adae_expanded;
    set adam.adae(in=ph1) adae_phase2a(in=ph2);
run;

%put NOTE: ==========================================================;
%put NOTE: DATA CALIBRATED WITH ZUMA-1 & JULIET BENCHMARKS;
%put NOTE:    DLBCL ORR ~72% (CR ~48%) | CLL ORR ~60% (CR ~25%);
%put NOTE:    CRS Rate ~94% (Med Onset 2d) | ICANS Rate ~87% (Med Onset 4d);
%put NOTE:    Cytokine Peaks Calibrated (>1000 pg/mL in severe cases);
%put NOTE: PERSISTED: Kinetics, Cytokines, MRD, Expanded ADaM;
%put NOTE: ==========================================================;

