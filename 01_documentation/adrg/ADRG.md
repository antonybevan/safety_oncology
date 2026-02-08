# Analysis Data Reviewer Guide (ADRG)
**Study**: BV-CAR20-P1  
**Product**: PBCAR20A (Allogeneic CD20 CAR-T)  
**Date**: 2026-02-08

## 1. Introduction
This Analysis Data Reviewer's Guide (ADRG) documents the ADaM datasets for Study BV-CAR20-P1. The package includes Phase 1 (SAP scope) and a Phase 2a expansion portfolio extension. Phase 2a data are synthetic and intended for demonstration only.

## 2. Controlled Terminology
Targeted terminology aligns to CDISC Controlled Terminology dated 2025-12-20. No external CT validation is executed in this repository. Study-specific analysis flags (for example `AESICAT`, `INFFL`) are derived in ADaM as described below.

## 3. Analysis Populations
| Population Flag | Description | Derivation |
|:---|:---|:---|
| **ITTFL** | Intent-To-Treat | All enrolled subjects in SDTM.DM. |
| **SAFFL** | Safety | Subjects with any exposure start date (`TRTSDT`). |
| **EFFFL** | Efficacy | SAFFL subjects with at least one response assessment in SDTM.RS. |
| **MBOINFL** | mBOIN Analysis | All subjects receiving the CAR-T IMP (`BV-CAR20`). |
| **DLTEVLFL** | DLT Evaluable | CAR-T subjects with 28-day evaluation window completed OR experienced a DLT within 28 days (and >=80% dose). |

## 4. Analysis Dataset Descriptions

### 4.1 ADSL (Subject Level Analysis)
- **Sources**: SDTM.DM, SDTM.EX, SDTM.RS, SDTM.AE (death only).
- **Key Dates**: `TRTSDT`, `TRTEDT`, `CARTDT`, `LDSTDT` derived from SDTM.EX; `RFSTDTC`/`RFXSTDTC` aligned to lymphodepletion start.
- **Efficacy Flag**: `EFFFL = Y` if at least one record exists in SDTM.RS.
- **Death**: `DTHDT`/`DTHDTC` derived from SDTM.AE Grade 5 events when present.
- **Last Known Alive**: `LSTALVDT` derived from `TRTEDT` (fallback `TRTSDT`).

### 4.2 ADAE (Adverse Event Analysis)
- **Sources**: SDTM.AE, SDTM.SUPPAE, ADaM.ADSL.
- **ASTCT Grade**: `ASTCTGR` mapped from SUPPAE `ASTCTGR` when available.
- **Treatment Emergent**: `TRTEMFL` based on `ASTDT >= LDSTDT` (lymphodepletion start).
- **AESI**: `AESIFL`/`AESICAT` derived from AEDECOD text (CRS, ICANS, GVHD).
- **Infection Flag**: `INFFL` derived from infection-related AEDECOD terms.
- **DLT Logic**: Rule-based derivation using severity, system organ class, and duration windows (72h, 7d, 14d, 42d) within Day 0-28 post-infusion.
- **Traceability**: `SRCDOM`, `SRCVAR`, `SRCSEQ` retained; `AEOUT` and `AECONTRT` carried through.

### 4.3 ADRS (Disease Response Analysis)
- **Sources**: SDTM.RS, SDTM.EX, SDTM.AE, and ADaM.ADSL.
- **Best Overall Response**: AVAL ranking is CR=1, PR=2, SD=3, PD=4.
- **Criteria**: `PARCAT3` set from `EVALCRIT` (Lugano 2016 or iwCLL 2018).
- **PFS**: Event date is the earliest of first PD or death; subjects starting non-protocol anti-cancer therapy before event are censored at the earlier of last assessment or therapy start. A simplified missed-visit rule censors when the gap exceeds 90 days. `EVNTDESC` indicates Event or censor reason.

### 4.4 ADLB (Laboratory Analysis)
- **Baseline**: `ABLFL` is the last non-missing value on or before `TRTSDT`.
- **Re-Baseline**: For CAR-T specific analysis, baseline is last value prior to `CARTDT`.
- **Toxicity Grading**: `ATOXGRL`/`ATOXGRH` apply bi-directional grading rules.

## 5. SAP v5.0 Nuances & Deviations
- **Study Day 0 (SAP §5.7)**: This study utilizes a "Study Day 0" for events occurring on the day of infusion. Standard CDISC (Day 1) logic is modified in `ADAE` and `ADLB` to scale onset as Day 0, Day 2, etc., omitting Day 1 as per sponsor requirement.
- **DLT Adjudication**: Algorithmic DLTs are flagged in `ADAE`. `ADSL.DLTEVLFL` incorporates an "event override" allowing early DLTs to be counted as evaluable despite incomplete windows.
- **TEAE_CELL**: A specific flag `TEAE_CELL` is used in safety reports to isolate toxicities emerging post-CAR-T infusion from background lymphodepletion chemotherapy effects.

## 6. Conformance and Validation
- Target standard: ADaM IG v1.3.
- External validation (Pinnacle 21, define.xml/arm metadata) is not executed in this repository and remains required for submission readiness.

---
**Status**: Not submission-ready without external validation and clinical adjudication.  
**Contact**: Clinical Programming Lead
