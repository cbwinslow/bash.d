#!/usr/bin/env bash

# Data Portal for bash.d Platform
# Public interface for integrated data sources with search and pagination

# Source core functions
source "$(dirname "${BASH_SOURCE[0]}")/../src/core.sh"

# Data portal configuration
readonly DATA_PORTAL_DIR="$HOME/.bash.d/data/processed"
readonly DATA_PORTAL_CONFIG="$HOME/.bash.d/config/data_portal.yaml"
readonly DATA_CACHE_DIR="$HOME/.bash.d/cache/data_portal"

# Initialize data portal
init_data_portal() {
    log "INFO" "Initializing data portal..."
    
    # Create directories
    ensure_dir "$DATA_PORTAL_DIR"
    ensure_dir "$DATA_CACHE_DIR"
    
    # Create default configuration
    if [[ ! -f "$DATA_PORTAL_CONFIG" ]]; then
        create_data_portal_config
    fi
    
    success "Data portal initialized"
}

# Create data portal configuration
create_data_portal_config() {
    cat > "$DATA_PORTAL_CONFIG" << EOF
# Data Portal Configuration
portal:
  title: "bash.d Data Portal"
  description: "Public access to integrated government, census, and research data"
  version: "1.0.0"
  
features:
  search: true
  pagination: true
  filtering: true
  export: true
  api_access: true
  
data_sources:
  - name: "Congress.gov"
    type: "legislative"
    description: "Bills, laws, and congressional data"
    update_frequency: "daily"
    
  - name: "Census.gov"
    type: "demographic"
    description: "US Census and demographic data"
    update_frequency: "monthly"
    
  - name: "FBI.gov"
    type: "crime"
    description: "Crime statistics and law enforcement data"
    update_frequency: "monthly"
    
  - name: "ACS"
    type: "survey"
    description: "American Community Survey data"
    update_frequency: "annual"
    
  - name: "GovInfo.gov"
    type: "government"
    description: "Government publications and reports"
    update_frequency: "weekly"
    
display:
  items_per_page: 20
  max_search_results: 100
  cache_duration: 3600  # 1 hour
EOF
}

# List available data sources
list_data_sources() {
    log "INFO" "Listing available data sources..."
    
    if [[ -f "$DATA_PORTAL_CONFIG" ]]; then
        grep -A 20 "data_sources:" "$DATA_PORTAL_CONFIG" | grep -E "^\s*- name:" | sed 's/^\s*-\s*name:\s*//'
    else
        error "Data portal configuration not found"
        return 1
    fi
}

# Search across all data sources
search_data() {
    local query="$1"
    local page="${2:-1}"
    local limit="${3:-20}"
    local source="${4:-all}"
    
    if [[ -z "$query" ]]; then
        error "Search query is required"
        return 1
    fi
    
    log "INFO" "Searching data for: $query (page: $page, limit: $limit, source: $source)"
    
    # Check cache first
    local cache_key="search_${source}_${query}_${page}"
    local cache_file="$DATA_CACHE_DIR/${cache_key}.json"
    
    if [[ -f "$cache_file" && $(find "$cache_file" -mmin -60 2>/dev/null) ]]; then
        log "DEBUG" "Using cached search results"
        cat "$cache_file"
        return 0
    fi
    
    # Perform search across configured sources
    local results=$(perform_data_search "$query" "$page" "$limit" "$source")
    
    # Cache results
    echo "$results" > "$cache_file"
    
    # Return results
    echo "$results"
}

