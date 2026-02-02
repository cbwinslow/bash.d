#!/bin/bash
#===============================================================================
#
#          FILE:  yadm_manager.sh
#
#         USAGE:  yadm_setup
#                 yadm_encrypt <file> [files...]
#                 yadm_decrypt <file> [files...]
#                 yadm_add <file> [files...]
#                 yadm_status
#                 yadm_help
#
#   DESCRIPTION:  YADM dotfile manager with encryption, organization,
#                 and automated management
#
#       OPTIONS:  file - Files to encrypt/decrypt/add
#  REQUIREMENTS:  yadm, gpg, git
#         NOTES:  Manages dotfiles with proper encryption and organization
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Configuration
YADM_CONFIG_DIR="${HOME}/.config/yadm"
YADM_ENCRYPTED_DIR="${HOME}/.config/yadm/encrypted"
YADM_LOG="${HOME}/.cache/bashd_yadm.log"
mkdir -p "$YADM_CONFIG_DIR" "$YADM_ENCRYPTED_DIR" "$(dirname "$YADM_LOG")"

# YADM setup and initialization
yadm_setup() {
    echo "Setting up YADM dotfile management..."

    # Check if yadm is installed
    if ! command -v yadm >/dev/null 2>&1; then
        echo "yadm is not installed."
        echo "Install with:"
        echo "  curl -fLo /usr/local/bin/yadm https://github.com/TheLocehiliosan/yadm/raw/master/yadm"
        echo "  chmod +x /usr/local/bin/yadm"
        return 1
    fi

    # Initialize yadm if not already
    if ! yadm status >/dev/null 2>&1; then
        echo "Initializing YADM repository..."
        yadm init
        yadm remote add origin git@github.com:$(whoami)/dotfiles.git 2>/dev/null || \
            yadm remote add origin https://github.com/$(whoami)/dotfiles.git
    fi

    # Create configuration files
    _create_yadm_config

    echo "YADM setup complete!"
    echo "Run: yadm_status to see current status"
}

