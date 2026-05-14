#!/usr/bin/env python3
"""
Figma Model Context Protocol (MCP) Server
Provides tools for Claude to interact with Figma files and projects
"""

import os
import json
import httpx
from typing import Any
from mcp.server import Server, Request
from mcp.types import Tool, TextContent, ToolResponse

# Initialize MCP Server
server = Server("figma-mcp")

# Configuration
FIGMA_TOKEN = os.getenv("FIGMA_ACCESS_TOKEN")
FIGMA_API_BASE = "https://api.figma.com/v1"

if not FIGMA_TOKEN:
    raise ValueError("FIGMA_ACCESS_TOKEN environment variable not set")


class FigmaClient:
    """Client for Figma API interactions"""
    
    def __init__(self, token: str):
        self.token = token
        self.headers = {
            "X-FIGMA-TOKEN": token,
            "Content-Type": "application/json"
        }
    
    async def get_file(self, file_key: str) -> dict:
        """Retrieve Figma file structure and metadata"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{FIGMA_API_BASE}/files/{file_key}",
                headers=self.headers
            )
            response.raise_for_status()
            return response.json()
    
    async def get_file_nodes(self, file_key: str, node_ids: list[str]) -> dict:
        """Get specific nodes from a Figma file"""
        params = {"ids": ",".join(node_ids)}
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{FIGMA_API_BASE}/files/{file_key}/nodes",
                headers=self.headers,
                params=params
            )
            response.raise_for_status()
            return response.json()
    
    async def get_file_images(self, file_key: str, node_ids: list[str]) -> dict:
        """Get image URLs for nodes"""
        params = {"ids": ",".join(node_ids)}
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{FIGMA_API_BASE}/files/{file_key}/images",
                headers=self.headers,
                params=params
            )
            response.raise_for_status()
            return response.json()
    
    async def get_team_projects(self, team_id: str) -> dict:
        """List projects in a team"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{FIGMA_API_BASE}/teams/{team_id}/projects",
                headers=self.headers
            )
            response.raise_for_status()
            return response.json()


# Initialize Figma client
figma = FigmaClient(FIGMA_TOKEN)


# ============================================================================
# MCP TOOLS - Functions Claude can call
# ============================================================================

@server.list_tools()
async def list_tools() -> list[Tool]:
    """List available Figma tools"""
    return [
        Tool(
            name="get_figma_file_info",
            description="Retrieve metadata and structure of a Figma file (name, version, pages, components)",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_key": {
                        "type": "string",
                        "description": "Figma file key (from URL: figma.com/file/FILE_KEY/)"
                    }
                },
                "required": ["file_key"]
            }
        ),
        Tool(
            name="analyze_figma_design_system",
            description="Extract design system elements (colors, typography, components) from a Figma file",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_key": {
                        "type": "string",
                        "description": "Figma file key"
                    }
                },
                "required": ["file_key"]
            }
        ),
        Tool(
            name="get_figma_component_details",
            description="Get detailed information about a specific component in Figma",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_key": {
                        "type": "string",
                        "description": "Figma file key"
                    },
                    "node_id": {
                        "type": "string",
                        "description": "Component node ID"
                    }
                },
                "required": ["file_key", "node_id"]
            }
        ),
        Tool(
            name="extract_figma_styles",
            description="Extract all color, typography, and spacing styles from a Figma file",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_key": {
                        "type": "string",
                        "description": "Figma file key"
                    },
                    "style_type": {
                        "type": "string",
                        "enum": ["colors", "typography", "spacing", "all"],
                        "description": "Type of styles to extract"
                    }
                },
                "required": ["file_key", "style_type"]
            }
        ),
        Tool(
            name="get_figma_pages",
            description="List all pages in a Figma file",
            inputSchema={
                "type": "object",
                "properties": {
                    "file_key": {
                        "type": "string",
                        "description": "Figma file key"
                    }
                },
                "required": ["file_key"]
            }
        ),
    ]


@server.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> str:
    """Execute Figma tools"""
    
    try:
        if name == "get_figma_file_info":
            file_key = arguments["file_key"]
            file_data = await figma.get_file(file_key)
            
            return json.dumps({
                "name": file_data.get("name"),
                "version": file_data.get("version"),
                "pages": [{"id": p["id"], "name": p["name"]} for p in file_data.get("pages", [])],
                "components_count": len(file_data.get("components", {})),
                "created_at": file_data.get("created_at"),
                "modified_at": file_data.get("modified_at")
            }, indent=2)
        
        elif name == "get_figma_pages":
            file_key = arguments["file_key"]
            file_data = await figma.get_file(file_key)
            
            pages = []
            for page in file_data.get("pages", []):
                pages.append({
                    "id": page["id"],
                    "name": page["name"],
                    "children_count": len(page.get("children", []))
                })
            
            return json.dumps({"pages": pages}, indent=2)
        
        elif name == "analyze_figma_design_system":
            file_key = arguments["file_key"]
            file_data = await figma.get_file(file_key)
            
            design_system = {
                "colors": {},
                "typography": {},
                "components": list(file_data.get("components", {}).keys())[:20]  # First 20
            }
            
            # Extract styles
            for style_id, style_data in file_data.get("styles", {}).items():
                style_type = style_data.get("styleType", "unknown")
                if style_type == "FILL":
                    design_system["colors"][style_data.get("name")] = style_data
                elif style_type == "TEXT":
                    design_system["typography"][style_data.get("name")] = style_data
            
            return json.dumps(design_system, indent=2)
        
        elif name == "get_figma_component_details":
            file_key = arguments["file_key"]
            node_id = arguments["node_id"]
            
            nodes = await figma.get_file_nodes(file_key, [node_id])
            
            return json.dumps(nodes, indent=2)
        
        elif name == "extract_figma_styles":
            file_key = arguments["file_key"]
            style_type = arguments.get("style_type", "all")
            
            file_data = await figma.get_file(file_key)
            styles = {}
            
            for style_id, style_data in file_data.get("styles", {}).items():
                s_type = style_data.get("styleType", "unknown")
                
                if style_type == "all" or style_type.upper() == s_type:
                    styles[style_data.get("name")] = {
                        "id": style_id,
                        "type": s_type,
                        "description": style_data.get("description", "")
                    }
            
            return json.dumps(styles, indent=2)
        
        else:
            return json.dumps({"error": f"Unknown tool: {name}"})
    
    except Exception as e:
        return json.dumps({"error": str(e), "tool": name})


# ============================================================================
# MCP RESOURCES - Read-only data endpoints
# ============================================================================

@server.list_resources()
async def list_resources():
    """List available resources"""
    return [
        {
            "uri": "figma://teams",
            "name": "Figma Teams",
            "description": "Information about accessible Figma teams"
        }
    ]


@server.read_resource()
async def read_resource(uri: str) -> str:
    """Read resource data"""
    if uri == "figma://teams":
        return json.dumps({
            "status": "connected",
            "token_status": "valid" if FIGMA_TOKEN else "missing",
            "note": "Use get_figma_file_info tool to access specific files"
        })
    
    raise ValueError(f"Unknown resource: {uri}")


if __name__ == "__main__":
    import asyncio
    # Run the server
    # This will be started by Claude Desktop or your MCP manager
    asyncio.run(server.run())
