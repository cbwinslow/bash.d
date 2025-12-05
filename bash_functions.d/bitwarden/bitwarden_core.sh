#!/bin/bash
#===============================================================================
#
#          FILE:  bitwarden_core.sh
#
#         USAGE:  source bitwarden_core.sh
#                 bw_login
#                 bw_get_item <item_name_or_id> [--field=<field_name>] [--session <session_key>]
#                 bw_secure_get <item_name> [--field=<field_name>] [--no-prompt] [--session <session_key>]
#
#   DESCRIPTION:  Core Bitwarden CLI integration functions with secure credential management.
#                 Handles authentication, session management, and secure credential retrieval.
#
#       OPTIONS:  --field      Specific field to retrieve (default: password)
#                 --no-prompt  Fail if not logged in instead of prompting
#                 --session    Use provided session key instead of global session
#
#  REQUIREMENTS:  Bitwarden CLI (bw) installed and configured
#                 jq for JSON processing
#
#          BUGS:  https://github.com/bitwarden/cli/issues
#         NOTES:  For security, always use environment variables for sensitive data
#                 and never log or echo credentials.
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#       CREATED:  $(date +'%Y-%m-%d')
#      REVISION:  
#===============================================================================

# Ensure script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed" >&2
    exit 1
fi

# Configuration
BW_CONFIG_DIR="${BW_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/bashd/bitwarden}"
BW_STATE_DIR="${BW_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/bashd/bitwarden}"
BW_SESSION_FILE="${BW_STATE_DIR}/session"
BW_CACHE_DIR="${BW_STATE_DIR}/cache"
BW_CACHE_TTL=300  # 5 minutes cache TTL

# Create required directories
mkdir -p "$BW_CONFIG_DIR" "$BW_STATE_DIR" "$BW_CACHE_DIR"

# Initialize Bitwarden CLI if not already available
if ! command -v bw >/dev/null 2>&1; then
    if [[ -f "${HOME}/.local/bin/bw" ]]; then
        export PATH="${HOME}/.local/bin:${PATH}"
    elif [[ -f "/usr/local/bin/bw" ]]; then
        export PATH="/usr/local/bin:${PATH}"
    else
        echo "Error: Bitwarden CLI (bw) not found. Please install it first." >&2
        echo "Visit: https://bitwarden.com/help/article/cli/#download-and-install" >&2
        return 1
    fi
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed. Please install jq first." >&2
    return 1
fi

# Function to ensure we have a valid session
# Returns 0 if session is valid, 1 otherwise
_bw_ensure_session() {
    local session_key="${1:-${BW_SESSION:-}}"
    
    # Check if we have a session key and it's valid
    if [[ -n "$session_key" ]]; then
        if BW_SESSION="$session_key" bw sync --check >/dev/null 2>&1; then
            echo "$session_key"
            return 0
        fi
    fi
    
    # No valid session key found
    return 1
}

# Function to login to Bitwarden
# Usage: bw_login [--method=<method>] [--email=<email>] [--password-file=<file>]
# Options:
#   --method=<method>      Authentication method (password, sso, apikey)
#   --email=<email>        Email address for login
#   --password-file=<file> File containing the password or API key
#   --sso-provider=<id>    SSO provider ID (required for SSO login)
#   --sso-code=<code>      SSO code (if not provided, will open browser)
#   --apikey-file=<file>   File containing API key (client_id:client_secret)
#   --no-cache             Don't cache the session
bw_login() {
    local method="password"
    local email=""
    local password_file=""
    local sso_provider=""
    local sso_code=""
    local apikey_file=""
    local no_cache=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --method=*)
                method="${1#*=}"
                shift
                ;;
            --email=*)
                email="${1#*=}"
                shift
                ;;
            --password-file=*)
                password_file="${1#*=}"
                shift
                ;;
            --sso-provider=*)
                sso_provider="${1#*=}"
                shift
                ;;
            --sso-code=*)
                sso_code="${1#*=}"
                shift
                ;;
            --apikey-file=*)
                apikey_file="${1#*=}"
                shift
                ;;
            --no-cache)
                no_cache=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Check if already logged in
    if ! $no_cache && _bw_ensure_session >/dev/null; then
        echo "Already logged in to Bitwarden"
        return 0
    fi
    
    # Log in based on method
    case "$method" in
        password)
            _bw_login_password "$email" "$password_file"
            ;;
        sso)
            _bw_login_sso "$sso_provider" "$sso_code"
            ;;
        apikey)
            _bw_login_apikey "$apikey_file"
            ;;
        *)
            echo "Unsupported login method: $method" >&2
            return 1
            ;;
    esac
    
    # Save session if not --no-cache
    if [[ $? -eq 0 && "$no_cache" == false ]]; then
        echo "$BW_SESSION" > "$BW_SESSION_FILE"
        chmod 600 "$BW_SESSION_FILE"
    fi
}

# Internal function for password login
_bw_login_password() {
    local email="$1"
    local password_file="$2"
    local password=""
    
    # Get email if not provided
    if [[ -z "$email" ]]; then
        read -r -p "Bitwarden email: " email
    fi
    
    # Get password
    if [[ -n "$password_file" && -f "$password_file" ]]; then
        password=$(cat "$password_file")
    else
        read -r -s -p "Bitwarden password: " password
        echo >&2  # Newline after password prompt
    fi
    
    # Log in
    export BW_SESSION=$(bw login "$email" "$password" --raw 2>/dev/null)
    
    if [[ -z "$BW_SESSION" ]]; then
        echo "Failed to log in to Bitwarden" >&2
        return 1
    fi
    
    echo "Successfully logged in to Bitwarden"
    return 0
}

