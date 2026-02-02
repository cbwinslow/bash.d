#!/usr/bin/env bash

# Government Data Sources Plugin for bash.d
# Integrates Congress.gov, GovInfo.gov, FBI.gov and other government APIs

set -euo pipefail

# Plugin metadata
readonly PLUGIN_NAME="government"
readonly PLUGIN_VERSION="1.0.0"
readonly PLUGIN_DEPENDENCIES="curl,jq"

# API endpoints
readonly CONGRESS_API="https://api.congress.gov/v3"
readonly GOVINFO_API="https://www.govinfo.gov/api"
readonly FBI_API="https://api.fbi.gov/v1"
readonly API_CACHE_DIR="$HOME/.bash.d/cache/government"

# Initialize government data plugin
plugin_init() {
    echo "Initializing Government Data Sources plugin..."
    
    # Create cache directory
    mkdir -p "$API_CACHE_DIR"
    
    # Setup API rate limiting
    setup_rate_limiting
    
    echo "Government Data Sources plugin initialized successfully"
}

# Setup rate limiting for government APIs
setup_rate_limiting() {
    # Government APIs typically have strict rate limits
    echo "Setting up rate limiting for government APIs..."
    
    # Create rate limit tracking
    cat > "$API_CACHE_DIR/rate_limits.json" << EOF
{
  "congress.gov": {
    "requests_per_hour": 3600,
    "current_requests": 0,
    "reset_time": null
  },
  "govinfo.gov": {
    "requests_per_hour": 1000,
    "current_requests": 0,
    "reset_time": null
  },
  "fbi.gov": {
    "requests_per_hour": 1000,
    "current_requests": 0,
    "reset_time": null
  }
}
EOF
}

# Check rate limit before API call
check_rate_limit() {
    local api="$1"
    local rate_file="$API_CACHE_DIR/rate_limits.json"
    
    if [[ ! -f "$rate_file" ]]; then
        setup_rate_limiting
    fi
    
    local current_requests=$(jq -r ".\"$api\".current_requests // 0" "$rate_file")
    local requests_per_hour=$(jq -r ".\"$api\".requests_per_hour" "$rate_file")
    local reset_time=$(jq -r ".\"$api\".reset_time // null" "$rate_file")
    
    # Check if we need to reset the counter
    local current_time=$(date +%s)
    if [[ -n "$reset_time" && "$current_time" -gt "$reset_time" ]]; then
        current_requests=0
    fi
    
    if [[ "$current_requests" -ge "$requests_per_hour" ]]; then
        echo "Rate limit reached for $api. Please wait before making more requests."
        return 1
    fi
    
    # Update the request count
    local new_requests=$((current_requests + 1))
    jq ".\"$api\".current_requests = $new_requests | .\"$api\".reset_time = $current_time + 3600" "$rate_file" > "$rate_file.tmp"
    mv "$rate_file.tmp" "$rate_file"
    
    return 0
}

# Fetch Congress.gov data with pagination
fetch_congress_data() {
    local endpoint="${1:-bill}"
    local congress="${2:-118}"
    local limit="${3:-50}"
    local offset="${4:-0}"
    
    echo "Fetching Congress data: $endpoint (Congress: $congress, Limit: $limit, Offset: $offset)"
    
    if ! check_rate_limit "congress.gov"; then
        return 1
    fi
    
    local cache_file="$API_CACHE_DIR/congress_${endpoint}_${congress}_${limit}_${offset}.json"
    
    # Check cache first
    if [[ -f "$cache_file" && $(find "$cache_file" -mmin -30 2>/dev/null) ]]; then
        echo "Using cached Congress data"
        cat "$cache_file"
        return 0
    fi
    
    # Fetch from API
    local url="${CONGRESS_API}/${endpoint}?congress=${congress}&limit=${limit}&offset=${offset}"
    echo "Fetching from: $url"
    
    local response=$(curl -s -H "Accept: application/json" \
                       -H "X-API-Key: ${CONGRESS_API_KEY:-}" \
                       "$url")
    
    if [[ $? -eq 0 && -n "$response" ]]; then
        # Cache the response
        echo "$response" > "$cache_file"
        
        # Return with pagination info
        local next_offset=$((offset + limit))
        echo "$response" | jq --arg next "$next_offset" '. + {pagination: {next_offset: $next_offset}}'
    else
        echo "Error fetching Congress data"
        return 1
    fi
}

# Fetch GovInfo.gov data
fetch_govinfo_data() {
    local package_name="${1:-CRS}"
    local last_updated="${2:-}"
    
    echo "Fetching GovInfo data: $package_name"
    
    if ! check_rate_limit "govinfo.gov"; then
        return 1
    fi
    
    local cache_file="$API_CACHE_DIR/govinfo_${package_name}.json"
    
    # Check cache first (24 hour cache)
    if [[ -f "$cache_file" && $(find "$cache_file" -mmin -1440 2>/dev/null) ]]; then
        echo "Using cached GovInfo data"
        cat "$cache_file"
        return 0
    fi
    
    # Build URL with optional parameters
    local url="${GOVINFO_API}/${package_name}"
    if [[ -n "$last_updated" ]]; then
        url="${url}?lastUpdated=${last_updated}"
    fi
    
    echo "Fetching from: $url"
    
    local response=$(curl -s "$url")
    
    if [[ $? -eq 0 && -n "$response" ]]; then
        # Cache the response
        echo "$response" > "$cache_file"
        echo "$response"
    else
        echo "Error fetching GovInfo data"
        return 1
    fi
}

