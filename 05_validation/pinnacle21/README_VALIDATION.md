# Pinnacle 21 Validation Runbook

## Current Status
- `define.xml` metadata shells are located under `m5/datasets/bv-car20-p1/tabulations/sdtm/` and `m5/datasets/bv-car20-p1/analysis/adam/`.
- Pinnacle 21 CLI is not pre-installed in this environment.
- No current P21 validation reports are present because no `.xpt` datasets are pre-packaged in the source code repository.

## Prerequisites
1. Generate SDTM/ADaM `.xpt` transport files by executing the master SAS pipeline (`m5/datasets/bv-car20-p1/analysis/adam/programs/00_main.sas`).
2. Install Pinnacle 21 Community (desktop or CLI tool).
3. Complete Define-XML metadata (ItemDefs, CodeLists, ValueLevel metadata, methods, and origins) before the final validation run.

## Execution
Run validation through the Pinnacle 21 Community application:
1. Select the target standard (e.g., SDTMIG 3.4 or ADaMIG 1.3).
2. Point the Source Path to the respective dataset directory:
   - SDTM: `m5/datasets/bv-car20-p1/tabulations/sdtm/`
   - ADaM: `m5/datasets/bv-car20-p1/analysis/adam/`
3. Point the Define-XML Path to the respective `define.xml` metadata file.
4. Run validation and export reports.

## Required Closure for Submission
- Resolve all `REJECT` and `ERROR` findings.
- Document all retained `WARNING` findings with clinical/programming rationale.
- Archive validation logs and final reports under `05_validation/pinnacle21`.
