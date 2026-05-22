# BV-CAR20-P1: Allogeneic Anti-CD20 CAR-T Clinical Programming

[![eCTD Module 5](https://img.shields.io/badge/eCTD-Module_5-0284c7?style=flat-square)](file:///d:/safety_oncology/m5/)
[![CDISC SDTM 1.7](https://img.shields.io/badge/CDISC-SDTM_1.7-10b981?style=flat-square)](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/tabulations/sdtm/define.xml)
[![CDISC ADaM 2.1](https://img.shields.io/badge/CDISC-ADaM_2.1-059669?style=flat-square)](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/define.xml)
[![SAS 9.4](https://img.shields.io/badge/SAS-9.4-7f1d1d?style=flat-square)](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/00_config.sas)
[![QC Level 3](https://img.shields.io/badge/QC-Level_3_Verified-4f46e5?style=flat-square)](file:///d:/safety_oncology/05_validation/qc-logs/QC_ACTIVITY_LOG.md)
[![FDA Submission Ready](https://img.shields.io/badge/FDA_CBER-Submission_Ready-1e1b4b?style=flat-square)](file:///d:/safety_oncology/05_validation/qc-logs/ECTD_CLEANLINESS_REPORT.md)


## Portfolio Overview

**Clinical Statistical Programming Portfolio Project — Antony Bevan**  
SAP-aligned Phase 1 dose-escalation study **BV-CAR20-P1** (allogeneic anti-CD20 CAR-T) in relapsed/refractory NHL/CLL. This repository is an end-to-end portfolio demonstration of regulatory-grade clinical programming, CDISC implementation, and formal submission readiness.

| Parameter | Value |
|-----------|-------|
| **Design** | Phase 1 Dose Escalation (3+3) |
| **Indication** | r/r B-cell NHL, CLL/SLL |
| **Protocol** | BV-CAR20-P1 v5.0 |
| **SAP** | v5.0 (Based on Public Domain CAR-T SAP) |

## eCTD Module 5 Structure

```text
safety_oncology/ (Workspace root)
├── m5/                                 # === FDA eCTD Module 5 Submission Package ===
│   └── datasets/
│       └── bv-car20-p1/
│           ├── tabulations/
│           │   └── sdtm/               # SDTM Folder
│           │       ├── define.xml      # SDTM Metadata Specification (linked to stylesheet)
│           │       ├── define2-1.xsl   # Interactive SDTM Stylesheet
│           │       ├── csdrg.md        # Clinical Study Data Reviewer's Guide (SDRG)
│           │       └── programs/       # SDTM mapping programs (dm.sas, ex.sas, etc.)
│           │
│           └── analysis/
│               └── adam/               # ADaM Folder
│                   ├── define.xml      # ADaM Metadata Specification (linked to stylesheet)
│                   ├── define2-1.xsl   # Interactive ADaM Stylesheet
│                   ├── adrg.md         # Analysis Data Reviewer's Guide (ADRG)
│                   └── programs/       # ADaM Analytical Programming Suite
│                       ├── 00_config.sas       # Master Environment Setup & Library Config
│                       ├── 00_main.sas         # Master Pipeline Build Driver
│                       ├── adsl.sas            # Subject-Level Analysis Dataset
│                       ├── adae.sas            # Adverse Event Analysis Dataset
│                       ├── adlb.sas            # Laboratory Analysis Dataset
│                       ├── adex.sas            # Exposure Analysis Dataset
│                       ├── adrs.sas            # Efficacy Response Analysis Dataset
│                       ├── gen_metadata.sas    # Analysis Metadata Shell generator
│                       │
│                       ├── reporting/          # TFL Generation Programs (t_*.sas, f_*.sas, etc.)
│                       └── macros/             # Autocall Utility Macros
│
├── 01_documentation/                   # === Sponsor Documentation & Checklists ===
│   ├── protocol/                       # Protocol synopsis and documentation
│   ├── sap/                            # Statistical Analysis Plan & Conformance Matrix
│   └── checklists/                     # Regulatory, programming, and SOP checklists
│
├── 04_outputs/                         # === Clinical Output Repository ===
│   ├── tables/                         # RTF medical tables
│   ├── figures/                        # PNG oncology figures
│   └── listings/                       # RTF patient-level listings
│
└── 05_validation/                      # === Sponsor Validation & Simulation Environment ===
    ├── data_gen/                       # [Sponsor] Raw Clinical Data Simulation
    │   └── generate_data.sas           # Data simulator (moved from m5/ to keep m5/ pristine)
    ├── independent/                    # Level 3 QC double programming
    ├── pinnacle21/                     # P21 issue resolution and validation guidelines
    ├── qc-logs/                        # QC evidence audit logs
    │   ├── ECTD_CLEANLINESS_REPORT.md  # eCTD structure and cleanliness conformance report
    │   ├── QC_ACTIVITY_LOG.md          # Log of validation activities
    │   └── QC_AUTOMATED_AUDIT_REPORT.md # SAS pipeline execution log audit report
    ├── qc_audit_tool.py                # Automated SAS log and pipeline quality auditor
    ├── verify_ectd_structure.py        # Automated eCTD structure and cleanliness checker
    └── utilities/                      # Sponsor developer utility scripts
        ├── GIT_PUSH.sas                # Git stage, commit, and push automation
        └── GIT_RESCUE.sas              # Branch restore and emergency recovery
```


## Regulatory Compliance

### FDA Standards
- **eCTD v3.2.2:** Module 5 clinical data structure
- **Study Data Technical Conformance Guide:** v4.4+
- **Define-XML:** v2.1 with full traceability

### CDISC Standards
- **SDTM:** v1.7 / IG v3.4 (oncology-specific)
- **ADaM:** v2.1 / IG v1.3
- **Controlled Terminology:** MedDRA v22.1, CTCAE v5.0, ASTCT

### PhUSE Best Practices
- **Good Programming Practice (GPP):** Applied to all SAS programs
- **QC Levels:** 1 (manual), 2 (review), 3 (double programming)
- **Analysis Results Metadata (ARM):** Embedded in define.xml

## Professional Certification

Status: **COMPLIANT | SUBMISSION READY**

This repository has undergone a comprehensive integrity and professionalism audit. All clinical programming logic, data traceability (SRCDOM/VAR/SEQ), and documentation conform to standard clinical trial and regulatory (FDA/Health Authority) submission requirements.

---
**Developed and Audited by**: Antony Bevan (Clinical Statistical Programmer)  
**Date**: 2026-05-22

## Key Safety Features

| Feature | Implementation |
|---------|----------------|
| **DLT Assessment** | 28-day window per 3+3 design |
| **AESI** | CRS/ICANS (ASTCT grading), GvHD |
| **Populations** | Safety (LD recipients), ITT, Response Evaluable |
| **Hybrid Grading** | ASTCT (CRS/ICANS) + CTCAE v5.0 (all others) |

## Deliverables

### Tables (per SAP Section 11)
- **1.1-1.3:** Disposition, Deviations, Demographics
- **2.1:** Objective Response Rate (ORR)
- **3.2-3.8:** Safety summaries (TEAE, AESI, SAE)

### Figures
- **2.1:** Swimmer Plot (PFS)
- **3.1:** Best Response vs. Max CRS Grade (Safety-Efficacy Correlation)

### Listings
- Screen failures, TEAEs, AESI events, SAEs, Deaths

## Tools & Languages

- **SAS 9.4+:** Primary programming language
- **R 4.0+:** Independent validation, visualization
- **Pinnacle 21 Community:** CDISC validation
- **Define-XML Generator:** Metadata creation

## Reference Documents

See `01_documentation/` folder for:
- Statistical Analysis Plan (SAP) v5.0
- Study Protocol BV-CAR20-P1 v5.0
- Regulatory Standards Compliance Document

---

**Compliance Status:** Regulatory-grade architecture (CDISC SDTM/ADaM)  
**Project Scope:** End-to-end clinical programming portfolio demonstration by Antony Bevan  

**Data Privacy:** 100% Synthetic data (No HIPAA/GDPR constraints)  
**Authenticity:** Trial design, SAP logic, and derivation rules are modeled on authentic Phase 1 CAR-T protocols.
