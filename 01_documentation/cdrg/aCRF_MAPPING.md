# Annotated CRF Metadata Mapping (aCRF)
**Study**: PBCAR20A-01  
**Project**: Clinical Safety of CD19 CAR-T  
**Date**: 2026-02-05

---

## 1. Overview
This document provides the metadata mapping from the clinical database (EDC) fields to the SDTM tabulation domains. This serves as the documentation for the `acrf.pdf` requirement in the FDA eCTD Module 5.

## 2. Domain Mapping Table

| EDC Form | Field Description | SDTM Domain | SDTM Variable | Mapping Logic |
|:---|:---|:---|:---|:---|
| **DM - Demographics** | Subject ID | DM | SUBJID | Direct Map |
| | Date of Birth | DM | BRTHDTC | ISO 8601 |
| | Sex | DM | SEX | CDISC CT |
| | Race | DM | RACE | CDISC CT |
| **EX - Exposure** | Treatment | EX | EXTRT | PBCAR20A, Fludarabine, Cyclophosphamide |
| | Start Date | EX | EXSTDTC | Date/Time of infusion/start |
| | End Date | EX | EXENDTC | Date/Time of infusion/end |
| | Dose Level | EX | EXDOSE | Specific cohort dose |
| **AE - Adverse Events** | Event Term | AE | AETERM | Investigator Reported |
| | Start Date | AE | AESTDTC | First observed date |
| | End Date | AE | AEENDTC | Final resolution date |
| | Severity | AE | AESEV | Mild/Mod/Severe (Mapped to CTCAE) |
| | Relationship | AE | AEREL | Related/Not Related |
| | AESI Cluster | SUPPAE | ASTCTGR | Map to ASTCT 2019 via SUPPAE |
| **LB - Laboratory** | Test Name | LB | LBTEST | Central/Local Lab Param |
| | Result | LB | LBORRES | Character result |
| | Reference Range | LB | LBORNRLO/HI | Site/Vendor range |
| **RS - Response** | Assessment Date | RS | RSDTC | Tumor assessment date |
| | BOR Assessment | RS | RSORRES | Investigator response (Lugano/iwCLL) |
| | Evaluation Crit | RS | RSCAT | LUGANO 2016 or iwCLL 2018 |

## 3. Derived Variables Traceability
| SDTM Variable | Source Dataset | Source Variable | Derivation Note |
|:---|:---|:---|:---|
| **DM.RFSTDTC** | EX | EXSTDTC | Earliest date of any study drug (Day -5) |
| **DM.ARMCD** | Enrollment | Cohort | DL1, DL2, or DL3 |
| **SUPPAE.ASTCTGR** | EDC | CRS/ICANS Grade | Adjudicated ASTCT 2019 grade |

---
**Status**: Submission Ready  
**Compliance**: FDA SDTCG v4.4 / CDISC SDTM v1.7
