# SAS OnDemand: Clinical Environment Configuration

This guide details the procedures for deploying, executing, and synchronizing the **BV-CAR20-P1** clinical programming pipeline within the **SAS OnDemand for Academics (ODA)** environment.

---

## 🏗️ Repository Architecture (FDA eCTD Compliant)

Our statistical programming pipeline is structurally aligned to FDA eCTD Module 5 folder guidelines. The environment relies on this hierarchy to automatically resolve libraries and paths:

```text
safety_oncology/
├── 01_rawdata/                 # Raw/Ingested Clinical Data (SAS format)
├── 02_datasets/
│   ├── sdtm/                   # CDISC SDTM Datasets (SAS & XPT format)
│   └── analysis/               # CDISC ADaM Datasets (SAS & XPT format)
├── 03_programs/
│   ├── data_gen/               # Raw Clinical Trial Database Simulator
│   ├── tabulations/            # SDTM Mapping Scripts (DM, AE, EX, LB, RS, etc.)
│   ├── analysis/               # ADaM Mapping Scripts (ADSL, ADAE, ADLB, ADRS, etc.)
│   ├── reporting/              # TFL/RTF Output Generation Suite (proc report/sgplot)
│   ├── macros/                 # Shared Utilities (load_config, ods_setup, xpt_export)
│   └── utilities/              # Studio Git Automation scripts
├── 04_outputs/
│   ├── tables/                 # Publication-grade RTF Tables (Table 14.x.x)
│   ├── figures/                # Survival and Toxicity Plots (Kaplan-Meier, SGPLOT)
│   ├── listings/               # Subject Data Listings (Listing 16.x.x)
│   └── metadata/               # Automated define-readiness metadata
├── 05_legacy_data/             # Ingestion CSV sources (EDC and external lab extracts)
├── 05_validation/              # Validation trace logs, QC, and Pinnacle 21 logs
├── 00_config.sas               # Master Configuration & Library Allocations
└── 00_main.sas                 # Master Pipeline Driver (One-click execution)
```

---

## 🚀 Execution Method 1: Master Pipeline (One-Click Run)

To compile and execute the complete pipeline, generating all SDTM/ADaM datasets and TFL outputs in one step:

1. **Deploy to ODA**: Clone the repository using **Method 2** (Git option below) or upload the repository structure to SAS OnDemand using the Studio upload utility.
2. **Open the Driver**: Navigate to `safety_oncology/` and open `00_main.sas`.
3. **Execute**: Click the **Run** (Submit) button in SAS Studio.
4. **Validation Check**: Open the SAS Log and verify there are no `ERROR` or `WARNING` messages.
   * The pipeline will automatically trap errors at each stage using the custom `%check_err` macro.
   * On successful run, the log will output:
     ```text
     NOTE: [PIPELINE] COMPLETE. ALL MAPPINGS AND TFL SUITES COMPILED WITH ZERO ERRORS.
     ```
5. **Output Verification**: Check `04_outputs/tables/` and `04_outputs/figures/` to verify that all RTFs and plots have compiled.

---

## 💻 Execution Method 2: Standalone Execution

Each program in this repository is designed to be **autonomous and portable**, meaning you can open any mapping or reporting script (e.g., `adsl.sas` or `t_eff.sas`) and run it individually.

1. **Portable Ingestion**: Every script includes `%load_config;` at the top.
2. **Library Resolution**: The macro dynamically checks parents, grandparents, and relative subfolders to locate and execute `00_config.sas`.
3. **Safe Execution**: It maps the active workspace libraries (`sdtm`, `adam`, `legacy`) without hardcoding local directories or user-profiles, resolving them safely on Linux/ODA.

---

## 🔄 Advanced Git Integration (Clone & Push from ODA Studio)

SAS OnDemand for Academics runs on a Linux server and has Git installed. To sync code directly back to your GitHub repository from SAS Studio, follow this procedure:

### Step 1: Generate a GitHub Personal Access Token (PAT)
For command-line authentication, GitHub requires a PAT instead of a password.
1. Navigate to **GitHub Settings** > **Developer settings** > **Personal access tokens** > **Tokens (classic)**.
2. Click **Generate new token (classic)**.
3. Select the `repo` scope.
4. **Copy the token** immediately (you will not be able to view it again).

### Step 2: Clone the Repository via SAS Studio Terminal
1. Open the SAS Studio **Command Line Terminal** (available in the bottom panel of the Studio dashboard).
2. Execute the clone command with your credentials embedded:
   ```bash
   git clone https://YOUR_USERNAME:YOUR_PAT_TOKEN@github.com/antonybevan/safety_oncology.git
   ```
   *Replace `YOUR_USERNAME` and `YOUR_PAT_TOKEN` with your actual Github handle and generated classic token.*
3. This creates the exact `safety_oncology/` directory structure under your SAS "Files" workspace.

### Step 3: Stage, Commit, and Push Directly from ODA Terminal
If you modify or update any SAS script or documentation within SAS Studio:
1. Open the terminal panel.
2. Execute the standard Git flow:
   ```bash
   cd safety_oncology
   git add -A
   git commit -m "style(clinical): standardize ODS destination setup"
   git push origin main
   ```
   *Because the clone URL embeds the PAT, authentication is completely automated and will not prompt for password entry.*

---

## 🛠️ Environmental Controls & Troubleshooting

### Shell Escape Safeguards
* **Restricted Action**: The SAS command line `X` statement is disabled within the SAS OnDemand hosting environment for security.
* **Our Solution**: The pipeline avoids any shell command execution. All workspace subfolders (`04_outputs/tables`, `02_datasets/sdtm`, etc.) are created dynamically and safely using native SAS file APIs (`dcreate()` and `fileexist()`) inside the setup macro, requiring no shell-level access.

### Custom Local overrides (Windows / Linux Platform Divergence)
The configuration engine automatically reads `&SYSSCP` to detect the host architecture:
* **Linux/ODA detection**: Sets the forward-slash path separator (`/`).
* **Session Neutralization**: The system starts by executing `*';*";*/;QUIT;RUN;` to cleanly reset any dangling quotes or unclosed blocks from previous interactive sessions.
* If you need to manually force paths, open `00_config.sas` and override `PROJ_ROOT` directly at the top.

---

**Clinical Setup Verified!** The BV-CAR20-P1 oncology pipeline is fully hardened, optimized, and verified for out-of-the-box SAS OnDemand deployment.
