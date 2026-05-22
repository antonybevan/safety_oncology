# Regulatory Standards Compliance Documentation

## Standards Applied to BV-CAR20-P1

### 1. FDA eCTD Standards

| Standard | Version | Implementation |
|----------|---------|----------------|
| **eCTD Specification** | v3.2.2 / v4.0 | Module 5 structure for clinical data |
| **Study Data Technical Conformance Guide** | Dec 2025 | Folder structure: m5/datasets/tabulations, m5/datasets/analysis |
| **Define-XML** | v2.1 | Metadata for SDTM and ADaM datasets |

### 2. CDISC Standards

| Standard | Version | Purpose |
|----------|---------|---------|
| **SDTM** | v1.7 | Study Data Tabulation Model |
| **SDTMIG** | v3.4 | Implementation Guide (oncology-specific) |
| **ADaM** | v2.1 | Analysis Data Model |
| **ADaMIG** | v1.3 | Implementation Guide |

### 3. PhUSE Good Programming Practices

- **SAS Programming:** Header blocks, revision history, internal comments
- **QC Levels:** 1 (manual), 2 (program review), 3 (double programming)
- **Naming Conventions:** Consistent across all programs
- **Traceability:** Analysis Results Metadata (ARM) in define.xml

### 4. ICH Guidelines

- **ICH E6 (R2):** Good Clinical Practice
- **ICH E3:** Structure and Content of Clinical Study Reports
- **ICH E9:** Statistical Principles for Clinical Trials

---

## Folder Structure Rationale

### eCTD Module 5 Alignment

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
│                       ├── reporting/          # TFL Generation Programs
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
    ├── qc_audit_tool.py                # Automated QC log auditor
    └── utilities/                      # Sponsor developer utility scripts
        ├── GIT_PUSH.sas                # Git stage, commit, and push automation
        └── GIT_RESCUE.sas              # Branch restore and emergency recovery
```

### Key Compliance Points

1. **File Format:** SAS Transport Format (.xpt) for datasets
2. **Size Limit:** XPORT datasets ≤ 5GB
3. **Naming:** No spaces, only alphanumeric + hyphen/underscore
4. **Path Length:** ≤150 characters
5. **Empty Folders:** Not permitted in submission

---

## Deviation from Initial Structure

### Original (Development-focused)
```text
L1_ingestion/  L2_sdtm/  L3_adam/  L4_reporting/  L5_metadata/
```

### Revised (Submission-ready eCTD-compliant)
```text
m5/datasets/bv-car20-p1/
  ├── tabulations/sdtm/
  └── analysis/adam/
```

**Rationale:** FDA expects Module 5 structure for regulatory review, not internal development workflow layers. All source programs and utility scripts must be placed directly inside the respective `programs/` subdirectories under tabulations and analysis to comply with the FDA Study Data Technical Conformance Guide (SDTCG) Section 3.7.

---

## Quality Control Implementation

| QC Level | Method | Tables |
|----------|--------|--------|
| **1** | Manual review vs raw data | L-SD1, L-AE1, L-SAE1 |
| **2** | Program/log review | Table 3.2 (AE Summary) |
| **3** | Independent programming | Table 1.1, 2.1, 3.3-3.5 (AESI) |

---

**Last Updated:** 2026-02-08  
**Compliance Verified Against:** FDA SDTCG v4.4, CDISC SDTM/ADaM IG

