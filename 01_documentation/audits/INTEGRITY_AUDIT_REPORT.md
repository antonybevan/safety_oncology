# Statistical Programming Integrity Audit: BV-CAR20-P1

**Study ID:** BV-CAR20-P1  
**Certification Date:** 2026-02-08  
**Auditor:** Antony Bevan (Clinical Statistical Programmer)  

---

## 1. Scope and Method
This audit covers the complete Phase 1 SDTM, ADaM, and reporting programs under `03_programs`. The review was performed as a comprehensive code inspection and logic trace, verifying adherence to SAP v5.0 and FDA submission standards.

## 2. Integrity Checks Performed
| Check Area | Status | Notes |
|:---|:---:|:---|
| Code path integrity | Complete | Programs reference relative paths and shared config; no destructive commands found. |
| Data lineage | Complete | SDTM to ADaM and ADaM to TFL traceability retained via `SRCDOM/SRCVAR/SRCSEQ`. |
| Deterministic outputs | Complete | RNG seeding standardized; date cutoffs used in time-to-event outputs. |
| CDISC alignment | Complete | Structures align to SDTMIG 3.4 and ADaMIG 1.3 intent. |

## 3. Key Findings and Remediations
- ADLB baseline derivation corrected to last on/before `TRTSDT` with explicit `ABLFL`, `BASE`, and `BASEDT`.
- ADRS PFS derivation stabilized with first PD/death event logic and deterministic censoring at last assessment.
- ADRS now censors at new anti-cancer therapy initiation (from non-protocol `SDTM.EX` records) when therapy starts before event.
- ADAE DLT rules aligned to protocol windows with explicit duration checks and AESI flagging.
- SDTM.LB now derives `LBSTRESC`/`LBSTRESN`; SDTM.AE now includes `AEACN`.
- ORR denominator corrected to BOR-only assessments.
- Data cutoffs introduced for OS and duration outputs to avoid nondeterministic `today()` usage.

## 4. Open Items and Residual Risk
- Final Pinnacle 21 validation results must be formally attached to the submission package post-execution.
- `define.xml` must be completed with final metadata before gateway upload.
- Death is derived from AE Grade 5 only; clinical data management must ensure DM/DS alignment.

## 5. Final Status
**Verdict:** Fully compliant from a structural and programmatic standpoint.  
**Submission Readiness:** Approved for final SAS execution and subsequent XML generation.

---

## 6. Addendum - Final Pipeline Update (2026-02-08)

### 6.1 Remediations Confirmed
- `03_programs/reporting/t_dor_by_arm.sas`: derives responders, event/censoring, and KM from source RS/ADSL data with explicit no-data fallback.
- `03_programs/reporting/f_waterfall.sas`: consumes only source percent-change from ADTR/ADRS if present, otherwise outputs a controlled no-data message.
- `03_programs/analysis/adsl.sas`: hardened death derivation by de-duplicating grade-5 AE records before hash lookup.
- `03_programs/analysis/adrs.sas`: hardened PFS death lookup with de-duplicated AE death records and retained new anti-cancer therapy censoring branch.

### 6.2 Pre-SAS Run Gate
- Gate status: `GO` for final formal SAS execution.
- Gate status for regulatory submission: `PENDING` define completion and P21 formal run.

---
*Note: This integrity audit report demonstrates quality control protocols for the Antony Bevan clinical programming portfolio. It verifies the programmatic soundness of the codebase but does not constitute an official regulatory audit.*
