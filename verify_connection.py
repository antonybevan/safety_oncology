import json
import os
from notebooklm_mcp.api_client import NotebookLMClient

def verify():
    auth_path = os.path.expanduser("~/.notebooklm-mcp/auth.json")
    if not os.path.exists(auth_path):
        print("Error: Auth file not found.")
        return

    with open(auth_path, 'r') as f:
        auth_data = json.load(f)

    print(f"Auth file found. Extracted at: {auth_data.get('extracted_at')}")
    
    client = NotebookLMClient(
        cookies=auth_data.get("cookies", {}),
        csrf_token=auth_data.get("csrf_token"),
        session_id=auth_data.get("session_id")
    )

    try:
        print("Attempting to list notebooks...")
        notebooks = client.list_notebooks()
        print(f"Success! Found {len(notebooks)} notebooks.")
        for nb in notebooks:
            print(f"- {nb.title} ({nb.id})")
            if nb.id == "cb92f159-0b2b-485c-9dfe-47e2ef24c228":
                print("  Target notebook found.")
                print(f"  Sources ({len(nb.sources)}):")
                for src in nb.sources[:10]: # First 10
                    print(f"    - {src.get('title')} ({src.get('id')})")

    except Exception as e:
        print(f"Authentication/Connection Error: {e}")

if __name__ == "__main__":
    verify()
