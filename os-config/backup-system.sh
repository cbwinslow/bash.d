#!/bin/bash
# Main OS Configuration Backup Script
# Orchestrates all collectors and generates portable bundle
# Usage: ./backup-system.sh [--name backup-name] [--output-dir path] [--dry-run]

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECTORS_DIR="$SCRIPT_DIR/collectors"
BUNDLES_DIR="$SCRIPT_DIR/bundles"
CLOUD_INIT_DIR="$SCRIPT_DIR/cloud-init"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
BACKUP_NAME=""
OUTPUT_DIR=""
DRY_RUN=false

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $*"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --name)
                BACKUP_NAME="$2"
                shift 2
                ;;
            --output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --auto)
                BACKUP_NAME="auto-$(date +%Y%m%d-%H%M%S)"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    cat << EOF
OS Configuration Backup Script

Usage: $0 [OPTIONS]

Options:
    --name NAME         Name for this backup (default: backup-YYYYMMDD-HHMMSS)
    --output-dir DIR    Output directory (default: $BUNDLES_DIR)
    --dry-run          Show what would be done without doing it
    --auto             Automated mode with timestamp name
    -h, --help         Show this help message

Examples:
    $0                                    # Basic backup with timestamp
    $0 --name "production-server"         # Named backup
    $0 --output-dir /tmp/backups          # Custom output directory
    $0 --dry-run                          # See what would be collected

EOF
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing=()
    
    # Check for required commands
    if ! command -v jq &> /dev/null; then
        missing+=("jq")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        log_info "Install with: sudo apt-get install ${missing[*]}"
        exit 1
    fi
    
    # Check collectors exist
    if [ ! -d "$COLLECTORS_DIR" ]; then
        log_error "Collectors directory not found: $COLLECTORS_DIR"
        exit 1
    fi
    
    log_info "All prerequisites satisfied"
}

# Create backup bundle directory
create_bundle_dir() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    BACKUP_NAME="${BACKUP_NAME:-backup-$timestamp}"
    OUTPUT_DIR="${OUTPUT_DIR:-$BUNDLES_DIR/$BACKUP_NAME}"
    
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$OUTPUT_DIR"
        log_info "Created bundle directory: $OUTPUT_DIR"
    else
        log_info "Would create bundle directory: $OUTPUT_DIR"
    fi
}

# Run a collector script
run_collector() {
    local collector_name="$1"
    local collector_script="$COLLECTORS_DIR/${collector_name}.sh"
    local output_file="$OUTPUT_DIR/${collector_name}.json"
    
    if [ ! -f "$collector_script" ]; then
        log_warn "Collector not found: $collector_script"
        return 1
    fi
    
    log_step "Running $collector_name collector..."
    
    if [ "$DRY_RUN" = false ]; then
        # Run collector, keeping stderr separate from stdout (JSON)
        if bash "$collector_script" > "$output_file" 2>/dev/null; then
            log_info "✓ $collector_name data collected"
        else
            log_warn "✗ $collector_name collector failed (non-fatal)"
        fi
    else
        log_info "Would run: $collector_script"
    fi
}

# Collect all system information
collect_all_data() {
    log_step "Collecting system configuration data..."
    
    # Run all collectors
    run_collector "system"
    run_collector "packages"
    run_collector "dotfiles"
    run_collector "tools"
    run_collector "databases"
    run_collector "containers"
    run_collector "repositories"
    run_collector "themes"
    
    log_info "Data collection complete"
}

# Generate cloud-init configuration
generate_cloud_init() {
    log_step "Generating cloud-init configuration..."
    
    local cloud_init_file="$OUTPUT_DIR/cloud-init-user-data.yaml"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would generate: $cloud_init_file"
        return
    fi
    
    # Call the cloud-init generator
    if [ -f "$SCRIPT_DIR/generators/cloud-init-simple.sh" ]; then
        bash "$SCRIPT_DIR/generators/cloud-init-simple.sh" "$OUTPUT_DIR" > "$cloud_init_file"
        log_info "✓ Cloud-init config generated"
    elif [ -f "$SCRIPT_DIR/generators/cloud-init.sh" ]; then
        bash "$SCRIPT_DIR/generators/cloud-init.sh" "$OUTPUT_DIR" > "$cloud_init_file" 2>/dev/null || \
            bash "$SCRIPT_DIR/generators/cloud-init-simple.sh" "$OUTPUT_DIR" > "$cloud_init_file"
        log_info "✓ Cloud-init config generated"
    else
        log_warn "Cloud-init generator not found, skipping"
    fi
}

