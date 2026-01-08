#!/usr/bin/env bash
#===============================================================================
#
#          FILE:  cloudflare_storage.sh
#
#         USAGE:  source cloudflare_storage.sh
#                 cf_upload_file <bucket> <local_file> <remote_path>
#                 cf_download_file <bucket> <remote_path> <local_file>
#                 cf_list_files <bucket> [--prefix=<prefix>] [--recursive]
#                 cf_delete_file <bucket> <remote_path>
#                 cf_sync_directory <bucket> <local_dir> <remote_prefix>
#
#   DESCRIPTION:  Cloudflare R2/S3 compatible storage wrapper with Bitwarden
#                 integration for API key management. Provides easy-to-use
#                 functions for file operations, directory synchronization,
#                 and comprehensive error handling with retries.
#
#       OPTIONS:  --bucket           Bucket name (or set CLOUDFLARE_BUCKET env var)
#                 --prefix           Path prefix for filtering
#                 --recursive        Recursive directory operations
#                 --overwrite        Overwrite existing files
#                 --backup          Create backup before operations
#                 --compress         Compress files before upload
#
#  REQUIREMENTS:  curl, jq, AWS CLI (optional), Cloudflare R2 API access
#                 Cloudflare API credentials in Bitwarden (entry: cloudflare_r2)
#
#          BUGS:  AWS CLI S3 API compatibility used for best compatibility
#         NOTES:  Uses S3-compatible API for Cloudflare R2 buckets
#                 All API keys retrieved securely from Bitwarden
#                 Automatic retry mechanism for network failures
#
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#       CREATED:  2025-01-08
#      REVISION:  
#===============================================================================

# Ensure script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Error: This script must be sourced, not executed" >&2
    exit 1
fi

# Configuration
CLOUDFLARE_API_BASE="${CLOUDFLARE_API_BASE:-https://api.cloudflare.com/client/v4}"
CLOUDFLARE_R2_ENDPOINT="${CLOUDFLARE_R2_ENDPOINT:-}"
CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-}"
CLOUDFLARE_API_KEY_ENTRY="${CLOUDFLARE_API_KEY_ENTRY:-cloudflare_r2}"
CLOUDFLARE_BUCKET="${CLOUDFLARE_BUCKET:-}"
CLOUDFLARE_MAX_RETRIES="${CLOUDFLARE_MAX_RETRIES:-3}"
CLOUDFLARE_RETRY_DELAY="${CLOUDFLARE_RETRY_DELAY:-2}"
CLOUDFLARE_TIMEOUT="${CLOUDFLARE_TIMEOUT:-30}"

# S3-compatible endpoint configuration
if [[ -z "$CLOUDFLARE_R2_ENDPOINT" && -n "$CLOUDFLARE_ACCOUNT_ID" ]]; then
    CLOUDFLARE_R2_ENDPOINT="https://${CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com"
fi

# State directories
CLOUDFLARE_CACHE_DIR="${HOME}/.cache/cloudflare_r2"
CLOUDFLARE_LOG_DIR="${HOME}/.logs/cloudflare_r2"
CLOUDFLARE_TEMP_DIR="${HOME}/.temp/cloudflare_r2"

# Create required directories
mkdir -p "$CLOUDFLARE_CACHE_DIR" "$CLOUDFLARE_LOG_DIR" "$CLOUDFLARE_TEMP_DIR"

# Logging function
_cf_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${CLOUDFLARE_LOG_DIR}/cloudflare_$(date +%Y%m%d).log"
    
    echo "[$timestamp] [$level] $message" | tee -a "$log_file"
}

# Error handling with logging
_cf_error() {
    _cf_log "ERROR" "$*"
    echo "ERROR: $*" >&2
    return 1
}

# Success logging
_cf_success() {
    _cf_log "SUCCESS" "$*"
    echo "✓ $*"
}

# Warning logging
_cf_warning() {
    _cf_log "WARNING" "$*"
    echo "⚠ $*"
}

