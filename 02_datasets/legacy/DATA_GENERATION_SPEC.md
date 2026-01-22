# BV-CAR20-P1 Synthetic Data Generation Specification
## Best-in-Class Clinical Realism for Phase 1/2a CAR-T Portfolio

This specification defines the synthetic data generation strategy to mimic real-world CAR-T clinical implications. All parameters are derived from published literature benchmarks and SAP v5.0 requirements.

---

## 1. Study Population Design

### 1.1 Sample Size & Dose Cohorts (per SAP §1.3)
| Dose Level | Dose | Target N | Actual N (Simulated) |
|:-----------|:-----|:---------|:---------------------|
| DL1 | 1×10⁶ cells/kg | 3-6 | 6 |
| DL2 | 3×10⁶ cells/kg | 3-6 | 6 |
| DL3 | 480×10⁶ cells (flat) | 3-6 | 6 |
| **Total** | | 9-18 | **18** |

> **Note:** DL 240×10⁶ (Protocol V4 DL2) is **excluded** per SAP §1.1.

### 1.2 Demographic Distributions (per SAP §6.2)
| Variable | Distribution | Rationale |
|:---------|:-------------|:----------|
| Age | Normal(62, 8), range 45-78 | NHL/CLL median age ~65 |
| Sex | 60% Male, 40% Female | NHL/CLL sex ratio |
| Race | 75% White, 15% Black, 10% Other | US trial demographics |
| ECOG PS | 70% ECOG 0, 30% ECOG 1 | Inclusion criteria |
| Disease | 70% NHL (DLBCL, FL), 30% CLL/SLL | Per SAP §1.2 indication |
| Prior Lines | Median 3 (range 2-6) | r/r population |

---

## 2. Treatment Timeline (per SAP §1.3)

```
Day -7:   Screening / Baseline
Day -5:   LD Start (Flu 30mg/m² + Cy 500mg/m²)
Day -4:   LD Day 2
Day -3:   LD Day 3 (Last LD)
Day 0:    BV-CAR20 Infusion
Day 2-28: DLT Observation Window (Note: No Study Day 1 per SAP §5.7)
Day 30+:  Follow-up Visits (D30, D60, D90, D180, D360)
```

---

## 3. Adverse Event Simulation (AESI Focus)

### 3.1 AESI Incidence Rates (Literature-Based Benchmarks)
| AESI | MedDRA PT (v22.1) | Code | Overall Rate | DL1 Rate | DL2 Rate | DL3 Rate |
|:-----|:-----------------|:-----|:-------------|:---------|:---------|:---------|
| **CRS** | Cytokine release syndrome | 10011693 | 45% | 33% | 50% | 67% |
| **ICANS** | Immune effector cell-associated neurotoxicity syndrome | 10082305 | 25% | 17% | 25% | 33% |
| **GvHD** | Graft versus host disease | 10018507 | 12% | 10% | 12% | 15% |

### 3.2 CRS Grade Distribution (ASTCT 2019)
| Grade | Proportion | Clinical Implication |
|:------|:-----------|:---------------------|
| Grade 1 | 50% | Fever only; supportive care |
| Grade 2 | 35% | Hypotension/hypoxia; tocilizumab |
| Grade 3 | 12% | Multiple vasopressors; ICU |
| Grade 4 | 3% | Life-threatening; rare in anti-CD20 |

### 3.3 ICANS Grade Distribution (ASTCT 2019)
| Grade | Proportion | DLT Implication |
|:------|:-----------|:----------------|
| Grade 1 | 45% | Mild confusion; not DLT |
| Grade 2 | 30% | Moderate; not DLT |
| Grade 3 | 20% | Severe; DLT if >72hr |
| Grade 4 | 5% | Critical; DLT |

### 3.4 AESI Onset & Duration (Real-World Patterns)
| AESI | Median Onset (Days) | Onset Range | Median Duration | Duration Range |
|:-----|:--------------------|:------------|:----------------|:---------------|
| CRS | 2 | 1-7 | 5 days | 2-14 days |
| ICANS | 5 | 2-14 | 4 days | 1-21 days |
| GvHD | 21 | 14-60 | 30 days | 7-90 days |

---

## 4. Non-AESI Adverse Events

### 4.1 Hematologic Toxicities (Post-LD)
| CTCAE v5.0 Term | Rate | Grade 3-4 Rate | Onset | Recovery |
|:----------------|:-----|:---------------|:------|:---------|
| **Neutrophil count decreased** | 90% | 75% | Day 0-7 | Day 14-28 |
| **Platelet count decreased** | 60% | 30% | Day 3-10 | Day 21-42 |
| **Anemia** | 45% | 15% | Day 7-14 | Day 28-60 |

