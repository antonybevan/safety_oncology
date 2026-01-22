import pandas as pd
import numpy as np
import os
from datetime import datetime, timedelta

# --- 1. CONFIGURATION & SEED ---
# FDA 21 CFR Part 11 Compliance: Fixed Seed for Reproducibility
SEED = 20260122
np.random.seed(SEED)

# Handle environment-specific paths
if os.name == 'nt':  # Windows
    OUTPUT_DIR = r"d:\safety_oncology\BV-CAR20-P1\02_datasets\legacy"
else:  # Linux (SAS OnDemand)
    # Auto-detect project root in home directory
    home = os.path.expanduser("~")
    OUTPUT_DIR = os.path.join(home, "BV-CAR20-P1", "02_datasets", "legacy")

if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

print(f"🔹 BV-CAR20-P1 Data Generator Initiated | Seed: {SEED}")

# --- 2. CONSTANTS ---
DOSE_COHORTS = {
    1: {'dose_val': '1x10^6 cells/kg', 'n': 6, 'crs_prob': 0.33, 'icans_prob': 0.17},
    2: {'dose_val': '3x10^6 cells/kg', 'n': 6, 'crs_prob': 0.50, 'icans_prob': 0.25},
    3: {'dose_val': '480x10^6 cells',  'n': 6, 'crs_prob': 0.67, 'icans_prob': 0.33}
}
TOTAL_N = sum([d['n'] for d in DOSE_COHORTS.values()])

# Study start date anchor (Subject 001 screened)
STUDY_ANCHOR_DATE = datetime(2023, 1, 15)

# --- 3. HELPER FUNCTIONS ---
def add_study_days(start_date, days):
    """
    Applies the SAP 'No Day 1' Logic.
    SAP §5.7:
    Post-dose: Date - Day0 + 1 (So Day 0 + 1 = Study Day 2)
    Pre-dose:  Date - Day0     (So Day 0 - 1 = Study Day -1)
    
    This function takes a 'logical' day offset and converts it to a real date,
    skipping the conceptual 'Day 1' if crossing the boundary.
    Real mapping:
    Logical 0 -> Day 0 (Infusion)
    Logical 1 -> Day 2 (Post-dose + 1 day)
    Logical -1 -> Day -1
    """
    # Simply adding days to the datetime object works for calendar time
    # The 'Study Day' (ADY) calculation is a derivation step, not a date generation step.
    # However, we must ensure we don't generate events on the "non-existent" Day 1 
    # if the SAP implied Day 1 is skipped in labeling.
    # SAP says: "Date - Day0 + 1". 
    # If Date == Day0, SDY = 1? No, usually Day 0 is Treatment.
    # Let's follow standard calendar logic first.
    return start_date + timedelta(days=int(days))

def get_meddra_code(term):
    mapping = {
        'Cytokine release syndrome': 10011693,
        'Immune effector cell-associated neurotoxicity syndrome': 10082305,
        'Graft versus host disease': 10018507,
        'Neutrophil count decreased': 10029366, # Standard PT
        'Platelet count decreased': 10035528,
        'Anemia': 10002272 
    }
    return mapping.get(term, '')

# --- 4. GENERATION MODULES ---

def generate_demographics():
    print("   Generating Demographics (DM)...")
    subjects = []
    current_date = STUDY_ANCHOR_DATE
    
    for level, config in DOSE_COHORTS.items():
        for i in range(config['n']):
            sid = f"101-{level}0{i+1}"
            
            # Stagger enrollment (3+3 design simulation)
            # Cohorts sequential, subjects within cohort slightly staggered
            gap = np.random.randint(14, 45) # Days between subjects
            current_date += timedelta(days=gap)
            screen_date = current_date
            
            # LD Start: Screen + 2 days
            # Infusion (Day 0): LD Start + 5 days (Days -5, -4, -3... gap... 0)
            ld_start_date = screen_date + timedelta(days=2)
            day0_date = ld_start_date + timedelta(days=5) 
            
            subj = {
                'USUBJID': sid,
                'DOSE_LEVEL': level,
                'ARM': config['dose_val'],
                'AGE': int(np.random.normal(62, 8)),
                'SEX': np.random.choice(['M', 'F'], p=[0.6, 0.4]),
                'RACE': np.random.choice(['WHITE', 'BLACK OR AFRICAN AMERICAN', 'ASIAN', 'OTHER'], p=[0.75, 0.15, 0.05, 0.05]),
                'ECOG': np.random.choice([0, 1], p=[0.7, 0.3]),
                'DISEASE': np.random.choice(['NHL', 'CLL', 'SLL'], p=[0.6, 0.3, 0.1]),
                'RFSTDTC': screen_date.strftime('%Y-%m-%d'), # Screening
                'TRTSDT': day0_date.strftime('%Y-%m-%d'),    # Infusion
                'LDSTDT': ld_start_date.strftime('%Y-%m-%d') # LD Start
            }
            # Clamp Age
            subj['AGE'] = max(45, min(78, subj['AGE']))
            subjects.append(subj)
            
    return pd.DataFrame(subjects)

