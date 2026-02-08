# Code Review & Version Control Guide
**Study**: BV-CAR20-P1  
**Document Version**: 1.0  
**Date**: 2026-02-08

---

## 1. Purpose
This document defines the version control and code review procedures for Study BV-CAR20-P1 statistical programming deliverables. These procedures ensure traceability, reproducibility, and audit-readiness.

## 2. Version Control

### 2.1 Repository Structure
```
BV-CAR20-P1/
├── .git/                    # Version control metadata
├── .gitignore               # Excludes sensitive/generated files
├── 01_documentation/        # Versioned documentation
├── 02_datasets/             # Data storage (large files excluded)
├── 03_programs/             # All SAS programs (fully versioned)
├── 04_outputs/              # Generated outputs (selectively versioned)
└── 05_validation/           # Validation logs and evidence
```

### 2.2 Branching Strategy
| Branch | Purpose | Protection |
|:-------|:--------|:-----------|
| `main` | Production-ready code | Protected, requires PR |
| `develop` | Integration branch | Protected, requires review |
| `feature/*` | New feature development | Developer discretion |
| `hotfix/*` | Critical fixes | Fast-track review |

### 2.3 Commit Standards
- **Format**: `[CATEGORY] Brief description`
- **Categories**: 
  - `[DATA]` - Data generation/processing
  - `[SDTM]` - SDTM tabulation changes
  - `[ADAM]` - ADaM derivation changes
  - `[TLF]` - Tables/Listings/Figures
  - `[DOC]` - Documentation updates
  - `[FIX]` - Bug fixes
  - `[QC]` - QC-related changes

**Example**:
```
[ADAM] Add DLTEVLFL population flag to ADSL
```

## 3. Code Review Process

### 3.1 Review Checklist
- [ ] Program executes without errors or warnings
- [ ] Output matches specifications
- [ ] Code follows programming standards
- [ ] Comments are clear and sufficient
- [ ] Labels and formats are correct
- [ ] Traceability variables are populated

### 3.2 Review Levels
| Level | Scope | Reviewer | Documentation |
|:------|:------|:---------|:--------------|
| 1 | Output spot-check | Self | None required |
| 2 | Full program review | Peer | Review checklist |
| 3 | Independent programming | Senior | Comparison log |

### 3.3 Sign-Off Requirements
| Deliverable Type | Required Level | Approvers |
|:-----------------|:---------------|:----------|
| Exploratory analysis | 1 | Programmer |
| Supporting tables | 2 | Programmer + Reviewer |
| Primary efficacy | 3 | Lead + Biostatistician |
| Safety summaries | 3 | Lead + Medical Writer |

## 4. Audit Trail

### 4.1 Change Log
All program changes are tracked via:
1. **Git commit history** - Complete change record
2. **Modification history block** - In-program documentation
3. **QC log** - Review evidence

### 4.2 Regulatory Compliance
This version control system supports:
- FDA 21 CFR Part 11 (electronic records)
- ICH E6(R2) (GCP audit trail)
- CDISC Foundational Standards

---

## 5. Quick Reference

### Common Git Commands
```bash
# Check status
git status

# Stage and commit
git add .
git commit -m "[ADAM] Update population flags"

# Push to remote
git push origin develop

# Create feature branch
git checkout -b feature/new-tlf
```

---
*This document is part of the study audit trail.*