### 4.2 Infections (Secondary to Immunosuppression)
| Event | Rate | Grade 3+ Rate |
|:------|:-----|:--------------|
| Any Infection | 35% | 15% |
| Febrile Neutropenia | 20% | 20% |
| Pneumonia | 8% | 8% |
| Sepsis | 5% | 5% |

---

## 5. DLT Simulation (per SAP §3.1)

### 5.1 DLT Definition Window
- **Window:** Day 0 to Day 28 post-infusion
- **Criteria:** Grade ≥3 non-hematologic toxicity OR prolonged Grade 4 hematologic

### 5.2 ICANS 72-Hour Exclusion Rule
```
IF ICANS Grade ≥3 AND Duration ≤72 hours THEN DLT = 'N';
IF ICANS Grade ≥3 AND Duration >72 hours THEN DLT = 'Y';
```

### 5.3 Target DLT Rates (3+3 Design Simulation)
| Dose Level | Target DLT Rate | Simulated DLTs |
|:-----------|:----------------|:---------------|
| DL1 | 0-17% | 0-1 of 6 |
| DL2 | 17-33% | 1-2 of 6 |
| DL3 (MTD) | 17-33% | 1-2 of 6 |

---

## 6. Efficacy Outcomes (Response Evaluable Population)

### 6.1 ORR by Dose Level (Exploratory)
| Dose Level | CR | PR | SD | PD | ORR |
|:-----------|:---|:---|:---|:---|:----|
| DL1 | 17% | 33% | 33% | 17% | 50% |
| DL2 | 33% | 33% | 17% | 17% | 67% |
| DL3 | 50% | 33% | 17% | 0% | 83% |

### 6.2 Safety-Efficacy Correlation (Figure 3.1 Data)
| Max CRS Grade | Mean Tumor Shrinkage | N |
|:--------------|:---------------------|:--|
| Grade 0 | -10% (growth) | 4 |
| Grade 1-2 | -45% | 8 |
| Grade 3-4 | -70% | 6 |

> **Clinical Insight:** Higher CRS grades correlate with better tumor response (CAR-T expansion marker).

---

## 7. Data File Specifications

### 7.1 Output Files
| File | Location | Format | Records |
|:-----|:---------|:-------|:--------|
| `raw_dm.csv` | `02_datasets/legacy/` | CSV | 18 |
| `raw_ex.csv` | `02_datasets/legacy/` | CSV | 54 (3 per subject) |
| `raw_ae.csv` | `02_datasets/legacy/` | CSV | ~150-200 |
| `raw_lb.csv` | `02_datasets/legacy/` | CSV | ~500 |
| `raw_rs.csv` | `02_datasets/legacy/` | CSV | ~50 |

### 7.2 Key Variables per File
- **DM:** USUBJID, AGE, SEX, RACE, ARM, TRTSDT, LDSTDT
- **EX:** USUBJID, EXTRT (Flu/Cy/BV-CAR20), EXDOSE, EXSTDTC, EXENDTC
- **AE:** USUBJID, AETERM, AEDECOD (MedDRA PT), AESTDTC, AEENDTC, AETOXGR, AESER, AESI
- **LB:** USUBJID, LBTEST, LBORRES, LBORNRLO, LBORNRHI, LBDTC
- **RS:** USUBJID, RSORRES (CR/PR/SD/PD), RSDTC

---

## 8. Implementation Strategy

### 8.1 Technology Choice & Reproducibility
- **Primary:** Python (pandas, numpy, faker) OR SAS DATA step
- **Reproducibility:** A fixed random seed (e.g., `SEED = 20260122`) MUST be documented and used for all generation runs to comply with **FDA 21 CFR Part 11** audit trail requirements.
- **Rationale:** reproducible, auditable, and SAP-aligned

### 8.2 Generation Workflow
1. **Anchor Demographics:** Generate DM with dose assignment.
2. **Temporal Grid:** Calculate `TRTSDT` (Anchor) and `LDSTDT` (TRTSDT - 3).
3. **Biological Core:** Simulate AESIs first (dose-dependent).
4. **Logic Check:** If AESI Grade >= 2, increase probability of Efficacy Response (CR/PR).
5. **Timeline Execution:** Generate AESTDTC/AEENDTC ensuring NO Day 1 records (ADY 0 -> 2).
6. **DLT Resolution:** Force-inject one 'DLT bypass' (Grade 3 ICANS resolving in <72hr) for pipeline validation.
7. **Lab Drift:** Simulate hematologic recovery (Neutropenia) finishing by Day 28.
8. **Final Scan:** Map BEST Response to RS domain correlated to Max CRS grade.

---

**Specification Date:** 2026-01-22  
**Author:** Antigravity (Advanced Agentic Clinical Programming Lead)  
**Status:** Ready for Implementation
