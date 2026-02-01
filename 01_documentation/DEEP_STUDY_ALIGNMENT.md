# Deep Study Alignment & Source Synthesis: PBCAR20A-01

> **Source Interaction:** This document synthesizes information from 75 sources including Protocol, SAP, ADaM Traceability, and Oncology Best Practices.

### Query 1: Synthesize the study design across all sources. How do the Protocol, SAP, and ADaM Traceability documents define the dose escalation (3+3 vs BOIN) and its impact on the ADAE and ADSL datasets?

**A:** **AUDIT REPORT: STUDY DESIGN SYNTHESIS & DERIVATION LOGIC**
**STUDY:** PBCAR20A-01
**STATUS:** CRITICAL FINDING – SOURCE CONTAMINATION DETECTED

**EXECUTIVE SUMMARY**
You have commingled source documentation for two distinct studies in your library: **PBCAR20A-01** (Precision BioSciences) and **Nivatrotamab Trial 402** (Y-mAbs Therapeutics).
*   **PBCAR20A-01** utilizes a standard **3+3 Dose Escalation** design [1], [2].
*   **Nivatrotamab Trial 402** utilizes a **modified BOIN (mBOIN)** design [3], [4].

**DIRECTION:**
For the PBCAR20A-01 submission, **you must ignore all mBOIN logic** found in the Nivatrotamab sources. Implementing BOIN logic for PBCAR20A-01 will result in a submission-blocking derivation error. The following analysis strictly enforces the **3+3 design** mandated by the PBCAR20A-01 Protocol V5.0 and SAP.

---

### TASK 1 — PROTOCOL → ADaM LOGIC EXTRACTION (PBCAR20A-01 ONLY)

**1. Dose Escalation Method (3+3)**
*   **Protocol Source:** "Phase 1... will follow a standard 3 + 3 design... until a DLT is observed and the MTD is established." [1]
*   **Operational Logic:**
    *   IF `NDLT` (Number of DLTs) in cohort = 0 (of 3) $\rightarrow$ Escalate.
    *   IF `NDLT` = 1 (of 3) $\rightarrow$ Expand cohort to 6.
    *   IF `NDLT` $\le$ 1 (of 6) $\rightarrow$ Escalate.
    *   IF `NDLT` $\ge$ 2 (of 3-6) $\rightarrow$ Stop; MTD exceeded [5].
*   **Ambiguity Flag:** Protocol mentions "possibility of a single de-escalation" [2]. Logic must handle `DOSE_LEVEL = -1`.

**2. DLT Evaluation Window**
*   **Protocol Source:** "28-day DLT evaluation period" [6].
*   **Derivation Logic:**
    *   `DLT_WINDOW_END` = `TRTSDT` (PBCAR20A) + 28 Days.
    *   Any DLT event where `ASTDT` > `DLT_WINDOW_END` is **NOT** a DLT for dose escalation (unless attributed to delayed toxicity by SRC).

**3. Safety Population (SAFFL)**
*   **Protocol Source:** "Safety analysis population includes all subjects who receive study treatment... starting with Lymphodepletion." [7]
*   **Derivation Logic:**
    *   IF `EX.EXTRT` IN ('FLUDARABINE', 'CYCLOPHOSPHAMIDE', 'PBCAR20A') AND `EX.EXOCCUR` = 'Y' THEN `SAFFL` = 'Y'.
    *   *Correction:* Protocol V5.0 implies Safety is "receive study treatment" [8], but SAP clarifies "starting with Lymphodepletion" [7]. **SAP rules apply.**

**4. DLT Evaluable Population (DLTEVALFL)**
*   **Protocol Source:** "Evaluable study subjects... are defined as those who either complete their treatment period through Day 28 or experience a DLT." [9]
*   **Derivation Logic:**
    *   IF `SAFFL` = 'Y' AND (`ADSL.TRTDUR` $\ge$ 28 OR `ADAE.DLTFL` = 'Y') THEN `DLTEVALFL` = 'Y'.
    *   *Constraint:* Subjects who discontinue prior to Day 28 for reasons *other* than DLT (e.g., progression, withdrawal) are **NOT** evaluable for dose escalation and must be replaced [9].

---

### TASK 2 — SAP CONFLICT DETECTION

**Comparison:** PBCAR20A-01 Protocol V5.0 [10] vs. PBCAR20A-01 SAP [11]

| Rule | Protocol V5.0 Position | SAP Position | Conflict | Resolution (Conservative) | Justification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Study Phases** | Phase 1/2a with expansion cohorts [12]. | "Subject enrollment will be discontinued after the completion of Phase 1. The study will not progress to Phase 2a." [13] | **YES** | **Abort Phase 2a derivations.** | SAP explicitly cancels Phase 2a. Programming Phase 2a flags is waste. |
| **Safety Population** | Subjects who receive study treatment (ambiguous if LD included) [8]. | Explicitly includes subjects "starting with Lymphodepletion" [7]. | **MINOR** | **Include LD-only subjects.** | SAP provides greater specificity. |
| **TEAE Start** | Not explicitly defined relative to LD vs CAR-T in Protocol snippets. | TEAE defined relative to "first dose of study drug(s)" [14] (Note: Source 348 is generic, refer to SAP [15] "related to investigational product"). | **AMBIGUOUS** | **Define TEAE relative to LD start.** | SAP [7] defines Safety pop starting at LD. Events during LD are TEAEs of the *regimen*, even if not CAR-T. |

