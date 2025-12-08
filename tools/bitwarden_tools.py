"""
Bitwarden Secret Management Tools

This module provides comprehensive Bitwarden integration for AI agents to
securely access secrets, API keys, passwords, and other sensitive data.

Requirements:
- Bitwarden CLI (bw) must be installed
- BW_SESSION environment variable or .env file with credentials
- Bitwarden vault must be unlocked

AI agents can use these tools to:
- Search for secrets by name
- Retrieve API keys
- Get credentials for services
- Manage secure notes
"""

from typing import Dict, Any, List, Optional
from .base import BaseTool, ToolCategory, ToolParameter, ToolResult
import os
import json
import subprocess


class BitwardenLogin(BaseTool):
    """
    Login to Bitwarden and get session token.
    
    Authenticates with Bitwarden using email/password or API key
    and returns a session token for subsequent operations.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_login",
            category=ToolCategory.SECURITY,
            description="Login to Bitwarden vault and obtain session token",
            parameters=[
                ToolParameter(
                    name="email",
                    type="string",
                    description="Bitwarden account email (or set BW_EMAIL env var)",
                    required=False
                ),
                ToolParameter(
                    name="password",
                    type="string",
                    description="Bitwarden master password (or set BW_PASSWORD env var)",
                    required=False
                ),
                ToolParameter(
                    name="api_key",
                    type="string",
                    description="Bitwarden API key for non-interactive login",
                    required=False
                )
            ],
            tags=["bitwarden", "security", "auth", "secrets"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        email = kwargs.get("email") or os.getenv("BW_EMAIL")
        password = kwargs.get("password") or os.getenv("BW_PASSWORD")
        api_key = kwargs.get("api_key") or os.getenv("BW_APIKEY")
        
        if api_key:
            # Login with API key
            cmd = ["bw", "login", "--apikey"]
            env = os.environ.copy()
            env["BW_CLIENTID"] = api_key.split(":")[0] if ":" in api_key else api_key
            env["BW_CLIENTSECRET"] = api_key.split(":")[1] if ":" in api_key else ""
            result = subprocess.run(cmd, capture_output=True, text=True, env=env)
        elif email and password:
            # Login with email/password
            cmd = ["bw", "login", email, password]
            result = subprocess.run(cmd, capture_output=True, text=True, input=password)
        else:
            raise ValueError("Must provide either email/password or api_key")
        
        if result.returncode != 0:
            return {
                "success": False,
                "error": result.stderr
            }
        
        # Extract session token from output
        session_token = None
        for line in result.stdout.splitlines():
            if "BW_SESSION" in line:
                # Parse: export BW_SESSION="token"
                session_token = line.split('"')[1]
                break
        
        return {
            "success": True,
            "session_token": session_token,
            "message": "Successfully logged in to Bitwarden"
        }


class BitwardenUnlock(BaseTool):
    """
    Unlock Bitwarden vault.
    
    Unlocks the vault with master password and returns session token.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_unlock",
            category=ToolCategory.SECURITY,
            description="Unlock Bitwarden vault and get session token",
            parameters=[
                ToolParameter(
                    name="password",
                    type="string",
                    description="Bitwarden master password (or set BW_PASSWORD env var)",
                    required=False
                )
            ],
            tags=["bitwarden", "security", "unlock", "secrets"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        password = kwargs.get("password") or os.getenv("BW_PASSWORD")
        
        if not password:
            raise ValueError("Password required to unlock vault")
        
        cmd = ["bw", "unlock", password, "--raw"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return {
                "success": False,
                "error": result.stderr
            }
        
        session_token = result.stdout.strip()
        
        # Set session token in environment
        os.environ["BW_SESSION"] = session_token
        
        return {
            "success": True,
            "session_token": session_token,
            "message": "Vault unlocked successfully"
        }


class BitwardenSearchItems(BaseTool):
    """
    Search for items in Bitwarden vault.
    
    Searches the vault for items matching the query.
    Returns item details including names, IDs, and types.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_search_items",
            category=ToolCategory.SECURITY,
            description="Search for items in Bitwarden vault by name or other criteria",
            parameters=[
                ToolParameter(
                    name="search_query",
                    type="string",
                    description="Search query (item name, URL, etc.)",
                    required=True
                ),
                ToolParameter(
                    name="session_token",
                    type="string",
                    description="Bitwarden session token (or set BW_SESSION env var)",
                    required=False
                )
            ],
            tags=["bitwarden", "search", "secrets"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        search_query = kwargs["search_query"]
        session_token = kwargs.get("session_token") or os.getenv("BW_SESSION")
        
        if not session_token:
            raise ValueError("Session token required. Use bitwarden_unlock or bitwarden_login first.")
        
        cmd = ["bw", "list", "items", "--search", search_query, "--session", session_token]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return {
                "success": False,
                "error": result.stderr
            }
        
        items = json.loads(result.stdout)
        
        # Simplify items for return
        simplified_items = []
        for item in items:
            simplified_items.append({
                "id": item.get("id"),
                "name": item.get("name"),
                "type": item.get("type"),
                "folder": item.get("folderId"),
                "favorite": item.get("favorite", False)
            })
        
        return {
            "success": True,
            "count": len(simplified_items),
            "items": simplified_items
        }


class BitwardenGetItem(BaseTool):
    """
    Get detailed item from Bitwarden vault.
    
    Retrieves complete details of a specific vault item by ID or name.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_get_item",
            category=ToolCategory.SECURITY,
            description="Get detailed information for a specific Bitwarden item",
            parameters=[
                ToolParameter(
                    name="item_id",
                    type="string",
                    description="Item ID or name to retrieve",
                    required=True
                ),
                ToolParameter(
                    name="session_token",
                    type="string",
                    description="Bitwarden session token",
                    required=False
                )
            ],
            tags=["bitwarden", "get", "secrets", "retrieve"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        item_id = kwargs["item_id"]
        session_token = kwargs.get("session_token") or os.getenv("BW_SESSION")
        
        if not session_token:
            raise ValueError("Session token required")
        
        cmd = ["bw", "get", "item", item_id, "--session", session_token]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return {
                "success": False,
                "error": result.stderr
            }
        
        item = json.loads(result.stdout)
        
        return {
            "success": True,
            "item": item
        }


class BitwardenGetPassword(BaseTool):
    """
    Get password from Bitwarden vault.
    
    Retrieves just the password field from a vault item.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_get_password",
            category=ToolCategory.SECURITY,
            description="Get password from a Bitwarden vault item",
            parameters=[
                ToolParameter(
                    name="item_name",
                    type="string",
                    description="Name of the item to get password from",
                    required=True
                ),
                ToolParameter(
                    name="session_token",
                    type="string",
                    description="Bitwarden session token",
                    required=False
                )
            ],
            tags=["bitwarden", "password", "secrets"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        item_name = kwargs["item_name"]
        session_token = kwargs.get("session_token") or os.getenv("BW_SESSION")
        
        if not session_token:
            raise ValueError("Session token required")
        
        cmd = ["bw", "get", "password", item_name, "--session", session_token]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return {
                "success": False,
                "error": result.stderr
            }
        
        password = result.stdout.strip()
        
        return {
            "success": True,
            "password": password,
            "item_name": item_name
        }


class BitwardenGetUsername(BaseTool):
    """
    Get username from Bitwarden vault.
    
    Retrieves just the username field from a vault item.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_get_username",
            category=ToolCategory.SECURITY,
            description="Get username from a Bitwarden vault item",
            parameters=[
                ToolParameter(
                    name="item_name",
                    type="string",
                    description="Name of the item to get username from",
                    required=True
                ),
                ToolParameter(
                    name="session_token",
                    type="string",
                    description="Bitwarden session token",
                    required=False
                )
            ],
            tags=["bitwarden", "username", "secrets"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        item_name = kwargs["item_name"]
        session_token = kwargs.get("session_token") or os.getenv("BW_SESSION")
        
        if not session_token:
            raise ValueError("Session token required")
        
        cmd = ["bw", "get", "username", item_name, "--session", session_token]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return {
                "success": False,
                "error": result.stderr
            }
        
        username = result.stdout.strip()
        
        return {
            "success": True,
            "username": username,
            "item_name": item_name
        }


class BitwardenGetAPIKey(BaseTool):
    """
    Get API key from Bitwarden vault.
    
    Retrieves an API key stored in a custom field or note.
    Common patterns: OpenAI API key, Anthropic API key, etc.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_get_api_key",
            category=ToolCategory.SECURITY,
            description="Get API key from Bitwarden vault item (searches custom fields and notes)",
            parameters=[
                ToolParameter(
                    name="service_name",
                    type="string",
                    description="Service name (e.g., 'OpenAI', 'Anthropic', 'GitHub')",
                    required=True
                ),
                ToolParameter(
                    name="field_name",
                    type="string",
                    description="Custom field name containing API key (default: 'api_key')",
                    required=False,
                    default="api_key"
                ),
                ToolParameter(
                    name="session_token",
                    type="string",
                    description="Bitwarden session token",
                    required=False
                )
            ],
            tags=["bitwarden", "api-key", "secrets", "keys"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        service_name = kwargs["service_name"]
        field_name = kwargs.get("field_name", "api_key")
        session_token = kwargs.get("session_token") or os.getenv("BW_SESSION")
        
        if not session_token:
            raise ValueError("Session token required")
        
        # First, search for the item
        search_cmd = ["bw", "list", "items", "--search", service_name, "--session", session_token]
        search_result = subprocess.run(search_cmd, capture_output=True, text=True)
        
        if search_result.returncode != 0:
            return {
                "success": False,
                "error": search_result.stderr
            }
        
        items = json.loads(search_result.stdout)
        
        if not items:
            return {
                "success": False,
                "error": f"No items found for service: {service_name}"
            }
        
        # Get the first matching item
        item = items[0]
        item_id = item["id"]
        
        # Try to get from custom field
        if "fields" in item and item["fields"]:
            for field in item["fields"]:
                if field.get("name", "").lower() == field_name.lower():
                    return {
                        "success": True,
                        "api_key": field.get("value"),
                        "service": service_name,
                        "field_name": field.get("name")
                    }
        
        # Try password field as fallback
        if "login" in item and "password" in item["login"]:
            return {
                "success": True,
                "api_key": item["login"]["password"],
                "service": service_name,
                "field_name": "password",
                "note": "Retrieved from password field"
            }
        
        # Try notes field as last resort
        if "notes" in item and item["notes"]:
            return {
                "success": True,
                "api_key": item["notes"],
                "service": service_name,
                "field_name": "notes",
                "note": "Retrieved from notes field - may need parsing"
            }
        
        return {
            "success": False,
            "error": f"No API key found in item for service: {service_name}"
        }


class BitwardenGetNotes(BaseTool):
    """
    Get notes from Bitwarden vault item.
    
    Retrieves the notes field from a vault item.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_get_notes",
            category=ToolCategory.SECURITY,
            description="Get notes field from a Bitwarden vault item",
            parameters=[
                ToolParameter(
                    name="item_name",
                    type="string",
                    description="Name of the item to get notes from",
                    required=True
                ),
                ToolParameter(
                    name="session_token",
                    type="string",
                    description="Bitwarden session token",
                    required=False
                )
            ],
            tags=["bitwarden", "notes", "secrets"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        item_name = kwargs["item_name"]
        session_token = kwargs.get("session_token") or os.getenv("BW_SESSION")
        
        if not session_token:
            raise ValueError("Session token required")
        
        cmd = ["bw", "get", "notes", item_name, "--session", session_token]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return {
                "success": False,
                "error": result.stderr
            }
        
        notes = result.stdout.strip()
        
        return {
            "success": True,
            "notes": notes,
            "item_name": item_name
        }


class BitwardenListFolders(BaseTool):
    """
    List all folders in Bitwarden vault.
    
    Returns a list of all folders for organization.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_list_folders",
            category=ToolCategory.SECURITY,
            description="List all folders in Bitwarden vault",
            parameters=[
                ToolParameter(
                    name="session_token",
                    type="string",
                    description="Bitwarden session token",
                    required=False
                )
            ],
            tags=["bitwarden", "folders", "list"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        session_token = kwargs.get("session_token") or os.getenv("BW_SESSION")
        
        if not session_token:
            raise ValueError("Session token required")
        
        cmd = ["bw", "list", "folders", "--session", session_token]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return {
                "success": False,
                "error": result.stderr
            }
        
        folders = json.loads(result.stdout)
        
        return {
            "success": True,
            "count": len(folders),
            "folders": folders
        }


class BitwardenSyncVault(BaseTool):
    """
    Sync Bitwarden vault with server.
    
    Synchronizes local vault data with Bitwarden server.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_sync_vault",
            category=ToolCategory.SECURITY,
            description="Synchronize Bitwarden vault with server",
            parameters=[
                ToolParameter(
                    name="session_token",
                    type="string",
                    description="Bitwarden session token",
                    required=False
                )
            ],
            tags=["bitwarden", "sync"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        session_token = kwargs.get("session_token") or os.getenv("BW_SESSION")
        
        if not session_token:
            raise ValueError("Session token required")
        
        cmd = ["bw", "sync", "--session", session_token]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return {
                "success": False,
                "error": result.stderr
            }
        
        return {
            "success": True,
            "message": "Vault synced successfully",
            "output": result.stdout.strip()
        }


class BitwardenGetCredentials(BaseTool):
    """
    Get complete credentials (username + password) from Bitwarden.
    
    Retrieves both username and password for a service in one call.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_get_credentials",
            category=ToolCategory.SECURITY,
            description="Get both username and password for a service",
            parameters=[
                ToolParameter(
                    name="service_name",
                    type="string",
                    description="Name of the service to get credentials for",
                    required=True
                ),
                ToolParameter(
                    name="session_token",
                    type="string",
                    description="Bitwarden session token",
                    required=False
                )
            ],
            tags=["bitwarden", "credentials", "username", "password", "secrets"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        service_name = kwargs["service_name"]
        session_token = kwargs.get("session_token") or os.getenv("BW_SESSION")
        
        if not session_token:
            raise ValueError("Session token required")
        
        # Get the item
        cmd = ["bw", "get", "item", service_name, "--session", session_token]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            return {
                "success": False,
                "error": result.stderr
            }
        
        item = json.loads(result.stdout)
        
        credentials = {
            "service": service_name,
            "username": None,
            "password": None,
            "url": None
        }
        
        if "login" in item:
            credentials["username"] = item["login"].get("username")
            credentials["password"] = item["login"].get("password")
            
            if "uris" in item["login"] and item["login"]["uris"]:
                credentials["url"] = item["login"]["uris"][0].get("uri")
        
        return {
            "success": True,
            "credentials": credentials
        }


class BitwardenCheckStatus(BaseTool):
    """
    Check Bitwarden CLI status.
    
    Checks if Bitwarden CLI is installed and vault is unlocked.
    """
    
    def __init__(self):
        super().__init__(
            name="bitwarden_check_status",
            category=ToolCategory.SECURITY,
            description="Check Bitwarden CLI installation and vault status",
            parameters=[],
            tags=["bitwarden", "status", "health"]
        )
    
    async def _execute_impl(self, **kwargs) -> Dict[str, Any]:
        # Check if bw is installed
        try:
            version_result = subprocess.run(["bw", "--version"], capture_output=True, text=True)
            cli_installed = version_result.returncode == 0
            cli_version = version_result.stdout.strip() if cli_installed else None
        except FileNotFoundError:
            cli_installed = False
            cli_version = None
        
        # Check if logged in
        status_result = subprocess.run(["bw", "status"], capture_output=True, text=True)
        
        status_info = {
            "cli_installed": cli_installed,
            "cli_version": cli_version
        }
        
        if status_result.returncode == 0:
            try:
                status_data = json.loads(status_result.stdout)
                status_info.update({
                    "logged_in": status_data.get("status") != "unauthenticated",
                    "vault_status": status_data.get("status"),
                    "user_email": status_data.get("userEmail"),
                    "server_url": status_data.get("serverUrl")
                })
            except json.JSONDecodeError:
                status_info["vault_status"] = "unknown"
        
        # Check for session token
        session_token = os.getenv("BW_SESSION")
        status_info["session_active"] = session_token is not None
        
        return status_info
