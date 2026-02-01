# Analysis Data Reviewer Guide (ADRG)
**Study:** PBCAR20A-01 (Clinical Safety of CD19 CAR-T)
**Date:** 2026-02-01

## 1. Introduction
This document provides guidance to the regulatory reviewer on the structure and content of the ADaM datasets for Study PBCAR20A-01.

## 2. Protocol Design & Clinical Alignment
### 2.1 Study Design
The study follows a **3+3 Dose Escalation** design. 
> [!NOTE]
> Dose Level 2 (240x10^6 cells) was skipped based on SRC recommendations; treatment proceeded from Level 1 to Level 3.

### 2.2 Safety Windows
Treatment Emergence (`TRTEMFL`) is defined relative to the start of the **Lymphodepletion Regimen (Day -5)** to ensure all conditioning-related toxicities are captured. CAR-T specific windows are flagged via `POSTCARFL`.

## 3. Analysis Populations
- **ITTFL (Intent-To-Treat)**: All enrolled subjects.
- **SAFFL (Safety)**: All subjects who received any component of the study regimen (LD or CAR-T).
- **EFFFL (Efficacy)**: Subset of SAFFL with at least one post-baseline tumor assessment.

## 4. Key Derivations
### 4.1 72-Hour ICANS DLT Rule
Neurotoxicity (ICANS) is flagged as a DLT (`DLTFL`) in `ADAE` only if the event is Grade 3 or higher and persists for more than 72 hours, per protocol specifications.

### 4.2 Bi-Directional Lab Grading
Laboratory toxicities are graded in both directions (`ATOXGRL` and `ATOXGRH`) to correctly capture electrolyte and metabolic shifts common in CAR-T therapy (e.g., Tumor Lysis Syndrome).

### 4.3 Efficacy Branching
Efficacy is assessed via **Lugano 2016** for NHL cohorts and **iwCLL 2018** for CLL/SLL cohorts, mapped in the `ADRS` domain.

## 5. Metadata Compliance
All datasets were validated with zero warnings in the SAS log. Define.xml metadata is traceable to `SDTM.RS`, `SDTM.AE`, and `SDTM.SUPPAE`.

---
**Status:** Submission Ready
**Contact:** Clinical Programming Lead
