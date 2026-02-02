#!/usr/bin/env bash

# Security Functions for bash.d
# Handles Bitwarden integration, encryption, and security management

# Source core functions
source "$(dirname "${BASH_SOURCE[0]}")/core.sh"

# Security configuration
readonly SECURITY_CONFIG_DIR="$BASHD_CONFIG_DIR/security"
readonly SECURITY_LOG_FILE="$BASHD_CONFIG_DIR/security.log"

# Initialize security module
init_security() {
    log "INFO" "Initializing security module..."
    
    # Create security directory
    ensure_dir "$SECURITY_CONFIG_DIR"
    
    # Load Bitwarden plugin
    load_plugin "bitwarden"
    
    # Setup encryption
    setup_encryption
    
    success "Security module initialized"
}

# Setup encryption (GPG + Age)
setup_encryption() {
    log "INFO" "Setting up encryption..."
    
    # Check for GPG
    if command_exists gpg; then
        log "INFO" "GPG found: $(gpg --version | head -n1)"
        
        # Generate GPG key if not exists
        if ! gpg --list-secret-keys | grep -q "$BASHD_EMAIL"; then
            log "INFO" "Generating GPG key for $BASHD_EMAIL"
            gpg --batch --generate-key << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name: bash.d Security
Email: $BASHD_EMAIL
Expire-Date: 1y
%commit
%echo done
EOF
        fi
    else
        warning "GPG not found. Install with: sudo apt-get install gnupg"
    fi
    
    # Check for Age
    if command_exists age; then
        log "INFO" "Age found: $(age --version 2>/dev/null || echo 'unknown')"
        
        # Generate Age key if not exists
        local age_key_file="$SECURITY_CONFIG_DIR/age.key"
        if [[ ! -f "$age_key_file" ]]; then
            log "INFO" "Generating Age key"
            age-keygen -o "$age_key_file" -n "bash.d" -l "$BASHD_EMAIL"
        fi
    else
        warning "Age not found. Install with: go install github.com/FiloSottile/age@latest"
    fi
}

# Encrypt file
encrypt_file() {
    local input_file="$1"
    local output_file="${2:-${input_file}.encrypted}"
    local method="${3:-gpg}"
    
    if ! file_exists "$input_file"; then
        error "Input file not found: $input_file"
        return 1
    fi
    
    log "INFO" "Encrypting $input_file using $method..."
    
    case "$method" in
        "gpg")
            if command_exists gpg; then
                gpg --trust-model always --encrypt -r "$BASHD_EMAIL" --output "$output_file" "$input_file"
                success "File encrypted with GPG: $output_file"
            else
                error "GPG not available"
                return 1
            fi
            ;;
        "age")
            if command_exists age; then
                age -r "$(cat "$SECURITY_CONFIG_DIR/age.pub" 2>/dev/null)" -o "$output_file" "$input_file"
                success "File encrypted with Age: $output_file"
            else
                error "Age not available"
                return 1
            fi
            ;;
        *)
            error "Unsupported encryption method: $method"
            return 1
            ;;
    esac
}

# Decrypt file
decrypt_file() {
    local input_file="$1"
    local output_file="${2:-${input_file%.encrypted}}"
    local method="${3:-gpg}"
    
    if ! file_exists "$input_file"; then
        error "Input file not found: $input_file"
        return 1
    fi
    
    log "INFO" "Decrypting $input_file using $method..."
    
    case "$method" in
        "gpg")
            if command_exists gpg; then
                gpg --output "$output_file" --decrypt "$input_file"
                success "File decrypted with GPG: $output_file"
            else
                error "GPG not available"
                return 1
            fi
            ;;
        "age")
            if command_exists age; then
                age -d -i "$SECURITY_CONFIG_DIR/age.key" -o "$output_file" "$input_file"
                success "File decrypted with Age: $output_file"
            else
                error "Age not available"
                return 1
            fi
            ;;
        *)
            error "Unsupported decryption method: $method"
            return 1
            ;;
    esac
}

# Secure file deletion
secure_delete() {
    local file_path="$1"
    local passes="${2:-3}"
    
    if ! file_exists "$file_path"; then
        error "File not found: $file_path"
        return 1
    fi
    
    log "INFO" "Securely deleting $file_path with $passes passes..."
    
    # Overwrite file with random data
    for ((i=1; i<=passes; i++)); do
        dd if=/dev/urandom of="$file_path" bs=1k count=1 2>/dev/null
    done
    
    # Remove the file
    rm -f "$file_path"
    
    # Sync filesystems
    sync
    
    success "File securely deleted: $file_path"
}

# Generate secure password
generate_secure_password() {
    local length="${1:-32}"
    local include_symbols="${2:-true}"
    
    # Use Bitwarden if available
    if load_plugin "bitwarden" && command_exists "plugin_init"; then
        bashd plugins bitwarden generate "$length" true
    else
        # Fallback to local generation
        local charset="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        [[ "$include_symbols" == "true" ]] && charset+="!@#$%^&*()_+-="
        
        local password=""
        for ((i=1; i<=length; i++)); do
            password+="${charset:$RANDOM%${#charset}:1}"
        done
        
        echo "$password"
    fi
}

# Security audit
security_audit() {
    log "INFO" "Performing security audit..."
    
    local issues=0
    
    # Check file permissions
    find "$BASHD_HOME" -type f -perm /o+w -exec ls -la {} \; 2>/dev/null | while read -r line; do
        warning "World-writable file: $line"
        ((issues++))
    done
    
    # Check for secrets in config
    if grep -r -i "password\|secret\|key\|token" "$BASHD_CONFIG_DIR" 2>/dev/null; then
        warning "Potential secrets found in configuration files"
        ((issues++))
    fi
    
    # Check log file permissions
    if [[ -f "$BASHD_LOG_FILE" ]]; then
        local log_perms=$(stat -c "%a" "$BASHD_LOG_FILE")
        if [[ "$log_perms" != "600" ]]; then
            warning "Log file has insecure permissions: $log_perms"
            ((issues++))
        fi
    fi
    
    # Report results
    if [[ $issues -eq 0 ]]; then
        success "Security audit passed"
    else
        error "Security audit found $issues issues"
        return 1
    fi
    
    # Log audit
    local audit_entry="Security audit completed: $issues issues found"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [AUDIT] $audit_entry" >> "$SECURITY_LOG_FILE"
}

# Setup secure temporary directory
setup_secure_temp() {
    local temp_dir="$1"
    
    # Create with restricted permissions
    mkdir -p -m 700 "$temp_dir"
    
    # Set sticky bit for security
    chmod +t "$temp_dir"
    
    log "INFO" "Secure temporary directory created: $temp_dir"
}

# Export security functions
export -f init_security
export -f setup_encryption
export -f encrypt_file
export -f decrypt_file
export -f secure_delete
export -f generate_secure_password
export -f security_audit
export -f setup_secure_temp

# Security constants
export SECURITY_CONFIG_DIR
export SECURITY_LOG_FILE