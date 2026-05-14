#!/usr/bin/env python3
"""
Fixed Figma MCP Configuration Setup for Claude Desktop
Properly configures MCP server for Claude.ai and Claude Desktop
"""

import os
import json
import pathlib
import sys
import platform
from typing import Optional


def get_claude_desktop_config_path() -> pathlib.Path:
    """
    Locates Claude Desktop's MCP configuration file.
    
    Paths vary by OS:
    - Windows: %APPDATA%/Claude/claude_desktop_config.json
    - macOS: ~/Library/Application Support/Claude/claude_desktop_config.json
    - Linux: ~/.config/Claude/claude_desktop_config.json
    """
    system = platform.system()
    
    if system == "Windows":
        config_dir = pathlib.Path(os.getenv("APPDATA")) / "Claude"
    elif system == "Darwin":  # macOS
        config_dir = pathlib.Path.home() / "Library" / "Application Support" / "Claude"
    else:  # Linux
        config_dir = pathlib.Path.home() / ".config" / "Claude"
    
    return config_dir / "claude_desktop_config.json"


def validate_figma_token(token: str) -> bool:
    """
    Validate Figma token format.
    Valid tokens start with 'figd_' and are reasonably long.
    """
    if not token or token.startswith("YOUR_"):
        return False
    if not token.startswith("figd_"):
        return False
    if len(token) < 20:
        return False
    return True


def get_figma_token() -> Optional[str]:
    """
    Get Figma token from multiple sources (in order):
    1. Command line argument
    2. FIGMA_ACCESS_TOKEN environment variable
    3. User input
    """
    # Check command line
    if len(sys.argv) > 1:
        token = sys.argv[1]
        if token.startswith("figd_"):
            return token
    
    # Check environment variable
    token = os.getenv("FIGMA_ACCESS_TOKEN")
    if token and validate_figma_token(token):
        return token
    
    # Ask user
    print("\n" + "="*70)
    print("FIGMA MCP CONFIGURATION SETUP")
    print("="*70)
    print("\n⚠️  No valid Figma token found.")
    print("\nHow to get your Figma Personal Access Token:")
    print("1. Go to https://www.figma.com/settings")
    print("2. Navigate to 'Developer' > 'Personal access tokens'")
    print("3. Click 'Generate new token'")
    print("4. Copy the token (starts with 'figd_')")
    print("\n" + "-"*70)
    
    user_token = input("\nPaste your Figma Personal Access Token: ").strip()
    
    if not validate_figma_token(user_token):
        print("❌ Invalid token format. Token should start with 'figd_'")
        return None
    
    return user_token


def get_server_command() -> tuple[str, list[str]]:
    """
    Return the command and args to start the Figma MCP server.
    Handles different environments (development, production, etc.)
    """
    # Auto-detect Python executable
    python_exe = sys.executable
    
    # Path to the server script
    server_path = pathlib.Path(__file__).parent / "figma_mcp_server.py"
    
    if not server_path.exists():
        print(f"⚠️  Warning: Server script not found at {server_path}")
        print("   Make sure figma_mcp_server.py is in the same directory as this script.")
    
    return python_exe, [str(server_path)]


def setup_figma_mcp_for_claude(figma_token: Optional[str] = None) -> bool:
    """
    Configure Figma MCP for Claude Desktop.
    
    Returns:
        bool: True if successful, False otherwise
    """
    
    # Get token
    if not figma_token:
        figma_token = get_figma_token()
    
    if not figma_token:
        print("\n❌ Setup failed: No valid Figma token provided")
        return False
    
    # Get config path
    config_path = get_claude_desktop_config_path()
    config_dir = config_path.parent
    
    print(f"\n📁 Configuration directory: {config_dir}")
    
    # Create directory if needed
    os.makedirs(config_dir, exist_ok=True)
    
    # Load existing config
    current_config = {"mcpServers": {}}
    
    if config_path.exists():
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                current_config = json.load(f)
                print(f"✓ Loaded existing configuration from {config_path}")
        except json.JSONDecodeError:
            print(f"⚠️  Existing config was malformed. Re-initializing...")
            current_config = {"mcpServers": {}}
    
    # Ensure mcpServers key exists
    if "mcpServers" not in current_config:
        current_config["mcpServers"] = {}
    
    # Get server command
    python_exe, server_args = get_server_command()
    
    # Create Figma MCP server configuration
    figma_server_config = {
        "command": python_exe,
        "args": server_args,
        "env": {
            "FIGMA_ACCESS_TOKEN": figma_token
        }
    }
    
    # Update config
    current_config["mcpServers"]["figma"] = figma_server_config
    
    # Write updated config
    try:
        with open(config_path, "w", encoding="utf-8") as f:
            json.dump(current_config, f, indent=2)
        print(f"✅ Updated Claude Desktop MCP configuration")
    except IOError as e:
        print(f"❌ Failed to write configuration: {e}")
        return False
    
    # Print summary
    print("\n" + "="*70)
    print("✅ SETUP COMPLETE!")
    print("="*70)
    print(f"\n📍 Configuration saved to:")
    print(f"   {config_path}")
    print(f"\n🔧 Server configuration:")
    print(f"   Command: {python_exe}")
    print(f"   Args: {server_args}")
    print(f"   Token: {figma_token[:10]}... (hidden)")
    print(f"\n📝 Next steps:")
    print(f"   1. Restart Claude Desktop completely")
    print(f"   2. Open a chat and try:")
    print(f"      'Analyze this Figma file: https://figma.com/file/YOUR_FILE_KEY/'")
    print(f"   3. Or try: 'Extract the color palette from my Figma design system'")
    print(f"\n🔗 Full config path for reference:")
    print(f"   {config_path}")
    print("="*70 + "\n")
    
    return True


def validate_setup() -> bool:
    """Validate that setup was successful"""
    config_path = get_claude_desktop_config_path()
    
    if not config_path.exists():
        print("❌ Configuration file not found")
        return False
    
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
        
        if "figma" not in config.get("mcpServers", {}):
            print("❌ Figma server not found in configuration")
            return False
        
        figma_config = config["mcpServers"]["figma"]
        
        if "command" not in figma_config or "args" not in figma_config:
            print("❌ Figma server configuration incomplete")
            return False
        
        if "FIGMA_ACCESS_TOKEN" not in figma_config.get("env", {}):
            print("❌ Figma token not configured")
            return False
        
        print("✅ Configuration is valid!")
        return True
    
    except Exception as e:
        print(f"❌ Error validating configuration: {e}")
        return False


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Setup Figma MCP for Claude Desktop",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python figma_mcp_config_fixed.py                    # Interactive setup
  python figma_mcp_config_fixed.py figd_YOUR_TOKEN    # Direct token
  FIGMA_ACCESS_TOKEN=figd_... python figma_mcp_config_fixed.py  # Env var
        """
    )
    
    parser.add_argument(
        "token",
        nargs="?",
        help="Figma Personal Access Token (starts with 'figd_')"
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate existing configuration instead of setting up"
    )
    
    args = parser.parse_args()
    
    if args.validate:
        success = validate_setup()
        sys.exit(0 if success else 1)
    else:
        success = setup_figma_mcp_for_claude(args.token)
        sys.exit(0 if success else 1)
