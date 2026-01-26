# Project Knowledge Base: BV-CAR20-P1 Safety Oncology
**Context:** Clinical Data Engineering & Safety Analysis (CAR-T Cell Therapy)

## 1. Executive Summary
This project implements an end-to-end clinical programming pipeline for a Phase 1 oncology trial (BV-CAR20-P1). It transforms synthetic raw data into CDISC-compliant SDTM and ADaM datasets, culminating in a professional AE Summary Table.

## 2. Technical Architecture
### Cloud Synchronization (SAS Git Rescue)
The project utilizes a custom "Rescue" logic for SAS OnDemand for Academics (ODA). 
- **Challenge:** Cloud file systems often face "In-Use" locks or sync errors.
- **Solution:** A SAS-native Git script (`GIT_RESCUE.sas`) that bypasses the GUI, performs a clean clone/pull from GitHub, and uses versioned paths or standardized short paths (`clinical_safety`) to maintain a stable environment.

### Dynamic Path Configuration (`00_config.sas`)
A robust configuration file auto-detects the environment (Linux/Windows) and applies advanced "Path Cleaving" logic:
- It locates the `03_programs` directory and extracts the project root, ensuring portability across local and cloud environments without manual path updates.

## 3. Clinical Data Logic (Synthetic)
The data generator (`generate_data.sas`) simulates a safety-focused oncology cohort:
- **Sample Size:** 18 Subjects across 3 Dose Levels.
- **Toxicities:** Specifically mimics CAR-T specific events:
    - **Cytokine Release Syndrome (CRS)**
    - **ICANS** (Neurotoxicity)
- **SUPPAE Logic:** Uses Supplemental Qualifiers to store toxicity grades for CDISC compliance.

## 4. ADaM & Analysis Specifications
- **ADSL (Subject Level):** Contains population flags (ITT, Safety, Efficay) and treatment dates.
- **ADAE (Adverse Events):** Incorporates ASTCT toxicity grades from SUPPAE for safety analysis.
- **ADLB (Labs) & ADRS (Response):** Calculates change from baseline (CHG) and Best Overall Response (BOR).

## 5. Result Summary (Table 14.3.1)
The pipeline produces a standard clinical output:
- **Any TEAE:** Reported for all 18 subjects.
- **Grade 3-4 Events:** Higher incidence predicted in Dose Level 3.
- **AESIs:** Consolidated summary of CRS/ICANS frequency.

## 6. Project Directory Standard
- `01_documentation`: SAP and Specs.
- `02_datasets`: Legacy (CSV), SDTM (SAS7BDAT), ADaM (SAS7BDAT/XPT).
- `03_programs`: Organized by `tabulations`, `analysis`, `reporting`, and `utilities`.
- `04_output`: Final Table results.
