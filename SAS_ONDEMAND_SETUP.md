# SAS OnDemand Setup Guide (Streamlined)

If you just want to run the programs, get your XPTs, and be done—use **Option 1**.

## Option 1: Simple & Fast (Flat Upload)

1.  **Create a Folder**: In the SAS OnDemand "Files" pane, right-click "Home" and create ONE folder named `safety_oncology`.
2.  **Upload EVERYTHING**: Drag and drop all your files directly into that folder:
    *   `00_config.sas`
    *   All CSV data files (e.g., `raw_ae.csv`, `raw_dm.csv`, etc.)
    *   All SAS domain scripts (e.g., `ae.sas`, `dm.sas`, etc.)
3.  **Run**:
    *   Open `00_config.sas` and **Run** (F3). It will see that everything is in one spot and configure itself.
    *   Open `ae.sas` (or any other) and **Run**.
4.  **Download**: Your `.xpt` files will appear in the same `safety_oncology` folder. Right-click and **Download**.

---

## Option 2: Professional Structure (eCTD)

If you cannot use `git clone`, follow these steps:

1.  **Create Project Folder**: In the SAS OnDemand "Files" pane, right-click "Home" and create a new folder named `safety_oncology`.
2.  **Upload Structure**: Under `safety_oncology`, manually create the following folders:
    *   `02_datasets`
        *   `legacy`
        *   `tabulations`
    *   `03_programs`
        *   `tabulations`
3.  **Upload Files**:
    *   Upload `03_programs/00_config.sas` to the `03_programs` folder.
    *   Upload the SAS programs (e.g., `ae.sas`) to `03_programs/tabulations`.
    *   Upload your input data (CSV/XLS) to `02_datasets/legacy`.
4.  **Run Config**: Open `00_config.sas` and run it. Check the log for the "✅ Configuration complete" message.

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

## Troubleshooting SAS OnDemand

### ERROR: Library RAW or SDTM does not exist
This means SAS cannot find your folders.
- **Flat Upload (Option 1)**: Ensure `00_config.sas`, all CSVs, and all SAS scripts are in the **same folder** (e.g., `safety_oncology`).
- **Structured Upload (Option 2)**: Ensure your folder structure exactly matches the eCTD hierarchy (02_datasets/legacy, etc.).
- **Verify Path**: Run `00_config.sas` and look at the LOG. It will tell you the `PROJ_ROOT` it is using. If that path is wrong, update the `MANUAL_ROOT` line in `00_config.sas`.

### ERROR: Shell escape is not valid
- **Reason**: SAS OnDemand disables the `X` command for security. 
- **Fix**: The latest code has removed all `X` commands. You must manually create folders using the SAS Studio interface if you are using the Professional Structure.

---

**Setup Complete!** You're ready to demonstrate the BV-CAR20-P1 clinical programming pipeline in SAS OnDemand.