---

### TASK 3 — ADAE HARDENING

**Issue 1: Treatment Emergence (TEAE) Timing**
*   **Risk:** The study involves Lymphodepletion (Day -5 to -3) followed by CAR-T (Day 0) [16]. Standard ADaM logic often flags TEAEs only after `TRTSDT`. If `TRTSDT` is set to CAR-T infusion, toxicities from Fludarabine (cytopenias) occurring on Day -2 will be dropped from safety tables.
*   **Fix:**
    *   Create `LDSTDT` (First Dose Lymphodepletion).
    *   Create `CARTDT` (First Dose PBCAR20A).
    *   `TRTEMFL`: IF `ASTDT` $\ge$ `LDSTDT` THEN 'Y'.
    *   `POSTCARFL`: IF `ASTDT` $\ge$ `CARTDT` THEN 'Y'.
*   **ADRG Note:** "TEAEs are defined relative to the start of Lymphodepletion chemotherapy, as this constitutes the start of the conditioning regimen."

**Issue 2: DLT Flagging in 3+3**
*   **Risk:** DLTs are manually adjudicated by the Safety Review Committee (SRC). Programmatic derivation based strictly on Grade 3+ logic is unsafe because the protocol allows exceptions (e.g., "excluding toxicities clearly related to disease progression" [17]).
*   **Fix:**
    *   Do not derive `DLTFL` programmatically.
    *   Map `DLTFL` from a hard-coded spreadsheet or specific CRF checkbox (e.g., `AE.AESPID` or `SUPPAE`).
    *   *Validation:* Flag any Grade $\ge$ 3 event in the first 28 days that is *not* marked as a DLT for medical review.

---

### TASK 4 — DLT FAILURE MODES (3+3 DESIGN)

**Failure Mode 1: The "Unevaluable" Completer**
*   **Scenario:** Subject receives CAR-T, develops rapid progression on Day 14, and withdraws. No DLT observed.
*   **Incorrect Outcome:** Counting this subject as "0 DLTs" in the 3+3 denominator.
*   **Correct Logic:** This subject is **NOT** `DLTEVALFL`. They did not complete the 28-day window and did not have a DLT. They must be replaced.
*   **Impact:** If included in the denominator, you dilute the toxicity rate and may falsely escalate dose.

**Failure Mode 2: DLT after Day 28**
*   **Scenario:** Subject has a DLT on Day 35.
*   **Incorrect Outcome:** Marking `DLTFL` = 'Y' for Dose Escalation analysis.
*   **Correct Logic:** Event is a TEAE, but for the specific `PARAMCD` "DLT for Dose Escalation", the window is hard-stopped at Day 28.
*   **Impact:** Incorrectly stopping dose escalation.

**Failure Mode 3: Retreatment Contamination**
*   **Scenario:** Subject receives second dose of CAR-T.
*   **Incorrect Outcome:** Counting AEs from the second infusion towards the dose escalation decision of the first cohort.
*   **Correct Logic:** 3+3 decisions are based strictly on **Cycle 1 / First Infusion** data. Censor safety data for escalation purposes at the start of retreatment.

---

### TASK 5 — TRACEABILITY AUDIT

**Target:** One Cytokine Release Syndrome (CRS) DLT.

| Variable | SDTM Source | ADaM Derivation / Logic | Traceability Check |
| :--- | :--- | :--- | :--- |
| **USUBJID** | `AE.USUBJID` | Direct Map | Matches ADSL? |
| **AEDECOD** | `AE.AEDECOD` | "Cytokine release syndrome" | Check MedDRA version. |
| **ASTDT** | `AE.AESTDTC` | ISO $\rightarrow$ Numeric | Must be $\ge$ `ADSL.TRTSDT`. |
| **AETOXGR** | `AE.AESEV` / `SUPPAE` | Map "Severe" or numeric grade | Protocol [18] mentions Gr $\ge$ 3 is standard DLT anchor. |
| **DLTFL** | `AE.AESPID` or `SUPPAE` | **SRC Adjudication** (Not derived) | **CRITICAL:** Do not derive. Merge from adjudication log. |
| **DLT_WINDOW**| N/A | `ADSL.TRTSDT` + 28 days | Check if `ASTDT` $\le$ `TRTSDT` + 28. |
| **SRCSEQ** | `AE.AESEQ` | Retain original sequence | Required for back-tracing. |

---

### TASK 6 — ADRG SAFETY SECTION REWRITE

**2.2 Protocol Design (Safety)**
The study follows a standard 3+3 dose escalation design (Protocol PBCAR20A-01). Note: References to "mBOIN" or "Nivatrotamab" in the raw data transfer specifications are artifacts of the CRO library and do not apply to this study. Phase 2a (Dose Expansion) was cancelled per Sponsor decision; all analyses are restricted to Phase 1 Dose Escalation.

**3.1 Analysis Populations**
*   **SAFFL (Safety Population):** All subjects who received any component of study treatment, defined as the start of Lymphodepletion (Fludarabine/Cyclophosphamide).
*   **DLTEVALFL (DLT Evaluable Population):** Subset of SAFFL who received PBCAR20A and either (1) completed the 28-day DLT observation period, or (2) experienced a DLT prior to discontinuation. Subjects discontinuing prior to Day 28 without DLT are excluded and replaced.

