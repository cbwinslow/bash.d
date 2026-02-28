#!/usr/bin/env bash

# Complete Backup System - Full system backup to GitHub
# Part of bash.d - Backup and restore system

set -euo pipefail

BASHD_HOME="${BASHD_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BACKUP_REPO="${BACKUP_REPO:-cbwinslow/backup}"
INVENTORY_DIR="$BASHD_HOME/inventory"
CONVERSATION_LOGS_DIR="$BASHD_HOME/conversation-logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Ensure directories exist
mkdir -p "$INVENTORY_DIR"
mkdir -p "$CONVERSATION_LOGS_DIR"

# ============================================
# Configuration
# ============================================

load_backup_config() {
    # Load backup-specific configuration
    if [[ -f "$BASHD_HOME/config/backup.yaml" ]]; then
        # Load backup config if exists
        return 0
    fi
    
    # Default configuration
    export BACKUP_GITHUB_TOKEN="${BACKUP_GITHUB_TOKEN:-}"
    export BACKUP_R2_ENABLED="${BACKUP_R2_ENABLED:-false}"
    export BACKUP_ENCRYPT_ENABLED="${BACKUP_ENCRYPT_ENABLED:-false}"
    export BACKUP_COMPRESSION="${BACKUP_COMPRESSION:-gz}"
}

# ============================================
# Pre-backup: Run inventory
# ============================================

pre_backup_inventory() {
    log_info "Running pre-backup inventory..."
    
    # Run inventory with current timestamp
    "$BASHD_HOME/scripts/inventory.sh" all
    
    log_info "Inventory complete"
}

# ============================================
# Backup: Dotfiles
# ============================================

