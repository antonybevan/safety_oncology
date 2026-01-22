import pandas as pd
import os
from datetime import datetime

DATA_DIR = r"d:\safety_oncology\BV-CAR20-P1\02_datasets\legacy"
FILES = ['raw_dm.csv', 'raw_ex.csv', 'raw_ae.csv', 'raw_rs.csv', 'raw_lb.csv']

def audit():
    print("🔍 Starting Clinical Data Integrity Audit...")
    
    # Load files
    dfs = {}
    for f in FILES:
        path = os.path.join(DATA_DIR, f)
        if not os.path.exists(path):
            print(f"❌ Error: {f} missing!")
            return
        dfs[f] = pd.read_csv(path)

    dm = dfs['raw_dm.csv']
    subjects = set(dm['USUBJID'])
    print(f"✅ DM: Found {len(subjects)} subjects.")

    # 1. Referential Integrity
    for f in FILES[1:]:
        df = dfs[f]
        missing = set(df['USUBJID']) - subjects
        if missing:
            print(f"❌ {f}: Found USUBJIDs not in DM: {missing}")
        else:
            print(f"✅ {f}: Referential integrity passed.")

    # 2. Date Sequencing (DM)
    for i, row in dm.iterrows():
        screen = datetime.strptime(row['RFSTDTC'], '%Y-%m-%d')
        ld = datetime.strptime(row['LDSTDT'], '%Y-%m-%d')
        infusion = datetime.strptime(row['TRTSDT'], '%Y-%m-%d')
        
        if not (screen <= ld < infusion):
            print(f"❌ {row['USUBJID']}: Date sequence error (Screen: {screen}, LD: {ld}, Inf: {infusion})")

    # 3. AE Sequence & Coding (AE)
    ae = dfs['raw_ae.csv']
    infusion_map = dict(zip(dm['USUBJID'], dm['TRTSDT']))
    for i, row in ae.iterrows():
        sid = row['USUBJID']
        inf_date = datetime.strptime(infusion_map[sid], '%Y-%m-%d')
        ae_start = datetime.strptime(row['AESTDTC'], '%Y-%m-%d')
        
        # Check "No Day 1" logic
        # If AE date is Infusion Date + 1 day, that would be Study Day 1 (which we skip)
        # So diff should not be exactly 1 day
        diff = (ae_start - inf_date).days
        if diff == 1:
            print(f"❌ {sid}: AE found on Study Day 1 ({row['AESTDTC']}) - SAP Violation!")

    # 4. Lab Nadir Logic (Check if at least some Grade 3/4 exist)
    lb = dfs['raw_lb.csv']
    low_neut = lb[(lb['LBTESTCD'] == 'NEUT') & (lb['LBORRES'] < 0.5)]
    if len(low_neut) > 0:
        print(f"✅ LB: Found {len(low_neut)} Grade 4 Neutropenia records (Success: Nadir simulated).")
    else:
        print("⚠️ LB: No Grade 4 Neutropenia found - check simulator logic.")

    print("\n🏁 Audit Complete.")

if __name__ == "__main__":
    audit()