**3.2 Data Limitations**
Due to the termination of the study after Phase 1 [13], long-term efficacy endpoints (OS, PFS) are censored early. Dose Level 2 (240x10^6 cells) was skipped; dosing proceeded from Level 1 to Level 3 (480x10^6 flat dose) based on Protocol V4 amendments [13].

---

### TASK 7 — REVIEWER ATTACK SIMULATION

**Q1: "Why is Subject 1004 included in SAFFL but excluded from the 3+3 Dose Escalation table?"**
*   **Answer:** Subject 1004 received Lymphodepletion and PBCAR20A (qualifying for SAFFL) but withdrew consent on Day 14 due to disease progression without observing a DLT. Per Protocol Section 9.2 [9], subjects who do not complete the 28-day observation period and have no DLT are non-evaluable for the 3+3 MTD determination and were replaced.

**Q2: "Protocol V5 mentions Phase 2a expansion cohorts. Where are these datasets?"**
*   **Answer:** As noted in SAP Section 1.1 [13], enrollment was discontinued after Phase 1 completion. The study did not progress to Phase 2a. No data exists for these cohorts.

**Q3: "This AE (Seq 002) started on Day -2. Why is `TRTEMFL` = 'Y'?"**
*   **Answer:** The study treatment regimen includes Lymphodepletion chemotherapy starting at Day -5 [19]. `TRTEMFL` is defined relative to the start of the *regimen* (Lymphodepletion), not just the CAR-T infusion (Day 0), to capture toxicity related to the preparative regimen.

**Q4: "Why is the MTD not defined by the BOIN probability boundaries found in the appendix?"**
*   **Answer:** The BOIN appendices belong to a different protocol (Nivatrotamab) erroneously included in the reference library. PBCAR20A-01 strictly follows the 3+3 algorithm as defined in Protocol Section 3.1.1 [1].

**Q5: "Subject 1006 has a Grade 3 Cytopenia on Day 10. Why is `DLTFL` 'N'?"**
*   **Answer:** Per Protocol Section 3.8, certain hematologic toxicities are excluded from the DLT definition unless they persist beyond specific timepoints (e.g., Day 28) or are refractory to transfusion. The SRC adjudicated this event as non-DLT based on recovery kinetics. `DLTFL` reflects the adjudicated status, not a raw grade derivation.

### Query 2: Extract the exact tumor response criteria (Lugano 2014 or RECIST 1.1) from the Protocol and cross-reference with the ADaM Oncology Examples. How should PR and CR be mapped in the ADRS domain?

**A:** **ONCOLOGY SAFETY PROGRAMMING — PROTOCOL TO ADAM DERIVATION AUDIT**

**REVIEW STATUS:** CONDITIONAL ACCEPTANCE PENDING LOGIC CORRECTION
**SEVERITY:** HIGH (Protocol/Standard Mismatch)

You have requested a cross-reference between Protocol PBCAR20A-01 and the ADaM Oncology Examples regarding Tumor Response. 

**IMMEDIATE FINDING:** The Protocol **DOES NOT** use RECIST 1.1 for the primary efficacy evaluation of the NHL (Non-Hodgkin Lymphoma) or CLL/SLL cohorts. It explicitly mandates **Lugano 2016** (NHL) and **iwCLL 2018** (CLL/SLL). 

The *ADaM Oncology Examples v1.0* source provided focuses exclusively on **RECIST 1.1** [1, 2]. Therefore, you cannot simply "copy-paste" the ADaM example logic. You must adapt the *structure* of the ADaM examples but replace the *response criteria logic* with the Protocol-specific definitions.

---

### 1. PROTOCOL LOGIC EXTRACTION (SOURCE OF TRUTH)

The Protocol explicitly defines response criteria in **Section 8.1**. You must program against these definitions, not generic RECIST macros.

| Disease Cohort | Protocol Source | Criteria Standard | Key Definition (Must map to ADRS) |
| :--- | :--- | :--- | :--- |
| **NHL** | Section 8.1 [3] | **Revised Lugano Classification (2016)** | **CR:** "Complete Metabolic Response" (Score 1, 2, or 3 on 5PS; No new lesions; Bone marrow evidence negative). <br> **PR:** "Partial Metabolic Response" (Score 4 or 5 with reduced uptake; No new lesions). [4, 5] |
| **CLL/SLL** | Section 8.1 [6] | **iwCLL 2018** | **CR:** Lymph nodes: None >1.5cm; Spleen <13cm; Normal blood counts. <br> **PR:** Decrease $\ge$ 50% from baseline in Lymph nodes/Spleen. [6] |
| **Ph2a Arm B** | Inclusion Crit. 7 [7] | **Lugano 2016** | Specific entry criteria: "Partial response, but not a complete response" to prior therapy. |

** CONSTRAINT:** Do not mix Revised Lugano (PET-CT based) with Cheson 1999 or RECIST 1.1 (CT based) unless the subject is FDG-non-avid. The Protocol specifies: "The PET-CT scan or CT scan for study subjects without PET-avid tumors will be performed..." [3]. Your programming logic must account for modality.

---

### 2. ADAM ONCOLOGY EXAMPLES CROSS-REFERENCE

The *ADaM Oncology Examples v1.0* source uses RECIST 1.1. We will retain the **BDS Structure** but override the **Derivation Logic**.

