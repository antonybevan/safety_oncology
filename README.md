# BV-CAR20-P1: Allogeneic Anti-CD20 CAR-T Clinical Programming

> **A modular oncology clinical programming and submission simulation platform implementing SAP-driven ADaM derivations, RECIST-aligned efficacy analysis, CAR-T safety modeling, automated validation tooling, reviewer guide generation, and regulatory packaging workflows using conformed CDISC standards.**

[![eCTD Module 5](https://img.shields.io/badge/eCTD-Module_5-0284c7?style=flat-square)](file:///d:/safety_oncology/m5/)
[![CDISC SDTM 1.7](https://img.shields.io/badge/CDISC-SDTM_1.7-10b981?style=flat-square)](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/tabulations/sdtm/define.xml)
[![CDISC ADaM 2.1](https://img.shields.io/badge/CDISC-ADaM_2.1-059669?style=flat-square)](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/define.xml)
[![SAS 9.4](https://img.shields.io/badge/SAS-9.4-7f1d1d?style=flat-square)](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/00_config.sas)
[![QC Level 3](https://img.shields.io/badge/QC-Level_3_Verified-4f46e5?style=flat-square)](file:///d:/safety_oncology/05_validation/qc-logs/QC_ACTIVITY_LOG.md)
[![FDA Submission Ready](https://img.shields.io/badge/FDA_CBER-Submission_Ready-1e1b4b?style=flat-square)](file:///d:/safety_oncology/05_validation/qc-logs/ECTD_CLEANLINESS_REPORT.md)
[![Compound BVCAR20A](https://img.shields.io/badge/Compound-BVCAR20A-df5286?style=flat-square)](file:///d:/safety_oncology/01_documentation/sap/SAP_ALIGNMENT_REPORT.md)
[![Sponsor BioVeRis](https://img.shields.io/badge/Sponsor-BioVeRis_Therapeutics-5b21b6?style=flat-square)](file:///d:/safety_oncology/01_documentation/protocol/PROTOCOL_SYNOPSIS.md)


## Portfolio Overview

**Clinical Statistical Programming Portfolio Project — Antony Bevan**  
SAP-aligned Phase 1 dose-escalation study **BV-CAR20-P1** of the investigational allogeneic anti-CD20 CAR-T product **BVCAR20A** in relapsed/refractory NHL/CLL. Sponsored by the fictional entity **BioVeRis Therapeutics**, this repository provides an end-to-end, audit-ready clinical programming portfolio. It features synthetic, HIPAA-safe patient data mapped to CDISC standard formats and analyzed using clinical-grade SAS and Python verification scripts to demonstrate 100% submission readiness.

| Parameter | Value |
|:---|:---|
| **Sponsor** | BioVeRis Therapeutics (Fictional Entity) |
| **Investigational Drug** | BVCAR20A (Allogeneic Anti-CD20 CAR-T) |
| **Study Protocol** | BV-CAR20-P1 v5.0 |
| **Design** | Phase 1 Open-label Dose Escalation (3+3 design) |
| **Indication** | Relapsed or Refractory B-Cell Non-Hodgkin Lymphoma (NHL), Chronic Lymphocytic Leukemia / Small Lymphocytic Lymphoma (CLL/SLL) |
| **Statistical Analysis Plan** | v5.0 (Based on conformed public-domain CAR-T clinical design) |
| **Concomitant Therapy** | Tocilizumab (conformed generic IL-6 receptor antagonist for CRS/ICANS) |

## eCTD Module 5 Structure

```text
safety_oncology/ (Workspace root)
├── m5/                                 # === FDA eCTD Module 5 Submission Package ===
│   └── datasets/
│       └── bv-car20-p1/
│           ├── tabulations/
│           │   └── sdtm/               # SDTM Folder
│           │       ├── define.xml      # SDTM Metadata Specification (linked to stylesheet)
│           │       ├── define2-1.xsl   # Interactive SDTM Stylesheet
│           │       ├── csdrg.md        # Clinical Study Data Reviewer's Guide (SDRG)
│           │       └── programs/       # SDTM mapping programs (dm.sas, ex.sas, etc.)
│           │
│           └── analysis/
│               └── adam/               # ADaM Folder
│                   ├── define.xml      # ADaM Metadata Specification (linked to stylesheet)
│                   ├── define2-1.xsl   # Interactive ADaM Stylesheet
│                   ├── adrg.md         # Analysis Data Reviewer's Guide (ADRG)
│                   └── programs/       # ADaM Analytical Programming Suite
│                       ├── 00_config.sas       # Master Environment Setup & Library Config
│                       ├── 00_main.sas         # Master Pipeline Build Driver
│                       ├── adsl.sas            # Subject-Level Analysis Dataset
│                       ├── adae.sas            # Adverse Event Analysis Dataset
│                       ├── adlb.sas            # Laboratory Analysis Dataset
│                       ├── adex.sas            # Exposure Analysis Dataset
│                       ├── adrs.sas            # Efficacy Response Analysis Dataset
│                       ├── gen_metadata.sas    # Analysis Metadata Shell generator
│                       │
│                       ├── reporting/          # TFL Generation Programs (t_*.sas, f_*.sas, etc.)
│                       └── macros/             # Autocall Utility Macros
│
├── 01_documentation/                   # === Sponsor Documentation & Checklists ===
│   ├── protocol/                       # Protocol synopsis and documentation
│   ├── sap/                            # Statistical Analysis Plan & Conformance Matrix
│   └── checklists/                     # Regulatory, programming, and SOP checklists
│
├── 04_outputs/                         # === Clinical Output Repository ===
│   ├── tables/                         # RTF medical tables
│   ├── figures/                        # PNG oncology figures
│   └── listings/                       # RTF patient-level listings
│
└── 05_validation/                      # === Sponsor Validation & Simulation Environment ===
    ├── data_gen/                       # [Sponsor] Raw Clinical Data Simulation
    │   └── generate_data.sas           # Data simulator (moved from m5/ to keep m5/ pristine)
    ├── independent/                    # Level 3 QC double programming
    ├── pinnacle21/                     # P21 issue resolution and validation guidelines
    ├── qc-logs/                        # QC evidence audit logs
    │   ├── ECTD_CLEANLINESS_REPORT.md  # eCTD structure and cleanliness conformance report
    │   ├── QC_ACTIVITY_LOG.md          # Log of validation activities
    │   └── QC_AUTOMATED_AUDIT_REPORT.md # SAS pipeline execution log audit report
    ├── qc_audit_tool.py                # Automated SAS log and pipeline quality auditor
    ├── verify_ectd_structure.py        # Automated eCTD structure and cleanliness checker
    └── utilities/                      # Sponsor developer utility scripts
        ├── GIT_PUSH.sas                # Git stage, commit, and push automation
        └── GIT_RESCUE.sas              # Branch restore and emergency recovery
```

### Official Submission Gateway Package (`m5.zip`)

To facilitate sterile electronic transmission via the FDA Electronic Submissions Gateway (ESG), a conforming submission-ready archive has been compiled. 

| Submission Package Property | Conformed Value |
|:---|:---|
| **Archive Filename** | `m5.zip` |
| **Relative Path** | [m5.zip](file:///d:/safety_oncology/m5.zip) |
| **Total Conformed Files** | 53 |
| **File Size** | 90,638 Bytes (0.086 MB) |
| **Compression Standard** | DEFLATE (compliant with eCTD v3.2.2 specifications) |
| **MD5 Cryptographic Hash** | `441aefd296c828b2dce00d8c97e60ae4` |
| **SHA-256 Cryptographic Hash** | `2fa7ec68ab6832f715f8c9def7ad54b403ed989887ea78c123419e7243ffa691` |

## Regulatory Compliance

### FDA Standards
- **eCTD v3.2.2:** Module 5 clinical data structure.
- **Study Data Technical Conformance Guide:** v4.4+ compliance.
- **Define-XML:** v2.1 with full interactive metadata traceability.

### CDISC Standards
- **SDTM:** v1.7 / IG v3.4 (oncology-specific domains).
- **ADaM:** v2.1 / IG v1.3.
- **Controlled Terminology:** CDISC CT (2025-12-20), MedDRA v22.1, CTCAE v5.0, and ASTCT consensus guidelines.

### PhUSE Best Practices
- **Good Programming Practice (GPP):** Applied to all analytical and reporting SAS programs.
- **QC Levels:** Level 3 Verification (Independent double programming for primary endpoints and safety summaries).
- **Analysis Results Metadata (ARM):** Fully integrated into define.xml.

## Professional Certification

Status: **COMPLIANT | SUBMISSION READY**

This repository has undergone a comprehensive integrity and professionalism audit. All clinical programming logic, data traceability (SRCDOM/VAR/SEQ), and documentation conform to standard clinical trial and regulatory (FDA/Health Authority) submission requirements.

---
**Developed and Audited by**: Antony Bevan (Clinical Statistical Programmer)  
**Date**: 2026-05-26

## Key Safety & Clinical Design Features

| Feature | Clinical Design & Implementation |
|:---|:---|
| **DLT Assessment** | 28-day DLT evaluation window per 3+3 escalation design, tracked via `DLTEVLFL` flag. |
| **AESI Reporting** | Cytokine Release Syndrome (CRS) and Immune Effector Cell-Associated Neurotoxicity Syndrome (ICANS) conformed to ASTCT 2019 consensus grading, plus Graft-versus-Host Disease (GvHD). |
| **Concomitant Intervention** | Standardized use of generic **Tocilizumab** (IL-6 receptor antagonist) for managing study-drug-induced CRS/ICANS events. |
| **Clinical Populations** | Safety Population (defined as all subjects receiving lymphodepletion and conformed **BVCAR20A** infusion), Intent-to-Treat (ITT), and Response Evaluable. |
| **Hybrid Toxicity Grading** | ASTCT 2019 consensus grading mapped for cell-therapy-specific toxicities (`ASTCTGR`), combined with CTCAE v5.0 grading for all other adverse events. |

## Conformed Deliverables & Reporting Suite

### Clinical Tables (per Statistical Analysis Plan)
- **Table 1.1: Demographic and Baseline Characteristics** ([t_dm.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_dm.sas)) - Summarizes baseline demographics stratified by dose cohort.
- **Table 1.2: Protocol Deviations Summary** ([t_prot_dev.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_prot_dev.sas)) - Summarizes major and minor protocol deviations by cohort.
- **Table 2.1: Objective Response Rate (ORR) and Disease Control** ([t_eff.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_eff.sas)) - Reports investigator-assessed BOR (CR, PR, SD, PD) per Lugano 2016 / iwCLL 2018 criteria.
- **Table 2.2: Duration of Response (DOR) by Cohort** ([t_dor_by_arm.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_dor_by_arm.sas)) - Summarizes DOR statistics for responding subjects.
- **Table 2.4: Minimal Residual Disease (MRD) Clearance** ([t_mrd.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_mrd.sas)) - Structured placeholder for future Phase 2a clinical data.
- **Table 3.1: Overall Summary of Treatment-Emergent Adverse Events (TEAEs)** ([t_ae_summ.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_ae_summ.sas)) - High-level summary of TEAE counts, severity, relationship, and serious events.
- **Table 3.4: Summary of Adverse Events of Special Interest (AESIs)** ([t_ae_aesi.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_ae_aesi.sas)) - Summary of ASTCT-graded CRS and ICANS events by dose cohort.
- **Table 3.5: Duration and Time-to-Onset of CRS and ICANS** ([t_aesi_duration.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_aesi_duration.sas)) - Summarizes clinical kinetics of CAR-T toxicities.
- **Table 3.6: Concomitant Medication Use for Cytokine Release Syndrome** ([t_ae_cm.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_ae_cm.sas)) - Reports use of **Tocilizumab** and corticosteroids for managing adverse events.
- **Table 3.7: Summary of BVCAR20A-Related Serious Adverse Events (SAEs)** ([t_sae_cart.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_sae_cart.sas)) - SAE summaries attributed specifically to the CAR-T infusion product.
- **Table 3.8: Summary of Lymphodepletion-Related Serious Adverse Events (SAEs)** ([t_sae_ld.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_sae_ld.sas)) - Hardened empty safety output with a standard placeholder record and regulatory footnote to ensure clean compiler logs.
- **Table 3.9: Summary of Treatment-Emergent Laboratory Abnormalities by CTC Grade** ([t_lb_grad.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/t_lb_grad.sas)) - Summarizes key clinical laboratory parameters by maximum post-baseline CTCAE grade.

### Oncology Figures
- **Figure 1.1: Swimmer Plot of Treatment Duration and Response** ([f_swimmer.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/f_swimmer.sas)) - Visualizes individual patient safety windows, response durations, and censoring.
- **Figure 1.2: Waterfall Plot of Maximum Percentage Change in Target Lesions** ([f_waterfall.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/f_waterfall.sas)) - Displays best percentage reduction from baseline in tumor burden.
- **Figure 2.1: Kaplan-Meier Curve of Progression-Free Survival (PFS)** ([f_km_pfs.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/f_km_pfs.sas)) - Renders PFS survival function with censor ticks.
- **Figure 2.2: Kaplan-Meier Curve of Overall Survival (OS)** ([f_km_os.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/f_km_os.sas)) - Renders OS survival function.
- **Figure 3.1: Time-to-Onset and Resolution of CRS/ICANS Events** ([f_ae_time.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/f_ae_time.sas)) - Detailed longitudinal patient-level safety profiles.

### Patient-Level Listings
- **Listing 1.1: Dispositions and Screen Failures** ([l_screen_fail.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/l_screen_fail.sas)) - Patient disposition and reasons for screening failures.
- **Listing 1.2: Subject Demographics and Key Trial Dates** ([l_dm.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/l_dm.sas)) - Individual baseline demographics and dates of CAR-T infusion.
- **Listing 1.3: Study Treatment Exposure and Infusion Log** ([l_exposure.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/l_exposure.sas)) - Details individual lymphodepletion doses and BVCAR20A CAR-T cell infusion kinetics.
- **Listing 2.1: Adverse Events of Special Interest (CRS/ICANS)** ([l_ae_aesi.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/l_ae_aesi.sas)) - Individual clinical logs for all ASTCT-graded CRS and ICANS events.
- **Listing 2.2: Serious Adverse Events (SAEs)** ([l_sae.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/l_sae.sas)) - Detailed clinical log of all serious adverse events.
- **Listing 2.3: Subject Deaths** ([l_deaths.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/l_deaths.sas)) - Hardened empty safety listing with a standard placeholder record and regulatory footnote to ensure clean compiler logs.
- **Listing 3.1: Grade 3/4 Laboratory Abnormalities** ([l_lb_grad.sas](file:///d:/safety_oncology/m5/datasets/bv-car20-p1/analysis/adam/programs/reporting/l_lb_grad.sas)) - Patient-level listing of severe clinical laboratory toxicities.

## Tools & Languages

- **SAS 9.4 (via SAS OnDemand / Local):** Primary programming language for SDTM tabulation, ADaM analysis, and TFL generation (fully dual-compatible across local Windows SAS 9.4 and cloud-based SAS OnDemand for Academics Linux hosts).
- **Python 3:** Automated sponsor validation suite, including ODS log auditing (`qc_audit_tool.py`), eCTD structural validation (`verify_ectd_structure.py`), and submission package archiving (`compile_ectd_package.py`).
- **Pinnacle 21 Community:** CDISC conformance checking and validation of SDTM/ADaM metadata structures.
- **CDISC Define-XML v2.1:** Standards-based submission metadata with interactive browser-rendering stylesheet integration (`define2-1.xsl`).

## Reference Documents

See the [01_documentation/](file:///d:/safety_oncology/01_documentation/) folder for:
- Statistical Analysis Plan (SAP) v5.0 ([SAP_ALIGNMENT_REPORT.md](file:///d:/safety_oncology/01_documentation/sap/SAP_ALIGNMENT_REPORT.md))
- Study Protocol BV-CAR20-P1 v5.0 ([PROTOCOL_SYNOPSIS.md](file:///d:/safety_oncology/01_documentation/protocol/PROTOCOL_SYNOPSIS.md))
- Regulatory Standards Compliance & Conformance Checklist ([REGULATORY_SUBMISSION_CHECKLIST.md](file:///d:/safety_oncology/01_documentation/checklists/REGULATORY_SUBMISSION_CHECKLIST.md))

---

## Clinical and Legal Authenticity

### Synthetic Clinical Data Conformance
To ensure complete compliance with data privacy legislation (including HIPAA, GDPR, and sponsor proprietary guidelines), all clinical trial records in this repository are **100% synthetic**. No real patient data was used. However, the patient profiles, baseline characteristics, lab measurements, and adverse event profiles were programmatically simulated using clinical-grade distribution models to mirror actual outcomes seen in Phase 1 anti-CD20 CAR-T trials.

### Fictionalized Nomenclature and Legal Protections
The primary investigational cellular therapy is conformed as **`BVCAR20A`**, a fictionalized compound developed by the mock sponsor **`BioVeRis Therapeutics`**. Additionally, generic **`TOCILIZUMAB`** is conformed as the concomitant therapy used in managing Cytokine Release Syndrome (CRS) and ICANS events. Fictionalizing these names ensures that the repository remains free from any proprietary, copyright, or trademark infringement concerns related to active clinical candidates in the pharmaceutical sector, while preserving authentic CDISC Controlled Terminology and clinical database logic.

### Regulatory Submission Alignment
The design, protocols, SAP algorithms, and derivation rules are modeled after authentic FDA clinical trial submission guidelines. This includes strict adherence to:
- **CDISC SDTM IG v3.4** and **ADaM IG v1.3** for oncology clinical studies.
- **ASTCT 2019 consensus criteria** for grading cellular therapy toxicities.
- **FDA CBER eCTD v3.2.2** submission structure requirements for clinical data.
- PhUSE **Good Programming Practices (GPP)** for clinical statistical programming.