# Create YADM configuration
_create_yadm_config() {
    # Main YADM config
    cat > "$YADM_CONFIG_DIR/config" << 'EOF'
[core]
    editor = vim
    autoupdate = true

[encrypt]
    gpg = true
    files = (
        "*.secret"
        "*.private"
        "*.key"
        "*.pem"
        "*.env"
        ".ssh/*"
        ".gnupg/*"
        ".aws/*"
        ".azure/*"
        ".gcp/*"
    )

[hooks]
    pre-commit = yadm_encrypt_hook
    post-checkout = yadm_decrypt_hook
EOF

    # Encryption rules
    cat > "$YADM_CONFIG_DIR/encryption_rules" << 'EOF'
# Files that should be encrypted
*.secret
*.private
*.key
*.pem
*.env
.ssh/*
.gnupg/*
.aws/*
.azure/*
.gcp/*
EOF

    # Dotfile organization rules
    cat > "$YADM_CONFIG_DIR/organization_rules" << 'EOF'
# Dotfile organization structure
# Format: source -> destination

# Shell configuration
.bashrc -> shell/bashrc
.bash_profile -> shell/bash_profile
.zshrc -> shell/zshrc
.zshenv -> shell/zshenv

# Editor configuration
.vimrc -> editor/vim/vimrc
.nvim/ -> editor/neovim/
.emacs.d/ -> editor/emacs/

# Development tools
.gitconfig -> dev/git/config
.gitignore_global -> dev/git/ignore
.npmrc -> dev/npm/config

# System configuration
.tmux.conf -> system/tmux.conf
.inputrc -> system/inputrc
.Xresources -> system/Xresources

# Application configuration
.config/* -> apps/
.local/* -> apps/
EOF

    echo "YADM configuration created at: $YADM_CONFIG_DIR"
}

# Encrypt files using GPG
yadm_encrypt() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: yadm_encrypt <file> [files...]"
        echo "Encrypt files using GPG for secure storage"
        return 1
    fi

    # Check for GPG
    if ! command -v gpg >/dev/null 2>&1; then
        echo "gpg is required for encryption"
        return 1
    fi

    local encrypted_count=0
    local failed_count=0

    for file in "$@"; do
        if [[ ! -f "$file" ]]; then
            echo "File not found: $file"
            ((failed_count++))
            continue
        fi

        local encrypted_file="${file}.gpg"
        echo "Encrypting: $file -> $encrypted_file"

        if gpg --yes --encrypt --output "$encrypted_file" "$file" 2>/dev/null; then
            # Remove original if encryption succeeded
            rm "$file"
            echo "✓ Encrypted: $file"
            ((encrypted_count++))
        else
            echo "✗ Failed to encrypt: $file"
            ((failed_count++))
        fi
    done

    echo "Encrypted $encrypted_count files, failed $failed_count files"
    echo "Files encrypted with GPG. Use 'yadm_decrypt' to decrypt."
}

# Decrypt files using GPG
yadm_decrypt() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: yadm_decrypt <file> [files...]"
        echo "Decrypt GPG encrypted files"
        return 1
    fi

    # Check for GPG
    if ! command -v gpg >/dev/null 2>&1; then
        echo "gpg is required for decryption"
        return 1
    fi

    local decrypted_count=0
    local failed_count=0

    for file in "$@"; do
        if [[ ! -f "$file" ]]; then
            echo "File not found: $file"
            ((failed_count++))
            continue
        fi

        # Check if file is GPG encrypted
        if ! file "$file" | grep -q "GPG"; then
            echo "File is not GPG encrypted: $file"
            ((failed_count++))
            continue
        fi

        local decrypted_file="${file%.gpg}"
        echo "Decrypting: $file -> $decrypted_file"

        if gpg --yes --decrypt --output "$decrypted_file" "$file" 2>/dev/null; then
            echo "✓ Decrypted: $file"
            ((decrypted_count++))
        else
            echo "✗ Failed to decrypt: $file"
            ((failed_count++))
        fi
    done

    echo "Decrypted $decrypted_count files, failed $failed_count files"
}

# Add files to YADM with proper organization
yadm_add() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: yadm_add <file> [files...]"
        echo "Add files to YADM with proper organization"
        return 1
    fi

    # Check if yadm is available
    if ! command -v yadm >/dev/null 2>&1; then
        echo "yadm is not installed"
        return 1
    fi

    local added_count=0
    local failed_count=0

    for file in "$@"; do
        if [[ ! -f "$file" && ! -d "$file" ]]; then
            echo "File/directory not found: $file"
            ((failed_count++))
            continue
        fi

        # Check if file should be encrypted
        local should_encrypt=false
        local filename=$(basename "$file")

        # Check against encryption rules
        while read -r pattern; do
            # Skip comments and empty lines
            [[ "$pattern" =~ ^#.*$ || -z "$pattern" ]] && continue

            # Remove quotes if present
            pattern=$(echo "$pattern" | tr -d '"' | tr -d "'")

            # Check if filename matches pattern
            if [[ "$filename" == *$pattern* ]]; then
                should_encrypt=true
                break
            fi
        done < "$YADM_CONFIG_DIR/encryption_rules"

        if [[ "$should_encrypt" == true ]]; then
            echo "Encrypting sensitive file: $file"
            yadm_encrypt "$file"
            file="${file}.gpg"
        fi

        # Add to yadm
        if yadm add "$file" 2>/dev/null; then
            echo "✓ Added to YADM: $file"
            ((added_count++))
        else
            echo "✗ Failed to add: $file"
            ((failed_count++))
        fi
    done

    echo "Added $added_count files to YADM, failed $failed_count files"
}

# YADM status with enhanced information
yadm_status() {
    if ! command -v yadm >/dev/null 2>&1; then
        echo "yadm is not installed"
        return 1
    fi

    echo "YADM Status:"
    echo "════════════════════════════════════════════════════════════════"

    # Basic status
    echo ""
    echo "Repository Status:"
    yadm status --short 2>/dev/null || echo "No changes"

    echo ""
    echo "Encrypted Files:"
    find "$HOME" -name "*.gpg" -type f 2>/dev/null | head -10 || echo "No encrypted files found"

    echo ""
    echo "Configuration:"
    echo "  Config Dir: $YADM_CONFIG_DIR"
    echo "  Encrypted Dir: $YADM_ENCRYPTED_DIR"
    echo "  Log: $YADM_LOG"

    echo ""
    echo "Quick Actions:"
    echo "  yadm_add <file>      - Add file to YADM"
    echo "  yadm_encrypt <file>  - Encrypt file"
    echo "  yadm_decrypt <file>  - Decrypt file"
    echo "  yadm_setup           - Setup YADM"
}

# YADM pre-commit hook for encryption
yadm_encrypt_hook() {
    echo "Running pre-commit encryption hook..."

    # Get list of files to be committed
    local files_to_commit
    files_to_commit=$(yadm diff --name-only --cached 2>/dev/null)

    if [[ -z "$files_to_commit" ]]; then
        echo "No files to commit"
        return 0
    fi

    local encrypted_count=0

    for file in $files_to_commit; do
        # Check if file should be encrypted
        local should_encrypt=false
        local filename=$(basename "$file")

        while read -r pattern; do
            [[ "$pattern" =~ ^#.*$ || -z "$pattern" ]] && continue
            pattern=$(echo "$pattern" | tr -d '"' | tr -d "'")

            if [[ "$filename" == *$pattern* ]]; then
                should_encrypt=true
                break
            fi
        done < "$YADM_CONFIG_DIR/encryption_rules"

        if [[ "$should_encrypt" == true ]]; then
            echo "Encrypting: $file"
            yadm_encrypt "$file"
            yadm add "${file}.gpg"
            yadm rm --cached "$file" 2>/dev/null
            ((encrypted_count++))
        fi
    done

    echo "Encrypted $encrypted_count files in pre-commit hook"
}

# YADM post-checkout hook for decryption
yadm_decrypt_hook() {
    echo "Running post-checkout decryption hook..."

    # Get list of encrypted files
    local encrypted_files
    encrypted_files=$(find . -name "*.gpg" -type f 2>/dev/null)

    if [[ -z "$encrypted_files" ]]; then
        echo "No encrypted files found"
        return 0
    fi

    local decrypted_count=0

    for file in $encrypted_files; do
        echo "Decrypting: $file"
        yadm_decrypt "$file"
        ((decrypted_count++))
    done

    echo "Decrypted $decrypted_count files in post-checkout hook"
}

# YADM help
yadm_help() {
    cat << 'EOF'
YADM Dotfile Management Commands:

  yadm_setup                - Setup YADM with configuration
  yadm_encrypt <file>...    - Encrypt files using GPG
  yadm_decrypt <file>...    - Decrypt GPG encrypted files
  yadm_add <file>...         - Add files to YADM with proper organization
  yadm_status                - Show YADM status and encrypted files
  yadm_help                 - Show this help message

Configuration Files:
  $YADM_CONFIG_DIR/config          - Main YADM configuration
  $YADM_CONFIG_DIR/encryption_rules - Files that should be encrypted
  $YADM_CONFIG_DIR/organization_rules - File organization structure

Examples:
  yadm_setup
  yadm_encrypt .ssh/id_rsa .aws/credentials
  yadm_decrypt .ssh/id_rsa.gpg
  yadm_add .bashrc .gitconfig
  yadm_status
EOF
}

# Export functions
export -f yadm_setup 2>/dev/null
export -f _create_yadm_config 2>/dev/null
export -f yadm_encrypt 2>/dev/null
export -f yadm_decrypt 2>/dev/null
export -f yadm_add 2>/dev/null
export -f yadm_status 2>/dev/null
export -f yadm_encrypt_hook 2>/dev/null
export -f yadm_decrypt_hook 2>/dev/null
export -f yadm_help 2>/dev/null