def generate_exposure(dm_df):
    print("   Generating Exposure (EX)...")
    ex_records = []
    for _, row in dm_df.iterrows():
        day0 = datetime.strptime(row['TRTSDT'], '%Y-%m-%d')
        ld_start = datetime.strptime(row['LDSTDT'], '%Y-%m-%d')
        
        # 1. Fludarabine (Days -5 to -3)
        ex_records.append({
            'USUBJID': row['USUBJID'],
            'EXTRT': 'FLUDARABINE',
            'EXDOSE': 30,
            'EXDOSU': 'mg/m2',
            'EXSTDTC': ld_start.strftime('%Y-%m-%d'),
            'EXENDTC': (ld_start + timedelta(days=2)).strftime('%Y-%m-%d')
        })
        
        # 2. Cyclophosphamide (Days -5 to -3)
        ex_records.append({
            'USUBJID': row['USUBJID'],
            'EXTRT': 'CYCLOPHOSPHAMIDE',
            'EXDOSE': 500,
            'EXDOSU': 'mg/m2',
            'EXSTDTC': ld_start.strftime('%Y-%m-%d'),
            'EXENDTC': (ld_start + timedelta(days=2)).strftime('%Y-%m-%d')
        })
        
        # 3. BV-CAR20 (Day 0)
        # Nomianlizing doses for higher fidelity in raw data
        nom_dose = 0
        if row['DOSE_LEVEL'] == 1: nom_dose = 1.0  # 1x10^6
        elif row['DOSE_LEVEL'] == 2: nom_dose = 3.0 # 3x10^6
        elif row['DOSE_LEVEL'] == 3: nom_dose = 480.0 # 480x10^6
        
        ex_records.append({
            'USUBJID': row['USUBJID'],
            'EXTRT': 'BV-CAR20',
            'EXDOSE': nom_dose, 
            'EXDOSU': '10^6 CELLS' if row['DOSE_LEVEL'] < 3 else '10^6 CELLS (FLAT)',
            'EXSTDTC': day0.strftime('%Y-%m-%d'),
            'EXENDTC': day0.strftime('%Y-%m-%d')
        })
    return pd.DataFrame(ex_records)

