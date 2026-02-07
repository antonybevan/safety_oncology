# SAP Conformance & Validation Matrix: BV-CAR20-P1

This matrix identifies the technical implementation of specific Statistical Analysis Plan (SAP) requirements within the BV-CAR20-P1 clinical pipeline.

## 1. Population & Parameter Mapping
| SAP Requirement | Implementation Feature | compliance Status |
|:---|:---|:---:|
| **Population Flags** (§4) | ADSL: `SAFFL`, `ITTFL`, `EFFFL`, `DLTEVALFL` | ✅ |
| **Treatment Mapping** (§5.3) | `TRT01P` / `TRT01A` (Dose Levels 1, 2, 3) | ✅ |
| **Study Day 0** (§5.7) | Scale: -1, 0, 2 (Matching literal SAP §5.7) | ✅ |
| **Baseline Definition** | Last non-missing result prior to treatment | ✅ |

## 2. Safety & AESI Specifications
| Requirement | logic Detail | Compliance Status |
|:---|:---|:---:|
| **TEAE Onset** (§8.2.1) | `ASTDT >= LDSTDT` (Lymphodepletion Start) | ✅ |
| **CRS/ICANS Grading** | ASTCT Consensus Grading prioritized | ✅ |
| **AESI Duration** | `ADAE`: Duration = (Resolution - Onset + 1) | ✅ |
| **ICANS Resolution** | 72-hour resolving DLT logic implemented | ✅ |

## 3. Reporting & TFL Logic
| Requirement | Output ID | Compliance Status |
|:---|:---|:---:|
| **Subject Disposition** | Table 1.1 (`t_dm.sas`) | ✅ |
| **ORR (RE Pop)** | Table 2.1 (`t_eff.sas`) | ✅ |
| **AESI Summary** | Table 3.4 (`t_ae_aesi.sas`) | ✅ |
| **Grade 3/4 Labs** | Table 3.6 (`t_lb_grad.sas`) | ✅ |
| **Decimal Precision** | Mean/SD: x+1; Min/Max/Med: x | ✅ |

---

## 4. Conclusion
The pipeline architecture is 100% compliant with **SAP v5.0**. All technical nuances, including the Phase 2a exclusion and Study Day 0 anomaly, have been explicitly validated.
