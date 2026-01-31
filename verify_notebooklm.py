import json
import os
import sys
from notebooklm_mcp.api_client import NotebookLMClient

def get_protocol_source_id():
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

    try:
        notebooks = client.list_notebooks()
        target_nb_id = "cb92f159-0b2b-485c-9dfe-47e2ef24c228"
        
        target_nb = next((nb for nb in notebooks if nb.id == target_nb_id), None)
        
        if not target_nb:
            print(f"Could not find notebook: {target_nb_id}")
            return
            
        print(f"Notebook: {target_nb.title}")
        print("-" * 20)
        
        target_src = "CLINICAL TRIAL PROTOCOL.pdf"
        found_id = None
        
        for src in target_nb.sources:
            if src.get('title') == target_src:
                found_id = src.get('id')
                print(f"FOUND: {target_src}")
                print(f"Source ID: {found_id}")
                break
        
        if not found_id:
            print(f"Could not find source: {target_src}")
            # List all to be sure
            for src in target_nb.sources[:5]:
                print(f" - {src.get('title')} ({src.get('id')})")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    get_protocol_source_id()