def generate_ae(dm_df):
    print("   Generating Adverse Events (AE)...")
    ae_records = []
    
    # Track Max CRS per subject for Efficacy correlation
    subj_max_crs = {} # {USUBJID: MaxGrade}

    for _, row in dm_df.iterrows():
        sid = row['USUBJID']
        dose = row['DOSE_LEVEL']
        day0 = datetime.strptime(row['TRTSDT'], '%Y-%m-%d')
        
        config = DOSE_COHORTS[dose]
        
        # --- AESI: CRS ---
        max_crs = 0
        if np.random.random() < config['crs_prob']:
            # Determine Grade (Skewed to G1/2)
            rand_g = np.random.random()
            if rand_g < 0.50: grade = 1
            elif rand_g < 0.85: grade = 2
            elif rand_g < 0.97: grade = 3
            else: grade = 4
            max_crs = grade
            
            # Duration/Onset
            onset_day = np.random.randint(1, 8) # Day 1-7
            duration = np.random.randint(2, 15)
            
            start_date = day0 + timedelta(days=onset_day)
            end_date = start_date + timedelta(days=duration)
            
            ae_records.append({
                'USUBJID': sid,
                'AETERM': 'Cytokine Release Syndrome',
                'AEDECOD': 'Cytokine release syndrome',
                'AESTDTC': start_date.strftime('%Y-%m-%d'),
                'AEENDTC': end_date.strftime('%Y-%m-%d'),
                'AETOXGR': grade,
                'AESER': 'Y' if grade >= 3 else 'N',
                'AESI_FL': 'Y',
                'DLT_FL': 'Y' if grade >= 3 else 'N' # CRS Gr 3+ is ALWAYS DLT
            })
        
        subj_max_crs[sid] = max_crs
        
        # --- AESI: ICANS ---
        if np.random.random() < config['icans_prob']:
             # Determine Grade 
            rand_g = np.random.random()
            if rand_g < 0.45: grade = 1
            elif rand_g < 0.75: grade = 2
            elif rand_g < 0.95: grade = 3
            else: grade = 4
            
            onset_day = np.random.randint(2, 15) # Day 2-14
            duration = np.random.randint(1, 22)
            
            # Force-inject DLT Bypass Logic rule for at least one case
            if grade == 3 and np.random.random() < 0.5:
                duration = 2
            
            start_date = day0 + timedelta(days=onset_day)
            end_date = start_date + timedelta(days=duration)
            
            # DLT Logic: >72 hours (3 days) Grade 3+
            is_dlt = 'Y' if (grade >= 4 or (grade == 3 and duration > 2)) else 'N'

            ae_records.append({
                'USUBJID': sid,
                'AETERM': 'ICANS',
                'AEDECOD': 'Immune effector cell-associated neurotoxicity syndrome',
                'AESTDTC': start_date.strftime('%Y-%m-%d'),
                'AEENDTC': end_date.strftime('%Y-%m-%d'),
                'AETOXGR': grade,
                'AESER': 'Y' if grade >= 3 else 'N',
                'AESI_FL': 'Y',
                'DLT_FL': is_dlt
            })
            
        # --- AESI: GvHD (Allogeneic Spec) ---
        if np.random.random() < 0.12:
            grade = np.random.choice([1, 2, 3], p=[0.6, 0.3, 0.1])
            onset_day = np.random.randint(14, 61)
            duration = np.random.randint(7, 91)
            
            start_date = day0 + timedelta(days=onset_day)
            end_date = start_date + timedelta(days=duration)
            
            ae_records.append({
                'USUBJID': sid,
                'AETERM': 'Skin GvHD',
                'AEDECOD': 'Graft versus host disease',
                'AESTDTC': start_date.strftime('%Y-%m-%d'),
                'AEENDTC': end_date.strftime('%Y-%m-%d'),
                'AETOXGR': grade,
                'AESER': 'N',
                'AESI_FL': 'Y',
                'DLT_FL': 'N'
            })

        # --- NON-AESI: Hematologic (Post-LD) ---
        # Neutropenia: Corrected to start between Day -3 and 0 (DURING LD)
        if np.random.random() < 0.90:
            grade = np.random.choice([3, 4], p=[0.4, 0.6])
            # Start before Day 0
            start_date = day0 - timedelta(days=np.random.randint(0, 4))
            end_date = day0 + timedelta(days=np.random.randint(14, 29))
            ae_records.append({
                'USUBJID': sid,
                'AETERM': 'Neutropenia',
                'AEDECOD': 'Neutrophil count decreased',
                'AESTDTC': start_date.strftime('%Y-%m-%d'),
                'AEENDTC': end_date.strftime('%Y-%m-%d'),
                'AETOXGR': grade,
                'AESER': 'N',
                'AESI_FL': 'N',
                'DLT_FL': 'N'
            })
            
    return pd.DataFrame(ae_records), subj_max_crs

