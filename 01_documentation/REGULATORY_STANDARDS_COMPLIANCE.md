# Regulatory Standards Compliance Documentation

## Standards Applied to BV-CAR20-P1

### 1. FDA eCTD Standards

| Standard | Version | Implementation |
|----------|---------|----------------|
| **eCTD Specification** | v3.2.2 / v4.0 | Module 5 structure for clinical data |
| **Study Data Technical Conformance Guide** | Dec 2025 | Folder structure: 02_datasets/tabulations, 02_datasets/analysis |
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

```
BV-CAR20-P1/
├── 01_documentation/            # Formal Docs (SAP, Audit, Compliance)
│   ├── adrg/                   # Analysis Data Reviewer's Guide
│   ├── cdrg/                   # Clinical Data Reviewer's Guide  
│   └── sap/                    # Statistical Analysis Plan
├── 02_datasets/                 # Study Data (FDA SDTCG compliant)
│   ├── tabulations/            # SDTM datasets (.xpt)
│   ├── analysis/               # ADaM datasets (.xpt)
│   ├── define/                 # define.xml v2.1
│   └── legacy/                 # Source/converted data
├── 03_programs/                 # SAS/R programs (ASCII text)
│   ├── tabulations/            # SDTM programs
│   ├── analysis/               # ADaM programs
│   └── reporting/              # TFL programs
├── 04_output/                   # RTF/PNG results
└── 05_validation/               # QC documentation
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
```
L1_ingestion/  L2_sdtm/  L3_adam/  L4_reporting/  L5_metadata/
```

### Revised (eCTD-compliant)
```
02_datasets/  03_programs/  01_documentation/  05_validation/
```

**Rationale:** FDA expects Module 5 structure for regulatory review, not internal workflow layers.

---

## Quality Control Implementation

| QC Level | Method | Tables |
|----------|--------|--------|
| **1** | Manual review vs raw data | L-SD1, L-AE1, L-SAE1 |
| **2** | Program/log review | Table 3.2 (AE Summary) |
| **3** | Independent programming | Table 1.1, 2.1, 3.3-3.5 (AESI) |

---

**Last Updated:** 2026-01-22  
**Compliance Verified Against:** FDA SDTCG v4.4, CDISC SDTM/ADaM IG
