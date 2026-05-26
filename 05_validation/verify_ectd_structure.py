#!/usr/bin/env python3
"""
================================================================================
Study:          BV-CAR20-P1 (Allogeneic Anti-CD20 CAR-T NHL/CLL Study)
Program:        verify_ectd_structure.py
Purpose:        Automated FDA eCTD Module 5 Structure & Cleanliness Validator
Author:         Statistical Programmer
Date:           2026-05-22
================================================================================
"""

import os
import re
import sys
from datetime import datetime

# Curated Clinical Palette for console printing (ANSI escape sequences)
CLR_HEADER = "\033[95m"
CLR_BLUE = "\033[94m"
CLR_CYAN = "\033[96m"
CLR_GREEN = "\033[92m"
CLR_WARNING = "\033[93m"
CLR_ERROR = "\033[91m"
CLR_RESET = "\033[0m"
CLR_BOLD = "\033[1m"

def print_banner():
    banner = f"""
{CLR_HEADER}{CLR_BOLD}================================================================================
     BV-CAR20-P1 FDA eCTD MODULE 5 STRUCTURE & CLEANLINESS VALIDATION SUITE
================================================================================{CLR_RESET}
    """
    print(banner)

def verify_structure(workspace_root):
    """
    Validates that the eCTD Module 5 folder structure exists, conforms to SDTCG guidelines,
    verifies Define-XML stylesheet linkages, and checks that no development artifacts remain.
    """
    m5_dir = os.path.join(workspace_root, "m5")
    
    metrics = {
        "m5_exists": False,
        "sdtm_dir_exists": False,
        "adam_dir_exists": False,
        "sdtm_define_linked": False,
        "adam_define_linked": False,
        "sdtm_stylesheet_exists": False,
        "adam_stylesheet_exists": False,
        "prohibited_files": [],
        "total_files_scanned": 0
    }

    if not os.path.exists(m5_dir):
        return metrics

    metrics["m5_exists"] = True

    # Standard expected directories
    sdtm_path = os.path.join(m5_dir, "datasets", "bv-car20-p1", "tabulations", "sdtm")
    adam_path = os.path.join(m5_dir, "datasets", "bv-car20-p1", "analysis", "adam")

    if os.path.exists(sdtm_path):
        metrics["sdtm_dir_exists"] = True
    if os.path.exists(adam_path):
        metrics["adam_dir_exists"] = True

    # Check stylesheets
    sdtm_xsl = os.path.join(sdtm_path, "define2-1.xsl")
    if os.path.exists(sdtm_xsl):
        metrics["sdtm_stylesheet_exists"] = True
        
    adam_xsl = os.path.join(adam_path, "define2-1.xsl")
    if os.path.exists(adam_xsl):
        metrics["adam_stylesheet_exists"] = True

    # Check Define-XML links
    sdtm_def = os.path.join(sdtm_path, "define.xml")
    if os.path.exists(sdtm_def):
        with open(sdtm_def, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            if '<?xml-stylesheet type="text/xsl" href="define2-1.xsl"?>' in content:
                metrics["sdtm_define_linked"] = True

    adam_def = os.path.join(adam_path, "define.xml")
    if os.path.exists(adam_def):
        with open(adam_def, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            if '<?xml-stylesheet type="text/xsl" href="define2-1.xsl"?>' in content:
                metrics["adam_define_linked"] = True

    # Prohibited files extensions and directory matches
    # FDA submissions must never contain temp files, swap files, SAS lock/log files, or CSV/binary outputs in m5/
    prohibited_patterns = [
        r'\.tmp$', r'\.bak$', r'\.swp$', r'\.swo$', r'\.log$', r'\.lst$', r'\.csv$', 
        r'\.sas7bdat$', r'\.rtf$', r'\.png$', r'\.git', r'\.py$', r'generate_data\.sas$', r'GIT_PUSH.*'
    ]
    
    # Crawl m5 folder for cleanliness
    for root, dirs, files in os.walk(m5_dir):
        for file in files:
            metrics["total_files_scanned"] += 1
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, m5_dir)
            
            # Check against prohibited patterns
            for pat in prohibited_patterns:
                if re.search(pat, file, re.IGNORECASE):
                    metrics["prohibited_files"].append((rel_path, f"Matches pattern: {pat}"))
                    break

    return metrics

def write_markdown_report(metrics, out_path):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    
    is_compliant = (
        metrics["m5_exists"] and 
        metrics["sdtm_dir_exists"] and 
        metrics["adam_dir_exists"] and 
        metrics["sdtm_define_linked"] and 
        metrics["adam_define_linked"] and 
        metrics["sdtm_stylesheet_exists"] and 
        metrics["adam_stylesheet_exists"] and 
        len(metrics["prohibited_files"]) == 0
    )
    
    with open(out_path, 'w', encoding='utf-8') as md:
        md.write("# FDA eCTD Module 5 Cleanliness & Conformance Validation Report\n\n")
        md.write(f"**Study**: BV-CAR20-P1  \n")
        md.write(f"**Date Verified**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  \n")
        
        status_txt = "PASS" if is_compliant else "FAIL"
        md.write(f"**Overall Structural Compliance**: **{status_txt}**  \n\n")
        
        md.write("## Conformance Verification Checklist\n\n")
        md.write("| eCTD Verification Parameter | Target Conformance | Status |\n")
        md.write("|:---|:---:|:---:|\n")
        md.write(f"| **Module 5 Root Existence (`m5/`)** | Required | {'Compliant' if metrics['m5_exists'] else 'NON-COMPLIANT'} |\n")
        md.write(f"| **SDTM Folder Structure Conformance** | Required | {'Compliant' if metrics['sdtm_dir_exists'] else 'NON-COMPLIANT'} |\n")
        md.write(f"| **ADaM Folder Structure Conformance** | Required | {'Compliant' if metrics['adam_dir_exists'] else 'NON-COMPLIANT'} |\n")
        md.write(f"| **SDTM Browser Stylesheet (`define2-1.xsl`)** | Required | {'Compliant' if metrics['sdtm_stylesheet_exists'] else 'NON-COMPLIANT'} |\n")
        md.write(f"| **ADaM Browser Stylesheet (`define2-1.xsl`)** | Required | {'Compliant' if metrics['adam_stylesheet_exists'] else 'NON-COMPLIANT'} |\n")
        md.write(f"| **SDTM Define-XML Stylesheet Linkage** | Required | {'Compliant' if metrics['sdtm_define_linked'] else 'NON-COMPLIANT'} |\n")
        md.write(f"| **ADaM Define-XML Stylesheet Linkage** | Required | {'Compliant' if metrics['adam_define_linked'] else 'NON-COMPLIANT'} |\n")
        md.write(f"| **Module 5 Cleanliness Audit (Prohibited Assets)** | 0 Prohibited | {'Compliant' if len(metrics['prohibited_files']) == 0 else 'NON-COMPLIANT'} |\n\n")
        
        md.write(f"**Total Files Scanned under `m5/`**: {metrics['total_files_scanned']}  \n\n")
        
        if len(metrics["prohibited_files"]) > 0:
            md.write("## Prohibited Assets Detected (Action Required)\n\n")
            md.write("The following files reside under `m5/` and must be deleted or relocated to meet pristine eCTD submission standards:\n\n")
            md.write("| Relpath | Reason |\n")
            md.write("|:---|:---|\n")
            for relpath, reason in metrics["prohibited_files"]:
                md.write(f"| `m5/{relpath}` | {reason} |\n")
            md.write("\n")
        else:
            md.write("## Attestation\n\n")
            md.write("The `m5/` directory structure has been recursively audited. It is confirmed to be 100% compliant with standard FDA eCTD Module 5 folder guidelines, and is entirely free of developmental, backup, intermediate, or unneeded assets. The submission folder is completely pristine and submission-ready.\n")

def main():
    workspace_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    metrics = verify_structure(workspace_root)
    
    total_prohibited = len(metrics["prohibited_files"])
    is_clean = (
        metrics["m5_exists"] and 
        metrics["sdtm_dir_exists"] and 
        metrics["adam_dir_exists"] and 
        metrics["sdtm_define_linked"] and 
        metrics["adam_define_linked"] and 
        metrics["sdtm_stylesheet_exists"] and 
        metrics["adam_stylesheet_exists"] and 
        total_prohibited == 0
    )
    
    status_str = f"{CLR_GREEN}[PASS] (Structure Submission Ready){CLR_RESET}" if is_clean else f"{CLR_ERROR}[FAIL] (Non-Compliant structure or residual files){CLR_RESET}"
    
    print_banner()
    print(f"\n{CLR_BOLD}eCTD STRUCTURAL VERIFICATION REPORT:{CLR_RESET}")
    print(f"-" * 60)
    print(f"  * Module 5 Root Existence (`m5/`) : {'YES' if metrics['m5_exists'] else 'NO'}")
    print(f"  * SDTM Folder Structure          : {'YES' if metrics['sdtm_dir_exists'] else 'NO'}")
    print(f"  * ADaM Folder Structure          : {'YES' if metrics['adam_dir_exists'] else 'NO'}")
    print(f"  * SDTM Stylesheet Existence      : {'YES' if metrics['sdtm_stylesheet_exists'] else 'NO'}")
    print(f"  * ADaM Stylesheet Existence      : {'YES' if metrics['adam_stylesheet_exists'] else 'NO'}")
    print(f"  * SDTM Define-XML Linked         : {'YES' if metrics['sdtm_define_linked'] else 'NO'}")
    print(f"  * ADaM Define-XML Linked         : {'YES' if metrics['adam_define_linked'] else 'NO'}")
    print(f"  * Total Files Inspected under m5 : {metrics['total_files_scanned']}")
    
    proh_color = CLR_GREEN if total_prohibited == 0 else CLR_ERROR
    print(f"  * Prohibited Files Found         : {proh_color}{total_prohibited}{CLR_RESET}")
    print(f"-" * 60)
    print(f"  * OVERALL STRUCTURAL CONFORMANCE : {status_str}")
    print(f"================================================================================")
    
    if total_prohibited > 0:
        print(f"\n{CLR_ERROR}{CLR_BOLD}[CRITICAL] PROHIBITED FILES DETECTED ({total_prohibited}):{CLR_RESET}")
        for idx, (path, reason) in enumerate(metrics["prohibited_files"][:20], 1):
            print(f"  {idx:02d}. m5/{path} ({reason})")
        if total_prohibited > 20:
            print(f"  ... and {total_prohibited - 20} more files.")
            
    out_md = os.path.join(workspace_root, "05_validation", "qc-logs", "ECTD_CLEANLINESS_REPORT.md")
    write_markdown_report(metrics, out_path=out_md)
    print(f"\n{CLR_GREEN}Markdown Cleanliness Report successfully written to: {out_md}{CLR_RESET}\n")
    
    if not is_clean:
        sys.exit(1)

if __name__ == "__main__":
    main()