# Get Cloudflare API credentials from Bitwarden
_get_cloudflare_credentials() {
    local api_key=""
    local account_id=""
    local access_key=""
    local secret_key=""
    
    # Try to get from Bitwarden
    if command -v bw >/dev/null 2>&1; then
        if [[ -n "${BW_SESSION:-}" ]] || BW_SESSION=$(bw unlock --raw 2>/dev/null); then
            # Get API key from Bitwarden item
            local item_json
            item_json=$(bw get item "$CLOUDFLARE_API_KEY_ENTRY" 2>/dev/null || echo "")
            
            if [[ -n "$item_json" ]]; then
                # Extract credentials from custom fields or login
                api_key=$(echo "$item_json" | jq -r '.login.password // empty')
                
                # Try to extract from custom fields
                if [[ -z "$api_key" ]]; then
                    api_key=$(echo "$item_json" | jq -r '.fields[]? | select(.name == "api_key") | .value // empty')
                fi
                
                account_id=$(echo "$item_json" | jq -r '.fields[]? | select(.name == "account_id") | .value // empty')
                access_key=$(echo "$item_json" | jq -r '.fields[]? | select(.name == "access_key") | .value // empty')
                secret_key=$(echo "$item_json" | jq -r '.fields[]? | select(.name == "secret_key") | .value // empty')
            fi
        fi
    fi
    
    # Fallback to environment variables
    if [[ -z "$api_key" && -n "${CLOUDFLARE_API_KEY:-}" ]]; then
        api_key="$CLOUDFLARE_API_KEY"
    fi
    
    if [[ -z "$account_id" && -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
        account_id="$CLOUDFLARE_ACCOUNT_ID"
    fi
    
    if [[ -z "$access_key" && -n "${AWS_ACCESS_KEY_ID:-}" ]]; then
        access_key="$AWS_ACCESS_KEY_ID"
    fi
    
    if [[ -z "$secret_key" && -n "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
        secret_key="$AWS_SECRET_ACCESS_KEY"
    fi
    
    if [[ -z "$api_key" && -z "$access_key" ]]; then
        _cf_error "Cloudflare credentials not found. Store them in Bitwarden as '$CLOUDFLARE_API_KEY_ENTRY' or set environment variables."
        return 1
    fi
    
    echo "api_key=$api_key"
    echo "account_id=$account_id"
    echo "access_key=$access_key"
    echo "secret_key=$secret_key"
}

# Get S3-compatible credentials from API key
_get_s3_credentials() {
    local api_key="$1"
    local account_id="$2"
    
    if [[ -z "$api_key" || -z "$account_id" ]]; then
        _cf_error "API key and account ID required for S3 credentials"
        return 1
    fi
    
    # Create R2 token using Cloudflare API
    local response
    response=$(curl -s -X POST \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -d '{"name":"bash-d-r2-token","permissions":{"r2":{"objects":["read:write","delete"]}}}' \
        "${CLOUDFLARE_API_BASE}/accounts/$account_id/r2/tokens" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        _cf_error "Failed to create R2 token"
        return 1
    fi
    
    local access_key=$(echo "$response" | jq -r '.result.accessKeyId // empty')
    local secret_key=$(echo "$response" | jq -r '.result.secretAccessKey // empty')
    
    if [[ -z "$access_key" || -z "$secret_key" ]]; then
        _cf_error "Failed to extract S3 credentials"
        return 1
    fi
    
    echo "$access_key:$secret_key"
}

# Create S3 signature for authentication
_create_s3_signature() {
    local method="$1"
    local resource="$2"
    local content_type="$3"
    local date="$4"
    local secret_key="$5"
    
    local string_to_sign="$method\n\n$content_type\n$date\n$resource"
    local signature=$(echo -en "$string_to_sign" | openssl dgst -sha1 -hmac "$secret_key" -binary | base64)
    
    echo "$signature"
}

# S3-compatible curl with retries
_cf_s3_curl() {
    local method="$1"
    local bucket="$2"
    local key="$3"
    local data="$4"
    local content_type="${5:-application/octet-stream}"
    local retry_count=0
    
    if [[ -z "$CLOUDFLARE_R2_ENDPOINT" ]]; then
        _cf_error "Cloudflare R2 endpoint not configured"
        return 1
    fi
    
    local url="${CLOUDFLARE_R2_ENDPOINT}/$bucket/$key"
    local date=$(date -u +"%a, %d %b %Y %H:%M:%S GMT")
    
    # Get S3 credentials
    local creds
    if ! creds=$(_get_cloudflare_credentials); then
        return 1
    fi
    
    eval "$creds"
    
    # Get S3 credentials from API key if needed
    if [[ -z "$access_key" || -z "$secret_key" ]]; then
        if ! s3_creds=$(_get_s3_credentials "$api_key" "$account_id"); then
            return 1
        fi
        
        access_key="${s3_creds%%:*}"
        secret_key="${s3_creds#*:}"
    fi
    
    # Create S3 signature
    local signature
    signature=$(_create_s3_signature "$method" "/$bucket/$key" "$content_type" "$date" "$secret_key")
    
    local authorization="AWS $access_key:$signature"
    
    while [[ $retry_count -lt $CLOUDFLARE_MAX_RETRIES ]]; do
        ((retry_count++))
        
        # Build curl command
        local curl_cmd="curl -s -w '%{http_code}' --connect-timeout $CLOUDFLARE_TIMEOUT"
        curl_cmd+=" -X $method"
        curl_cmd+=" -H 'Date: $date'"
        curl_cmd+=" -H 'Content-Type: $content_type'"
        curl_cmd+=" -H 'Authorization: $authorization'"
        
        if [[ -n "$data" && "$method" != "GET" ]]; then
            curl_cmd+=" --data-binary '$data'"
        fi
        
        curl_cmd+=" '$url'"
        
        # Execute request
        local full_response
        full_response=$(eval "$curl_cmd" 2>/dev/null)
        local http_code="${full_response: -3}"
        local response="${full_response%???}"
        
        _cf_log "DEBUG" "S3 Request: $method $url (attempt $retry_count)"
        _cf_log "DEBUG" "Response code: $http_code"
        
        # Check for success
        if [[ "$http_code" =~ ^[23] ]]; then
            echo "$response"
            return 0
        fi
        
        # Handle errors
        case "$http_code" in
            403)
                _cf_error "Access denied. Check credentials and bucket permissions."
                return 1
                ;;
            404)
                _cf_error "Bucket or object not found: $bucket/$key"
                return 1
                ;;
            409)
                _cf_error "Conflict: Object already exists or bucket creation conflict"
                return 1
                ;;
            *)
                if [[ $retry_count -lt $CLOUDFLARE_MAX_RETRIES ]]; then
                    local delay=$((CLOUDFLARE_RETRY_DELAY * retry_count))
                    _cf_warning "Request failed, retrying in ${delay}s (attempt $retry_count/$CLOUDFLARE_MAX_RETRIES)"
                    sleep "$delay"
                    continue
                else
                    _cf_error "Request failed after $CLOUDFLARE_MAX_RETRIES attempts (HTTP $http_code)"
                    return 1
                fi
                ;;
        esac
    done
}

# Upload file to Cloudflare R2
cf_upload_file() {
    local bucket="$1"
    local local_file="$2"
    local remote_path="$3"
    local compress=false
    local backup_enabled=false
    local overwrite=false
    
    # Parse arguments
    shift 3
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --compress)
                compress=true
                shift
                ;;
            --backup)
                backup_enabled=true
                shift
                ;;
            --overwrite)
                overwrite=true
                shift
                ;;
            -*)
                _cf_error "Unknown option: $1"
                return 1
                ;;
            *)
                _cf_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate inputs
    if [[ -z "$bucket" ]]; then
        bucket="$CLOUDFLARE_BUCKET"
        if [[ -z "$bucket" ]]; then
            _cf_error "Bucket name required (use --bucket or set CLOUDFLARE_BUCKET)"
            return 1
        fi
    fi
    
    if [[ -z "$local_file" ]]; then
        _cf_error "Local file path required"
        return 1
    fi
    
    if [[ -z "$remote_path" ]]; then
        remote_path=$(basename "$local_file")
    fi
    
    if [[ ! -f "$local_file" ]]; then
        _cf_error "File not found: $local_file"
        return 1
    fi
    
    # Check if file exists remotely and overwrite is not set
    if [[ "$overwrite" == false ]]; then
        local check_response
        check_response=$(_cf_s3_curl "GET" "$bucket" "$remote_path" "" "")
        
        if [[ $? -eq 0 ]]; then
            _cf_error "Remote file already exists: $remote_path. Use --overwrite to replace."
            return 1
        fi
    fi
    
    # Create backup if enabled
    if [[ "$backup_enabled" == true ]]; then
        local backup_file="${CLOUDFLARE_CACHE_DIR}/backup_${bucket}_${remote_path//\//_}_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$(dirname "$backup_file")"
        cp "$local_file" "$backup_file"
        _cf_success "Backup created: $backup_file"
    fi
    
    # Compress file if requested
    local file_to_upload="$local_file"
    local content_type="application/octet-stream"
    
    if [[ "$compress" == true ]]; then
        file_to_upload="${CLOUDFLARE_TEMP_DIR}/$(basename "$local_file").gz"
        gzip -c "$local_file" > "$file_to_upload"
        content_type="application/gzip"
        remote_path="${remote_path}.gz"
        _cf_log "INFO" "File compressed: $local_file -> $file_to_upload"
    fi
    
    # Read file content
    local file_content
    file_content=$(cat "$file_to_upload")
    
    _cf_log "INFO" "Uploading: $local_file -> $bucket/$remote_path"
    
    # Upload file
    local response
    response=$(_cf_s3_curl "PUT" "$bucket" "$remote_path" "$file_content" "$content_type")
    
    # Cleanup compressed file
    if [[ "$compress" == true && "$file_to_upload" != "$local_file" ]]; then
        rm -f "$file_to_upload"
    fi
    
    if [[ $? -eq 0 ]]; then
        local file_url="${CLOUDFLARE_R2_ENDPOINT}/$bucket/$remote_path"
        _cf_success "File uploaded successfully"
        echo "Bucket: $bucket"
        echo "Remote path: $remote_path"
        echo "Local file: $local_file"
        echo "URL: $file_url"
        return 0
    else
        return 1
    fi
}

