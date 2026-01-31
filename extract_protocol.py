import json
import os
import sys
from notebooklm_mcp.api_client import NotebookLMClient

def extract_protocol_text():
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
    
    # Programmatically find the protocol source ID
    notebooks = client.list_notebooks()
    target_nb = next((nb for nb in notebooks if nb.id == notebook_id), None)
    if not target_nb:
        print("Notebook not found.")
        return
        
    protocol_id = next((src['id'] for src in target_nb.sources if "PROTOCOL.pdf" in src['title']), None)
    if not protocol_id:
        print("Protocol source not found.")
        return
        
    print(f"Extracting full text for Protocol (ID: {protocol_id})...")

    try:
        source_data = client.get_source_fulltext(protocol_id)
        if source_data and source_data.get('content'):
            content = source_data['content']
            print(f"Success! Extracted {len(content)} characters.")
            
            output_path = "protocol_text.txt"
            with open(output_path, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Full text saved to {output_path}")
        else:
            print("Failed to extract content or content is empty.")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    extract_protocol_text()
