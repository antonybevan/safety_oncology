import json
import os
import sys
from notebooklm_mcp.api_client import NotebookLMClient

def interactive_deep_query():
    auth_path = os.path.expanduser("~/.notebooklm-mcp/auth.json")
    if not os.path.exists(auth_path):
        print("Error: Auth file not found.")
        return

    with open(auth_path, 'r') as f:
        auth_data = json.load(f)

    client = NotebookLMClient(
        cookies=auth_data.get("cookies", {}),
        csrf_token=auth_data.get("csrf_token"),
        session_id=auth_data.get("session_id")
    )

    notebook_id = "cb92f159-0b2b-485c-9dfe-47e2ef24c228"

    queries = [
        "Synthesize the study design across all sources. How do the Protocol, SAP, and ADaM Traceability documents define the dose escalation (3+3 vs BOIN) and its impact on the ADAE and ADSL datasets?",
        "Extract the exact tumor response criteria (Lugano 2014 or RECIST 1.1) from the Protocol and cross-reference with the ADaM Oncology Examples. How should PR and CR be mapped in the ADRS domain?",
        "List all Adverse Events of Special Interest (AESI) for PBCAR20A-01. Include specific keywords for CRS, ICANS, and GvHD mentioned in any source.",
        "Based on 'ADaM Oncology Examples', what are the mandatory variables for a Grade 3-4 treatment-emergent toxicity summary in CAR-T therapy?",
        "How do the inclusion/exclusion criteria for 'r/r NHL' and 'CLL' differ across the Protocol and SAP?"
    ]

    print(f"Starting Deep Interaction with Notebook {notebook_id}...")
    results = []
    
    try:
        conv_id = None
        for i, q in enumerate(queries):
            print(f"[{i+1}/{len(queries)}] Querying: {q[:50]}...")
            # Interaction: Not limiting to a single source ID to allow cross-source synthesis
            response = client.query(
                notebook_id=notebook_id,
                query_text=q,
                conversation_id=conv_id
            )
            if response:
                answer = response.get('answer', 'No answer received.')
                conv_id = response.get('conversation_id')
                results.append(f"### Query {i+1}: {q}\n\n**A:** {answer}\n")
            else:
                print(f"Failed to get response for query {i+1}.")

        output_path = "01_documentation/DEEP_STUDY_ALIGNMENT.md"
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            f.write("# Deep Study Alignment & Source Synthesis: PBCAR20A-01\n\n")
            f.write("> **Source Interaction:** This document synthesizes information from 75 sources including Protocol, SAP, ADaM Traceability, and Oncology Best Practices.\n\n")
            f.write("\n".join(results))
        
        print(f"Success! Deep alignment saved to {output_path}")

    except Exception as e:
        print(f"Interruption during interaction: {e}")
        if "Authentication expired" in str(e) or "16" in str(e):
            print("\nCRITICAL: The NotebookLM session has expired. Please refresh the auth.json or re-log in to continue.")

if __name__ == "__main__":
    interactive_deep_query()
