# BV-CAR20-P1 Portfolio Setup Guide
## SAS OnDemand for Academics (Git Clone Method)

This guide shows how to execute the BV-CAR20-P1 clinical programming pipeline in SAS OnDemand cloud using Git.

---

## 🚀 Quick Start (3 Steps)

### Step 1: Clone Repository in SAS Studio

1. Log into SAS OnDemand: https://welcome.oda.sas.com/
2. Open **SAS Studio**
3. In the terminal (bottom panel), run:

```bash
cd ~
git clone https://github.com/antonybevan/safety_oncology.git
```

### Step 2: Generate Synthetic Data

Run the Python data generator:

```bash
cd ~/safety_oncology/02_datasets/legacy
python3 generate_data.py
```

This creates the 5 raw CSV files needed for SDTM programming.

### Step 3: Run SAS Programs

In SAS Studio, open and run `00_config.sas` first:
- Located at: `~/safety_oncology/03_programs/00_config.sas`
- This auto-detects your home directory and sets up all paths

Then run SDTM programs in sequence:
1. `dm.sas`
2. `ex.sas`
3. `ae.sas`
4. `lb.sas`
5. `suppae.sas`
6. `rs.sas`

---

## 📁 Post-Clone Structure

```
~/safety_oncology/
├── 02_datasets/
│   ├── legacy/           (Python generates CSVs here)
│   └── tabulations/      (.gitkeep ensures this folder exists)
└── 03_programs/
    ├── 00_config.sas     (⭐ RUN THIS FIRST)
    └── tabulations/
        ├── dm.sas
        ├── ex.sas
        └── ...
```

---

## 🚀 Execution Order

Run programs in this sequence:

1. **Upload Data:** Transfer all `raw_*.csv` files to `/02_datasets/legacy/`
2. **Run SDTM Programs:**
   - `dm.sas` → Creates `dm.xpt`
   - `ex.sas` → Creates `ex.xpt`
   - `ae.sas` → Creates `ae.xpt`
   - `lb.sas` → Creates `lb.xpt`
   - `suppae.sas` → Creates `suppae.xpt`
   - `rs.sas` → Creates `rs.xpt`

3. **Verify Output:** Check `/02_datasets/tabulations/` for `.xpt` files

---

## 💡 Tips for SAS OnDemand

1. **File Upload:** Use the "Upload" button in SAS Studio's left navigation panel
2. **Libraries:** After uploading, assign libraries using the macro above
3. **XPT Generation:** SAS OnDemand supports `libname xport` natively
4. **Logs:** Always review the LOG window for errors after running

---

## 📊 Expected Output

After successful execution, you should have:
- 6 SDTM XPT files (dm, ex, ae, lb, suppae, rs)
- SAS LOG files showing 0 errors
- PROC FREQ/MEANS output confirming data counts

---

## 🆘 Common Issues

### Issue 1: "Library SDTM does not exist"
**Fix:** Create the output directory first:
```sas
x "mkdir -p &PROJ_ROOT/02_datasets/tabulations";
```

### Issue 2: "File raw_dm.csv not found"
**Fix:** Verify upload location matches library path exactly

### Issue 3: "PROC IMPORT failed"
**Fix:** Ensure CSV files have headers and no special characters in column names

---

**Setup Complete!** You're ready to demonstrate the BV-CAR20-P1 clinical programming pipeline in SAS OnDemand.
