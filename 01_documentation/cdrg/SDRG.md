# Study Data Reviewer Guide (SDRG)
**Study**: PBCAR20A-01  
**Date**: 2026-02-05

---

## 1. Introduction
This Study Data Reviewer's Guide (SDRG) provides documentation to support the regulatory review of the SDTM tabulation datasets for Study PBCAR20A-01.

## 2. Protocol Design & Data Flow
The SDTM datasets represent the direct tabulation of source data from electronic Case Report Forms (eCRF) and external laboratory vendors.
- **SDTM Version**: v1.7 / SDTMIG v3.4.
- **Controlled Terminology**: CDISC CT 2025-12-20.

## 3. Domain-Specific Annotations

### 3.1 DM (Demographics)
- **RFSTDTC**: Set to the date of the first study-related procedure (Lymphodepletion start).
- **ARMCD/ARM**: Standardized to 'DL1', 'DL2', 'DL3' dosing cohorts.

### 3.2 AE (Adverse Events)
- **AESEV**: Mapped from eCRF severity (Mild, Moderate, Severe).
- **AETOXGR**: Assigned in ADaM layer based on CTCAE v5.0 and ASTCT 2019 criteria.
- **SUPPAE**: Supplemental qualifiers include the `ASTCTGR` (Consensus Grade) variable for CAR-T toxicity.

### 3.3 RS (Response)
- **RSCAT**: Categorized by evaluation criteria ('LUGANO 2016' or 'iwCLL 2018').
- **RSORRES**: Contains original investigator assessment text (e.g., 'Complete Metabolic Response').

### 3.4 LB (Laboratory)
- **LBORRES**: Original character results.
- **LBNRIND**: Normal range indicator (LOW, HIGH, NORMAL) based on site-specific reference ranges.

### 3.5 Trial Design (TS, TA, TE)
- **TS (Trial Summary)**: Contains trial objectives, registry IDs, and product identifiers.
- **TA (Trial Arms)**: Defines the dose level cohorts (DL1-DL3).
- **TE (Trial Elements)**: Maps the lifecycle from Screening to Follow-up.

## 4. Conformance Summary
SDTM domains were validated using Pinnacle 21 Community. There are no blocking errors.
- **Warnings on SUPP-- Domains**: Standard warnings regarding the use of non-standard variables in supplemental domains are expected and documented.

---
**Status**: Submission Ready  
**Contact**: Clinical Programming Lead
