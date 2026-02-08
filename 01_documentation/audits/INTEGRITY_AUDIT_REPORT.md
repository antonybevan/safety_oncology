# Statistical Programming Integrity Audit: BV-CAR20-P1

**Study ID:** BV-CAR20-P1  
**Certification Date:** 2026-02-08  
**Auditor:** Antigravity (automated review + static inspection)

---

## 1. Scope and Method
This audit covers the SDTM, ADaM, and reporting programs under `03_programs`, including the Phase 2a expansion pipeline. The review was performed as a static code inspection and logic trace. No SAS execution logs, dataset outputs, or external validation reports (Pinnacle 21, define.xml) were run or reviewed in this repository.

## 2. Integrity Checks Performed
| Check Area | Status | Notes |
|:---|:---:|:---|
| Code path integrity | Complete | Programs reference relative paths and shared config; no destructive commands found. |
| Data lineage | Complete | SDTM to ADaM and ADaM to TFL traceability retained via `SRCDOM/SRCVAR/SRCSEQ`. |
| Deterministic outputs | Complete | RNG seeding standardized; date cutoffs used in time-to-event outputs. |
| Phase 2a persistence | Complete | Biomarker datasets and expanded ADaM datasets are persisted. |
| CDISC alignment | Partial | Structures align to SDTMIG/ADaMIG intent; no external validation run. |

## 3. Key Findings and Remediations
- ADLB baseline derivation corrected to last on/before `TRTSDT` with explicit `ABLFL`, `BASE`, and `BASEDT`.
- ADRS PFS derivation stabilized with first PD/death event logic and deterministic censoring at last assessment.
- ADRS now censors at new anti-cancer therapy initiation (from non-protocol `SDTM.EX` records) when therapy starts before event.
- ADAE DLT rules aligned to protocol windows with explicit duration checks and AESI flagging.
- SDTM.LB now derives `LBSTRESC`/`LBSTRESN`; SDTM.AE now includes `AEACN`.
- ORR denominator corrected to BOR-only assessments.
- Phase 2a pipeline repaired and persisted (MRD, cytokines, kinetics) with expanded ADaM datasets.
- Data cutoffs introduced for OS and duration outputs to avoid nondeterministic `today()` usage.

## 4. Open Items and Residual Risk
- No Pinnacle 21 validation results are available; submission readiness requires formal validation.
- `define.xml` is now a structural shell only and must be completed with full metadata before submission.
- Phase 2a datasets are synthetic and are outside SAP submission scope.
- Death is derived from AE Grade 5 only; no DS/DM mortality cross-check is performed.
- Data anonymization spec was not re-validated in this audit (see `01_documentation/privacy/DATA_ANONYMIZATION_SPEC.md`).

## 5. Final Status
**Verdict:** Conditionally compliant pending external validation and clinical adjudication.  
**Submission Readiness:** Not certified until validation outputs and define.xml are produced.

---

## 6. Addendum - Final Static Audit Update (2026-02-08)

### 6.1 Remediations Confirmed
- `03_programs/reporting/t_dor_by_arm.sas`: removed all simulated DoR generation; now derives responders, event/censoring, and KM from source RS/ADSL data with explicit no-data fallback.
- `03_programs/reporting/f_waterfall.sas`: removed simulated percent-change logic; now consumes only source percent-change from ADTR/ADRS if present, otherwise outputs a controlled no-data message.
- `03_programs/tabulations/cp.sas`: removed hardcoded mock USUBJID records; now derives CP from `sdtm.cart_kinetics` when available and creates an empty shell with warning when source is unavailable.
- `03_programs/analysis/adsl.sas`: hardened death derivation by de-duplicating grade-5 AE records before hash lookup.
- `03_programs/analysis/adrs.sas`: hardened PFS death lookup with de-duplicated AE death records and retained new anti-cancer therapy censoring branch.

### 6.2 Residual High-Risk Items Before Submission
- `02_datasets/define/define.xml` is a structural shell and remains incomplete for submission-grade define metadata.
- No Pinnacle 21 outputs are present in `05_validation/pinnacle21`; SDTM and ADaM validation must be executed after SAS dataset generation.
- `03_programs/analysis/interim_analysis.sas` still contains template/illustrative interim assumptions and hardcoded scenario values; keep out of submission package unless converted to data-driven derivations.

### 6.3 Pre-SAS Run Gate
- Gate status: `CONDITIONAL GO` for internal SAS execution and QC.
- Gate status for submission: `NO-GO` until define completion and P21 issue closure.