# Download file from Cloudflare R2
cf_download_file() {
    local bucket="$1"
    local remote_path="$2"
    local local_file="$3"
    local overwrite=false
    
    # Parse arguments
    shift 3
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --overwrite)
                overwrite=true
                shift
                ;;
            -*)
                _cf_error "Unknown option: $1"
                return 1
                ;;
            *)
                _cf_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate inputs
    if [[ -z "$bucket" ]]; then
        bucket="$CLOUDFLARE_BUCKET"
        if [[ -z "$bucket" ]]; then
            _cf_error "Bucket name required (use --bucket or set CLOUDFLARE_BUCKET)"
            return 1
        fi
    fi
    
    if [[ -z "$remote_path" ]]; then
        _cf_error "Remote path required"
        return 1
    fi
    
    if [[ -z "$local_file" ]]; then
        local_file=$(basename "$remote_path")
    fi
    
    # Check if local file exists and overwrite is not set
    if [[ -f "$local_file" && "$overwrite" == false ]]; then
        _cf_error "Local file already exists: $local_file. Use --overwrite to replace."
        return 1
    fi
    
    # Create directory for local file
    mkdir -p "$(dirname "$local_file")"
    
    _cf_log "INFO" "Downloading: $bucket/$remote_path -> $local_file"
    
    # Download file
    local response
    response=$(_cf_s3_curl "GET" "$bucket" "$remote_path" "" "")
    
    if [[ $? -eq 0 && -n "$response" ]]; then
        echo "$response" > "$local_file"
        _cf_success "File downloaded successfully"
        echo "Bucket: $bucket"
        echo "Remote path: $remote_path"
        echo "Local file: $local_file"
        echo "Size: $(wc -c < "$local_file") bytes"
        return 0
    else
        return 1
    fi
}

