import json
import os
import sys
from notebooklm_mcp.api_client import NotebookLMClient

def debug_query():
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
    
    # Get the protocol source ID again to be 100% sure
    notebooks = client.list_notebooks()
    target_nb = next((nb for nb in notebooks if nb.id == notebook_id), None)
    if not target_nb:
        print("Notebook not found.")
        return
        
    protocol_id = next((src['id'] for src in target_nb.sources if "PROTOCOL.pdf" in src['title']), None)
    if not protocol_id:
        print("Protocol source not found.")
        return
        
    print(f"Protocol Source ID: {protocol_id}")

    q = "Summarize this notebook."
    print(f"Querying: {q}")
    
    try:
        response = client.query(
            notebook_id=notebook_id,
            query_text=q
        )
        
        if response:
            print("Response keys:", response.keys())
            print("Answer:", response.get('answer'))
            # PRINT FULL RAW RESPONSE
            print("-" * 20)
            print("FULL RAW RESPONSE:")
            # Use raw_response if the method captured it, or just use the response object if I had it
            # Actually, I'll modify the client locally to print it or just return it.
            # For now, let's just see what's in the response dict.
            print(response.get('raw_response'))
        else:
            print("No response object returned.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    debug_query()
