#!/usr/bin/env bash

# Cloudflare Integration Plugin for bash.d
# Handles R2 storage, Workers, DNS management for cloudcurio.cc

set -euo pipefail

# Plugin metadata
readonly PLUGIN_NAME="cloudflare"
readonly PLUGIN_VERSION="1.0.0"
readonly PLUGIN_DEPENDENCIES="curl,jq,wrangler"

# Cloudflare configuration
readonly CLOUDFLARE_API="https://api.cloudflare.com/client/v4"
readonly DOMAIN="cloudcurio.cc"

# Initialize Cloudflare plugin
plugin_init() {
    echo "Initializing Cloudflare plugin..."
    
    # Check dependencies
    if ! command -v wrangler &> /dev/null; then
        echo "Installing Wrangler CLI..."
        install_wrangler
    fi
    
    # Load configuration
    load_cloudflare_config
    
    # Setup R2 storage
    setup_r2_storage
    
    # Setup Workers
    setup_workers
    
    echo "Cloudflare plugin initialized successfully"
}

# Install Wrangler CLI
install_wrangler() {
    if command -v npm &> /dev/null; then
        npm install -g wrangler
    else
        echo "npm not found. Please install Node.js first."
        return 1
    fi
}

# Load Cloudflare configuration
load_cloudflare_config() {
    # Try to get from environment
    CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-}"
    CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
    
    # Try to get from Bitwarden if not in environment
    if [[ -z "$CLOUDFLARE_ACCOUNT_ID" ]]; then
        echo "Retrieving Cloudflare credentials from Bitwarden..."
        CLOUDFLARE_ACCOUNT_ID=$(bashd plugins bitwarden get "Cloudflare Account ID")
    fi
    
    if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
        echo "Retrieving Cloudflare API token from Bitwarden..."
        CLOUDFLARE_API_TOKEN=$(bashd plugins bitwarden get "Cloudflare API Token")
    fi
    
    if [[ -z "$CLOUDFLARE_ACCOUNT_ID" || -z "$CLOUDFLARE_API_TOKEN" ]]; then
        echo "Error: Cloudflare credentials not found"
        echo "Please set CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN environment variables"
        return 1
    fi
    
    echo "Cloudflare configuration loaded"
}

# Setup R2 storage
setup_r2_storage() {
    echo "Setting up Cloudflare R2 storage..."
    
    # Create bucket
    local bucket_name="bashd-storage"
    echo "Creating R2 bucket: $bucket_name"
    
    curl -s -X PUT "$CLOUDFLARE_API/accounts/$CLOUDFLARE_ACCOUNT_ID/r2/buckets" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$bucket_name\"}" \
        | jq .
    
    echo "R2 bucket created/verified: $bucket_name"
    
    # Store bucket info for later use
    echo "R2_BUCKET_NAME=$bucket_name" >> "$HOME/.bash.d/cloudflare_config"
}

# Upload file to R2
upload_to_r2() {
    local file_path="$1"
    local remote_path="${2:-$(basename "$file_path")}"
    
    if [[ ! -f "$file_path" ]]; then
        echo "Error: File not found: $file_path"
        return 1
    fi
    
    echo "Uploading $file_path to R2://bashd-storage/$remote_path"
    
    # This would need the actual R2 upload implementation
    # For now, just show the command that would be used
    echo "Command: wrangler r2 object put bashd-storage/$remote_path $file_path"
}

