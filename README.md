# BV-CAR20-P1: Allogeneic Anti-CD20 CAR-T Clinical Programming

[![eCTD](https://img.shields.io/badge/eCTD-Module%205-blue)]()
[![CDISC](https://img.shields.io/badge/CDISC-SDTM%201.7%20|%20ADaM%202.1-green)]()
[![FDA](https://img.shields.io/badge/FDA-CBER%20Submission%20Ready-success)]()

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

```
BV-CAR20-P1/
├── 01_documentation/            # Formal Docs (SAP, Audit, Compliance)
│   ├── adrg/                   # Analysis Data Reviewer's Guide
│   ├── cdrg/                   # Clinical Data Reviewer's Guide
│   ├── sap/                    # Statistical Analysis Plan
│   └── protocol/               # Study protocol
│
├── 02_datasets/                 # Study Data (FDA SDTCG compliant)
│   ├── tabulations/            # SDTM v1.7 datasets (.xpt)
│   ├── analysis/               # ADaM v2.1 datasets (.xpt)
│   ├── define/                 # define.xml v2.1
│   └── legacy/                 # Source/converted data
│
├── 03_programs/                 # ASCII text programs
│   ├── tabulations/            # SDTM mapping programs (SAS)
│   ├── analysis/               # ADaM derivation programs (SAS)
│   ├── reporting/              # TFL programs (SAS/R)
│   └── macros/                 # Reusable utilities
│
├── 04_outputs/
│   ├── tables/                 # Summary tables (RTF)
│   ├── figures/                # Swimmer plots, KM curves
│   └── listings/               # Subject-level listings
│
└── 05_validation/
    ├── independent/            # QC Level 3 (double programming)
    ├── pinnacle21/             # P21 validation results
    └── qc-logs/                # QC documentation
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
**Date**: 2026-02-08

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
