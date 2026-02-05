import re
import os

def extract_sap_info():
    sap_path = 'd:/safety_oncology/sap_text.txt'
    output_path = 'd:/safety_oncology/01_documentation/SAP_SUMMARY.md'
    
    if not os.path.exists(sap_path):
        print("SAP text file not found.")
        return

    with open(sap_path, 'r', encoding='utf-8') as f:
        text = f.read()

    summary_lines = []
    summary_lines.append("# SAP Summary: PBCAR20A-01")
    summary_lines.append("\n**Extracted Essential Information for Clinical Programming**\n")

    # 1. Study Title & Phase
    title_match = re.search(r'Title:(.*?)Protocol', text, re.DOTALL)
    if title_match:
        summary_lines.append(f"## Study Title\n{title_match.group(1).strip()}\n")

    # 2. Populations
    summary_lines.append("## Analysis Populations")
    pop_keywords = ['Safety Population', 'Intent-to-Treat', 'Efficacy Evaluable', 'Per Protocol']
    for keyword in pop_keywords:
        # Find sentences containing the keyword
        sentences = re.findall(r'([^.]*?' + re.escape(keyword) + r'[^.]*\.)', text, re.IGNORECASE)
        if sentences:
            summary_lines.append(f"### {keyword}")
            for s in sentences[:2]: # First 2 mentions usually define it
                 summary_lines.append(f"- {s.strip()}")
            summary_lines.append("")

    # 3. Demographics Variables
    summary_lines.append("## Demographics Variables (Table 14.1)")
    demo_keywords = ['Age', 'Sex', 'Race', 'Ethnicity', 'Weight', 'BMI', 'ECOG']
    found_demos = []
    for keyword in demo_keywords:
        if re.search(r'\b' + re.escape(keyword) + r'\b', text, re.IGNORECASE):
            found_demos.append(keyword)
    
    if found_demos:
        summary_lines.append(f"**Identified Variables:** {', '.join(found_demos)}")
        summary_lines.append("\n*Note: Standard derivation rules apply as per CDISC ADSL.*")

    # 4. Dose Levels
    summary_lines.append("\n## Study Design & Cohorts")
    dose_matches = re.findall(r'(Dose Level [0-9]+|Cohort [0-9]+)', text, re.IGNORECASE)
    if dose_matches:
        unique_doses = sorted(list(set(dose_matches)))
        summary_lines.append(f"**Identified Cohorts:** {', '.join(unique_doses)}")

    # Write Output
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("\n".join(summary_lines))
    
    print(f"SAP Summary created at: {output_path}")

if __name__ == "__main__":
    extract_sap_info()