# Generate setup guide
generate_setup_guide() {
    log_step "Generating setup guide..."
    
    local guide_file="$OUTPUT_DIR/SETUP_GUIDE.md"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would generate: $guide_file"
        return
    fi
    
    cat > "$guide_file" << 'EOF'
# System Configuration Setup Guide

This bundle contains a complete backup of your system configuration.

## Contents

- `system.json` - OS and hardware information
- `packages.json` - Installed packages from all package managers
- `dotfiles.json` - Dotfiles and configuration files
- `tools.json` - Development tools and utilities
- `databases.json` - Database installations and status
- `containers.json` - Docker/Podman containers and images
- `repositories.json` - Git repositories
- `themes.json` - Themes, fonts, and appearance settings
- `cloud-init-user-data.yaml` - Cloud-init configuration file

## Quick Restoration

### Using Cloud-Init (Recommended for Cloud VMs)

```bash
# Use the cloud-init configuration when creating a new instance
# Copy cloud-init-user-data.yaml to your cloud provider
```

### Manual Restoration

1. **Install System Packages**
   ```bash
   # See packages.json for the list
   # For Ubuntu/Debian:
   sudo apt-get update
   sudo apt-get install <packages>
   ```

2. **Restore Dotfiles**
   ```bash
   # Extract dotfiles from the backup
   # Copy to home directory
   ```

3. **Install Programming Language Packages**
   ```bash
   # Python packages
   pip3 install <packages>
   
   # Node.js packages
   npm install -g <packages>
   ```

4. **Configure Services**
   ```bash
   # Enable and start services
   sudo systemctl enable <service>
   sudo systemctl start <service>
   ```

## AI Agent Instructions

This backup is designed to be easily consumed by AI agents. Each JSON file contains:
- Structured data about installed software
- Version information
- Configuration details
- Paths and locations

An AI agent can parse these files to:
1. Generate installation commands
2. Recreate the environment
3. Configure services
4. Restore configurations

## Security Notes

- Sensitive data (passwords, keys) has been filtered out
- Review all configurations before applying
- Update credentials and secrets separately
- Use a password manager for sensitive information

EOF
    
    log_info "✓ Setup guide generated"
}

# Generate metadata file
generate_metadata() {
    log_step "Generating bundle metadata..."
    
    local metadata_file="$OUTPUT_DIR/metadata.json"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Would generate: $metadata_file"
        return
    fi
    
    cat > "$metadata_file" << EOF
{
    "backup_name": "$BACKUP_NAME",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$(hostname)",
    "created_by": "$(whoami)",
    "os": "$(uname -s)",
    "bundle_path": "$OUTPUT_DIR",
    "files": [
        "system.json",
        "packages.json",
        "dotfiles.json",
        "tools.json",
        "databases.json",
        "containers.json",
        "repositories.json",
        "themes.json",
        "cloud-init-user-data.yaml",
        "SETUP_GUIDE.md",
        "metadata.json"
    ]
}
EOF
    
    log_info "✓ Metadata generated"
}

# Create symlink to latest backup
create_latest_symlink() {
    if [ "$DRY_RUN" = true ]; then
        log_info "Would create symlink: $BUNDLES_DIR/latest -> $OUTPUT_DIR"
        return
    fi
    
    local latest_link="$BUNDLES_DIR/latest"
    
    # Remove old symlink if it exists
    [ -L "$latest_link" ] && rm "$latest_link"
    
    # Create new symlink
    ln -s "$OUTPUT_DIR" "$latest_link"
    
    log_info "✓ Created symlink: latest -> $BACKUP_NAME"
}

# Print summary
print_summary() {
    echo ""
    echo "========================================"
    echo "  Backup Complete!"
    echo "========================================"
    echo ""
    echo "Backup Name:    $BACKUP_NAME"
    echo "Bundle Path:    $OUTPUT_DIR"
    echo "Cloud-Init:     $OUTPUT_DIR/cloud-init-user-data.yaml"
    echo "Setup Guide:    $OUTPUT_DIR/SETUP_GUIDE.md"
    echo ""
    echo "To restore this configuration:"
    echo "  ./os-config/restore-system.sh $OUTPUT_DIR"
    echo ""
    echo "To use with cloud-init:"
    echo "  cp $OUTPUT_DIR/cloud-init-user-data.yaml /path/to/user-data"
    echo ""
}

# Main function
main() {
    echo "========================================"
    echo "  OS Configuration Backup"
    echo "========================================"
    echo ""
    
    parse_args "$@"
    check_prerequisites
    create_bundle_dir
    collect_all_data
    generate_cloud_init
    generate_setup_guide
    generate_metadata
    create_latest_symlink
    print_summary
    
    if [ "$DRY_RUN" = true ]; then
        log_info "Dry run complete. No files were created."
    fi
}

# Run main
main "$@"
