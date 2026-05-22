# QC Log: Statistical Programming Activities
**Study**: BV-CAR20-P1  
**Log Version**: 1.0  
**Last Updated**: 2026-05-22

---

## Purpose
This log documents all quality control activities performed on the statistical programming deliverables for Study BV-CAR20-P1.

---

## QC Activity Log

### 2026-02-08: Program Review - Phase 1 ADaM
| Program | Reviewer | Result | Comments |
|:--------|:---------|:------:|:---------|
| adsl.sas | QC Lead | Pass | Population flags verified |
| adae.sas | QC Lead | Pass | DLT logic reviewed |
| adrs.sas | QC Lead | Pass | PFS censoring logic correct |
| adlb.sas | QC Lead | Pass | Baseline flagging verified |
| adex.sas | QC Lead | Pass | Exposure logic verified |

### 2026-02-08: Log Review - Zero Warnings Standard
| Program | Warnings | Errors | Status |
|:--------|:--------:|:------:|:------:|
| 00_main.sas | 0 | 0 | Pass |
| 00_config.sas | 0 | 0 | Pass |
| All tabulations/*.sas | 0 | 0 | Pass |
| All analysis/*.sas | 0 | 0 | Pass |
| All reporting/*.sas | 0 | 0 | Pass |

### 2026-02-08: Output Review - TLF Verification
| Output ID | Description | SAP Ref | Status |
|:----------|:------------|:--------|:------:|
| T1.1 | Subject Disposition | §11.1 | Verified |
| T2.1 | Overall Response Rate | §11.2 | Verified |
| T3.4 | AESI Summary | §11.3 | Verified |
| F-SW | Swimmer Plot | §11.4 | Verified |
| F-WF | Waterfall Plot | §11.4 | Verified |

### 2026-05-22: Submission Conformance & Log Audit
| Program / Audit | Reviewer / Suite | Result | Comments |
|:---|:---|:---:|:---|
| verify_ectd_structure.py | Automated Suite | Pass | eCTD Module 5 structure and cleanliness checked; 0 prohibited files found |
| qc_audit_tool.py (Main Log) | Automated Suite | Pass | Audited 00_main-log.html; 0 errors/warnings/uninitialized references |
| qc_audit_tool.py (Main Results) | Automated Suite | Pass | Audited 00_main-results.html; 0 errors/warnings/uninitialized references |
| compile_ectd_package.py | Automated Suite | Pass | Pristine m5/ directory compiled to m5.zip; submission checksums generated |

---

## Sign-Off

| Role | Name | Date | Signature |
|:-----|:-----|:-----|:----------|
| Statistical Programmer | Antony Bevan | 2026-05-22 | *e-Signed* |
| QC Reviewer | Sarah Jenkins | 2026-05-22 | *e-Signed* |
| Statistical Lead | David Chen, PhD | 2026-05-22 | *e-Signed* |

---
*This log is maintained as part of the audit trail for regulatory submission.*
