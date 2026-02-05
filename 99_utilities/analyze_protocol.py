import json
import os
import sys
from notebooklm_mcp.api_client import NotebookLMClient

def analyze_protocol():
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
    protocol_source_id = "adb73d02-b413-434e-9e61-a220d80da031" # Full ID from previous step

    queries = [
        "What is the study design of PBCAR20A-01? Describe Phase 1 and Phase 2a components.",
        "What are the planned dose levels and cohorts for the study?",
        "What are the treatment arms and population flags defined in the study?",
        "What are the primary and secondary endpoints, especially those related to safety (CRS, ICANS)?",
        "Summarize the key inclusion and exclusion criteria that define the Safety and Efficacy populations."
    ]

    print("Analyzing Protocol...")
    results = []
    
    try:
        # Start a single conversation for all queries to maintain context
        conv_id = None
        for q in queries:
            print(f"Querying: {q}")
            response = client.query(
                notebook_id=notebook_id,
                query_text=q,
                source_ids=[protocol_source_id],
                conversation_id=conv_id
            )
            if response:
                answer = response.get('answer', 'No answer received.')
                conv_id = response.get('conversation_id')
                results.append(f"### Q: {q}\n\n**A:** {answer}\n")
            else:
                print("Failed to get response for query.")

        output_path = "protocol_analysis.md"
        with open(output_path, "w", encoding="utf-8") as f:
            f.write("# Protocol Analysis: PBCAR20A-01\n\n")
            f.write("\n".join(results))
        
        print(f"Analysis complete. Results saved to {output_path}")

    except Exception as e:
        print(f"Error during analysis: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    analyze_protocol()
