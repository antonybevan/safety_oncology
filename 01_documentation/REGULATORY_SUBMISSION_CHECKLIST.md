# Regulatory Submission Checklist
**Study**: BV-CAR20-P1  
**Submission Type**: IND/NDA Module 5 Clinical Study Data  
**Reference**: FDA SDTCG December 2025  
**Date**: 2026-02-08

---

## Pre-Submission Checklist

### 1. Data Standards Compliance
| Requirement | Standard | Status | Notes |
|:------------|:---------|:------:|:------|
| SDTM datasets | IG 3.4 | Complete | TS (SSTDTC), EXCAT, and CP/GF shells for CAR-T |
| ADaM datasets | IG 1.3 | Verified | ADSL, ADAE (ASTCT), TEAE_CELL |
| Define-XML | v2.1 | Shell | Requires P21 or SAS Clinical |
| Controlled Terminology | CDISC CT 2025-12-20 | Compliant | Applied throughout |
| XPT format | v5 transport | Compliant | All datasets exported |
| SDSP | Study Data Standardization Plan | Compliant | Documented in SAP |

### 2. Oncology TAUG Compliance
| Requirement | Status | Implementation |
|:------------|:------:|:---------------|
| Tumor Response (RS) | Compliant | Lugano 2016 / iwCLL 2018 |
| Staging (TU/TR) | Not Applicable | Not required for Phase 1 |
| BOR Derivation | Compliant | ADRS with AVALC ranking |
| PFS/OS Parameters | Compliant | Time-to-event with censoring |
| Cell Therapy Variables | Compliant | CARTDT, LDSTDT, CAR-T kinetics |
| CRS/ICANS Grading | Compliant | ASTCT 2019; Traceable `ASTCTGR` in ADAE |

### 3. Pinnacle 21 Validation
| Requirement | Tool | Status | Target |
|:------------|:-----|:------:|:-------|
| SDTM validation | P21 Community | Pending | Zero REJECT |
| ADaM validation | P21 Community | Pending | Zero REJECT |
| Define-XML validation | P21 | Pending | Zero ERROR |
| REJECT findings | Required: 0 | Pending | Blocking |
| ERROR findings | Required: 0 | Pending | Blocking |
| WARNING review | Document all | Pending | Document rationale |

### 4. Reviewer's Guides
| Document | Location | Status | FDA Required |
|:---------|:---------|:------:|:------------:|
| adrg.pdf | 01_documentation/adrg/ | Complete | Required |
| csdrg.pdf | 01_documentation/cdrg/ | Complete | Required |
| Define-XML | 02_datasets/define/ | Shell | Required |
| SAP | 01_documentation/sap/ | Compliant | Recommended |
| aCRF | N/A | N/A | Required for NDA |

### 5. eCTD Submission Format
| Requirement | Standard | Status |
|:------------|:---------|:------:|
| eCTD version | v3.2.2 (transitional) / v4.0 | Pending |
| ESG transmission | FDA Electronic Submissions Gateway | Pending |
| Module 5 structure | datasets/, programs/, misc/ | Compliant | Standardized `adrg.md`, `csdrg.md` |
| File naming | Max 8 chars, lowercase | Compliant |
| Path length | ≤150 characters | Compliant |

### 6. Programs & QC
| Requirement | Status | Evidence |
|:------------|:------:|:---------|
| ASCII text format | Yes | All .sas files |
| PhUSE headers | Yes | Modification history, QC block |
| Level 3 QC | Yes | Primary endpoints double-programmed |
| QC evidence log | Yes | 05_validation/independent/ |
| Version control | Yes | Git with signed commits |

---

## Maximum Compliance Roadmap

### Immediate (Before Submission)
1. **Run Pinnacle 21** - Generate validation reports
2. **Complete Define-XML** - Use P21 Enterprise or SAS Clinical
3. **Review all WARNINGs** - Document rationale for each
4. **Finalize eCTD package** - Per SDTCG folder structure

### Optional Enhancements
- [ ] DOR (Duration of Response) parameter
- [ ] TTR (Time to Response) parameter  
- [ ] ADTR (Tumor Response BDS) if tumor data available
- [ ] aCRF generation from EDC

---

## Sign-Off

| Role | Name | Date | Signature |
|:-----|:-----|:-----|:----------|
| Statistical Programmer | Antony Bevan | 2026-02-08 | *e-Signed* |
| Independent QC Review | Sarah Jenkins | 2026-02-08 | *e-Signed* |
| Documentation Author | Antony Bevan | 2026-02-08 | *e-Signed* |

---
*Note: This checklist demonstrates regulatory submission preparation for the Antony Bevan clinical programming portfolio. The procedures mimic industry standards but do not represent an actual corporate clinical trial submission.*
*Reference: FDA Study Data Technical Conformance Guide (December 2025)*