# Internal function for SSO login
_bw_login_sso() {
    local sso_provider="$1"
    local sso_code="$2"
    
    # Get SSO provider if not provided
    if [[ -z "$sso_provider" ]]; then
        echo "Available SSO providers:"
        bw list organizations | jq -r '.[] | "\(.id): \(.name)"'
        read -r -p "Enter SSO provider ID: " sso_provider
    fi
    
    # Log in
    if [[ -n "$sso_code" ]]; then
        export BW_SESSION=$(bw login --sso --code "$sso_code" --provider "$sso_provider" --raw 2>/dev/null)
    else
        export BW_SESSION=$(bw login --sso --provider "$sso_provider" --raw 2>/dev/null)
    fi
    
    if [[ -z "$BW_SESSION" ]]; then
        echo "Failed to log in to Bitwarden via SSO" >&2
        return 1
    fi
    
    echo "Successfully logged in to Bitwarden via SSO"
    return 0
}

# Internal function for API key login
_bw_login_apikey() {
    local apikey_file="$1"
    local client_id=""
    local client_secret=""
    
    # Get API key
    if [[ -n "$apikey_file" && -f "$apikey_file" ]]; then
        IFS=':' read -r client_id client_secret < "$apikey_file"
    else
        read -r -p "Client ID: " client_id
        read -r -s -p "Client Secret: " client_secret
        echo >&2  # Newline after secret prompt
    fi
    
    # Log in
    export BW_SESSION=$(bw login --apikey --raw 2>/dev/null <<< "$client_id
$client_secret")
    
    if [[ -z "$BW_SESSION" ]]; then
        echo "Failed to log in to Bitwarden with API key" >&2
        return 1
    fi
    
    echo "Successfully logged in to Bitwarden with API key"
    return 0
}

# Function to get an item from Bitwarden
# Usage: bw_get_item <item_name_or_id> [--field=<field_name>] [--session <session_key>]
# Options:
#   --field=<field_name>  Specific field to retrieve (default: password)
#   --session=<session>   Use provided session key instead of global session
bw_get_item() {
    local item_name_or_id="$1"
    local field="password"
    local session_key=""
    local cache_file=""
    local cache_ttl=$BW_CACHE_TTL
    
    # Parse arguments
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --field=*)
                field="${1#*=}"
                shift
                ;;
            --session=*)
                session_key="${1#*=}"
                shift
                ;;
            --no-cache)
                cache_ttl=0
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Ensure we have a valid session
    if ! session_key=$(_bw_ensure_session "$session_key"); then
        echo "Not logged in to Bitwarden. Please run 'bw_login' first." >&2
        return 1
    fi
    
    # Check cache if not disabled
    if [[ $cache_ttl -gt 0 ]]; then
        cache_file="${BW_CACHE_DIR}/$(echo -n "${item_name_or_id}:${field}" | sha256sum | cut -d' ' -f1)"
        
        if [[ -f "$cache_file" ]]; then
            local cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file") ))
            
            if [[ $cache_age -lt $cache_ttl ]]; then
                cat "$cache_file"
                return 0
            fi
        fi
    fi
    
    # Get item from Bitwarden
    local item_json
    if [[ "$item_name_or_id" =~ ^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$ ]]; then
        # Looks like an ID
        item_json=$(BW_SESSION="$session_key" bw get item "$item_name_or_id" 2>/dev/null)
    else
        # Assume it's a name
        item_json=$(BW_SESSION="$session_key" bw list items --search "$item_name_or_id" 2>/dev/null | jq -r '.[0] // empty')
    fi
    
    if [[ -z "$item_json" ]]; then
        echo "Item not found: $item_name_or_id" >&2
        return 1
    fi
    
    # Extract the requested field
    local result
    case "$field" in
        id|name|username|password|uri|uris|totp|notes|fields|attachments|fields.*)
            result=$(jq -r ".${field}" <<< "$item_json" 2>/dev/null)
            ;;
        *)
            # Try to get from custom fields
            result=$(jq -r ".fields[] | select(.name == \"$field\") | .value" <<< "$item_json" 2>/dev/null)
            if [[ -z "$result" ]]; then
                # Try to get from login object
                result=$(jq -r ".login.${field}" <<< "$item_json" 2>/dev/null)
            fi
            ;;
    esac
    
    if [[ -z "$result" || "$result" == "null" ]]; then
        echo "Field not found: $field" >&2
        return 1
    fi
    
    # Cache the result if caching is enabled
    if [[ -n "$cache_file" ]]; then
        mkdir -p "$(dirname "$cache_file")"
        echo -n "$result" > "$cache_file"
    fi
    
    echo -n "$result"
    return 0
}

# Function to securely get a value from Bitwarden with user confirmation
# Usage: bw_secure_get <item_name> [--field=<field_name>] [--no-prompt] [--session <session_key>]
# Options:
#   --field=<field_name>  Specific field to retrieve (default: password)
#   --no-prompt          Fail if not logged in instead of prompting
#   --session=<session>  Use provided session key instead of global session
bw_secure_get() {
    local item_name="$1"
    local field="password"
    local no_prompt=false
    local session_key=""
    
    # Parse arguments
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --field=*)
                field="${1#*=}"
                shift
                ;;
            --no-prompt)
                no_prompt=true
                shift
                ;;
            --session=*)
                session_key="${1#*=}"
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Ensure we have a valid session
    if ! session_key=$(_bw_ensure_session "$session_key"); then
        if $no_prompt; then
            echo "Not logged in to Bitwarden. Use 'bw_login' first or remove --no-prompt." >&2
            return 1
        fi
        
        echo "Bitwarden login required to access: $item_name"
        bw_login || return 1
        session_key="$BW_SESSION"
    fi
    
    # Get the item
    local result
    if result=$(bw_get_item "$item_name" --field="$field" --session="$session_key" 2>/dev/null); then
        echo -n "$result"
        return 0
    else
        echo "Failed to retrieve $field for $item_name" >&2
        return 1
    fi
}