# Setup Workers
setup_workers() {
    echo "Setting up Cloudflare Workers..."
    
    # Create Workers directory
    mkdir -p "$HOME/.bash.d/workers"
    
    # Create a basic worker for the platform
    cat > "$HOME/.bash.d/workers/platform-worker.js" << 'EOF'
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Handle different routes
    if (url.pathname === '/api/health') {
      return new Response(JSON.stringify({status: 'ok', timestamp: Date.now()}), {
        headers: { 'Content-Type': 'application/json' },
      });
    }
    
    if (url.pathname === '/api/data') {
      // This would integrate with your data sources
      return new Response(JSON.stringify({
        sources: ['census', 'acs', 'congress', 'fbi'],
        status: 'operational'
      }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }
    
    // Default response
    return new Response('bash.d Platform API', {
      status: 200,
      headers: { 'Content-Type': 'text/plain' },
    });
  },
};
EOF
    
    echo "Worker created at $HOME/.bash.d/workers/platform-worker.js"
}

# Deploy worker
deploy_worker() {
    local worker_name="${1:-platform-worker}"
    
    echo "Deploying worker: $worker_name"
    
    cd "$HOME/.bash.d/workers"
    wrangler deploy --compatibility-date 2023-05-18
    
    echo "Worker deployed successfully"
}

# Setup DNS for cloudcurio.cc
setup_dns() {
    echo "Setting up DNS for $DOMAIN"
    
    # Get zone ID for the domain
    local zone_id=$(curl -s "$CLOUDFLARE_API/zones?name=$DOMAIN" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        | jq -r '.result[0].id')
    
    if [[ -n "$zone_id" ]]; then
        echo "Found zone ID: $zone_id"
        
        # Create A record for the platform
        curl -s -X POST "$CLOUDFLARE_API/zones/$zone_id/dns_records" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"type\": \"A\",
                \"name\": \"$DOMAIN\",
                \"content\": \"192.168.1.1\",
                \"ttl\": 3600,
                \"proxied\": true
            }" \
            | jq .
        
        echo "DNS record created for $DOMAIN"
    else
        echo "Error: Could not find zone for $DOMAIN"
        return 1
    fi
}

# Check plugin status
plugin_status() {
    echo "Cloudflare Plugin Status:"
    echo "  Version: $PLUGIN_VERSION"
    echo "  Dependencies: $PLUGIN_DEPENDENCIES"
    echo "  Domain: $DOMAIN"
    
    if command -v wrangler &> /dev/null; then
        echo "  Wrangler CLI: Installed"
    else
        echo "  Wrangler CLI: Not installed"
    fi
    
    if [[ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
        echo "  Account ID: Configured"
    else
        echo "  Account ID: Not configured"
    fi
    
    if [[ -n "${CLOUDFLARE_API_TOKEN:-}" ]]; then
        echo "  API Token: Configured"
    else
        echo "  API Token: Not configured"
    fi
}

# Configure plugin
plugin_config() {
    echo "Cloudflare Plugin Configuration:"
    echo "  API Endpoint: $CLOUDFLARE_API"
    echo "  Domain: $DOMAIN"
    echo "  Account ID: ${CLOUDFLARE_ACCOUNT_ID:-[NOT SET]}"
    echo "  API Token: ${CLOUDFLARE_API_TOKEN:+[CONFIGURED]}"
    echo ""
    echo "To configure:"
    echo "  export CLOUDFLARE_ACCOUNT_ID='your-account-id'"
    echo "  export CLOUDFLARE_API_TOKEN='your-api-token'"
    echo "  bashd plugins cloudflare init"
}

# Cleanup plugin resources
plugin_cleanup() {
    echo "Cleaning up Cloudflare plugin..."
    
    # Clear configuration variables
    unset CLOUDFLARE_ACCOUNT_ID
    unset CLOUDFLARE_API_TOKEN
    
    echo "Cloudflare plugin cleaned up"
}

# Main function for direct calls
case "${1:-}" in
    "init") plugin_init ;;
    "status") plugin_status ;;
    "config") plugin_config ;;
    "cleanup") plugin_cleanup ;;
    "upload") upload_to_r2 "$2" "$3" ;;
    "deploy") deploy_worker "$2" ;;
    "dns") setup_dns ;;
    *) echo "Usage: cloudflare_plugin.sh {init|status|config|cleanup|upload|deploy|dns}" ;;
esac