| Component | ADaM Oncology Example (RECIST 1.1) [2, 8, 9] | PBCAR20A-01 Implementation (Lugano/iwCLL) | Action Required |
| :--- | :--- | :--- | :--- |
| **Input Data** | `SDTM.RS` where `RSCAT` = "RECIST 1.1" | `SDTM.RS` where `RSCAT` = "LUGANO CLASSIFICATION" or "iwCLL" | **OVERRIDE.** Filter `ADRS` source data by specific `RSCAT` defined in Protocol/SDTM. |
| **Values** | CR, PR, SD, PD, NE | **NHL:** CMR, PMR, NMR, PMD (Metabolic) <br> **CLL:** CR, PR, PD, SD | **MAP.** You must standardize Lugano "Complete Metabolic Response" to `AVALC="CR"` for pooling. |
| **Confirmation** | `derive_param_confirmed_resp` (requires 4 weeks) [10] | Protocol Section 16.2.1 implies confirmation required for BOR [11] | **RETAIN STRUCTURE.** Use the ADaM function but adjust `ref_confirm` window if Protocol differs from 28 days (Protocol implies 4 weeks for confirmation [12]). |
| **New Lesions** | `derive_param_exist_flag` checks `TU` for "NEW" [13] | **NHL:** Lugano defines PD as "New FDG-avid foci" [14] | **ADAPT.** Logic must check `RS` or `TR` for metabolic new lesions (Score 4/5), not just anatomic size increase. |

---

### 3. EXECUTION: MAPPING PR AND CR IN ADRS

You must produce a Submission-Grade mapping. Ambiguity in `AVAL` vs `AVALC` assignment leads to traceability failure.

**Assumption:** `SDTM.RS` contains the raw investigator assessment text.
**Target:** `ADRS` Dataset (BDS Structure).

#### A. Derivation Logic for `AVALC` (Character Result)
Map Protocol-specific terms to standard CDISC submission values.

```text
IF RSCAT = 'LUGANO 2016' THEN DO;
    IF RSORRES IN ('COMPLETE METABOLIC RESPONSE', 'CMR') THEN AVALC = 'CR';
    ELSE IF RSORRES IN ('PARTIAL METABOLIC RESPONSE', 'PMR') THEN AVALC = 'PR';
    ELSE IF RSORRES IN ('NO METABOLIC RESPONSE', 'STABLE DISEASE') THEN AVALC = 'SD';
    ELSE IF RSORRES IN ('PROGRESSIVE METABOLIC DISEASE', 'PMD') THEN AVALC = 'PD';
    ELSE AVALC = 'NE';
END;

IF RSCAT = 'iwCLL 2018' THEN DO;
    IF RSORRES = 'CR' THEN AVALC = 'CR';
    /* Note: iwCLL requires bone marrow confirmation for CR. 
       If SDTM.RS reflects only radiographic data, this may be 'CRi' or 'nPR'. 
       Check SAP for handling of 'CRi' (CR with incomplete marrow recovery). */
    ELSE IF RSORRES = 'PR' THEN AVALC = 'PR';
    ELSE AVALC = RSORRES; 
END;
```

#### B. Derivation Logic for `AVAL` (Numeric Rank)
The ADaM Examples source suggests a ranking scheme where `CR=1`. However, some examples reverse this (`CR=7`). **You must define this strictly in the SAP.** Based on the *ADaM Oncology Examples* [9, 15], use the following hierarchy for Best Overall Response (BOR) derivation:

*   **1** = CR (Best)
*   **2** = PR
*   **3** = SD
*   **4** = NON-CR/NON-PD (if applicable for non-measurable disease)
*   **5** = PD (Worst)
*   **6** = NE
*   **7** = MISSING

*Rationale:* The ADaM example assigns `CR` the lowest numeric value (1) or highest (7) depending on sort order required for "Best" determination. If using `min()` function for "Best", assign CR=1.

#### C. Traceability Variables (Mandatory)
FDA reviewers will trace `ADRS` back to `SDTM.RS`. You must populate these variables:

*   **SRCDOM:** "RS"
*   **SRCVAR:** "RSORRES"
*   **SRCSEQ:** `RS.RSSEQ`
*   **PARCAT1:** "Tumor Response"
*   **PARCAT2:** "Investigator" (or "Independent Review" if IERC is used)
*   **PARCAT3:** **"Lugano 2016"** or **"iwCLL 2018"** (DO NOT HARDCODE RECIST 1.1 HERE)

### 4. AUDIT FINDINGS & WARNINGS

1.  **Modality Conflict (CT vs PET):** Lugano classification relies on PET-CT. If a subject is assessed via CT only (due to non-avidity), the response criteria revert to anatomic (size-based).
    *   *Risk:* Programming logic looking for "Metabolic Response" will fail for CT-only subjects.
    *   *Fix:* Your logic must handle `RSORRES` values of "Complete Response" (Anatomic) alongside "Complete Metabolic Response". Map both to `AVALC="CR"`.

2.  **CR Confirmation in CLL:** The Protocol requires bone marrow confirmation for CR in CLL [6].
    *   *Risk:* A subject may have radiologic CR but positive bone marrow.
    *   *Fix:* Ensure `ADRS` derivation looks at the *integrated* response in `SDTM.RS` (where the investigator should have already accounted for marrow), or create a composite derivation checking `LB` (Bone Marrow) and `TR` (Nodes) if the SAP requires derived response.

3.  **"Efficacy" Terminology:** The ADaM source refers to "Efficacy". The Protocol title and objectives refer to "Clinical Activity" or "Dose-Finding".
    *   *Directive:* Ensure table titles refer to "Tumor Response" or "Clinical Activity", not "Efficacy", to align with Phase 1 objectives.

