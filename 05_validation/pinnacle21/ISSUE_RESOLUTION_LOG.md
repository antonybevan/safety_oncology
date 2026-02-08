# Pinnacle 21 Validation Issue Resolution Log
**Study**: BV-CAR20-P1  
**Tooling**: Pinnacle 21 CLI  
**Date**: 2026-02-08

## Validation Status
- Validation is **pending execution** in this workspace.
- Reason: `p21` CLI not currently installed and no current `.xpt` payload is staged under `02_datasets/tabulations` and `02_datasets/analysis`.

## Run Command
```powershell
powershell -ExecutionPolicy Bypass -File 99_utilities/run_p21_validation.ps1
```

## To Be Completed After Run
1. Attach SDTM report: `05_validation/pinnacle21/p21_sdtm_report.csv`
2. Attach ADaM report: `05_validation/pinnacle21/p21_adam_report.csv`
3. Record all REJECT/ERROR findings and disposition.
4. Record any retained WARNING with rationale and approver sign-off.

## Sign-Off
- Programming Lead: Pending
- QC Lead: Pending
- Biostatistics Lead: Pending