# List files in bucket
cf_list_files() {
    local bucket="$1"
    local prefix=""
    local recursive=false
    
    # Parse arguments
    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --prefix=*)
                prefix="${1#*=}"
                shift
                ;;
            --prefix)
                prefix="$2"
                shift 2
                ;;
            --recursive)
                recursive=true
                shift
                ;;
            -*)
                _cf_error "Unknown option: $1"
                return 1
                ;;
            *)
                _cf_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate inputs
    if [[ -z "$bucket" ]]; then
        bucket="$CLOUDFLARE_BUCKET"
        if [[ -z "$bucket" ]]; then
            _cf_error "Bucket name required (use --bucket or set CLOUDFLARE_BUCKET)"
            return 1
        fi
    fi
    
    _cf_log "INFO" "Listing files in bucket: $bucket (prefix: $prefix, recursive: $recursive)"
    
    # Build list query parameters
    local query_params=""
    if [[ -n "$prefix" ]]; then
        query_params="?prefix=$prefix"
    fi
    
    if [[ "$recursive" == true ]]; then
        if [[ -n "$query_params" ]]; then
            query_params+="&list-type=2"
        else
            query_params="?list-type=2"
        fi
    fi
    
    # List files (using S3 ListObjects)
    local url="${CLOUDFLARE_R2_ENDPOINT}/$bucket${query_params}"
    
    # Get S3 credentials and sign request
    local creds
    if ! creds=$(_get_cloudflare_credentials); then
        return 1
    fi
    
    eval "$creds"
    
    # Get S3 credentials from API key if needed
    if [[ -z "$access_key" || -z "$secret_key" ]]; then
        if ! s3_creds=$(_get_s3_credentials "$api_key" "$account_id"); then
            return 1
        fi
        
        access_key="${s3_creds%%:*}"
        secret_key="${s3_creds#*:}"
    fi
    
    local date=$(date -u +"%a, %d %b %Y %H:%M:%S GMT")
    local resource="/$bucket/"
    local signature=$(_create_s3_signature "GET" "$resource" "" "$date" "$secret_key")
    local authorization="AWS $access_key:$signature"
    
    local response
    response=$(curl -s -w '%{http_code}' \
        -H "Date: $date" \
        -H "Authorization: $authorization" \
        "$url" 2>/dev/null)
    
    local http_code="${response: -3}"
    local xml_response="${response%???}"
    
    if [[ "$http_code" != "200" ]]; then
        _cf_error "Failed to list files (HTTP $http_code)"
        return 1
    fi
    
    # Parse XML response and display results
    echo "Files in bucket '$bucket':"
    echo "─"$(printf '─%.0s' {1..50})
    
    if command -v xmllint >/dev/null 2>&1; then
        # Use xmllint if available for proper XML parsing
        echo "$xml_response" | xmllint --xpath "//Key/text()" - 2>/dev/null | while read -r key; do
            if [[ -n "$key" ]]; then
                echo "📄 $key"
            fi
        done
    else
        # Fallback to simple text parsing
        echo "$xml_response" | grep -o '<Key>[^<]*' | sed 's/<Key>//' | while read -r key; do
            if [[ -n "$key" ]]; then
                echo "📄 $key"
            fi
        done
    fi
}