# Perform actual data search
perform_data_search() {
    local query="$1"
    local page="$2"
    local limit="$3"
    local source="$4"
    
    local offset=$(((page - 1) * limit))
    
    # This would integrate with actual data sources
    # For now, return mock results
    cat << EOF
{
  "query": "$query",
  "source": "$source",
  "page": $page,
  "limit": $limit,
  "offset": $offset,
  "total": 150,
  "results": [
    {
      "id": "congress_bill_123",
      "title": "Infrastructure Investment and Jobs Act",
      "source": "Congress.gov",
      "type": "legislation",
      "description": "A bill to invest in American infrastructure and create jobs",
      "url": "https://congress.gov/bill/123",
      "date": "2024-01-15",
      "relevance": 0.95
    },
    {
      "id": "census_data_456",
      "title": "Population Demographics by State",
      "source": "Census.gov",
      "type": "demographic",
      "description": "Population breakdown by demographics for all US states",
      "url": "https://api.census.gov/data/456",
      "date": "2024-01-10",
      "relevance": 0.87
    },
    {
      "id": "fbi_crime_789",
      "title": "2023 Crime Statistics Report",
      "source": "FBI.gov",
      "type": "crime",
      "description": "Annual crime statistics for US cities",
      "url": "https://api.fbi.gov/crime/789",
      "date": "2024-01-05",
      "relevance": 0.82
    }
  ],
  "pagination": {
    "current_page": $page,
    "total_pages": 8,
    "has_next": $((page < 8)),
    "has_prev": $((page > 1))
  }
}
EOF
}

# Get specific data item
get_data_item() {
    local item_id="$1"
    local source_type="${2:-}"
    
    if [[ -z "$item_id" ]]; then
        error "Item ID is required"
        return 1
    fi
    
    log "INFO" "Retrieving data item: $item_id"
    
    # Check cache
    local cache_file="$DATA_CACHE_DIR/item_${item_id}.json"
    
    if [[ -f "$cache_file" && $(find "$cache_file" -mmin -30 2>/dev/null) ]]; then
        log "DEBUG" "Using cached item"
        cat "$cache_file"
        return 0
    fi
    
    # This would fetch from actual data source
    # For now, return mock item
    cat << EOF
{
  "id": "$item_id",
  "title": "Sample Data Item",
  "description": "This is a sample data item that would be fetched from the actual data source",
  "source": "$source_type",
  "data": {
    "field1": "value1",
    "field2": "value2",
    "field3": "value3"
  },
  "metadata": {
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-15T12:30:00Z",
    "version": "1.0",
    "tags": ["sample", "data"]
  },
  "download_urls": {
    "json": "https://api.example.com/data/$item_id.json",
    "csv": "https://api.example.com/data/$item_id.csv",
    "xml": "https://api.example.com/data/$item_id.xml"
  }
}
EOF
    
    # Cache the item
    echo "$results" > "$cache_file"
}

# Export data in different formats
export_data() {
    local item_id="$1"
    local format="${2:-json}"
    local output_file="${3:-data_export_${item_id}.${format}}"
    
    if [[ -z "$item_id" ]]; then
        error "Item ID is required"
        return 1
    fi
    
    log "INFO" "Exporting data item $item_id as $format"
    
    # Get the data item
    local data_item=$(get_data_item "$item_id")
    
    case "$format" in
        "json")
            echo "$data_item" | jq . > "$output_file"
            ;;
        "csv")
            echo "$data_item" | jq -r '.data | to_entries[] | [.field1, .field2, .field3] | @csv' > "$output_file"
            ;;
        "xml")
            echo "$data_item" | jq -x > "$output_file"
            ;;
        *)
            error "Unsupported format: $format"
            return 1
            ;;
    esac
    
    success "Data exported: $output_file"
}

# Data portal statistics
data_portal_stats() {
    log "INFO" "Data portal statistics:"
    
    local total_items=$(find "$DATA_PORTAL_DIR" -name "*.json" | wc -l)
    local cache_size=$(du -sh "$DATA_CACHE_DIR" | cut -f1)
    local cache_files=$(find "$DATA_CACHE_DIR" -type f | wc -l)
    
    echo "  Total data items: $total_items"
    echo "  Cache size: $cache_size"
    echo "  Cached files: $cache_files"
    echo "  Last updated: $(find "$DATA_PORTAL_DIR" -name "*.json" -printf "%T\n" | sort -r | head -n1)"
}

# Clear data cache
clear_data_cache() {
    log "INFO" "Clearing data portal cache..."
    
    if [[ -d "$DATA_CACHE_DIR" ]]; then
        rm -rf "$DATA_CACHE_DIR"/*
        success "Data cache cleared"
    else
        warning "Data cache directory does not exist"
    fi
}

# Export data portal functions
export -f init_data_portal
export -f create_data_portal_config
export -f list_data_sources
export -f search_data
export -f perform_data_search
export -f get_data_item
export -f export_data
export -f data_portal_stats
export -f clear_data_cache