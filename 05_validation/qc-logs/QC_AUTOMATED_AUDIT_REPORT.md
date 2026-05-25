# Automated Quality Control (QC) & Log Verification Report

**Study**: BV-CAR20-P1  
**Target Log File**: `00_main-log (1).html`  
**Date Verified**: 2026-05-25 18:08:49  
**Overall Compliance Status**: **FAIL**  

## QC Metrics Checklist

| Quality Parameter | Count | Clinical Threshold | Compliance Status |
|:---|:---:|:---:|:---:|
| **Errors (`ERROR:`)** | 9 | 0 | NON-COMPLIANT |
| **Warnings (`WARNING:`)** | 6 | 0 | NON-COMPLIANT |
| **Uninitialized Variables** | 0 | 0 | Compliant |
| **Implicit Type Conversions** | 0 | 0 | Compliant |
| **Merge BY Value Repeats** | 0 | 0 | Compliant |
| **Missing Values Generated** | 0 | Info Only | Informational |

## Action Items Required for Submission

### Critical Errors (9)
The following compilation or execution errors must be resolved:

- **Line 5536**: `ERROR: The following columns were not found in the contributing tables: null.`
- **Line 5557**: `ERROR: File WORK.SAE_COUNTS.DATA does not exist.`
- **Line 5579**: `ERROR: File WORK.SAE_REPORT_WIDE.DATA does not exist.`
- **Line 5621**: `ERROR: [PIPELINE] Execution of t_sae_cart.sas failed with SYSCC=3000`
- **Line 5681**: `ERROR: The following columns were not found in the contributing tables: null.`
- **Line 5702**: `ERROR: File WORK.SAE_LD_COUNTS.DATA does not exist.`
- **Line 5748**: `ERROR: There is no statistic associated with Result.`
- **Line 5789**: `ERROR: [PIPELINE] Execution of t_sae_ld.sas failed with SYSCC=1012`
- **Line 7438**: `ERROR: [FAILED] [MAIN] Phase 1 Pipeline Execution Complete with errors!`

### Compiler Warnings (6)
The following standard warnings must be eliminated to achieve the Zero Warning Standard:

- **Line 5705**: `WARNING: The data set WORK.SAE_LD_REPORT may be incomplete.  When this step was stopped there were 0 observations and 3`
- **Line 5725**: `WARNING: Multiple lengths were specified for the variable Result by input data set(s). This can cause truncation of`
- **Line 6305**: `WARNING: Multiple lengths were specified for the variable DTHCAUS by input data set(s). This can cause truncation of`
- **Line 6307**: `WARNING: Multiple lengths were specified for the variable COHORT by input data set(s). This can cause truncation of`
- **Line 6309**: `WARNING: Multiple lengths were specified for the variable USUBJID by input data set(s). This can cause truncation of`
- **Line 6311**: `WARNING: Multiple lengths were specified for the variable ARMCD by input data set(s). This can cause truncation of data.`

