# Bitwarden Integration for AI Agents

## Overview

This system provides comprehensive Bitwarden integration allowing AI agents to securely access secrets, API keys, passwords, and other sensitive data stored in your Bitwarden vault.

## Prerequisites

1. **Bitwarden CLI Installation**
   ```bash
   # Install Bitwarden CLI
   npm install -g @bitwarden/cli
   
   # Or download from https://bitwarden.com/download/
   ```

2. **Bitwarden Account**
   - Active Bitwarden account (free or premium)
   - Master password
   - Optionally: API key for automated access

## Setup

### Option 1: Environment Variables (.env file)

Create or update your `.env` file:

```bash
# Bitwarden Credentials
BW_EMAIL=your-email@example.com
BW_PASSWORD=your-master-password
BW_SESSION=your-session-token  # Optional, will be set after unlock

# Alternative: Use API Key
BW_CLIENTID=your-client-id
BW_CLIENTSECRET=your-client-secret
```

### Option 2: Direct Tool Parameters

You can pass credentials directly to the tools (less secure, not recommended for production).

## Quick Start Guide

See full documentation in the file for complete examples of:
- Login and unlock procedures
- Searching for items
- Retrieving API keys
- Getting credentials
- Best practices for AI agents

## Security Considerations

1. **Never Log Secrets**: Never print or log actual secret values
2. **Environment Variables**: Use .env files that are gitignored
3. **Session Timeout**: Sessions expire; handle re-authentication
4. **Audit Access**: Bitwarden logs all vault access
5. **Principle of Least Privilege**: Only unlock when needed

## Available Tools

- `bitwarden_login` - Login and get session token
- `bitwarden_unlock` - Unlock vault
- `bitwarden_search_items` - Search for items
- `bitwarden_get_item` - Get item details
- `bitwarden_get_api_key` - Get API keys
- `bitwarden_get_password` - Get passwords
- `bitwarden_get_username` - Get usernames
- `bitwarden_get_credentials` - Get username+password
- `bitwarden_get_notes` - Get notes
- `bitwarden_list_folders` - List folders
- `bitwarden_sync_vault` - Sync with server
- `bitwarden_check_status` - Check CLI status
