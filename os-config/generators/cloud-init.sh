#!/bin/bash
# Cloud-Init Configuration Generator
# Converts collected system data into cloud-init user-data format
# Usage: ./cloud-init.sh <bundle-directory>

set -euo pipefail

BUNDLE_DIR="${1:-.}"

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

# Start cloud-init user-data
cat << 'EOF'
#cloud-config
# Generated OS Configuration
# This file can be used with cloud-init to recreate system configuration

# Update and upgrade packages on first boot
package_update: true
package_upgrade: true

EOF

# Extract and format package lists
if [ -f "$BUNDLE_DIR/packages.json" ]; then
    echo "# System packages"
    echo "packages:"
    
    # Extract apt packages if available (limit to first 100)
    jq -r '.package_managers[] | select(.manager == "apt") | .manually_installed[]? // empty' "$BUNDLE_DIR/packages.json" 2>/dev/null | \
    head -100 | \
    while read -r pkg; do
        # Filter out some problematic packages
        if [[ ! "$pkg" =~ ^(linux-|lib.*-dev$) ]]; then
            echo "  - $pkg"
        fi
    done
    
    echo ""
fi

# Generate runcmd section for additional setup
echo "# Additional setup commands"
echo "runcmd:"

# Python packages
if [ -f "$BUNDLE_DIR/packages.json" ]; then
    pip_packages=$(jq -r '.package_managers[] | select(.manager == "pip3") | .packages[].name' "$BUNDLE_DIR/packages.json" 2>/dev/null | head -20)
    if [ -n "$pip_packages" ]; then
        echo "  # Install Python packages"
        echo "  - pip3 install $(echo $pip_packages | tr '\n' ' ')"
    fi
fi

# NPM packages
if [ -f "$BUNDLE_DIR/packages.json" ]; then
    npm_packages=$(jq -r '.package_managers[] | select(.manager == "npm") | .global_packages | keys[]' "$BUNDLE_DIR/packages.json" 2>/dev/null | head -10)
    if [ -n "$npm_packages" ]; then
        echo "  # Install NPM packages"
        echo "  - npm install -g $(echo $npm_packages | tr '\n' ' ')"
    fi
fi

# System services
if [ -f "$BUNDLE_DIR/system.json" ]; then
    services=$(jq -r '.services.enabled_services[]?' "$BUNDLE_DIR/system.json" 2>/dev/null | head -10)
    if [ -n "$services" ]; then
        echo "  # Enable system services"
        while read -r service; do
            echo "  - systemctl enable $service"
        done <<< "$services"
    fi
fi

# Create user directories
echo "  # Create common directories"
echo "  - mkdir -p /home/ubuntu/projects"
echo "  - mkdir -p /home/ubuntu/.config"
echo "  - chown ubuntu:ubuntu /home/ubuntu/projects /home/ubuntu/.config"

echo ""

# Write dotfiles if they exist
if [ -f "$BUNDLE_DIR/dotfiles.json" ]; then
    echo "# Write configuration files"
    echo "write_files:"
    
    # Example: Create a basic bashrc entry
    cat << 'INNEREOF'
  - path: /etc/profile.d/custom-env.sh
    permissions: '0644'
    content: |
      # Custom environment variables
      export EDITOR=vim
      export VISUAL=vim

INNEREOF
fi

# Final setup
cat << 'EOF'
# Set timezone
timezone: UTC

# Configure SSH
ssh_pwauth: false
ssh_authorized_keys: []

# Final message
final_message: "System configuration completed. Time: $UPTIME"

EOF