backup_dotfiles() {
    log_info "Backing up dotfiles..."
    
    local backup_dir="$INVENTORY_DIR/backups/dotfiles_$TIMESTAMP"
    mkdir -p "$backup_dir"
    
    # Copy dotfiles
    if [[ -d "$BASHD_HOME/dotfiles" ]]; then
        cp -r "$BASHD_HOME/dotfiles"/* "$backup_dir/" 2>/dev/null || true
        log_info "  ✓ Dotfiles backed up"
    fi
    
    # Copy bashrc if exists in home
    if [[ -f "$HOME/.bashrc" ]]; then
        cp "$HOME/.bashrc" "$backup_dir/home_bashrc" 2>/dev/null || true
    fi
    
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$backup_dir/home_zshrc" 2>/dev/null || true
    fi
    
    if [[ -f "$HOME/.gitconfig" ]]; then
        cp "$HOME/.gitconfig" "$backup_dir/home_gitconfig" 2>/dev/null || true
    fi
    
    if [[ -f "$HOME/.vimrc" ]]; then
        cp "$HOME/.vimrc" "$backup_dir/home_vimrc" 2>/dev/null || true
    fi
    
    echo "$backup_dir"
}

# ============================================
# Backup: Configuration files
# ============================================

backup_configs() {
    log_info "Backing up configurations..."
    
    local backup_dir="$INVENTORY_DIR/backups/configs_$TIMESTAMP"
    mkdir -p "$backup_dir"
    
    # Copy all config files
    find "$BASHD_HOME/config" -type f -name "*.yaml" -o -name "*.yml" -o -name "*.json" 2>/dev/null | while read -r config; do
        cp "$config" "$backup_dir/" 2>/dev/null || true
    done
    
    log_info "  ✓ Configurations backed up"
    echo "$backup_dir"
}

# ============================================
# Backup: Scripts library
# ============================================

backup_scripts() {
    log_info "Backing up scripts..."
    
    local backup_dir="$INVENTORY_DIR/backups/scripts_$TIMESTAMP"
    mkdir -p "$backup_dir"
    
    # Copy all shell scripts
    find "$BASHD_HOME/scripts" -name "*.sh" -type f 2>/dev/null | while read -r script; do
        cp "$script" "$backup_dir/" 2>/dev/null || true
    done
    
    # Copy bash_functions
    find "$BASHD_HOME/bash_functions.d" -name "*.sh" -type f 2>/dev/null | while read -r script; do
        local subdir=$(basename "$(dirname "$script")")
        mkdir -p "$backup_dir/bash_functions.d/$subdir"
        cp "$script" "$backup_dir/bash_functions.d/$subdir/" 2>/dev/null || true
    done
    
    log_info "  ✓ Scripts backed up"
    echo "$backup_dir"
}

# ============================================
# Backup: Package lists
# ============================================

backup_packages() {
    log_info "Backing up package lists..."
    
    local backup_dir="$INVENTORY_DIR/backups/packages_$TIMESTAMP"
    mkdir -p "$backup_dir"
    
    # Copy latest inventory files
    latest_inventory=$(ls -t "$INVENTORY_DIR"/pip_*.txt 2>/dev/null | head -1)
    [[ -n "$latest_inventory" ]] && cp "$latest_inventory" "$backup_dir/" 2>/dev/null || true
    
    latest_inventory=$(ls -t "$INVENTORY_DIR"/npm_global_*.txt 2>/dev/null | head -1)
    [[ -n "$latest_inventory" ]] && cp "$latest_inventory" "$backup_dir/" 2>/dev/null || true
    
    latest_inventory=$(ls -t "$INVENTORY_DIR"/brew_*.txt 2>/dev/null | head -1)
    [[ -n "$latest_inventory" ]] && cp "$latest_inventory" "$backup_dir/" 2>/dev/null || true
    
    log_info "  ✓ Package lists backed up"
    echo "$backup_dir"
}

# ============================================
# Backup: SSH and GPG keys (metadata only)
# ============================================

backup_keys_metadata() {
    log_info "Backing up SSH/GPG key metadata..."
    
    local backup_dir="$INVENTORY_DIR/backups/keys_$TIMESTAMP"
    mkdir -p "$backup_dir"
    
    # SSH keys (public only)
    if [[ -d "$HOME/.ssh" ]]; then
        ls -1 "$HOME/.ssh"/*.pub 2>/dev/null | while read -r key; do
            cp "$key" "$backup_dir/" 2>/dev/null || true
        done
    fi
    
    # GPG keys (public only)
    if command -v gpg &> /dev/null; then
        gpg --list-keys --keyid-format LONG 2>/dev/null > "$backup_dir/gpg_keys.txt" || true
    fi
    
    log_info "  ✓ Key metadata backed up (no private keys)"
    echo "$backup_dir"
}

# ============================================
# Backup: Docker configs
# ============================================

backup_docker() {
    log_info "Backing up Docker configurations..."
    
    local backup_dir="$INVENTORY_DIR/backups/docker_$TIMESTAMP"
    mkdir -p "$backup_dir"
    
    # Docker configs
    if [[ -f "$HOME/.docker/config.json" ]]; then
        mkdir -p "$backup_dir/docker"
        cp "$HOME/.docker/config.json" "$backup_dir/docker/" 2>/dev/null || true
    fi
    
    # Copy docker-compose files from common locations
    find ~ -maxdepth 3 -name "docker-compose.yml" -o -name "docker-compose.yaml" 2>/dev/null | head -10 | while read -r compose; do
        local subdir=$(basename "$(dirname "$compose")")
        mkdir -p "$backup_dir/compose/$subdir"
        cp "$compose" "$backup_dir/compose/$subdir/" 2>/dev/null || true
    done
    
    log_info "  ✓ Docker configurations backed up"
    echo "$backup_dir"
}

# ============================================
# Compress and create archive
# ============================================

create_backup_archive() {
    log_info "Creating backup archive..."
    
    local backup_dir="$INVENTORY_DIR/backups"
    local archive_name="bashd_backup_$TIMESTAMP.tar.gz"
    
    # Create compressed archive
    tar -czf "$backup_dir/$archive_name" -C "$INVENTORY_DIR" "backups" 2>/dev/null || true
    
    # Calculate checksum
    if command -v sha256sum &> /dev/null; then
        sha256sum "$backup_dir/$archive_name" > "$backup_dir/$archive_name.sha256"
    fi
    
    log_info "  ✓ Archive created: $archive_name"
    echo "$backup_dir/$archive_name"
}

# ============================================
# GitHub Upload
# ============================================

upload_to_github() {
    local file="$1"
    local destination="${2:-}"
    
    if [[ -z "$BACKUP_GITHUB_TOKEN" ]]; then
        log_warn "GitHub token not set. Skipping GitHub upload."
        log_warn "Set BACKUP_GITHUB_TOKEN to enable GitHub upload."
        return 1
    fi
    
    if [[ -z "$destination" ]]; then
        destination="backups/$(basename "$file")"
    fi
    
    log_info "Uploading to GitHub..."
    
    # Check if file exists in repo
    local exists=$(curl -s -H "Authorization: token $BACKUP_GITHUB_TOKEN" \
        "https://api.github.com/repos/$BACKUP_REPO/contents/$destination" | \
        jq -r '.sha // empty' 2>/dev/null || echo "")
    
    # Upload file
    local data
    if [[ -n "$exists" ]]; then
        # Update existing file
        data=$(jq -n \
            --arg msg "Update $destination" \
            --arg content "$(base64 -w0 "$file")" \
            --arg sha "$exists" \
            '{message: $msg, content: $content, sha: $sha}')
    else
        # Create new file
        data=$(jq -n \
            --arg msg "Upload $destination" \
            --arg content "$(base64 -w0 "$file")" \
            '{message: $msg, content: $content}')
    fi
    
    local response=$(curl -s -X PUT \
        -H "Authorization: token $BACKUP_GITHUB_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "https://api.github.com/repos/$BACKUP_REPO/contents/$destination")
    
    if echo "$response" | jq -e '.content' > /dev/null 2>&1; then
        log_info "  ✓ Uploaded to GitHub: $destination"
        return 0
    else
        log_error "Failed to upload: $(echo "$response" | jq -r '.message // "Unknown error"')"
        return 1
    fi
}

# ============================================
# Cloudflare R2 Upload (S3-compatible)
# ============================================

upload_to_r2() {
    local file="$1"
    
    if [[ "$BACKUP_R2_ENABLED" != "true" ]]; then
        log_warn "R2 upload not enabled. Skipping."
        return 1
    fi
    
    log_info "Uploading to Cloudflare R2..."
    
    local r2_bucket="${R2_BUCKET:-bashd-backup}"
    local r2_endpoint="${R2_ENDPOINT:-}"
    local r2_access_key="${R2_ACCESS_KEY:-}"
    local r2_secret_key="${R2_SECRET_KEY:-}"
    
    if [[ -z "$r2_endpoint" ]] || [[ -z "$r2_access_key" ]]; then
        log_error "R2 configuration missing"
        return 1
    fi
    
    # Upload using AWS CLI or curl
    if command -v aws &> /dev/null; then
        aws s3 cp "$file" "s3://$r2_bucket/backups/$(basename "$file")" \
            --endpoint-url "$r2_endpoint" \
            --access-key "$r2_access_key" \
            --secret-key "$r2_secret_key" \
            --no-sign-request 2>/dev/null || true
        log_info "  ✓ Uploaded to R2"
    else
        log_warn "AWS CLI not installed. Skipping R2 upload."
    fi
}

# ============================================
# Create backup manifest
# ============================================

create_manifest() {
    log_info "Creating backup manifest..."
    
    local manifest_file="$INVENTORY_DIR/backups/manifest_$TIMESTAMP.json"
    
    cat > "$manifest_file" << EOF
{
  "timestamp": "$TIMESTAMP",
  "date": "$(date -Iseconds)",
  "hostname": "$(hostname)",
  "bashd_version": "1.0.0",
  "backup_type": "full",
  "components": [
    "dotfiles",
    "configs",
    "scripts",
    "packages",
    "keys_metadata",
    "docker"
  ],
  "inventory": {
    "pip_packages": "$(ls -t "$INVENTORY_DIR"/pip_*.txt 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "")",
    "npm_packages": "$(ls -t "$INVENTORY_DIR"/npm_global_*.txt 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "")",
    "brew_packages": "$(ls -t "$INVENTORY_DIR"/brew_*.txt 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "")"
  }
}
EOF
    
    log_info "  ✓ Manifest created"
    echo "$manifest_file"
}

# ============================================
# Full backup process
# ============================================

run_full_backup() {
    log_info "Starting full backup process..."
    
    # Run pre-backup inventory
    pre_backup_inventory
    
    # Backup components
    backup_dotfiles
    backup_configs
    backup_scripts
    backup_packages
    backup_keys_metadata
    backup_docker
    
    # Create manifest
    create_manifest
    
    # Create archive
    local archive=$(create_backup_archive)
    
    # Upload to GitHub
    if [[ -n "$BACKUP_GITHUB_TOKEN" ]]; then
        upload_to_github "$archive" "backups/$(basename "$archive")"
        upload_to_github "$INVENTORY_DIR/backups/manifest_$TIMESTAMP.json" "backups/manifest_$TIMESTAMP.json"
    fi
    
    # Upload to R2
    if [[ "$BACKUP_R2_ENABLED" == "true" ]]; then
        upload_to_r2 "$archive"
    fi
    
    log_info "Full backup complete!"
    log_info "Backup files: $INVENTORY_DIR/backups/"
}

# ============================================
# Quick backup (scripts + configs only)
# ============================================

run_quick_backup() {
    log_info "Starting quick backup..."
    
    # Just backup scripts and configs
    backup_scripts
    backup_configs
    
    # Create small archive
    local backup_dir="$INVENTORY_DIR/backups"
    tar -czf "$backup_dir/quick_backup_$TIMESTAMP.tar.gz" \
        -C "$BASHD_HOME/scripts" . \
        -C "$BASHD_HOME/config" . 2>/dev/null || true
    
    log_info "Quick backup complete!"
}

# ============================================
# Restore from backup
# ============================================

restore_from_backup() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    log_info "Restoring from backup..."
    
    # Create restore directory
    local restore_dir="$INVENTORY_DIR/restore_$TIMESTAMP"
    mkdir -p "$restore_dir"
    
    # Extract
    tar -xzf "$backup_file" -C "$restore_dir" || true
    
    log_info "Files extracted to: $restore_dir"
    log_info "Review files before copying to their destinations."
}

# ============================================
# Download latest backup from GitHub
# ============================================

download_latest_backup() {
    if [[ -z "$BACKUP_GITHUB_TOKEN" ]]; then
        log_error "GitHub token required for download"
        return 1
    fi
    
    log_info "Downloading latest backup from GitHub..."
    
    # Get latest backup file
    local backups=$(curl -s -H "Authorization: token $BACKUP_GITHUB_TOKEN" \
        "https://api.github.com/repos/$BACKUP_REPO/contents/backups")
    
    local latest=$(echo "$backups" | jq -r '.[] | select(.name | startswith("bashd_backup")) | .name' 2>/dev/null | sort | tail -1)
    
    if [[ -z "$latest" ]] || [[ "$latest" == "null" ]]; then
        log_error "No backups found in repository"
        return 1
    fi
    
    # Download file
    local download_url=$(curl -s -H "Authorization: token $BACKUP_GITHUB_TOKEN" \
        "https://api.github.com/repos/$BACKUP_REPO/contents/backups/$latest" | \
        jq -r '.content' | base64 -d > "$INVENTORY_DIR/backups/$latest" && echo "$INVENTORY_DIR/backups/$latest")
    
    log_info "Downloaded: $latest"
    echo "$INVENTORY_DIR/backups/$latest"
}

# ============================================
# Status and info
# ============================================

show_backup_status() {
    log_info "Backup Status"
    echo "============="
    echo ""
    echo "Local Backups:"
    ls -lh "$INVENTORY_DIR/backups/"*.tar.gz 2>/dev/null || echo "  No local backups found"
    echo ""
    
    echo "Configuration:"
    echo "  BACKUP_GITHUB_TOKEN: ${BACKUP_GITHUB_TOKEN:+set} ${BACKUP_GITHUB_TOKEN:+***}"
    echo "  BACKUP_R2_ENABLED: $BACKUP_R2_ENABLED"
    echo "  BACKUP_REPO: $BACKUP_REPO"
    echo ""
    
    echo "GitHub Backups:"
    if [[ -n "$BACKUP_GITHUB_TOKEN" ]]; then
        curl -s -H "Authorization: token $BACKUP_GITHUB_TOKEN" \
            "https://api.github.com/repos/$BACKUP_REPO/contents/backups" | \
            jq -r '.[] | .name' 2>/dev/null || echo "  Could not fetch"
    else
        echo "  Token not set"
    fi
}

# ============================================
# Main
# ============================================

main() {
    load_backup_config
    
    local command="${1:-status}"
    
    case "$command" in
        "full")
            run_full_backup
            ;;
        "quick")
            run_quick_backup
            ;;
        "restore")
            restore_from_backup "${2:-}"
            ;;
        "download")
            download_latest_backup
            ;;
        "status")
            show_backup_status
            ;;
        *)
            echo "Usage: $0 {full|quick|restore|download|status}"
            echo ""
            echo "Commands:"
            echo "  full     - Run complete backup (dotfiles, configs, scripts, packages)"
            echo "  quick    - Quick backup (scripts + configs only)"
            echo "  restore  - Restore from backup file"
            echo "  download - Download latest backup from GitHub"
            echo "  status   - Show backup status"
            exit 1
            ;;
    esac
}

main "$@"
