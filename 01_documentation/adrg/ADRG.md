# Analysis Data Reviewer Guide (ADRG)
**Study**: BV-CAR20-P1  
**Product**: PBCAR20A (Allogeneic CD20 CAR-T)  
**Date**: 2026-02-08

---

## 1. Introduction
This Analysis Data Reviewer's Guide (ADRG) provides additional information and documentation to support the regulatory review of the ADaM datasets for Study BV-CAR20-P1. This guide follows the PhUSE ADRG template.

### 1.1 Controlled Terminology
All analysis datasets use **CDISC Controlled Terminology (v2025-12-20)**. No custom codelists were utilized outside of the standard regulatory descriptors for CAR-T specific cell counts.

## 2. Protocol Design & Clinical Alignment
### 2.1 Study Design
BV-CAR20-P1 is a Phase 1, open-label, dose-escalation study. The primary objective is to evaluate the safety and MTD of PBCAR20A in subjects with r/r NHL or r/r CLL/SLL.
- **Design**: Standard 3+3 Dose Escalation.
- **Dose Levels**: 
  - DL1: 1 x 10^6 cells/kg
  - DL2: 3 x 10^6 cells/kg (historically represented as ~240 x 10^6 flat equivalent; skipped per SRC)
  - DL3: 480 x 10^6 cells
- **Regimen**: Lymphodepletion (Day -5 to -3) followed by CAR-T Infusion (Day 0).

### 2.2 Safety Evaluation Windows
- **DLT Window**: 28 days post-infusion.
- **Treatment Emergence**: Defined from the start of the Lymphodepletion regimen (Day -5) to capture conditioning-related toxicities.

## 3. Analysis Populations
| Population Flag | Description | Derivation |
|:---|:---|:---|
| **ITTFL** | Intent-To-Treat | All enrolled subjects who signed informed consent. |
| **SAFFL** | Safety | Subjects receiving any study treatment (LD or CAR-T). |
| **EFFFL** | Efficacy | Subset of SAFFL with at least one post-baseline response assessment. |
| **DLTEVLFL** | DLT Evaluable | SAFFL subjects who completed 28-day window or experienced a DLT. |

## 4. Analysis Dataset Descriptions

### 4.1 ADSL (Subject Level Analysis)
- **Traceability**: Direct predecessor is SDTM.DM and SDTM.EX.
- **Key Variables**: `TRTSDT` (LD Start), `CARTDT` (Infusion Start), `COHORT` (NHL vs CLL).
- **Disease Stratification**: Subjects are grouped by `COHORT` to dictate the efficacy criteria used (Lugano vs iwCLL).

### 4.2 ADAE (Adverse Event Analysis)
- **Toxicity Grading**: ASTCT 2019 Consensus Grading is prioritized for CRS and ICANS. CTCAE v5.0 used for all other events.
- **AESI Categories**: `AESICAT` identifies CRS, ICANS, and GVHD.
- **Infection Flag**: `INFFL` identifies treatment-emergent infections (e.g., Sepsis, Pneumonia) for pooled safety summaries as per SAP §8.2.2.
- **DLT Logic**: Implements the 72-hour persistence rule for Grade 3+ ICANS and CRS.

### 4.3 ADRS (Disease Response Analysis)
- **Traceability**: Sources include SDTM.RS (Investigator assessments).
- **Evaluation Criteria**: 
  - `PARCAT3` = 'Lugano 2016' for NHL.
  - `PARCAT3` = 'iwCLL 2018' for CLL.
- **PFS Parameter**: Implements strict Progression-Free Survival (Days) derivation as per SAP §7.1.2, including Table 6 censoring rules for missed visits and new anti-cancer therapy.
- **Variables**: `SRCDOM`, `SRCVAR`, and `SRCSEQ` are provided for 100% record-level traceability back to SDTM.RS.

### 4.4 ADLB (Laboratory Analysis)
- **Bi-Directional Grading**: Toxicity is graded Low (`ATOXGRL`) and High (`ATOXGRH`) to capture metabolic shifts (e.g., Hypokalemia vs Hyperkalemia).

## 5. Data Conformance Summary
The ADaM datasets were validated against CDISC ADaMIG v1.3 and FDA SDTCG v4.4 standards.
- **Pinnacle 21**: Zero High-Severity Errors.
- **Warnings**: Expected warnings regarding "Variable Lengths" are due to standardized XPORT V6 compliance.

## 6. Analysis Results Metadata (ARM)
Key safety tables (TEAE Summary, AESI Summary) and efficacy tables (BOR, ORR) are traceable to the ADaM datasets provided. No computational methods outside of the provided SAS programs were used for summary statistics.

---
**Status**: Submission Ready  
**Contact**: Clinical Programming Lead