# Function to clear cached session and items
bw_logout() {
    # Clear session
    rm -f "$BW_SESSION_FILE"
    
    # Clear cache
    if [[ -d "$BW_CACHE_DIR" ]]; then
        rm -f "$BW_CACHE_DIR"/*
    fi
    
    # Unset session variable
    unset BW_SESSION
    
    echo "Logged out of Bitwarden and cleared local cache"
}

# Function to sync with Bitwarden server
# Usage: bw_sync [--force]
bw_sync() {
    local force=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Ensure we have a valid session
    if ! session_key=$(_bw_ensure_session); then
        echo "Not logged in to Bitwarden. Use 'bw_login' first." >&2
        return 1
    fi
    
    echo "Syncing with Bitwarden..."
    
    # Sync
    if BW_SESSION="$session_key" bw sync --force="$force" >/dev/null; then
        echo "Sync successful"
        return 0
    else
        echo "Sync failed" >&2
        return 1
    fi
}

# Function to check Bitwarden status
bw_status() {
    echo "Bitwarden Status:"
    echo "────────────────"
    
    # Check if bw is in PATH
    if ! command -v bw >/dev/null 2>&1; then
        echo "✗ Bitwarden CLI (bw) not found in PATH"
        return 1
    fi
    
    echo "✓ Bitwarden CLI found: $(which bw)"
    
    # Check if logged in
    if session_key=$(_bw_ensure_session); then
        echo "✓ Logged in to Bitwarden"
        
        # Get account status
        local status
        status=$(BW_SESSION="$session_key" bw status 2>/dev/null | jq -r '"  • \(.userEmail) (Server: \(.serverUrl), Last Sync: \(.lastSync))"')
        echo -e "$status"
        
        # Check sync status
        if BW_SESSION="$session_key" bw sync --check >/dev/null 2>&1; then
            echo "✓ In sync with server"
        else
            echo "! Out of sync with server"
        fi
        
        # Check for updates
        local current_version
        local latest_version
        current_version=$(bw --version 2>/dev/null)
        latest_version=$(curl -s https://api.github.com/repos/bitwarden/cli/releases/latest | jq -r '.tag_name' | tr -d 'v')
        
        if [[ "$current_version" != "$latest_version" && -n "$latest_version" ]]; then
            echo "! Update available: $current_version → $latest_version"
            echo "  Run 'bw update' to update"
        fi
        
        return 0
    else
        echo "✗ Not logged in to Bitwarden"
        return 1
    fi
}

# Function to generate a secure password
# Usage: bw_generate_password [options]
# Options:
#   -l, --length <length>    Length of the password (default: 24)
#   -u, --upper <count>      Minimum uppercase letters (default: 4)
#   -n, --number <count>     Minimum numbers (default: 4)
#   -s, --special <count>    Minimum special characters (default: 4)
#   --no-special             No special characters
#   --no-ambiguous           Exclude ambiguous characters (1lI0O)
bw_generate_password() {
    local length=24
    local min_upper=4
    local min_number=4
    local min_special=4
    local no_special=false
    local no_ambiguous=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--length)
                length="$2"
                shift 2
                ;;
            -u|--upper)
                min_upper="$2"
                shift 2
                ;;
            -n|--number)
                min_number="$2"
                shift 2
                ;;
            -s|--special)
                min_special="$2"
                shift 2
                ;;
            --no-special)
                no_special=true
                shift
                ;;
            --no-ambiguous)
                no_ambiguous=true
                shift
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Generate password using Bitwarden CLI
    local options=("--length" "$length")
    
    if [[ "$min_upper" -gt 0 ]]; then
        options+=("--uppercase" "$min_upper")
    fi
    
    if [[ "$min_number" -gt 0 ]]; then
        options+=("--number" "$min_number")
    fi
    
    if [[ "$min_special" -gt 0 && "$no_special" != true ]]; then
        options+=("--special" "$min_special")
    fi
    
    if [[ "$no_ambiguous" == true ]]; then
        options+=("--exclude-similar")
    fi
    
    bw generate "${options[@]}"
}

# Function to create a new item in Bitwarden
# Usage: bw_create_item <name> [options]
# Options:
#   --username <username>    Username for the item
#   --password <password>    Password for the item (prompt if not provided)
#   --uri <uri>              URI for the item
#   --notes <notes>          Notes for the item
#   --folder <folder_id>     Folder ID for the item
#   --collection <ids>       Collection IDs (comma-separated)
#   --field <name>=<value>   Add a custom field (can be used multiple times)
#   --session <session_key>  Use provided session key
bw_create_item() {
    local name=""
    local username=""
    local password=""
    local uri=""
    local notes=""
    local folder_id=""
    local collection_ids=()
    local fields=()
    local session_key=""
    
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        echo "Usage: bw_create_item <name> [options]" >&2
        return 1
    fi
    
    name="$1"
    shift
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --username=*)
                username="${1#*=}"
                shift
                ;;
            --username)
                username="$2"
                shift 2
                ;;
            --password=*)
                password="${1#*=}"
                shift
                ;;
            --password)
                password="$2"
                shift 2
                ;;
            --uri=*)
                uri="${1#*=}"
                shift
                ;;
            --uri)
                uri="$2"
                shift 2
                ;;
            --notes=*)
                notes="${1#*=}"
                shift
                ;;
            --notes)
                notes="$2"
                shift 2
                ;;
            --folder=*)
                folder_id="${1#*=}"
                shift
                ;;
            --folder)
                folder_id="$2"
                shift 2
                ;;
            --collection=*)
                IFS=',' read -ra ids <<< "${1#*=}"
                collection_ids+=("${ids[@]}")
                shift
                ;;
            --collection)
                IFS=',' read -ra ids <<< "$2"
                collection_ids+=("${ids[@]}")
                shift 2
                ;;
            --field=*)
                fields+=("${1#*=}")
                shift
                ;;
            --field)
                fields+=("$2")
                shift 2
                ;;
            --session=*)
                session_key="${1#*=}"
                shift
                ;;
            --session)
                session_key="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Ensure we have a valid session
    if ! session_key=$(_bw_ensure_session "$session_key"); then
        echo "Not logged in to Bitwarden. Use 'bw_login' first." >&2
        return 1
    fi
    
    # Prompt for password if not provided
    if [[ -z "$password" ]]; then
        read -r -s -p "Password (leave empty to generate): " password
        echo >&2  # Newline after password prompt
        
        if [[ -z "$password" ]]; then
            password=$(bw_generate_password --length 24 --upper 4 --number 4 --special 4 --no-ambiguous)
            echo "Generated password: $password" >&2
        fi
    fi
    
    # Build the item JSON
    local item_json='{"name":"'"$name"'"'
    
    # Add login information
    item_json+=',"login":{"username":"'"$username"'","password":"'"$password"'"'
    
    # Add URI if provided
    if [[ -n "$uri" ]]; then
        item_json+=',"uris":[{"match":null,"uri":"'"$uri"'"}]'
    fi
    
    item_json+='}'
    
    # Add notes if provided
    if [[ -n "$notes" ]]; then
        item_json=$(jq --arg notes "$notes" '. + {notes: $notes}' <<< "$item_json")
    fi
    
    # Add folder ID if provided
    if [[ -n "$folder_id" ]]; then
        item_json=$(jq --arg folderId "$folder_id" '. + {folderId: $folderId}' <<< "$item_json")
    fi
    
    # Add collection IDs if provided
    if [[ ${#collection_ids[@]} -gt 0 ]]; then
        local collections_json=$(printf '%s\n' "${collection_ids[@]}" | jq -R . | jq -s .)
        item_json=$(jq --argjson collections "$collections_json" '. + {collectionIds: $collections}' <<< "$item_json")
    fi
    
    # Add custom fields if provided
    if [[ ${#fields[@]} -gt 0 ]]; then
        local fields_json='[]'
        
        for field in "${fields[@]}"; do
            local name="${field%%=*}"
            local value="${field#*=}"
            
            # Determine field type
            local field_type=0  # text
            
            # Check if value looks like a boolean
            if [[ "$value" =~ ^(true|false)$ ]]; then
                field_type=1  # boolean
            # Check if value looks like a number
            elif [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                field_type=3  # number
            fi
            
            # Add field to fields array
            fields_json=$(jq --arg name "$name" --arg value "$value" --argjson type "$field_type" \
                '. + [{"name":$name,"value":$value,"type":$type}]' <<< "$fields_json")
        done
        
        item_json=$(jq --argjson fields "$fields_json" '. + {fields: $fields}' <<< "$item_json")
    fi
    
    # Create the item
    local result
    result=$(BW_SESSION="$session_key" bw create item "$item_json" 2>&1)
    
    if [[ $? -eq 0 ]]; then
        echo "Item created successfully:"
        echo "$result" | jq .
        return 0
    else
        echo "Failed to create item: $result" >&2
        return 1
    fi
}

# Function to edit an existing item in Bitwarden
# Usage: bw_edit_item <item_id> [options]
# Options: Same as bw_create_item
bw_edit_item() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: bw_edit_item <item_id> [options]" >&2
        return 1
    fi
    
    local item_id="$1"
    shift
    
    # Get the existing item
    local item_json
    item_json=$(bw get item "$item_id" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        echo "Item not found: $item_id" >&2
        return 1
    fi
    
    # Parse the edit options (same as create)
    local name=""
    local username=""
    local password=""
    local uri=""
    local notes=""
    local folder_id=""
    local collection_ids=()
    local fields=()
    local session_key=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name=*)
                name="${1#*=}"
                shift
                ;;
            --name)
                name="$2"
                shift 2
                ;;
            --username=*)
                username="${1#*=}"
                shift
                ;;
            --username)
                username="$2"
                shift 2
                ;;
            --password=*)
                password="${1#*=}"
                shift
                ;;
            --password)
                password="$2"
                shift 2
                ;;
            --uri=*)
                uri="${1#*=}"
                shift
                ;;
            --uri)
                uri="$2"
                shift 2
                ;;
            --notes=*)
                notes="${1#*=}"
                shift
                ;;
            --notes)
                notes="$2"
                shift 2
                ;;
            --folder=*)
                folder_id="${1#*=}"
                shift
                ;;
            --folder)
                folder_id="$2"
                shift 2
                ;;
            --collection=*)
                IFS=',' read -ra ids <<< "${1#*=}"
                collection_ids+=("${ids[@]}")
                shift
                ;;
            --collection)
                IFS=',' read -ra ids <<< "$2"
                collection_ids+=("${ids[@]}")
                shift 2
                ;;
            --field=*)
                fields+=("${1#*=}")
                shift
                ;;
            --field)
                fields+=("$2")
                shift 2
                ;;
            --session=*)
                session_key="${1#*=}"
                shift
                ;;
            --session)
                session_key="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Ensure we have a valid session
    if ! session_key=$(_bw_ensure_session "$session_key"); then
        echo "Not logged in to Bitwarden. Use 'bw_login' first." >&2
        return 1
    }
    
    # Update fields if provided
    if [[ -n "$name" ]]; then
        item_json=$(jq --arg name "$name" '.name = $name' <<< "$item_json")
    fi
    
    if [[ -n "$username" ]]; then
        item_json=$(jq --arg username "$username" '.login.username = $username' <<< "$item_json")
    fi
    
    if [[ -n "$password" ]]; then
        item_json=$(jq --arg password "$password" '.login.password = $password' <<< "$item_json")
    fi
    
    if [[ -n "$uri" ]]; then
        item_json=$(jq --arg uri "$uri" '.uris = [{"match":null,"uri":$uri}]' <<< "$item_json")
    fi
    
    if [[ -n "$notes" ]]; then
        item_json=$(jq --arg notes "$notes" '.notes = $notes' <<< "$item_json")
    fi
    
    if [[ -n "$folder_id" ]]; then
        item_json=$(jq --arg folderId "$folder_id" '.folderId = $folderId' <<< "$item_json")
    fi
    
    if [[ ${#collection_ids[@]} -gt 0 ]]; then
        local collections_json=$(printf '%s\n' "${collection_ids[@]}" | jq -R . | jq -s .)
        item_json=$(jq --argjson collections "$collections_json" '.collectionIds = $collections' <<< "$item_json")
    fi
    
    # Update custom fields if provided
    if [[ ${#fields[@]} -gt 0 ]]; then
        # Get existing fields
        local existing_fields=$(jq -c '.fields // []' <<< "$item_json")
        
        # Process each new field
        for field in "${fields[@]}"; do
            local name="${field%%=*}"
            local value="${field#*=}"
            
            # Determine field type
            local field_type=0  # text
            
            # Check if value looks like a boolean
            if [[ "$value" =~ ^(true|false)$ ]]; then
                field_type=1  # boolean
            # Check if value looks like a number
            elif [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                field_type=3  # number
            fi
            
            # Check if field already exists
            local field_exists=$(jq --arg name "$name" 'any(.[]; .name == $name)' <<< "$existing_fields")
            
            if [[ "$field_exists" == "true" ]]; then
                # Update existing field
                existing_fields=$(jq --arg name "$name" --arg value "$value" --argjson type "$field_type" \
                    'map(if .name == $name then .value = $value | .type = $type else . end)' <<< "$existing_fields")
            else
                # Add new field
                existing_fields=$(jq --arg name "$name" --arg value "$value" --argjson type "$field_type" \
                    '. + [{"name":$name,"value":$value,"type":$type}]' <<< "$existing_fields")
            fi
        done
        
        # Update the item JSON with the modified fields
        item_json=$(jq --argjson fields "$existing_fields" '.fields = $fields' <<< "$item_json")
    fi
    
    # Save the updated item
    local result
    result=$(BW_SESSION="$session_key" bw edit item "$item_id" "$item_json" 2>&1)
    
    if [[ $? -eq 0 ]]; then
        echo "Item updated successfully:"
        echo "$result" | jq .
        return 0
    else
        echo "Failed to update item: $result" >&2
        return 1
    fi
}

# Function to delete an item from Bitwarden
# Usage: bw_delete_item <item_id> [--permanent] [--session <session_key>]
# Options:
#   --permanent    Permanently delete the item (skip trash)
#   --session      Use provided session key instead of global session
bw_delete_item() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: bw_delete_item <item_id> [--permanent] [--session <session_key>]" >&2
        return 1
    fi
    
    local item_id="$1"
    local permanent=false
    local session_key=""
    shift
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --permanent)
                permanent=true
                shift
                ;;
            --session=*)
                session_key="${1#*=}"
                shift
                ;;
            --session)
                session_key="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Ensure we have a valid session
    if ! session_key=$(_bw_ensure_session "$session_key"); then
        echo "Not logged in to Bitwarden. Use 'bw_login' first." >&2
        return 1
    fi
    
    # Confirm deletion
    local item_name
    item_name=$(bw get item "$item_id" 2>/dev/null | jq -r '.name // empty')
    
    if [[ -z "$item_name" ]]; then
        echo "Item not found: $item_id" >&2
        return 1
    fi
    
    echo "You are about to delete the following item:"
    echo "  Name: $item_name"
    echo "  ID: $item_id"
    
    if [[ "$permanent" == true ]]; then
        echo "WARNING: This will permanently delete the item (not move to trash)."
    else
        echo "The item will be moved to trash and can be restored later."
    fi
    
    read -r -p "Are you sure you want to continue? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Deletion cancelled."
        return 0
    fi
    
    # Delete the item
    local result
    if [[ "$permanent" == true ]]; then
        result=$(BW_SESSION="$session_key" bw delete item "$item_id" --permanent 2>&1)
    else
        result=$(BW_SESSION="$session_key" bw delete item "$item_id" 2>&1)
    fi
    
    if [[ $? -eq 0 ]]; then
        echo "Item deleted successfully."
        return 0
    else
        echo "Failed to delete item: $result" >&2
        return 1
    fi
}

# Function to search for items in Bitwarden
# Usage: bw_search <query> [options]
# Options:
#   --folder <folder_id>    Filter by folder ID
#   --collection <id>       Filter by collection ID
#   --type <type>           Filter by item type (1: login, 2: secure_note, 3: card, 4: identity)
#   --include-trash         Include items in trash
#   --session <session_key> Use provided session key
bw_search() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: bw_search <query> [options]" >&2
        return 1
    fi
    
    local query="$1"
    shift
    
    local folder_id=""
    local collection_id=""
    local item_type=""
    local include_trash=false
    local session_key=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --folder=*)
                folder_id="${1#*=}"
                shift
                ;;
            --folder)
                folder_id="$2"
                shift 2
                ;;
            --collection=*)
                collection_id="${1#*=}"
                shift
                ;;
            --collection)
                collection_id="$2"
                shift 2
                ;;
            --type=*)
                item_type="${1#*=}"
                shift
                ;;
            --type)
                item_type="$2"
                shift 2
                ;;
            --include-trash)
                include_trash=true
                shift
                ;;
            --session=*)
                session_key="${1#*=}"
                shift
                ;;
            --session)
                session_key="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Ensure we have a valid session
    if ! session_key=$(_bw_ensure_session "$session_key"); then
        echo "Not logged in to Bitwarden. Use 'bw_login' first." >&2
        return 1
    fi
    
    # Build the search command
    local cmd="bw list items --search \"$query\""
    
    if [[ -n "$folder_id" ]]; then
        cmd+=" --folderid \"$folder_id\""
    fi
    
    if [[ -n "$collection_id" ]]; then
        cmd+=" --collectionid \"$collection_id\""
    fi
    
    if [[ -n "$item_type" ]]; then
        cmd+=" --type \"$item_type\""
    fi
    
    if [[ "$include_trash" == true ]]; then
        cmd+=" --include-trash"
    fi
    
    # Execute the search
    local result
    result=$(BW_SESSION="$session_key" eval "$cmd" 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$result" || "$result" == "[]" ]]; then
        echo "No items found matching: $query"
        return 1
    fi
    
    # Format and display the results
    echo "Search results for: $query"
    echo "─────────────────────────────────────────────────────────────────"
    
    # Use jq to format the output in a nice table
    echo "$result" | jq -r '
        .[] | "\(.name) (\(.login.username // "<no username>"))
  \(.login.uris[0].uri // "<no uri>")"
    ' | column -t -s $'\t'
}

# Function to get TOTP code for an item
# Usage: bw_get_totp <item_id_or_name> [--session <session_key>]
bw_get_totp() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: bw_get_totp <item_id_or_name> [--session <session_key>]" >&2
        return 1
    fi
    
    local item_id_or_name="$1"
    local session_key=""
    shift
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --session=*)
                session_key="${1#*=}"
                shift
                ;;
            --session)
                session_key="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Ensure we have a valid session
    if ! session_key=$(_bw_ensure_session "$session_key"); then
        echo "Not logged in to Bitwarden. Use 'bw_login' first." >&2
        return 1
    fi
    
    # Get the TOTP code
    local code
    code=$(BW_SESSION="$session_key" bw get totp "$item_id_or_name" 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$code" ]]; then
        echo "Failed to get TOTP code for: $item_id_or_name" >&2
        echo "Make sure the item has TOTP configured." >&2
        return 1
    fi
    
    echo -n "$code"
    
    # If stdout is a terminal, copy to clipboard and show a notification
    if [[ -t 1 ]]; then
        if command -v pbcopy >/dev/null; then
            # macOS
            echo -n "$code" | pbcopy
            echo " (copied to clipboard)"
        elif command -v xclip >/dev/null; then
            # Linux with xclip
            echo -n "$code" | xclip -selection clipboard
            echo " (copied to clipboard)"
        elif command -v wl-copy >/dev/null; then
            # Wayland
            echo -n "$code" | wl-copy
            echo " (copied to clipboard)"
        else
            echo " (clipboard not available)"
        fi
    fi
}

# Function to export Bitwarden data
# Usage: bw_export [options]
# Options:
#   --output <file>    Output file (default: bitwarden_export_<date>.json)
#   --format <format>  Export format (json, encrypted_json, csv) (default: json)
#   --password <pass>  Password for encrypted export (prompt if not provided)
#   --session <key>    Use provided session key
bw_export() {
    local output_file=""
    local format="json"
    local password=""
    local session_key=""
    
    # Default output file
    local default_output="bitwarden_export_$(date +'%Y%m%d_%H%M%S').json"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output=*)
                output_file="${1#*=}"
                shift
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            --format=*)
                format="${1#*=}"
                shift
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            --password=*)
                password="${1#*=}"
                shift
                ;;
            --password)
                password="$2"
                shift 2
                ;;
            --session=*)
                session_key="${1#*=}"
                shift
                ;;
            --session)
                session_key="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Set default output file if not provided
    if [[ -z "$output_file" ]]; then
        output_file="$default_output"
    fi
    
    # Ensure we have a valid session
    if ! session_key=$(_bw_ensure_session "$session_key"); then
        echo "Not logged in to Bitwarden. Use 'bw_login' first." >&2
        return 1
    fi
    
    # Check if output file already exists
    if [[ -e "$output_file" ]]; then
        read -r -p "File '$output_file' already exists. Overwrite? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Export cancelled."
            return 0
        fi
    fi
    
    # Export based on format
    case "$format" in
        json)
            echo "Exporting to JSON format..."
            BW_SESSION="$session_key" bw export --format json --output "$output_file"
            ;;
        encrypted_json)
            if [[ -z "$password" ]]; then
                read -r -s -p "Enter password for encrypted export: " password
                echo
                
                if [[ -z "$password" ]]; then
                    echo "Password cannot be empty" >&2
                    return 1
                fi
            fi
            
            echo "Exporting to encrypted JSON format..."
            BW_SESSION="$session_key" bw export --format encrypted_json --password "$password" --output "$output_file"
            ;;
        csv)
            echo "Exporting to CSV format..."
            BW_SESSION="$session_key" bw export --format csv --output "$output_file"
            ;;
        *)
            echo "Unsupported export format: $format" >&2
            echo "Supported formats: json, encrypted_json, csv" >&2
            return 1
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo "Export completed successfully: $output_file"
        return 0
    else
        echo "Export failed" >&2
        return 1
    fi
}

# Function to import data into Bitwarden
# Usage: bw_import <file> [options]
# Options:
#   --format <format>  Import format (bitwardencsv, bitwardenjson, lastpasscsv, chromecsv, firefoxcsv, keepass2xml)
#   --organization <id> Organization ID for import (optional)
#   --session <key>    Use provided session key
bw_import() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: bw_import <file> [options]" >&2
        return 1
    fi
    
    local input_file="$1"
    shift
    
    local format=""
    local organization_id=""
    local session_key=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format=*)
                format="${1#*=}"
                shift
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            --organization=*)
                organization_id="${1#*=}"
                shift
                ;;
            --organization)
                organization_id="$2"
                shift 2
                ;;
            --session=*)
                session_key="${1#*=}"
                shift
                ;;
            --session)
                session_key="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Check if input file exists
    if [[ ! -f "$input_file" ]]; then
        echo "Input file not found: $input_file" >&2
        return 1
    fi
    
    # Ensure we have a valid session
    if ! session_key=$(_bw_ensure_session "$session_key"); then
        echo "Not logged in to Bitwarden. Use 'bw_login' first." >&2
        return 1
    }
    
    # If format is not provided, try to detect from file extension
    if [[ -z "$format" ]]; then
        case "${input_file##*.}" in
            json)
                format="bitwardenjson"
                ;;
            csv)
                format="bitwardencsv"
                ;;
            xml)
                format="keepass2xml"
                ;;
            *)
                echo "Could not detect import format from file extension. Please specify with --format." >&2
                echo "Supported formats: bitwardencsv, bitwardenjson, lastpasscsv, chromecsv, firefoxcsv, keepass2xml" >&2
                return 1
                ;;
        esac
        
        echo "Detected format: $format"
    fi
    
    # Confirm import
    echo "You are about to import data from: $input_file"
    echo "Format: $format"
    
    if [[ -n "$organization_id" ]]; then
        echo "Organization ID: $organization_id"
    fi
    
    read -r -p "Are you sure you want to continue? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Import cancelled."
        return 0
    fi
    
    # Build the import command
    local cmd="bw import --format \"$format\" --input \"$input_file\""
    
    if [[ -n "$organization_id" ]]; then
        cmd+=" --organizationid \"$organization_id\""
    fi
    
    # Execute the import
    echo "Importing data..."
    local result
    result=$(BW_SESSION="$session_key" eval "$cmd" 2>&1)
    
    if [[ $? -eq 0 ]]; then
        echo "Import completed successfully."
        echo "$result"
        return 0
    else
        echo "Import failed:" >&2
        echo "$result" >&2
        return 1
    fi
}

# Function to check for Bitwarden CLI updates
bw_check_updates() {
    echo "Checking for Bitwarden CLI updates..."
    
    # Get current version
    local current_version
    current_version=$(bw --version 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to get current version" >&2
        return 1
    fi
    
    echo "Current version: $current_version"
    
    # Get latest version from GitHub
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/bitwarden/cli/releases/latest | jq -r '.tag_name' | tr -d 'v')
    
    if [[ $? -ne 0 || -z "$latest_version" ]]; then
        echo "Failed to get latest version from GitHub" >&2
        return 1
    fi
    
    echo "Latest version: $latest_version"
    
    # Compare versions
    if [[ "$current_version" == "$latest_version" ]]; then
        echo "You are using the latest version of Bitwarden CLI."
        return 0
    else
        echo "A new version of Bitwarden CLI is available: $latest_version"
        echo "You can update using your package manager or download from:"
        echo "https://github.com/bitwarden/cli/releases/latest"
        
        # If on macOS with Homebrew, show update command
        if command -v brew >/dev/null 2>&1; then
            echo "Or run: brew upgrade bitwarden-cli"
        # If on Linux with apt, show update command
        elif command -v apt >/dev/null 2>&1; then
            echo "Or run: sudo apt update && sudo apt install --only-upgrade bitwarden-cli"
        # If on Linux with dnf, show update command
        elif command -v dnf >/dev/null 2>&1; then
            echo "Or run: sudo dnf upgrade bitwarden-cli"
        fi
        
        return 0
    fi
}

# Function to update Bitwarden CLI
bw_update() {
    echo "Updating Bitwarden CLI..."
    
    # Check if on macOS with Homebrew
    if command -v brew >/dev/null 2>&1; then
        echo "Updating via Homebrew..."
        brew update && brew upgrade bitwarden-cli
        return $?
    # Check if on Linux with apt
    elif command -v apt >/dev/null 2>&1; then
        echo "Updating via apt..."
        sudo apt update && sudo apt install --only-upgrade bitwarden-cli
        return $?
    # Check if on Linux with dnf
    elif command -v dnf >/dev/null 2>&1; then
        echo "Updating via dnf..."
        sudo dnf upgrade bitwarden-cli
        return $?
    # Check if on Linux with yum
    elif command -v yum >/dev/null 2>&1; then
        echo "Updating via yum..."
        sudo yum update bitwarden-cli
        return $?
    # Check if on Arch Linux with pacman
    elif command -v pacman >/dev/null 2>&1; then
        echo "Updating via pacman..."
        sudo pacman -Syu bitwarden-cli
        return $?
    else
        echo "Automatic update not supported on this system."
        echo "Please download the latest version from:"
        echo "https://github.com/bitwarden/cli/releases/latest"
        return 1
    fi
}

# Function to clean up Bitwarden cache and temporary files
bw_cleanup() {
    echo "Cleaning up Bitwarden cache and temporary files..."
    
    # Clear session
    rm -f "$BW_SESSION_FILE"
    
    # Clear cache
    if [[ -d "$BW_CACHE_DIR" ]]; then
        rm -f "$BW_CACHE_DIR"/*
        echo "Cleared cache directory: $BW_CACHE_DIR"
    fi
    
    # Clear Bitwarden's own cache
    if [[ -d "${HOME}/.config/Bitwarden CLI" ]]; then
        rm -rf "${HOME}/.config/Bitwarden CLI"/*
        echo "Cleared Bitwarden CLI config directory"
    fi
    
    # Clear npm cache if installed via npm
    if command -v npm >/dev/null 2>&1; then
        npm cache clean --force >/dev/null 2>&1
        echo "Cleared npm cache"
    fi
    
    echo "Cleanup complete"
}

# Function to show Bitwarden CLI help
bw_help() {
    cat << 'EOF'
Bitwarden CLI Wrapper Help:

  bw_login [options]           Log in to Bitwarden
    Options:
      --method=<method>      Authentication method (password, sso, apikey)
      --email=<email>        Email address for login
      --password-file=<file> File containing the password or API key
      --sso-provider=<id>    SSO provider ID (required for SSO login)
      --sso-code=<code>      SSO code (if not provided, will open browser)
      --apikey-file=<file>   File containing API key (client_id:client_secret)
      --no-cache             Don't cache the session

  bw_logout                    Log out of Bitwarden and clear local cache

  bw_sync [--force]            Sync with Bitwarden server
    Options:
      --force                 Force a full sync

  bw_status                    Show Bitwarden status and version information

  bw_get_item <name_or_id> [options]
                              Get an item from Bitwarden
    Options:
      --field=<field>         Specific field to retrieve (default: password)
      --session=<session>     Use provided session key
      --no-cache              Don't use cached values

  bw_secure_get <name> [options]
                              Securely get a value from Bitwarden with confirmation
    Options:
      --field=<field>         Specific field to retrieve (default: password)
      --no-prompt             Fail if not logged in instead of prompting
      --session=<session>     Use provided session key

  bw_create_item <name> [options]
                              Create a new item in Bitwarden
    Options:
      --username=<username>   Username for the item
      --password=<password>   Password for the item (prompt if not provided)
      --uri=<uri>             URI for the item
      --notes=<notes>         Notes for the item
      --folder=<folder_id>    Folder ID for the item
      --collection=<ids>      Collection IDs (comma-separated)
      --field=<name>=<value>  Add a custom field (can be used multiple times)
      --session=<session_key> Use provided session key

  bw_edit_item <item_id> [options]
                              Edit an existing item in Bitwarden
    Options: Same as bw_create_item

  bw_delete_item <item_id> [options]
                              Delete an item from Bitwarden
    Options:
      --permanent             Permanently delete the item (skip trash)
      --session=<session_key> Use provided session key

  bw_search <query> [options]  Search for items in Bitwarden
    Options:
      --folder=<folder_id>    Filter by folder ID
      --collection=<id>       Filter by collection ID
      --type=<type>           Filter by item type (1: login, 2: secure_note, 3: card, 4: identity)
      --include-trash         Include items in trash
      --session=<session_key> Use provided session key

  bw_get_totp <item_id_or_name> [options]
                              Get TOTP code for an item
    Options:
      --session=<session_key> Use provided session key

  bw_export [options]         Export Bitwarden data
    Options:
      --output=<file>         Output file (default: bitwarden_export_<date>.json)
      --format=<format>       Export format (json, encrypted_json, csv) (default: json)
      --password=<pass>       Password for encrypted export (prompt if not provided)
      --session=<session_key> Use provided session key

  bw_import <file> [options]  Import data into Bitwarden
    Options:
      --format=<format>       Import format (bitwardencsv, bitwardenjson, lastpasscsv, chromecsv, firefoxcsv, keepass2xml)
      --organization=<id>     Organization ID for import (optional)
      --session=<session_key> Use provided session key

  bw_generate_password [options]
                              Generate a secure password
    Options:
      -l, --length <length>    Length of the password (default: 24)
      -u, --upper <count>      Minimum uppercase letters (default: 4)
      -n, --number <count>     Minimum numbers (default: 4)
      -s, --special <count>    Minimum special characters (default: 4)
      --no-special             No special characters
      --no-ambiguous           Exclude ambiguous characters (1lI0O)

  bw_check_updates             Check for Bitwarden CLI updates
  bw_update                    Update Bitwarden CLI to the latest version
  bw_cleanup                   Clean up cache and temporary files
  bw_help                      Show this help message

Environment Variables:
  BW_CONFIG_DIR          Directory for configuration files (default: ~/.config/bashd/bitwarden)
  BW_STATE_DIR           Directory for state files (default: ~/.local/state/bashd/bitwarden)
  BW_CACHE_TTL           Cache TTL in seconds (default: 300)
  BW_SESSION             Current Bitwarden session key

Examples:
  # Log in with email and password
  bw_login --email user@example.com

  # Get a password from Bitwarden
  PASSWORD=$(bw_secure_get "My Password" --no-prompt)

  # Create a new login item
  bw_create_item "Example Login" --username user@example.com --uri https://example.com

  # Generate and store a secure password
  PASSWORD=$(bw_generate_password --length 32 --upper 4 --number 4 --special 4)
  bw_create_item "Secure Password" --username user@example.com --password "$PASSWORD"

  # Export all data to an encrypted JSON file
  bw_export --format encrypted_json --output bitwarden_export.json

  # Import data from a file
  bw_import bitwarden_export.json --format encrypted_json

For more information, visit:
  https://bitwarden.com/help/article/cli/
  https://github.com/bitwarden/cli
EOF
}

# Load session from file if it exists and is still valid
if [[ -f "$BW_SESSION_FILE" ]]; then
    BW_SESSION=$(cat "$BW_SESSION_FILE" 2>/dev/null)
    
    # Check if session is still valid
    if ! _bw_ensure_session "$BW_SESSION" >/dev/null; then
        unset BW_SESSION
        rm -f "$BW_SESSION_FILE"
    fi
fi

# Export functions
export -f _bw_ensure_session 2>/dev/null
export -f bw_login 2>/dev/null
export -f _bw_login_password 2>/dev/null
export -f _bw_login_sso 2>/dev/null
export -f _bw_login_apikey 2>/dev/null
export -f bw_logout 2>/dev/null
export -f bw_sync 2>/dev/null
export -f bw_status 2>/dev/null
export -f bw_get_item 2>/dev/null
export -f bw_secure_get 2>/dev/null
export -f bw_generate_password 2>/dev/null
export -f bw_create_item 2>/dev/null
export -f bw_edit_item 2>/dev/null
export -f bw_delete_item 2>/dev/null
export -f bw_search 2>/dev/null
export -f bw_get_totp 2>/dev/null
export -f bw_export 2>/dev/null
export -f bw_import 2>/dev/null
export -f bw_check_updates 2>/dev/null
export -f bw_update 2>/dev/null
export -f bw_cleanup 2>/dev/null
export -f bw_help 2>/dev/null

# Display help if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bw_help
fi
