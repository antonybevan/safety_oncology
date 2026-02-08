# Programming Standards Checklist
**Study**: BV-CAR20-P1  
**Prepared By**: Clinical Programming Lead  
**Date**: 2026-02-08

---

## 1. Program Structure Standards

| Requirement | Standard | Compliance |
|:------------|:---------|:----------:|
| Program header block | PhUSE GPP format | ✅ |
| Modification history | Date / Author / Description | ✅ |
| Purpose statement | Clear, single-sentence | ✅ |
| Input/Output documentation | Full paths or macro references | ✅ |
| Author and date | Required | ✅ |

## 2. Code Quality Standards

| Requirement | Standard | Compliance |
|:------------|:---------|:----------:|
| Indentation | 4 spaces (no tabs) | ✅ |
| Line length | ≤100 characters | ✅ |
| Variable naming | CDISC standard names | ✅ |
| Macro naming | Lowercase with underscores | ✅ |
| Comments | Block and inline as needed | ✅ |

## 3. Data Standards

| Requirement | Standard | Compliance |
|:------------|:---------|:----------:|
| SDTM version | IG 3.4 | ✅ |
| ADaM version | IG 1.3 | ✅ |
| Controlled terminology | CDISC CT 2025-12-20 | ✅ |
| Variable labels | Required for all variables | ✅ |
| Traceability | SRCDOM/SRCVAR/SRCSEQ | ✅ |

## 4. Validation Standards

| Requirement | Standard | Compliance |
|:------------|:---------|:----------:|
| Log review | Zero warnings | ✅ |
| Pinnacle 21 | All REJECT/ERROR resolved | ⏳ Pending |
| Independent programming | Critical outputs | ✅ |
| Define-XML | Complete metadata | ⏳ Shell only |

## 5. Documentation Standards

| Requirement | Standard | Compliance |
|:------------|:---------|:----------:|
| ADRG | ADaM analysis datasets | ✅ |
| SDRG | SDTM tabulation datasets | ✅ |
| Define-XML | v2.1 format | ✅ |
| SAP alignment | Conformance matrix | ✅ |

---

## Certification
All programs and datasets in this repository meet or exceed the standards defined above, with noted exceptions for external validation pending.

**Certified By**: Clinical Programming Lead  
**Date**: 2026-02-08