def generate_response(dm_df, subj_max_crs):
    print("   Generating Response (RS) with Safety-Correlation...")
    rs_records = []
    
    for _, row in dm_df.iterrows():
        sid = row['USUBJID']
        day0 = datetime.strptime(row['TRTSDT'], '%Y-%m-%d')
        max_crs = subj_max_crs.get(sid, 0)
        
        # Biological Correlation Logic:
        # Higher CRS -> Higher Chance of Response
        # Base Probabilities:
        if max_crs == 0:
            probs = [0.10, 0.20, 0.30, 0.40] # CR, PR, SD, PD (Poor)
        elif max_crs <= 2:
            probs = [0.30, 0.40, 0.20, 0.10] # CR, PR, SD, PD (Good)
        else:
            probs = [0.60, 0.30, 0.10, 0.00] # CR, PR, SD, PD (Excellent but Toxic)
            
        best_resp = np.random.choice(['CR', 'PR', 'SD', 'PD'], p=probs)
        
        # D30 Assessment
        rs_records.append({
            'USUBJID': sid,
            'RSTESTCD': 'BOR',
            'RSORRES': best_resp,
            'RSDTC': (day0 + timedelta(days=30)).strftime('%Y-%m-%d')
        })
        
    return pd.DataFrame(rs_records)

def generate_labs(dm_df):
    print("   Generating Labs (LB)...")
    lb_records = []
    
    # Lab Parameters (Normal Ranges)
    LAB_CONFIG = {
        'NEUT': {'test': 'Neutrophils', 'unit': '10^9/L', 'low': 1.8, 'high': 7.5},
        'PLAT': {'test': 'Platelets',   'unit': '10^9/L', 'low': 150, 'high': 400},
        'HGB':  {'test': 'Hemoglobin',  'unit': 'g/L',    'low': 120, 'high': 160}
    }
    
    for _, row in dm_df.iterrows():
        sid = row['USUBJID']
        # Generate baseline and follow-up labs
        # Schedule: Screening, Day 0, Day 7, 14, 21, 28, 30, 60
        day0 = datetime.strptime(row['TRTSDT'], '%Y-%m-%d')
        
        visits = {
            'SCREENING': day0 - timedelta(days=7),
            'DAY 0': day0,
            'DAY 7': day0 + timedelta(days=7),
            'DAY 14': day0 + timedelta(days=14),
            'DAY 28': day0 + timedelta(days=28),
            'DAY 60': day0 + timedelta(days=60)
        }
        
        for visit, date_obj in visits.items():
            for code, config in LAB_CONFIG.items():
                # Simulate "Nadir" effect between Day 0 and Day 14 (Toxicity)
                val = np.random.normal((config['high'] + config['low'])/2, (config['high'] - config['low'])/6)
                
                # Apply Toxicity Dip (Flu/Cy effect)
                days_from_start = (date_obj - day0).days
                if code == 'NEUT' and 0 <= days_from_start <= 14:
                    val = max(0.1, val * 0.1) # Grade 4 Neutropenia simulation
                elif code == 'PLAT' and 3 <= days_from_start <= 21:
                    val = max(10, val * 0.3) # Grade 3/4 Thrombocytopenia
                
                lb_records.append({
                    'USUBJID': sid,
                    'LBTESTCD': code,
                    'LBTEST': config['test'],
                    'LBORRES': round(val, 2),
                    'LBORRESU': config['unit'],
                    'LBORNRLO': config['low'],
                    'LBORNRHI': config['high'],
                    'LBDTC': date_obj.strftime('%Y-%m-%d'),
                    'VISIT': visit
                })
                
    return pd.DataFrame(lb_records)

# --- 5. EXECUTION ---
if __name__ == "__main__":
    # A. Demographics
    dm = generate_demographics()
    dm.to_csv(os.path.join(OUTPUT_DIR, "raw_dm.csv"), index=False)
    
    # B. Exposure
    ex = generate_exposure(dm)
    ex.to_csv(os.path.join(OUTPUT_DIR, "raw_ex.csv"), index=False)
    
    # C. Adverse Events
    ae, max_crs_dict = generate_ae(dm)
    ae.to_csv(os.path.join(OUTPUT_DIR, "raw_ae.csv"), index=False)
    
    # D. Response
    rs = generate_response(dm, max_crs_dict)
    rs.to_csv(os.path.join(OUTPUT_DIR, "raw_rs.csv"), index=False)

    # E. Labs
    lb = generate_labs(dm)
    lb.to_csv(os.path.join(OUTPUT_DIR, "raw_lb.csv"), index=False)
    
    print("✅ synthetic generation complete. Files saved to 02_datasets/legacy/")
