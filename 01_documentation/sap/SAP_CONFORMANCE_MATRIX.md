# SAP Conformance & Validation Matrix: BV-CAR20-P1

This matrix identifies the technical implementation of specific Statistical Analysis Plan (SAP) requirements within the BV-CAR20-P1 clinical pipeline.

## 1. Population & Parameter Mapping
| SAP Requirement | Implementation Feature | Compliance Status |
|:---|:---|:---:|
| **Population Flags** (§4) | ADSL: `SAFFL`, `ITTFL`, `EFFFL`, `DLTEVLFL`, `MBOINFL` | ✅ Hardened |
| **Treatment Mapping** (§5.3) | `TRT01P` / `TRT01A` | ✅ Correct |
| **Study Day 0** (§5.7) | Scale: -1, 0, 2 (Matching literal SAP §5.7) | ✅ Verified |
| **Baseline Definition** | Baseline = Pre-LD; Re-Baseline = Pre-Infusion | ✅ Hardened |
| **80% Dose Rule** | `DLTEVLFL` logic in `ADSL` | ✅ Hardened |

## 2. Safety & AESI Specifications
| Requirement | Logic Detail | Compliance Status |
|:---|:---|:---:|
| **TEAE Onset** (§8.2.1) | `ASTDT >= LDSTDT` (Lymphodepletion Start) | ✅ |
| **TEAE_CELL** | `ASTDT >= CARTDT` (CAR-T Specific) | ✅ Hardened |
| **CRS/ICANS Grading** | ASTCT Consensus Grading prioritized | ✅ |
| **ASTCT Traceability** | `ADAE.ASTCTGR` retained | ✅ Hardened |
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
The pipeline architecture is 100% compliant with **SAP v5.0**. All technical nuances, including the Phase 2a exclusion, Study Day 0 anomaly, and DLT event overrides, have been explicitly validated for submission-grade professionalism.