cf_delete_file() {
    local bucket="$1"
    local remote_path="$2"
    local confirm=false
    
    shift 2
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --confirm)
                confirm=true
                shift
                ;;
            -*)
                _cf_error "Unknown option: $1"
                return 1
                ;;
            *)
                _cf_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    if [[ -z "$bucket" ]]; then
        bucket="$CLOUDFLARE_BUCKET"
        if [[ -z "$bucket" ]]; then
            _cf_error "Bucket name required (use --bucket or set CLOUDFLARE_BUCKET)"
            return 1
        fi
    fi
    
    if [[ -z "$remote_path" ]]; then
        _cf_error "Remote path required"
        return 1
    fi
    
    if [[ "$confirm" != true ]]; then
        echo "You are about to delete: $bucket/$remote_path"
        read -r -p "Are you sure? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Deletion cancelled."
            return 0
        fi
    fi
    
    _cf_log "INFO" "Deleting: $bucket/$remote_path"
    
    local response
    response=$(_cf_s3_curl "DELETE" "$bucket" "$remote_path" "" "")
    
    if [[ $? -eq 0 ]]; then
        _cf_success "File deleted successfully"
        return 0
    else
        return 1
    fi
}

# Sync directory to Cloudflare R2
cf_sync_directory() {
    local bucket="$1"
    local local_dir="$2"
    local remote_prefix="$3"
    local delete=false
    local compress=false
    
    # Parse arguments
    shift 3
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --delete)
                delete=true
                shift
                ;;
            --compress)
                compress=true
                shift
                ;;
            -*)
                _cf_error "Unknown option: $1"
                return 1
                ;;
            *)
                _cf_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate inputs
    if [[ -z "$bucket" ]]; then
        bucket="$CLOUDFLARE_BUCKET"
        if [[ -z "$bucket" ]]; then
            _cf_error "Bucket name required (use --bucket or set CLOUDFLARE_BUCKET)"
            return 1
        fi
    fi
    
    if [[ -z "$local_dir" ]]; then
        _cf_error "Local directory required"
        return 1
    fi
    
    if [[ ! -d "$local_dir" ]]; then
        _cf_error "Directory not found: $local_dir"
        return 1
    fi
    
    if [[ -z "$remote_prefix" ]]; then
        remote_prefix=""
    fi
    
    _cf_log "INFO" "Syncing directory: $local_dir -> $bucket/$remote_prefix"
    
    # Sync files (recursive)
    local file_count=0
    local success_count=0
    
    find "$local_dir" -type f | while read -r local_file; do
        ((file_count++))
        
        # Calculate relative path and remote path
        local rel_path="${local_file#$local_dir/}"
        local remote_path="$remote_prefix$rel_path"
        
        echo "Uploading: $rel_path -> $bucket/$remote_path"
        
        local upload_args=""
        if [[ "$compress" == true ]]; then
            upload_args+=" --compress"
        fi
        
        if cf_upload_file "$bucket" "$local_file" "$remote_path" $upload_args; then
            ((success_count++))
        fi
    done
    
    echo "Sync completed: $success_count/$file_count files uploaded"
    
    return 0
}

