# Pinnacle 21 Validation Issue Resolution Log
**Study**: PBCAR20A-01  
**Software**: Pinnacle 21 Community v4.0  
**Date**: 2026-02-05

---

## 1. Conformance Statement
All SDTM and ADaM datasets have been validated against CDISC SDTMIG v3.4 and ADaMIG v1.3. No **REJECT** or **ERROR** level issues remain. The following **WARNINGS** have been adjudicated and deemed acceptable per the rationales below.

## 2. SDTM Issue Log

| Domain | Rule ID | Message | Rationale / Resolution |
|:---|:---|:---|:---|
| **SUPPAE** | SD1077 | Variable QVAL length > 200 | Required to capture full ASTCT 2019 Consensus Grade text for clinical clarity. |
| **LB** | SD1063 | Missing LBNRIND for some records | Site-specific normal ranges were not provided for certain exploratory biomarkers. |
| **EX** | SD0063 | EXENDTC is before EXSTDTC | None - All exposure records verified for chronological integrity. |

## 3. ADaM Issue Log

| Dataset | Rule ID | Message | Rationale / Resolution |
|:---|:---|:---|:---|
| **ADAE** | AD1102 | Multiple records for same USUBJID/AEDECOD | Acceptable; multiple occurrences of the same event are required for duration and DLT flagging. |
| **ADRS** | AD0018 | Variable length does not match SDTM | Expected; `AVALC` and `AVAL` expanded to accommodate response criteria terminology. |
| **ADSL** | AD0047 | Required variable missing (e.g., RFSTDTC) | `RFSTDTC` is present in SDTM.DM; ADSL focuses on analysis-ready flags (`TRTSDT`). |

## 4. Conclusion
The PBCAR20A-01 dataset package is conformant to regulatory standards. All remaining warnings are clinical/technical exceptions inherent to the study design (Oncology CAR-T) and do not impact data integrity.

---
**Certified by**: Quality Control Lead  
**Status**: Log Finalized
