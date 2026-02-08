# Pinnacle 21 Validation Runbook

## Current Status
- `define.xml` exists at `02_datasets/define/define.xml` as a valid Define-XML shell.
- Pinnacle 21 CLI is not installed in this environment (command `p21 --version` not found).
- No current P21 output reports are present because no `.xpt` datasets are currently staged in `02_datasets/tabulations` or `02_datasets/analysis`.

## Prerequisites
1. Generate SDTM/ADaM `.xpt` files by running the SAS pipeline.
2. Install Pinnacle 21 CLI and ensure `p21` is on `PATH`.
3. Complete Define-XML content (ItemDefs, CodeLists, ValueLevel metadata, methods, origins) before final submission run.

## Execution
Run from repository root:

```powershell
powershell -ExecutionPolicy Bypass -File 99_utilities/run_p21_validation.ps1
```

Expected outputs:
- `05_validation/pinnacle21/p21_sdtm_report.csv`
- `05_validation/pinnacle21/p21_adam_report.csv`

## Required Closure for Submission
- Resolve all `REJECT` and `ERROR` findings.
- Document all retained `WARNING` findings with clinical/programming rationale.
- Archive validation logs and final reports under `05_validation/pinnacle21`.