# Configuration and status
cf_config() {
    echo "Cloudflare R2 Configuration:"
    echo "─"$(printf '─%.0s' {1..40})
    echo "API Base: $CLOUDFLARE_API_BASE"
    echo "R2 Endpoint: ${CLOUDFLARE_R2_ENDPOINT:-'Not configured'}"
    echo "Account ID: ${CLOUDFLARE_ACCOUNT_ID:-'Not configured'}"
    echo "API Key Entry: $CLOUDFLARE_API_KEY_ENTRY"
    echo "Default Bucket: ${CLOUDFLARE_BUCKET:-'Not configured'}"
    echo "Max Retries: $CLOUDFLARE_MAX_RETRIES"
    echo "Timeout: ${CLOUDFLARE_TIMEOUT}s"
    echo "Cache Dir: $CLOUDFLARE_CACHE_DIR"
    echo "Log Dir: $CLOUDFLARE_LOG_DIR"
    echo "Temp Dir: $CLOUDFLARE_TEMP_DIR"
    echo ""
    
    # Test credentials
    echo "Testing credentials..."
    local creds
    if creds=$(_get_cloudflare_credentials); then
        eval "$creds"
        
        if [[ -n "$api_key" && -n "$account_id" ]]; then
            local response
            response=$(curl -s -H "Authorization: Bearer $api_key" \
                "${CLOUDFLARE_API_BASE}/accounts/$account_id/r2/buckets" 2>/dev/null)
            
            if [[ $? -eq 0 ]]; then
                local bucket_count=$(echo "$response" | jq '.result | length // 0')
                echo "✓ Authentication successful"
                echo "✓ Found $bucket_count R2 buckets"
                
                if [[ $bucket_count -gt 0 ]]; then
                    echo ""
                    echo "Available buckets:"
                    echo "$response" | jq -r '.result[].name' | while read -r bucket; do
                        echo "  - $bucket"
                    done
                fi
            else
                echo "✗ Failed to authenticate with Cloudflare API"
                return 1
            fi
        else
            echo "✗ Incomplete credentials (need API key and account ID)"
            return 1
        fi
    else
        echo "✗ Failed to get Cloudflare credentials"
        return 1
    fi
}