**Final Instruction:** Proceed with mapping `RSORRES` -> `ADRS.AVALC` using the Lugano/iwCLL definitions found in Protocol Section 8.1. Do not apply RECIST 1.1 sum of diameters logic to Lymphoma response derivations.

### Query 3: List all Adverse Events of Special Interest (AESI) for PBCAR20A-01. Include specific keywords for CRS, ICANS, and GvHD mentioned in any source.

**A:** **Study:** PBCAR20A-01
**Role:** Regulatory Oncology Safety Programming Lead
**Status:** **WARNING.** Derivation logic requires strict adherence to ASTCT and specific protocol definitions. Do not conflate "Infections" with AESI despite SAP grouping in summary tables.

The following list constitutes the **only** authorized Adverse Events of Special Interest (AESI) for Study PBCAR20A-01. Any expansion of this list without Protocol Amendment reference will result in a finding during traceability review.

### 1. OFFICIAL AESI LIST
**Source:** Protocol Section 7.2.1.3 [1]; SAP Section 8.2.2 [2].

| AESI Category | Protocol Definition / Requirement | Regulatory reporting Trigger |
| :--- | :--- | :--- |
| **Cytokine Release Syndrome (CRS)** | Assessed via ASTCT Consensus Grading. | DLT if Grade $\ge$ 3 does not resolve to $\le$ 2 within 72h [3]. |
| **ICANS** | Immune Effector Cell-Associated Neurotoxicity Syndrome. Assessed via ASTCT Consensus Grading. | **Critical:** In event of **encephalitis**, sponsor must be notified within 24 hours [1]. |
| **GvHD** | Graft-versus-Host Disease. Graded based on organ involvement (Skin, Liver, Gut) [4]. | DLT if Acute GvHD Grade $\ge$ 2 does not resolve within 14 days [3]. |

**Note on Infections:** While SAP Section 8.2.1 specifies listing AESIs and Infections together in Summary Table 3.5 [5], Infections are **not** defined as an AESI in Protocol Section 7.2.1.3 [1]. Programmers must maintain separate flags in `ADAE` (`AESIFL` vs `INFFL`) to allow distinct subsetting.

---

### 2. DERIVATION KEYWORDS & SEARCH TERMS
You are mandated to scan `AEDECOD`, `AETERM`, and linked `FA` (Findings About) domains for the following specific terms. These keywords are derived directly from the management guidelines and grading tables referenced in the Protocol.

#### A. Cytokine Release Syndrome (CRS)
**Derivation Logic:** `AETERM` contains "Cytokine Release Syndrome" OR (Event is linked to CRS Cluster AND Onset is proximal to infusion).
**Source:** Protocol Section 7.3.1 [6], Appendix 2 Table 14 [7]; Nivatrotamab Protocol Section 7.2.4.1 [8].

*   **Primary Term:** Cytokine release syndrome
*   **Constituent Symptoms (Must link to CRS event in `RELREC` or `ADAE` clustering):**
    *   Fever (Temperature $\ge$ 38.0°C) [6]
    *   Hypotension (requiring vasopressors/vasopressin) [7]
    *   Hypoxia (requiring nasal cannula/blow-by oxygen) [7]
    *   Difficulty breathing [6]
    *   Coagulopathy [6]
    *   Hepatic dysfunction [6]
    *   Renal dysfunction [6]
    *   Cardiac dysfunction [6]

#### B. ICANS (Neurotoxicity)
**Derivation Logic:** `AETERM` matches keyword list below OR `AECAT` = "Neurotoxicity" per ASTCT guidelines.
**Source:** Protocol Section 7.3.2 [9], Appendix 2 Table 15 [10].

