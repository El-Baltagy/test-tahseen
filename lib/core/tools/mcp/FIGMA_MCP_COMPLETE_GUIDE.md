# 🎨 Figma MCP - Complete Professional Integration Suite

**Version**: 1.0.0 | **Last Updated**: May 2026 | **Status**: ✅ Production Ready

---

## 📖 Table of Contents

1. [Overview](#overview)
2. [Quick Start (5-Minute Setup)](#quick-start)
3. [Core Features & Available Tools](#core-features--available-tools)
4. [Platform Installation Guide](#platform-installation-guide)
5. [Technical Deep Dive: Bug Analysis & Comparison](#technical-deep-dive)
6. [Troubleshooting & FAQ](#troubleshooting--faq)
7. [Security & Best Practices](#security--best-practices)

---

## 1. Overview
The **Figma MCP Suite** is a Model Context Protocol (MCP) implementation that allows AI assistants (like Claude) to interact directly with Figma design files. It bridges the gap between design and code by providing the AI with real-time access to design tokens, component structures, and file metadata.

### What it enables:
*   **Design to Code**: Generate production-ready Flutter/React components directly from Figma links.
*   **Token Extraction**: Instantly pull colors, typography, and spacing into CSS/JSON/SCSS.
*   **Documentation**: Automatically generate documentation for design systems.
*   **Accessibility Audits**: Let the AI analyze design structures for accessibility compliance.

---

## 2. Quick Start
If you're in a hurry, follow these three steps:

1.  **Get Your Figma Token**:
    *   Go to [Figma Settings](https://www.figma.com/settings) > Developer > Personal access tokens.
    *   Generate a new token (starts with `figd_`).
2.  **Run Configuration**:
    ```bash
    # Navigate to lib/core/tools/mcp
    python figma_mcp_config_fixed.py figd_YOUR_TOKEN_HERE
    ```
3.  **Restart Claude Desktop**:
    *   Fully quit and restart Claude.
    *   Ask: *"Extract colors from this Figma file: [FILE_KEY]"*

---

## 3. Core Features & Available Tools

Once configured, your AI assistant can invoke the following tools:

| Tool | Purpose | Example Prompt |
|------|---------|----------------|
| `get_figma_file_info` | Metadata, pages, and counts | *"Tell me about this Figma file: ABC123"* |
| `get_figma_pages` | Full list of pages & structure | *"List all pages in this design file"* |
| `analyze_figma_design_system` | Full extraction of tokens | *"What's the design system for file ABC123?"* |
| `get_figma_component_details` | Deep dive into a specific component | *"Give me the props for the Button component"* |
| `extract_figma_styles` | Export specific style types | *"Export all colors as CSS variables"* |

---

## 4. Platform Installation Guide

### 🪟 Windows
*   **Dependencies**: `pip install -r requirements.txt`
*   **Setup**: `python figma_mcp_config_fixed.py figd_TOKEN`
*   **Config Location**: `%APPDATA%\Claude\claude_desktop_config.json`

### 🍎 macOS
*   **Dependencies**: `pip3 install -r requirements.txt`
*   **Setup**: `python3 figma_mcp_config_fixed.py figd_TOKEN`
*   **Config Location**: `~/Library/Application Support/Claude/claude_desktop_config.json`

### 🐧 Linux
*   **Dependencies**: `pip3 install -r requirements.txt`
*   **Setup**: `python3 figma_mcp_config_fixed.py figd_TOKEN`
*   **Config Location**: `~/.config/Claude/claude_desktop_config.json`

---

## 5. Technical Deep Dive: Bug Analysis & Comparison

This suite replaces an earlier, broken implementation. Below are the 7 critical fixes applied to make the integration stable and production-ready.

### 🐛 Critical Bug Fixes

| # | Issue | Problem | Fix |
|---|-------|---------|-----|
| 1 | **Invalid URL** | Used `figma.com` as MCP endpoint | Implemented proper `stdio` process communication. |
| 2 | **Wrong Type** | Used `type: "http"` incorrectly | Implemented full MCP server specification. |
| 3 | **No API Logic** | Script was config-only | Added full `FigmaClient` with real API calls. |
| 4 | **Env Mismatch** | `FIGMA_PAT_TOKEN` vs `FIGMA_ACCESS_TOKEN` | Standardized environment variable naming. |
| 5 | **Wrong Paths** | Targeted outdated Google directories | Now correctly targets Claude Desktop paths. |
| 6 | **No Validation** | Accepted placeholder tokens | Added validation for `figd_` prefix and length. |
| 7 | **Incomplete Spec** | Missing `command` and `args` | Provided full execution path for Python server. |

### 📊 Code Comparison

**❌ Original (Broken):**
```python
"type": "http",
"url": "figma.com",
"env": { "FIGMA_ACCESS_TOKEN": token }
```

**✅ Fixed (Working):**
```python
"command": python_exe,
"args": [server_path],
"env": { "FIGMA_ACCESS_TOKEN": figma_token }
```

---

## 6. Troubleshooting & FAQ

### ❌ "Server failed to start"
*   **Cause**: Relative paths or Python not in system PATH.
*   **Fix**: Run `python figma_mcp_config_fixed.py --validate`. It will check if paths are absolute and accessible.

### ❌ "Invalid Token"
*   **Cause**: Truncated token or missing `figd_` prefix.
*   **Fix**: Re-generate token at Figma settings and ensure it's copied in full.

### ❓ Can I use this with other models?
*   **Yes!** While optimized for Claude Desktop, the `figma_mcp_server.py` is a standard MCP server. It works with **Ollama**, **LM Studio**, and any custom agent that supports the MCP protocol over stdio.

---

## 7. Security & Best Practices

> [!CAUTION]
> **Never commit your Figma token to Git.**

*   **Token Safety**: Use the automated config script to inject the token safely into your local AppData/Application Support directory.
*   **Minimal Scopes**: If your Figma organization allows, create tokens with "Read-only" scopes for maximum security.
*   **Environment Variables**: The server can read tokens from your shell environment (`export FIGMA_ACCESS_TOKEN="..."`) instead of hardcoded config.
*   **Git Hygiene**: Add `claude_desktop_config.json` and `.env` to your global `.gitignore`.

---

<div align="center">

**Figma MCP Suite for Tahseen Project**
*Bridging Design and Development with AI*

</div>