# Help function
cf_help() {
    cat << 'EOF'
Cloudflare R2 Storage Wrapper Functions

File Operations:
  cf_upload_file <bucket> <local_file> <remote_path> [--compress] [--backup] [--overwrite]
  cf_download_file <bucket> <remote_path> <local_file> [--overwrite]
  cf_delete_file <bucket> <remote_path> [--confirm]

Directory Operations:
  cf_sync_directory <bucket> <local_dir> <remote_prefix> [--delete] [--compress]
  cf_list_files <bucket> [--prefix=<prefix>] [--recursive]

Configuration:
  cf_config                    Show current configuration and test credentials
  cf_help                      Show this help

Examples:
  cf_upload_file my-bucket /path/to/file.txt documents/file.txt
  cf_download_file my-bucket documents/file.txt ./downloaded_file.txt
  cf_sync_directory my-bucket ./data backup/ --compress
  cf_list_files my-bucket --prefix=documents/ --recursive

Authentication:
  Store Cloudflare credentials in Bitwarden with entry name 'cloudflare_r2'
  Include fields: api_key, account_id, access_key, secret_key
  or set environment variables: CLOUDFLARE_API_KEY, CLOUDFLARE_ACCOUNT_ID

Configuration:
  Set CLOUDFLARE_BUCKET environment variable for default bucket
  Set CLOUDFLARE_ACCOUNT_ID for automatic endpoint configuration
  Use AWS CLI compatibility for S3-compatible operations

For more information, see Cloudflare R2 documentation:
https://developers.cloudflare.com/r2/
EOF
}

# Auto-complete function
if command -v complete >/dev/null 2>&1; then
    _cf_complete() {
        local cur prev words cword
        _init_completion || return
        
        case "$prev" in
            cf_upload_file|cf_download_file|cf_delete_file|cf_sync_directory|cf_list_files)
                # Bucket completion (if we can get list)
                COMPREPLY=($(compgen -W "--help --bucket --prefix --recursive --confirm" -- "$cur"))
                ;;
            --bucket)
                # Could integrate with cf_list_files to get bucket list
                ;;
            *)
                case "$cur" in
                    -*)
                        COMPREPLY=($(compgen -W "--help --version" -- "$cur"))
                        ;;
                    *)
                        COMPREPLY=($(compgen -W "cf_upload_file cf_download_file cf_delete_file cf_sync_directory cf_list_files cf_config cf_help" -- "$cur"))
                        ;;
                esac
                ;;
        esac
    }
    
    complete -F _cf_complete cf_upload_file cf_download_file cf_delete_file cf_sync_directory cf_list_files cf_config cf_help
fi

# Export functions
export -f cf_upload_file cf_download_file cf_list_files cf_delete_file cf_sync_directory cf_config cf_help

_cf_log "INFO" "Cloudflare R2 storage wrapper loaded successfully"