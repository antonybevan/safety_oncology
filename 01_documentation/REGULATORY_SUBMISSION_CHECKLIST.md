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
| SDTM datasets | IG 3.4 | ✅ | All domains implemented |
| ADaM datasets | IG 1.3 | ✅ | ADSL, ADAE, ADRS, ADLB, ADTR |
| Define-XML | v2.1 | ⏳ Shell | Requires P21 or SAS Clinical |
| Controlled Terminology | CDISC CT 2025-12-20 | ✅ | Applied throughout |
| XPT format | v5 transport | ✅ | All datasets exported |
| SDSP | Study Data Standardization Plan | ✅ | Documented in SAP |

### 2. Oncology TAUG Compliance
| Requirement | Status | Implementation |
|:------------|:------:|:---------------|
| Tumor Response (RS) | ✅ | Lugano 2016 / iwCLL 2018 |
| Staging (TU/TR) | ⚠️ | Not required for Phase 1 |
| BOR Derivation | ✅ | ADRS with AVALC ranking |
| PFS/OS Parameters | ✅ | Time-to-event with censoring |
| Cell Therapy Variables | ✅ | CARTDT, LDSTDT, CAR-T kinetics |
| CRS/ICANS Grading | ✅ | ASTCT Consensus v2020 |

### 3. Pinnacle 21 Validation
| Requirement | Tool | Status | Target |
|:------------|:-----|:------:|:-------|
| SDTM validation | P21 Community | ⏳ | Zero REJECT |
| ADaM validation | P21 Community | ⏳ | Zero REJECT |
| Define-XML validation | P21 | ⏳ | Zero ERROR |
| REJECT findings | Required: 0 | ⏳ | Blocking |
| ERROR findings | Required: 0 | ⏳ | Blocking |
| WARNING review | Document all | ⏳ | Document rationale |

### 4. Reviewer's Guides
| Document | Location | Status | FDA Required |
|:---------|:---------|:------:|:------------:|
| adrg.pdf | 01_documentation/adrg/ | ✅ Complete | Required |
| csdrg.pdf | 01_documentation/cdrg/ | ✅ Complete | Required |
| Define-XML | 02_datasets/define/ | ⏳ Shell | Required |
| SAP | 01_documentation/sap/ | ✅ | Recommended |
| aCRF | N/A | N/A | Required for NDA |

### 5. eCTD Submission Format
| Requirement | Standard | Status |
|:------------|:---------|:------:|
| eCTD version | v3.2.2 (transitional) / v4.0 | ⏳ |
| ESG transmission | FDA Electronic Submissions Gateway | ⏳ |
| Module 5 structure | datasets/, programs/, misc/ | ✅ |
| File naming | Max 8 chars, lowercase | ✅ |
| Path length | ≤150 characters | ✅ |

### 6. Programs & QC
| Requirement | Status | Evidence |
|:------------|:------:|:---------|
| ASCII text format | ✅ | All .sas files |
| PhUSE headers | ✅ | Modification history, QC block |
| Level 3 QC | ✅ | Primary endpoints double-programmed |
| QC evidence log | ✅ | 05_validation/independent/ |
| Version control | ✅ | Git with signed commits |

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
| Lead Programmer | | 2026-02-08 | [Pending] |
| Biostatistician | | 2026-02-08 | [Pending] |
| Regulatory Affairs | | 2026-02-08 | [Pending] |

---
*Reference: FDA Study Data Technical Conformance Guide (December 2025)*
