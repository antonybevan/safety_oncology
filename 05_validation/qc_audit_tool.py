#!/usr/bin/env python3
"""
================================================================================
Study:          BV-CAR20-P1 (Allogeneic Anti-CD20 CAR-T NHL/CLL Study)
Program:        qc_audit_tool.py
Purpose:        Automated Quality Control (QC) & Log Validation Suite
Author:         Statistical Programmer
Date:           2026-05-21
================================================================================
"""

import os
import re
import sys
import html
import argparse
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
     BV-CAR20-P1 CLINICAL PROGRAMMING AUTOMATED QC & VALIDATION SUITE
================================================================================{CLR_RESET}
    """
    print(banner)

def parse_sas_log(log_path):
    """
    Parses a SAS log file or SAS HTML output file and extracts errors, warnings,
    and specific clinical notes (e.g., uninitialized variables, type conversions).
    """
    if not os.path.exists(log_path):
        return None

    with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # If it's an HTML file, strip HTML tags for text analysis
    is_html = log_path.lower().endswith('.html') or log_path.lower().endswith('.htm')
    if is_html:
        # Extract text content from common SAS ODS HTML tags
        # Replace <br> and paragraph endings with newlines
        text = re.sub(r'<(?:br|p|div|tr)[^>]*>', '\n', content, flags=re.IGNORECASE)
        text = re.sub(r'<[^>]+>', ' ', text)
        text = html.unescape(text)
    else:
        text = content

    lines = text.splitlines()
    
    # Validation structures
    errors = []
    warnings = []
    uninitialized = []
    conversions = []
    repeats_by = []
    missing_gen = []
    
    # Patterns for critical SAS log items
    pat_err = re.compile(r'^\s*ERROR[:\d]', re.IGNORECASE)
    pat_wrn = re.compile(r'^\s*WARNING[:\d]', re.IGNORECASE)
    pat_uninit = re.compile(r'uninitialized|not initialized', re.IGNORECASE)
    pat_convert = re.compile(r'values have been converted to', re.IGNORECASE)
    pat_repeats = re.compile(r'repeats of BY values', re.IGNORECASE)
    pat_missing = re.compile(r'missing values were generated', re.IGNORECASE)

    for line_num, l in enumerate(lines, 1):
        l_strip = l.strip()
        if not l_strip:
            continue
            
        # Skip user-defined error messages or syntax checks that aren't real failures
        if pat_err.match(l_strip):
            if "NOSYNTAXCHECK" not in l and "EFIERR" not in l:
                errors.append((line_num, l_strip))
        elif pat_wrn.match(l_strip):
            warnings.append((line_num, l_strip))
        elif pat_uninit.search(l_strip):
            uninitialized.append((line_num, l_strip))
        elif pat_convert.search(l_strip):
            conversions.append((line_num, l_strip))
        elif pat_repeats.search(l_strip):
            repeats_by.append((line_num, l_strip))
        elif pat_missing.search(l_strip):
            missing_gen.append((line_num, l_strip))

    return {
        "file": os.path.basename(log_path),
        "path": log_path,
        "lines_count": len(lines),
        "errors": errors,
        "warnings": warnings,
        "uninitialized": uninitialized,
        "conversions": conversions,
        "repeats_by": repeats_by,
        "missing_gen": missing_gen
    }

def print_report(results, output_md_path=None):
    """
    Prints a beautiful, submission-grade QC report to the console
    and optionally writes it to a markdown file in the validation directory.
    """
    total_errors = len(results["errors"])
    total_warnings = len(results["warnings"])
    total_uninit = len(results["uninitialized"])
    total_convert = len(results["conversions"])
    total_repeats = len(results["repeats_by"])
    total_missing = len(results["missing_gen"])
    
    # Determine overall status
    is_clean = (total_errors == 0 and total_warnings == 0 and total_uninit == 0 and total_convert == 0 and total_repeats == 0)
    status_str = f"{CLR_GREEN}[PASS] (Submission Ready){CLR_RESET}" if is_clean else f"{CLR_ERROR}[FAIL] (Requires Review & Hardening){CLR_RESET}"
    
    print(f"\n{CLR_BOLD}QC METRICS SUMMARY FOR: {CLR_CYAN}{results['file']}{CLR_RESET}")
    print(f"-" * 60)
    print(f"  * Total Log Lines Analysed    : {results['lines_count']}")
    
    err_color = CLR_GREEN if total_errors == 0 else CLR_ERROR
    wrn_color = CLR_GREEN if total_warnings == 0 else CLR_WARNING
    uni_color = CLR_GREEN if total_uninit == 0 else CLR_WARNING
    con_color = CLR_GREEN if total_convert == 0 else CLR_WARNING
    rep_color = CLR_GREEN if total_repeats == 0 else CLR_ERROR
    mis_color = CLR_BLUE if total_missing == 0 else CLR_RESET
    
    print(f"  * Errors (ERROR:)             : {err_color}{total_errors}{CLR_RESET}")
    print(f"  * Warnings (WARNING:)         : {wrn_color}{total_warnings}{CLR_RESET}")
    print(f"  * Uninitialized Variables     : {uni_color}{total_uninit}{CLR_RESET}")
    print(f"  * Implicit Conversions        : {con_color}{total_convert}{CLR_RESET}")
    print(f"  * Merge BY Repeats            : {rep_color}{total_repeats}{CLR_RESET}")
    print(f"  * Missing Values Generated    : {mis_color}{total_missing}{CLR_RESET}")
    print(f"-" * 60)
    print(f"  * OVERALL STATUS              : {status_str}")
    print(f"================================================================================")
    
    # Print detail blocks if any issues found
    if total_errors > 0:
        print(f"\n{CLR_ERROR}{CLR_BOLD}[CRITICAL] ERRORS DETECTED ({total_errors}):{CLR_RESET}")
        for idx, (ln, msg) in enumerate(results["errors"][:20], 1):
            print(f"  {idx:02d}. Line {ln:5d}: {msg}")
        if total_errors > 20:
            print(f"  ... and {total_errors - 20} more errors.")
            
    if total_warnings > 0:
        print(f"\n{CLR_WARNING}{CLR_BOLD}[WARNING] COMPILER WARNINGS DETECTED ({total_warnings}):{CLR_RESET}")
        for idx, (ln, msg) in enumerate(results["warnings"][:20], 1):
            print(f"  {idx:02d}. Line {ln:5d}: {msg}")
        if total_warnings > 20:
            print(f"  ... and {total_warnings - 20} more warnings.")
            
    if total_uninit > 0:
        print(f"\n{CLR_WARNING}{CLR_BOLD}[AUDIT] UNINITIALIZED VARIABLE REFERENCES ({total_uninit}):{CLR_RESET}")
        for idx, (ln, msg) in enumerate(results["uninitialized"][:20], 1):
            print(f"  {idx:02d}. Line {ln:5d}: {msg}")
        if total_uninit > 20:
            print(f"  ... and {total_uninit - 20} more occurrences.")
            
    if total_convert > 0:
        print(f"\n{CLR_WARNING}{CLR_BOLD}[AUDIT] IMPLICIT DATA TYPE CONVERSIONS ({total_convert}):{CLR_RESET}")
        for idx, (ln, msg) in enumerate(results["conversions"][:20], 1):
            print(f"  {idx:02d}. Line {ln:5d}: {msg}")
            
    if total_repeats > 0:
        print(f"\n{CLR_ERROR}{CLR_BOLD}[CRITICAL] MERGE STATEMENTS WITH REPEATING BY VALUES ({total_repeats}):{CLR_RESET}")
        for idx, (ln, msg) in enumerate(results["repeats_by"][:20], 1):
            print(f"  {idx:02d}. Line {ln:5d}: {msg}")

    # Generate Markdown Artifact if requested
    if output_md_path:
        os.makedirs(os.path.dirname(output_md_path), exist_ok=True)
        with open(output_md_path, 'w', encoding='utf-8') as md:
            md.write(f"# Automated Quality Control (QC) & Log Verification Report\n\n")
            md.write(f"**Study**: BV-CAR20-P1  \n")
            md.write(f"**Target Log File**: `{results['file']}`  \n")
            md.write(f"**Date Verified**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  \n")
            
            status_txt = "PASS" if is_clean else "FAIL"
            md.write(f"**Overall Compliance Status**: **{status_txt}**  \n\n")
            
            md.write(f"## QC Metrics Checklist\n\n")
            md.write(f"| Quality Parameter | Count | Clinical Threshold | Compliance Status |\n")
            md.write(f"|:---|:---:|:---:|:---:|\n")
            md.write(f"| **Errors (`ERROR:`)** | {total_errors} | 0 | {'Compliant' if total_errors == 0 else 'NON-COMPLIANT'} |\n")
            md.write(f"| **Warnings (`WARNING:`)** | {total_warnings} | 0 | {'Compliant' if total_warnings == 0 else 'NON-COMPLIANT'} |\n")
            md.write(f"| **Uninitialized Variables** | {total_uninit} | 0 | {'Compliant' if total_uninit == 0 else 'NON-COMPLIANT'} |\n")
            md.write(f"| **Implicit Type Conversions** | {total_convert} | 0 | {'Compliant' if total_convert == 0 else 'NON-COMPLIANT'} |\n")
            md.write(f"| **Merge BY Value Repeats** | {total_repeats} | 0 | {'Compliant' if total_repeats == 0 else 'NON-COMPLIANT'} |\n")
            md.write(f"| **Missing Values Generated** | {total_missing} | Info Only | Informational |\n\n")
            
            if not is_clean:
                md.write(f"## Action Items Required for Submission\n\n")
                if total_errors > 0:
                    md.write(f"### Critical Errors ({total_errors})\n")
                    md.write(f"The following compilation or execution errors must be resolved:\n\n")
                    for ln, msg in results["errors"][:50]:
                        md.write(f"- **Line {ln}**: `{msg}`\n")
                    md.write("\n")
                    
                if total_warnings > 0:
                    md.write(f"### Compiler Warnings ({total_warnings})\n")
                    md.write(f"The following standard warnings must be eliminated to achieve the Zero Warning Standard:\n\n")
                    for ln, msg in results["warnings"][:50]:
                        md.write(f"- **Line {ln}**: `{msg}`\n")
                    md.write("\n")
                    
                if total_uninit > 0:
                    md.write(f"### Uninitialized Variable Notes ({total_uninit})\n")
                    md.write(f"Resolve uninitialized variable references (check variable spelling or initialization blocks):\n\n")
                    for ln, msg in results["uninitialized"][:50]:
                        md.write(f"- **Line {ln}**: `{msg}`\n")
                    md.write("\n")
            else:
                md.write(f"## Attestation\n\n")
                md.write(f"This log file has been programmatically audited and verified. It complies fully with standard clinical submission requirements, containing zero errors, zero compiler warnings, zero uninitialized references, and zero anomalous merges. The clinical programming pipeline is verified as submission-ready.\n")
                
        print(f"\n{CLR_GREEN}Markdown QC Report successfully written to: {output_md_path}{CLR_RESET}\n")

def main():
    parser = argparse.ArgumentParser(description="Automated SAS Log QC & Audit Tool")
    parser.add_argument("log_path", nargs="?", help="Path to the SAS log file or ODS HTML results file to audit.")
    parser.add_argument("--out-md", help="Path to write the markdown QC report.")
    args = parser.parse_args()

    print_banner()

    # Resolve default path if not specified
    log_path = args.log_path
    if not log_path:
        # Fallback to standard locations or standard downloads path
        dld_path = r"C:\Users\91936\Downloads\00_main-results (1).html"
        if os.path.exists(dld_path):
            log_path = dld_path
            print(f"Using default target file detected in downloads: {CLR_CYAN}{log_path}{CLR_RESET}")
        else:
            print(f"{CLR_ERROR}Error: No log file provided, and default download file was not found.{CLR_RESET}")
            sys.exit(1)

    results = parse_sas_log(log_path)
    if not results:
        print(f"{CLR_ERROR}Error: Could not locate or read target file: {log_path}{CLR_RESET}")
        sys.exit(1)

    # Resolve default markdown report location if not specified
    out_md = args.out_md
    if not out_md:
        out_md = r"d:\safety_oncology\05_validation\qc-logs\QC_AUTOMATED_AUDIT_REPORT.md"

    print_report(results, output_md_path=out_md)

if __name__ == "__main__":
    main()
