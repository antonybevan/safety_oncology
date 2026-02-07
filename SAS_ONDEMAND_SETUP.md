# SAS OnDemand: Clinical Environment Configuration

This guide details the procedures for deploying and executing the BV-CAR20-P1 clinical pipeline within the SAS OnDemand for Academics (ODA) environment.

## Method 1: Rapid Deployment (Unified Directory)

For rapid verification of clinical logic and TFL generation, use the following procedure:

1.  **Directory Initialization**: In the SAS OnDemand "Files" pane, initialize a new directory named `safety_oncology`.
2.  **Asset Upload**: Upload all configuration (`00_config.sas`), source data (CSV format), and clinical programs (SAS format) to the root of the `safety_oncology` directory.
3.  **Initialization**:
    *   Open and execute `00_config.sas` to establish environment variables and library references.
    *   Execute the desired clinical programs (e.g., `ae.sas`) to process data.
4.  **Asset Retrieval**: Generated datasets and TFL outputs will be located within the `safety_oncology` directory. Use the "Download" utility to retrieve primary artifacts.

---

## Method 2: Regulatory Structure (eCTD Standards)

To simulate a formal regulatory submission environment using the repository's native hierarchy:

1.  **Root Initialization**: Initialize a root directory named `safety_oncology`.
2.  **Hierarchy Construction**: Construct the following subdirectory architecture:
    *   `02_datasets`
        *   `legacy` (Source Data)
        *   `tabulations` (SDTM)
    *   `03_programs`
        *   `tabulations` (Mapping Scripts)
3.  **Asset Mapping**:
    *   Deploy `03_programs/00_config.sas` to the `03_programs` path.
    *   Deploy clinical mapping programs to `03_programs/tabulations`.
    *   Deploy source data (CSV/XLS) to `02_datasets/legacy`.
4.  **Environment Validation**: Execute `00_config.sas` and verify the SAS Log for the "Configuration complete" confirmation message.

## Option 3: Advanced Git Workflow (Clone & Push)

If you want to sync changes directly back to GitHub from SAS OnDemand, use this method.

### 1. Generate a GitHub Personal Access Token (PAT)
GitHub no longer accepts your account password for command-line Git.
1. Go to **Settings** > **Developer settings** > **Personal access tokens** > **Tokens (classic)**.
2. Click **Generate new token (classic)**.
3. Select `repo` scope.
4. **Copy the token** (you won't see it again).

### 2. Clone using the Token
In the SAS OnDemand Terminal:
```bash
# Syntax: git clone https://<username>:<token>@github.com/<owner>/<repo>.git
git clone https://YOUR_USERNAME:YOUR_TOKEN@github.com/antonybevan/safety_oncology.git
```
*Replace `YOUR_USERNAME` and `YOUR_TOKEN` with your actual details.*

### 3. Push Changes back to GitHub
After you modify a SAS program in SAS Studio:
1. Open the Terminal.
2. Run the following:
```bash
cd safety_oncology
git add .
git commit -m "docs: update analysis logic in sdtm"
git push origin main
```
*Note: Since you included the token in the clone URL, it should not ask for a password again.*

---

---

## Troubleshooting & Environment Support

### Directory Resolution Errors
Failure to resolve `RAW` or `SDTM` libraries indicates a pathing discrepancy.
- **Rapid Deployment**: Ensure all assets reside in a singular directory alongside `00_config.sas`.
- **Structured Deployment**: Verify the directory tree strictly adheres to the mandated hierarchy (`02_datasets/legacy/`, etc.).
- **Manual Overrides**: Execute `00_config.sas` and inspect the Log for the `PROJ_ROOT` resolution. If required, utilize the `MANUAL_ROOT` macro variable for hard-pathing.

### System Permissions (Shell Escape)
- **Status**: The `X` command and shell escapes are restricted within the ODA environment.
- **Resolution**: The current codebase utilizes SAS native functions for file/directory management. Ensure all required system folders are created manually via the SAS Studio interface prior to execution.

---

**Setup Complete!** You're ready to demonstrate the BV-CAR20-P1 clinical programming pipeline in SAS OnDemand.