# Fetch FBI crime data
fetch_fbi_data() {
    local endpoint="${1:-crime}"
    local state="${2:-}"
    local year="${3:-2023}"
    
    echo "Fetching FBI data: $endpoint (State: ${state:-ALL}, Year: $year)"
    
    if ! check_rate_limit "fbi.gov"; then
        return 1
    fi
    
    local cache_file="$API_CACHE_DIR/fbi_${endpoint}_${state}_${year}.json"
    
    # Check cache first (7 day cache)
    if [[ -f "$cache_file" && $(find "$cache_file" -mmin -10080 2>/dev/null) ]]; then
        echo "Using cached FBI data"
        cat "$cache_file"
        return 0
    fi
    
    # Build URL
    local url="${FBI_API}/${endpoint}"
    if [[ -n "$state" ]]; then
        url="${url}?state_abbr=${state}"
    fi
    if [[ -n "$year" ]]; then
        url="${url}&year=${year}"
    fi
    
    echo "Fetching from: $url"
    
    local response=$(curl -s -H "Accept: application/json" "$url")
    
    if [[ $? -eq 0 && -n "$response" ]]; then
        # Cache the response
        echo "$response" > "$cache_file"
        echo "$response"
    else
        echo "Error fetching FBI data"
        return 1
    fi
}

# Get all available Congress endpoints
get_congress_endpoints() {
    echo "Available Congress.gov endpoints:"
    echo "  bill           - Bill information"
    echo "  amendment      - Amendment information"
    echo "  law            - Law information"
    echo "  congress       - Congress member information"
    echo "  committee      - Committee information"
    echo "  hearing        - Hearing information"
    echo "  nomination     - Nomination information"
    echo ""
    echo "Usage: bashd plugins government congress bill [congress] [limit] [offset]"
}

# Get all available FBI endpoints
get_fbi_endpoints() {
    echo "Available FBI.gov endpoints:"
    echo "  crime          - Crime statistics"
    echo "  hate-crime    - Hate crime statistics"
    echo "  leo            - Law enforcement officer data"
    echo "  background-check - Background check services"
    echo ""
    echo "Usage: bashd plugins government fbi crime [state] [year]"
}

# Search across all government sources
search_government_data() {
    local query="$1"
    local limit="${2:-20}"
    
    echo "Searching government data for: $query"
    
    # This would implement federated search across all configured sources
    # For now, return placeholder
    cat << EOF
{
  "query": "$query",
  "sources": ["congress.gov", "govinfo.gov", "fbi.gov"],
  "results": [
    {
      "source": "congress.gov",
      "type": "bill",
      "title": "Example bill matching $query",
      "url": "https://congress.gov/bill/123"
    }
  ],
  "pagination": {
    "total": 1,
    "limit": $limit,
    "offset": 0
  }
}
EOF
}

# Check plugin status
plugin_status() {
    echo "Government Data Sources Plugin Status:"
    echo "  Version: $PLUGIN_VERSION"
    echo "  Dependencies: $PLUGIN_DEPENDENCIES"
    echo "  Cache Directory: $API_CACHE_DIR"
    echo "  APIs Configured:"
    echo "    - Congress.gov: ${CONGRESS_API_KEY:+[CONFIGURED]}"
    echo "    - GovInfo.gov: Always available"
    echo "    - FBI.gov: Always available"
    
    # Show cache status
    if [[ -d "$API_CACHE_DIR" ]]; then
        local cache_size=$(du -sh "$API_CACHE_DIR" | cut -f1)
        echo "  Cache Size: $cache_size"
        local file_count=$(find "$API_CACHE_DIR" -type f | wc -l)
        echo "  Cached Files: $file_count"
    fi
}

# Configure plugin
plugin_config() {
    echo "Government Data Sources Plugin Configuration:"
    echo "  Congress API Key: ${CONGRESS_API_KEY:-[NOT SET]}"
    echo "  Cache Directory: $API_CACHE_DIR"
    echo ""
    echo "To configure Congress.gov API:"
    echo "  export CONGRESS_API_KEY='your-api-key'"
    echo ""
    echo "Cache settings in: $API_CACHE_DIR/rate_limits.json"
}

# Cleanup plugin resources
plugin_cleanup() {
    echo "Cleaning up Government Data Sources plugin..."
    
    # Clear cache
    if [[ -d "$API_CACHE_DIR" ]]; then
        rm -rf "$API_CACHE_DIR"
        echo "Cache cleared"
    fi
    
    echo "Government Data Sources plugin cleaned up"
}

# Main function for direct calls
case "${1:-}" in
    "init") plugin_init ;;
    "status") plugin_status ;;
    "config") plugin_config ;;
    "cleanup") plugin_cleanup ;;
    "congress") fetch_congress_data "$2" "$3" "$4" "$5" ;;
    "govinfo") fetch_govinfo_data "$2" "$3" ;;
    "fbi") fetch_fbi_data "$2" "$3" "$4" ;;
    "search") search_government_data "$2" "$3" ;;
    "congress-endpoints") get_congress_endpoints ;;
    "fbi-endpoints") get_fbi_endpoints ;;
    *) echo "Usage: government_plugin.sh {init|status|config|cleanup|congress|govinfo|fbi|search}" ;;
esac