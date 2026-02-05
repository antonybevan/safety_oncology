import json
import os
import sys
from notebooklm_mcp.api_client import NotebookLMClient

def get_protocol_guide():
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

    protocol_id = "adb73d02-b413-434e-9e61-a220d80da031"
    
    print(f"Requesting Source Guide for {protocol_id}...")

    try:
        guide = client.get_source_guide(protocol_id)
        print("Source Guide Summary:")
        print(guide.get('summary', 'No summary found.'))
        print("\nKeywords:")
        print(", ".join(guide.get('keywords', [])))

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    get_protocol_guide()