*   **Primary Terms:**
    *   Immune effector cell-associated neurotoxicity syndrome
    *   Encephalopathy (specifically named as a trigger for sponsor notification) [1]
    *   Seizure (Life-threatening prolonged >5 min; or repetitive) [11]
    *   Tremor [9]
    *   Dizziness [9]
    *   Aphasia (Global aphasia defines Grade 3 if awake) [12]
    *   Delirium [9]
    *   Insomnia [9]
    *   Anxiety [9]
    *   Stupor or Coma [11]
    *   Motor weakness (Deep focal motor weakness, hemiparesis, paraparesis) [11]
    *   Cerebral edema (Decerebrate/decorticate posturing, papilledema, Cushing's triad) [11]
    *   Cranial nerve VI palsy [11]

#### C. Graft-versus-Host Disease (GvHD)
**Derivation Logic:** `AETERM` includes "GvHD" or "Graft versus Host" OR clinical presentation in Skin, Liver, or Gut with biopsy confirmation.
**Source:** Protocol Section 7.3.3 [4], Table 9 [13].

*   **Primary Term:** Graft versus host disease
*   **Organ-Specific Manifestations (Requires adjudication or linkage):**
    *   **Skin:** Maculopapular rash, Generalized erythroderma, Bullous formation [13].
    *   **Liver:** Bilirubin increase (>2 mg/dL to >15 mg/dL) [13].
    *   **Gut:** Persistent nausea, Diarrhea (Stool output >500 mL/day), Severe abdominal pain, Ileus [13].

---

### 3. REQUIRED ADaM IMPLEMENTATION
Do not improvise. Map these specific variables in `ADAE` to support AESI Tables 14.3.1.x defined in the SAP [14].

1.  **`AESIFL` (Adverse Event of Special Interest Flag):**
    *   `Y` if `AETERM` or `AEDECOD` matches the sponsor-defined MedDRA query for CRS, ICANS, or GvHD.
    *   **Constraint:** Do not auto-flag symptoms (e.g., "Fever") as AESI unless linked to the diagnosis.

2.  **`AESICAT` (AESI Category):**
    *   Values: `CRS`, `ICANS`, `GVHD`.
    *   **Note:** If an event is "Encephalitis", flag as `ICANS` but ensure the 24-hour notification flag (`SPNOTFL`) is derived in the raw data or SUPP domain [1].

3.  **`AETOXGR` (Analysis Toxicity Grade):**
    *   **Override Rule:** For CRS and ICANS, you **must** prioritize ASTCT consensus grading over CTCAE v5.0 if both are available.
    *   **Source:** Protocol Section 7.2.2 explicitly states: "The intensity of AEs and SAEs related to CRS and ICANS will be assessed based on the ASTCT grading" [15].
    *   **Failure Mode:** If you report a CRS event as Grade 2 based on CTCAE but it is Grade 1 based on ASTCT (Lee et al. 2019), the safety profile will be misrepresented. Use the ASTCT grade recorded in `FA` or `RS` domains if not in `AE`.

4.  **`AEREL` (Causality):**
    *   Ensure causality logic accounts for "Related to PBCAR20A" separately from "Related to Lymphodepletion" as SAP output 3.7 and 3.8 require separation [16].

**Audit Point:** Ensure that "Infections" are **not** flagged as `AESIFL = 'Y'` in `ADAE`. They must be handled via a separate flag (`INFFL`) to support SAP Table 3.5 [5] without corrupting the strict AESI analysis required by Protocol Section 7.2.1.3.

### Query 4: Based on 'ADaM Oncology Examples', what are the mandatory variables for a Grade 3-4 treatment-emergent toxicity summary in CAR-T therapy?

**A:** **Safety Programming Audit: Grade 3-4 Toxicity Summary (CAR-T Focus)**

**Review Status:** **ACTION REQUIRED**
**Scope:** Definition of mandatory variables for Grade 3-4 Treatment-Emergent Adverse Events (TEAE) and Laboratory Toxicities based on *ADaM Oncology Examples* and *Protocol PBCAR20A-01*.

You are attempting to summarize high-grade toxicity for a CAR-T therapy. Standard ADaM BDS implementation is insufficient for oncology safety due to bi-directional laboratory grading (Hypo- vs Hyper-) and the specific nature of Cytokine Release Syndrome (CRS) and ICANS grading.

The *ADaM Oncology Examples* [1] and *ADaMIG v1.3* [2] introduce provisional logic that must be implemented to avoid regulatory queries regarding data loss during bi-directional grading.

### 1. Mandatory ADLB Variables (Laboratory Toxicity)
For laboratory data, you cannot rely on a single `ATOXGR` variable. Oncology safety requires assessment of shifts in both directions (e.g., Hypoglycemia vs. Hyperglycemia).

| Variable | Label | Dataset | Derivation/Requirement | Failure Risk |
| :--- | :--- | :--- | :--- | :--- |
| **ATOXGRL** | Analysis Toxicity Grade Low | ADLB | **Mandatory per Source [1], [2].**<br>Derive NCI-CTCAE v5.0 grade for values *below* normal/baseline. <br>Logic: If `AVAL` < Low Criteria, assign 1-4. If `AVAL` represents high toxicity, set `ATOXGRL` = 0. | **High.** Using a single `ATOXGR` masks the direction of toxicity. FDA cannot distinguish Grade 3 Hypokalemia from Hyperkalemia without this split. |
| **ATOXGRH** | Analysis Toxicity Grade High | ADLB | **Mandatory per Source [1], [2].**<br>Derive NCI-CTCAE v5.0 grade for values *above* normal/baseline. <br>Logic: If `AVAL` > High Criteria, assign 1-4. If `AVAL` represents low toxicity, set `ATOXGRH` = 0. | **High.** See above. Essential for CAR-T where electrolyte imbalances (TLS) are frequent. |
| **ATOXDSCL** | Analysis Toxicity Description Low | ADLB | **Mandatory.** Text description of the toxicity (e.g., "Anemia", "Hypokalemia"). Must align with `ATOXGRL`. Source: [1], [2]. | **Medium.** Traceability failure. Reviewer cannot easily map numeric grade back to clinical event. |
| **ATOXDSCH** | Analysis Toxicity Description High | ADLB | **Mandatory.** Text description (e.g., "Hyperkalemia"). Must align with `ATOXGRH`. Source: [1], [2]. | **Medium.** Traceability failure. |
| **SHIFT1** | Shift Toxicity Grade Low | ADLB | **Conditional.** `BTOXGRL` || ' to ' || `ATOXGRL`. Required for shift tables. Source: [3]. | **Low.** Can be derived table-side, but safer in dataset for QC. |
| **SHIFT2** | Shift Toxicity Grade High | ADLB | **Conditional.** `BTOXGRH` || ' to ' || `ATOXGRH`. Required for shift tables. Source: [3]. | **Low.** |

### 2. Mandatory ADAE Variables (Clinical Toxicity)
For clinical AEs (specifically CAR-T AESIs like CRS/ICANS), standard `AETOXGR` is required, but specific focus must be applied to the *source* of the grading.

| Variable | Label | Dataset | Derivation/Requirement | Failure Risk |
| :--- | :--- | :--- | :--- | :--- |
| **AETOXGR** | Standard Toxicity Grade | ADAE | **Mandatory.** Mapped from SDTM `AETOXGR`. Must be numeric 1-5. Do not preserve "Grade " text prefix. Source: [4], [5]. | **Critical.** Character values (e.g., "Grade 3") prevent numeric filtering for ">= 3". |
| **TRTEMFL** | Treatment Emergent Analysis Flag | ADAE | **Mandatory.** Logic: `ASTDT` >= `TRTSDT` (First Dose). <br>*Constraint:* For CAR-T, ensure `TRTSDT` is the specific infusion date, not Lymphodepletion (LD) start date, unless analysis specifically covers LD period. Source: [6]. | **Critical.** Misclassification of LD-related toxicity as CAR-T toxicity triggers FDA Information Request. |
| **AESI** | Adverse Event of Special Interest | ADAE | **Mandatory for CAR-T.** Flag for CRS, ICANS, GvHD. Derived via MedDRA preferred term lists specified in Protocol/SAP. Source: [7], [8]. | **High.** Reviewer cannot isolate CAR-T specific safety signals without this flag. |
| **AEREL** | Analysis Causality | ADAE | **Mandatory.** Mapped from `AEREL`. Required for "Treatment-Related Grade 3-4" tables. Source: [9]. | **High.** Missing causality must be imputed as "Related" for safety summaries (Conservative Approach). |

### 3. Derivation Logic Check: Treatment Emergence (TEAE)
The definition of TEAE in CAR-T trials is high-risk due to the gap between Lymphodepletion (LD) and Infusion.

**Incorrect Logic:**
`IF AESTDT >= TRTSDT THEN TRTEMFL = 'Y';`
*Why it fails:* In CAR-T, `TRTSDT` in ADSL often defaults to the first dose of *any* study drug (LD). This lumps LD toxicities (neutropenia) with CAR-T toxicities.

**Correct Logic (Source [6], [10]):**
Define distinct phases or flags:
1.  **TRTEMFL:** Events starting on/after CAR-T Infusion.
2.  **LDTEMFL:** Events starting on/after LD start but before CAR-T Infusion.

**Regulatory Defense:**
"The analysis separates Lymphodepletion-period events from CAR-T post-infusion events to accurately characterize the toxicity profile of the cell therapy, independent of the conditioning regimen [10]."

### 4. DLT Failure Modes (Grade 3-4 Specific)
Protocol PBCAR20A-01 defines DLTs based on Grade 3-4 toxicities with *duration* constraints. A simple cut on `AETOXGR >= 3` is **false positive** for DLT derivation.

*   **Logic Gap:** A Grade 3 non-hematologic toxicity is a DLT *unless* it resolves to Grade <=2 within 72 hours [11].
*   **Mandatory Variable:** `ADUR` (Analysis Duration) or `AENDT` in ADAE to calculate duration of the Grade 3 event.
*   **Action:** Ensure `ADAE` contains duration variables derived from `AESTDTC` and `AEENDTC` to support algorithmic DLT assignment.

### 5. Audit Instructions
1.  **Check ADLB:** Does it contain `ATOXGRL` and `ATOXGRH`? If it only contains `ATOXGR`, **reject the dataset**. It cannot support the bi-directional shift tables required for hematologic safety in oncology [1].
2.  **Check ADAE:** Filter for `TRTEMFL = 'Y'`. Check the minimum `ASTDT`. If dates pre-date the CAR-T infusion (i.e., during Lymphodepletion), the flag derivation is unsafe for the primary safety analysis of the CAR-T product.
3.  **Check Missing Grades:** Ensure missing `AETOXGR` is **not** imputed to 0. It should be left missing or imputed to worst-case depending on SAP, but never 0 (which implies "No Adverse Event") [1].

### Query 5: How do the inclusion/exclusion criteria for 'r/r NHL' and 'CLL' differ across the Protocol and SAP?

**A:** **ONCOLOGY SAFETY PROGRAMMING — REGULATORY REVIEW FINDINGS**

**TO:** Lead Statistical Programmer
**FROM:** Regulatory Oncology Safety Programming Lead
**RE:** PBCAR20A-01 Inclusion/Exclusion Logic Audit (Protocol v5.0 vs. SAP v1.0)

I have audited the Inclusion/Exclusion (I/E) criteria for Non-Hodgkin Lymphoma (NHL) versus Chronic Lymphocytic Leukemia (CLL) across the provided Protocol and SAP. 

There is a **critical logical disconnect** between the SAP's instruction to "combine cohorts" and the Protocol's requirement for distinct, mutually exclusive efficacy derivations. If you blindly follow the SAP's "combine" instruction without establishing a hard derivation dependency on the I/E criteria, your ADaM datasets will fail efficacy traceability.

### 1. EXECUTION RISK: COHORT HOMOGENIZATION
The SAP explicitly instructs that "Cohort A (NHL) and Cohort B (CLL/SLL) will be combined for all analyses" [1]. This represents a **high-risk simplification**. While the safety population can be pooled, the efficacy endpoints (ORR) are governed by fundamentally incompatible algorithms (Lugano vs. iwCLL).

**FAILURE MODE:** If you treat the "Combined" instruction as a directive to process all subjects under a single set of logic, you will apply solid tumor rules (Lugano) to leukemia patients (CLL), or vice versa, resulting in incorrect `AVALC` derivations in `ADRS`.

### 2. PROTOCOL I/E LOGIC EXTRACTION (SOURCE: PROTOCOL V5.0)
The Protocol strictly segregates the disease definitions via Inclusion Criteria. You must use `SDTM.IE` to derive a hard `ADSL` flag (e.g., `EVALCRIT`) that dictates which response algorithm applies.

| Parameter | NHL Logic (Criteria 1-3) | CLL/SLL Logic (Criteria 4-5) | Derivation Constraint |
| :--- | :--- | :--- | :--- |
| **Diagnosis** | **Inc #1:** r/r CD20+ B-cell NHL confirmed by biopsy [2]. | **Inc #4:** CD20+ CLL (iwCLL guidelines) OR SLL (biopsy proven) [3]. | **Mutually Exclusive:** Subject cannot meet Inc #1 AND Inc #4. |
| **Disease Burden** | **Inc #2:** Measurable/detectable (PET-positive) per **Lugano** [4]. | **Inc #4:** Clinically measurable (CLL) or lymphadenopathy/splenomegaly (SLL) per **iwCLL** [3]. | **Source of Baseline:** `ADTR` baseline logic must switch based on this entry criterion. |
| **Prior Therapy** | **Inc #3:** 2 prior regimens (unless specific subtype exceptions apply) [4]. | **Inc #5:** ≥2 prior lines INCLUDING **BTK inhibitor AND venetoclax** [5]. | **Hard Validation:** CLL subjects missing BTK/Venetoclax history in `CM`/`AH` are protocol violators. |

### 3. SAP CONFLICT & RESOLUTION (SOURCE: SAP V1.0)
The SAP introduces ambiguity by mandating combined reporting without specifying how to handle the heterogeneous criteria in the backend data.

| Rule | Protocol Position | SAP Position | **CONFLICT** | **RESOLUTION (MANDATORY)** |
| :--- | :--- | :--- | :--- | :--- |
| **Cohort Definition** | Distinct criteria for NHL (Inc 1-3) vs. CLL (Inc 4-5) [2], [3]. | "Cohort A (NHL) and Cohort B (CLL/SLL) will be combined for all analyses" [1]. | **YES** (Operational) | Create `ADSL.COHORT` variable derived from `IE.IETESTCD`. <br> IF `IETESTCD` IN ('INCL01', 'INCL02', 'INCL03') AND `IEORRES`='Y' THEN COHORT='NHL'.<br> IF `IETESTCD` IN ('INCL04', 'INCL05') AND `IEORRES`='Y' THEN COHORT='CLL'. |
| **Response Criteria** | **Lugano 2016** for NHL [6]; **iwCLL 2018** for CLL [7]. | Mentions Lugano and iwCLL separately for endpoints [8] but pools populations for analysis tables [1]. | **Potential** | Create `ADSL.EVALCRIT`. <br> **Do not** rely on a "pooled" analysis flag alone. Efficacy derivation code must use `IF COHORT='CLL' THEN CALL iwCLL_MACRO`. |
| **Prior Therapy** | Specific requirements (BTK/Venetoclax for CLL) [5]. | No specific instruction on handling differential prior therapy requirements in baseline tables. | **N/A** | In `ADSL` or `ADSUB`, create flags for `PRIOR_BTK` and `PRIOR_VENETOCLAX`. These are mandatory covariates for CLL subjects but optional for NHL. |

### 4. REGULATORY INTERROGATION (HOSTILE)
**Q: "How did you ensure that a CLL patient with 'Partial Response' wasn't evaluated using Lugano criteria in your 'Combined' dataset?"**

**A (Required Response):** "We derived the `ADSL.EVALCRIT` variable strictly based on the specific Inclusion Criteria met in `SDTM.IE` (Criterion 4/5 for CLL vs. Criterion 1/2/3 for NHL). In `ADRS`, the `PARAMCD` derivation logic branched explicitly: subjects with `EVALCRIT='iwCLL'` were assessed against iwCLL response definitions (lymphocyte count, hepatosplenomegaly), whereas subjects with `EVALCRIT='LUGANO'` were assessed against Lugano definitions (metabolic response/PET). Though reported in a combined table per SAP Section 4 [9], the underlying `AVALC` determination remained criteria-specific to preserve traceability."

### 5. PROGRAMMING ACTION ITEMS
1.  **ADSL:** Derive `COHORT` and `EVALCRIT` immediately. Do not wait for the efficacy programmer to ask for it.
    *   Map `IE.IETESTCD` 'INCL01'-'INCL03' -> NHL / Lugano.
    *   Map `IE.IETESTCD` 'INCL04'-'INCL05' -> CLL / iwCLL.
2.  **ADRS:** Hard-code a check. If `EVALCRIT` = 'CLL' and `PARAMCD` implies a PET-based assessment (Lugano specific), flag as **DATA ISSUE**. CLL response does not typically utilize PET metabolic response categories (Score 1-5) as primary drivers [7].
3.  **Validation:** Cross-check `ADSL.COHORT` against `SDTM.DX` (Diagnosis). If `COHORT`='CLL' but `DX`='Diffuse Large B-Cell Lymphoma', issue a query. The Inclusion Criteria are the source of truth for the *Analysis* cohort, but the medical history must align.
