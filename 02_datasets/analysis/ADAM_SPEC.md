# ADaM Mapping Specifications: ADSL

**Dataset:** ADSL (Analysis Data Subject Level)  
**Description:** Foundation for all analysis datasets. One record per subject.

| Variable | Label | Source / Derivation |
| :--- | :--- | :--- |
| **STUDYID** | Study Identifier | `sdtm.dm.STUDYID` |
| **USUBJID** | Unique Subject Identifier | `sdtm.dm.USUBJID` |
| **SUBJID** | Subject Identifier | `sdtm.dm.SUBJID` |
| **SITEID** | Study Site Identifier | `sdtm.dm.SITEID` |
| **AGE** | Age | `sdtm.dm.AGE` |
| **AGEU** | Age Units | "YEARS" |
| **SEX** | Sex | `sdtm.dm.SEX` |
| **RACE** | Race | `sdtm.dm.RACE` |
| **ETHNIC** | Ethnicity | `sdtm.dm.ETHNIC` |
| **TRT01P** | Planned Trt for Period 01 | Copy of `ARM` |
| **TRT01PN** | Planned Trt (N) | 1 if DL1, 2 if DL2, 3 if DL3 |
| **TRT01A** | Actual Trt for Period 01 | Copy of `ACTARM` |
| **TRT01AN** | Actual Trt (N) | 1 if DL1, 2 if DL2, 3 if DL3 |
| **TRTSDT** | Date of First Dose | First `EXSTDTC` where `EXTRT` = 'BV-CAR20' |
| **TRTEDT** | Date of Last Dose | Last `EXENDTC` where `EXTRT` = 'BV-CAR20' |
| **RFSTDTC** | Subject Ref Start Date | `sdtm.dm.RFSTDTC` |
| **ITTFL** | Intent-To-Treat Pop Flag | "Y" for all subjects in DM |
| **SAFFL** | Safety Population Flag | "Y" if `TRTSDT` is not null |
| **EFFFL** | Efficacy Pop Flag | "Y" if `SAFFL`="Y" AND subject has rec in `sdtm.rs` |
| **AGEGR1** | Pooled Age Group 1 | "<65", ">=65" |

---

# ADaM Mapping Specifications: ADAE

**Dataset:** ADAE (Analysis Data Adverse Events)  
**Description:** Analysis of Adverse Events. One record per SDTM event.

| Variable | Label | Source / Derivation |
| :--- | :--- | :--- |
| **USUBJID** | Unique Subject Identifier | `adsl.USUBJID` |
| **AETERM** | Reported Term | `sdtm.ae.AETERM` |
| **AEDECOD** | Dictionary-Derived Term | `sdtm.ae.AEDECOD` |
| **AESEQ** | Sequence Number | `sdtm.ae.AESEQ` (Traceability) |
| **ASTDT** | Analysis Start Date | Numeric `sdtm.ae.AESTDTC` |
| **AENDT** | Analysis End Date | Numeric `sdtm.ae.AEENDTC` |
| **TRTA** | Actual Treatment | `adsl.TRT01A` |
| **AESEV** | Severity/Intensity | `sdtm.ae.AESEV` |
| **AETOXGR** | Toxicity Grade | `sdtm.ae.AETOXGR` |
| **AETOXGRN** | Toxicity Grade (N) | Numeric version of AETOXGR |
| **TRTEMFL** | Treatment Emergent Flag | "Y" if `ASTDT` >= `adsl.TRTSDT` |
| **AESIFL** | AESI Flag | `sdtm.ae.AESI_FL` |
| **ASTCTGR** | ASTCT 2019 Grade | Merged from `sdtm.suppae` where `QNAM`='ASTCTGR' |
| **AOCCPFL** | First Primary Occurrence | "Y" for first occurrence of PT per subject |

---

# ADaM Mapping Specifications: ADLB

**Dataset:** ADLB (Analysis Data Laboratory)  
**Description:** Analysis of Lab Results (Hematology). One record per analysis value.

| Variable | Label | Source / Derivation |
| :--- | :--- | :--- |
| **USUBJID** | Unique Subject Identifier | `adsl.USUBJID` |
| **TRTA** | Actual Treatment | `adsl.TRT01A` |
| **PARAMCD** | Parameter Code | `sdtm.lb.LBTESTCD` |
| **PARAM** | Parameter | `sdtm.lb.LBTEST` |
| **ADT** | Analysis Date | Numeric `sdtm.lb.LBDTC` |
| **ADY** | Analysis Relative Day | `ADT` - `adsl.TRTSDT` + (1 if >= 0 else 0) |
| **AVISIT** | Analysis Visit | `sdtm.lb.VISIT` |
| **AVAL** | Analysis Value | Numeric `sdtm.lb.LBORRES` |
| **ANRIND** | Analysis Range Indicator | `Low`, `Normal`, `High` based on Ref Ranges |
| **ABLFL** | Baseline Record Flag | "Y" for last non-missing value on or before `TRTSDT` |
| **BASE** | Baseline Value | `AVAL` where `ABLFL`="Y" |
| **CHG** | Change from Baseline | `AVAL` - `BASE` |
| **BNRIND** | Baseline Range Indicator | `ANRIND` of Baseline record |
| **SHIFT1** | Shift Baseline to Analysis | Concatenation of `BNRIND` to `ANRIND` |

---

# ADaM Mapping Specifications: ADRS

**Dataset:** ADRS (Analysis Data Response)  
**Description:** Analysis of Disease Response. One record per assessment plus derived Best Response.

| Variable | Label | Source / Derivation |
| :--- | :--- | :--- |
| **USUBJID** | Unique Subject Identifier | `adsl.USUBJID` |
| **PARAMCD** | Parameter Code | "BOR" (Best Overall Response) |
| **PARAM** | Parameter | "Best Overall Response" |
| **AVALC** | Analysis Value (Char) | `sdtm.rs.RSORRES` |
| **ADT** | Analysis Date | Numeric `sdtm.rs.RSDTC` |
| **ANL01FL** | Analysis Flag 01 | "Y" for Best Response Record (Ordered: CR > PR > SD > PD) |

---

# ADaM Mapping Specifications: ADEX

**Dataset:** ADEX (Analysis Data Exposure)  
**Description:** Analysis of Treatment Exposure. One record per infusion.

| Variable | Label | Source / Derivation |
| :--- | :--- | :--- |
| **USUBJID** | Unique Subject Identifier | `adsl.USUBJID` |
| **PARAMCD** | Parameter Code | `sdtm.ex.EXTRT` (Truncated/Coded) |
| **PARAM** | Parameter | `sdtm.ex.EXTRT` |
| **AVAL** | Analysis Value | `sdtm.ex.EXDOSE` |
| **AVALU** | Analysis Value Unit | `sdtm.ex.EXDOSU` |
| **ADT** | Analysis Date | Numeric `sdtm.ex.EXSTDTC` |
| **TRTSDT** | Date of First Dose | `adsl.TRTSDT` |
| **TRTEDT** | Date of Last Dose | `adsl.TRTEDT` |
