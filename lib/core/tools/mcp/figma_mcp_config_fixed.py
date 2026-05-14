#!/usr/bin/env python3
import os
import subprocess
import sys
import json
import pathlib

def install_dependencies():
    """Install required libraries if not present."""
    print("Checking dependencies...")
    try:
        import httpx
        import mcp
        print("Dependencies already installed.")
    except ImportError:
        print("Installing required libraries (httpx, mcp, python-dotenv)...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "httpx", "mcp", "python-dotenv"])
        print("Installation complete.")

def save_figma_credentials(token):
    """Save Figma token to a secure local file for AI access."""
    cred_path = pathlib.Path.home() / ".figma_mcp_credentials.json"
    data = {"FIGMA_TOKEN": token}
    
    with open(cred_path, "w") as f:
        json.dump(data, f)
    
    print(f"Credentials saved to: {cred_path}")
    return cred_path

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("❌ Usage: python figma_mcp_config_fixed.py figd_YOUR_TOKEN")
        sys.exit(1)
    
    token = sys.argv[1]
    
    # 1. Install dependencies
    install_dependencies()
    
    # 2. Save credentials
    save_figma_credentials(token)
    
    print("\nSETUP SUCCESSFUL!")
    print("Now any AI model can use your token to read Figma files.")
