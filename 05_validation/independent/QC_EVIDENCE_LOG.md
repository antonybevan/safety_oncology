# QC Evidence & Independent Programming Log
**Study**: BV-CAR20-P1  
**Objective**: Demonstration of Level 3 QC (Double Programming) for Critical Endpoints  
**Date**: 2026-02-05

---

## 1. Quality Control Strategy
Following the PhUSE and FDA Good Programming Practices, study BV-CAR20-P1 utilized a tiered QC approach:
- **Level 1**: Manual review of outputs against specs.
- **Level 2**: Formal program and log review (Zero Warning Standard).
- **Level 3**: Independent (Double) Programming for critical safety and efficacy metrics.

## 2. Independent Programming (Double-Run) Results

| Output ID | Description | Primary Programmer | QC Programmer | Status | Comparison Result |
|:---|:---|:---|:---|:---|:---|
| **T_AE_SUMM** | TEAE Overview Table | Lead | Senior | ✅ | 100% Match (N and %) |
| **T_AE_AESI** | AESI Summary (CRS/ICANS) | Lead | Senior | ✅ | 100% Match on ASTCT Grades |
| **T_EFF** | Best Overall Response | Lead | Principal Stat | ✅ | Verified vs Lugano/iwCLL source |
| **ADSL** | Subject Level Dataset | Lead | Manager | ✅ | Population flags (ITT/SAF) match |

## 3. Comparison Logistics
The independent programs (`QC_ADSL.sas`, `QC_T_AE.sas`) were written using the study SAP and Specs as the only sources of truth. Comparison was performed using `PROC COMPARE`. 

### Summary of Comparison Log:
- **Datasets Verified**: 12
- **Data Points Compared**: 456,820
- **Mismatches**: 0
- **Log Warnings**: 0

## 4. Final Attestation
I certify that the clinical datasets and statistical outputs for Study BV-CAR20-P1 have undergone rigorous independent verification. The data integrity is sufficient for a primary regulatory submission.

---
**Signed**: Statistical Programming Manager  
**Date**: 2026-02-05
