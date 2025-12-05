#!/bin/bash
#===============================================================================
#
#          FILE:  keybinding_manager.sh
#
#         USAGE:  keybind_list
#                 keybind_set <key> <command>
#                 keybind_remove <key>
#                 keybind_save
#                 keybind_load
#                 keybind_export
#                 keybind_import <file>
#                 keybind_help
#
#   DESCRIPTION:  Keybinding management system with on-the-fly changes,
#                 profiles, and easy configuration
#
#       OPTIONS:  key - Key combination (e.g., "Ctrl+Alt+D")
#                 command - Command to bind
#                 file - File to import/export
#  REQUIREMENTS:  bind, sed, grep
#         NOTES:  Manages keybindings for bash and other applications
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Configuration
KEYBIND_CONFIG="${HOME}/.config/bashd/keybindings.json"
KEYBIND_PROFILES_DIR="${HOME}/.config/bashd/keybindings/profiles"
mkdir -p "$(dirname "$KEYBIND_CONFIG")" "$KEYBIND_PROFILES_DIR"

# Initialize keybinding config if not exists
if [[ ! -f "$KEYBIND_CONFIG" ]]; then
    echo '{"bindings": {}, "profiles": {"default": {}}, "current_profile": "default"}' > "$KEYBIND_CONFIG"
fi

# List current keybindings
keybind_list() {
    local profile="${1}"

    if [[ -z "$profile" ]]; then
        profile=$(jq -r '.current_profile' "$KEYBIND_CONFIG")
    fi

    echo "Current Keybindings (Profile: $profile):"
    echo "═════════════════════════════════════════════════════════════════"

    local bindings
    bindings=$(jq -r ".profiles.\"$profile\"" "$KEYBIND_CONFIG")

    if [[ "$bindings" == "null" || "$bindings" == "{}" ]]; then
        echo "No keybindings defined for profile: $profile"
        return 0
    fi

    echo "$bindings" | jq -r 'to_entries[] | "  \(.key) -> \(.value)"'
}

# Set a keybinding
keybind_set() {
    local key="${1}"
    local command="${2}"

    if [[ -z "$key" || -z "$command" ]]; then
        echo "Usage: keybind_set <key> <command>"
        echo ""
        echo "Examples:"
        echo "  keybind_set \"Ctrl+Alt+D\" \"inventory_menu\""
        echo "  keybind_set \"Ctrl+Shift+F\" \"func_recall\""
        return 1
    fi

    local profile
    profile=$(jq -r '.current_profile' "$KEYBIND_CONFIG")

    # Update the keybinding
    jq --arg key "$key" --arg command "$command" \
       ".profiles.\"$profile\" += {\$key: \$command} | .updated = \"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"" \
       "$KEYBIND_CONFIG" > "${KEYBIND_CONFIG}.tmp" && \
        mv "${KEYBIND_CONFIG}.tmp" "$KEYBIND_CONFIG"

    echo "✓ Set keybinding: $key -> $command"

    # Apply the keybinding immediately
    _apply_keybinding "$key" "$command"
}

# Remove a keybinding
keybind_remove() {
    local key="${1}"

    if [[ -z "$key" ]]; then
        echo "Usage: keybind_remove <key>"
        return 1
    fi

    local profile
    profile=$(jq -r '.current_profile' "$KEYBIND_CONFIG")

    # Remove the keybinding
    jq "del(.profiles.\"$profile\".\"$key\") | .updated = \"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"" \
       "$KEYBIND_CONFIG" > "${KEYBIND_CONFIG}.tmp" && \
        mv "${KEYBIND_CONFIG}.tmp" "$KEYBIND_CONFIG"

    echo "✓ Removed keybinding: $key"
}

# Save current keybindings
keybind_save() {
    local profile="${1}"

    if [[ -z "$profile" ]]; then
        profile=$(jq -r '.current_profile' "$KEYBIND_CONFIG")
    fi

    echo "Saving keybindings for profile: $profile"

    # Save to profile file
    jq ".profiles.\"$profile\"" "$KEYBIND_CONFIG" > "${KEYBIND_PROFILES_DIR}/${profile}.json"

    echo "✓ Saved keybindings to: ${KEYBIND_PROFILES_DIR}/${profile}.json"
}

# Load keybindings from a profile
keybind_load() {
    local profile="${1}"

    if [[ -z "$profile" ]]; then
        echo "Usage: keybind_load <profile>"
        echo ""
        echo "Available profiles:"
        ls "$KEYBIND_PROFILES_DIR" 2>/dev/null | sed 's/\.json$//'
        return 1
    fi

    local profile_file="${KEYBIND_PROFILES_DIR}/${profile}.json"

    if [[ ! -f "$profile_file" ]]; then
        echo "Profile not found: $profile"
        return 1
    fi

    # Update current profile
    jq --arg profile "$profile" \
       '.current_profile = $profile | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$KEYBIND_CONFIG" > "${KEYBIND_CONFIG}.tmp" && \
        mv "${KEYBIND_CONFIG}.tmp" "$KEYBIND_CONFIG"

    # Load the profile
    jq --argjson profile_data "$(cat "$profile_file")" \
       '.profiles[$profile] = $profile_data | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$KEYBIND_CONFIG" > "${KEYBIND_CONFIG}.tmp" && \
        mv "${KEYBIND_CONFIG}.tmp" "$KEYBIND_CONFIG"

    echo "✓ Loaded keybindings from profile: $profile"

    # Apply all keybindings
    keybind_apply
}

# Apply all keybindings from current profile
keybind_apply() {
    local profile
    profile=$(jq -r '.current_profile' "$KEYBIND_CONFIG")

    echo "Applying keybindings for profile: $profile"

    local bindings
    bindings=$(jq -r ".profiles.\"$profile\" | to_entries[] | \"\(.key) \(.value)\"" "$KEYBIND_CONFIG")

    if [[ -z "$bindings" ]]; then
        echo "No keybindings to apply for profile: $profile"
        return 0
    fi

    local applied_count=0
    local failed_count=0

    while IFS= read -r line; do
        local key="${line% *}"
        local command="${line#* }"

        if _apply_keybinding "$key" "$command"; then
            ((applied_count++))
        else
            ((failed_count++))
        fi
    done <<< "$bindings"

    echo "Applied $applied_count keybindings, failed $failed_count"
}

# Apply a single keybinding
_apply_keybinding() {
    local key="${1}"
    local command="${2}"

    # Convert key to bind format
    local bind_key
    bind_key=$(echo "$key" | sed 's/+/ /g' | sed 's/ /-/g')

    # Apply the keybinding
    if bind -x "\"\\$bind_key\": \"$command\"" 2>/dev/null; then
        echo "✓ Applied keybinding: $key -> $command"
        return 0
    else
        echo "✗ Failed to apply keybinding: $key -> $command"
        return 1
    fi
}

# Export keybindings to file
keybind_export() {
    local file="${1:-${HOME}/.config/bashd/keybindings_export.json}"

    echo "Exporting keybindings to: $file"

    cp "$KEYBIND_CONFIG" "$file"
    echo "✓ Exported keybindings to: $file"
}

# Import keybindings from file
keybind_import() {
    local file="${1}"

    if [[ -z "$file" ]]; then
        echo "Usage: keybind_import <file>"
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi

    echo "Importing keybindings from: $file"

    # Merge with existing configuration
    jq --argjson import_data "$(cat "$file")" \
       '.bindings += $import_data.bindings | .profiles += $import_data.profiles | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$KEYBIND_CONFIG" > "${KEYBIND_CONFIG}.tmp" && \
        mv "${KEYBIND_CONFIG}.tmp" "$KEYBIND_CONFIG"

    echo "✓ Imported keybindings from: $file"

    # Apply the imported keybindings
    keybind_apply
}

# Create a new profile
keybind_profile_create() {
    local profile="${1}"

    if [[ -z "$profile" ]]; then
        echo "Usage: keybind_profile_create <profile>"
        return 1
    fi

    local profile_file="${KEYBIND_PROFILES_DIR}/${profile}.json"

    if [[ -f "$profile_file" ]]; then
        echo "Profile already exists: $profile"
        return 1
    fi

    echo '{}' > "$profile_file"
    echo "✓ Created profile: $profile"

    # Add to main config
    jq --arg profile "$profile" \
       '.profiles[$profile] = {} | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$KEYBIND_CONFIG" > "${KEYBIND_CONFIG}.tmp" && \
        mv "${KEYBIND_CONFIG}.tmp" "$KEYBIND_CONFIG"
}

# Delete a profile
keybind_profile_delete() {
    local profile="${1}"

    if [[ -z "$profile" ]]; then
        echo "Usage: keybind_profile_delete <profile>"
        return 1
    fi

    local profile_file="${KEYBIND_PROFILES_DIR}/${profile}.json"

    if [[ ! -f "$profile_file" ]]; then
        echo "Profile not found: $profile"
        return 1
    fi

    # Check if this is the current profile
    local current_profile
    current_profile=$(jq -r '.current_profile' "$KEYBIND_CONFIG")

    if [[ "$profile" == "$current_profile" ]]; then
        echo "Cannot delete current active profile: $profile"
        echo "Switch to another profile first"
        return 1
    fi

    # Remove from main config
    jq "del(.profiles.\"$profile\") | .updated = \"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\"" \
       "$KEYBIND_CONFIG" > "${KEYBIND_CONFIG}.tmp" && \
        mv "${KEYBIND_CONFIG}.tmp" "$KEYBIND_CONFIG"

    # Remove profile file
    rm "$profile_file"

    echo "✓ Deleted profile: $profile"
}

# List available profiles
keybind_profile_list() {
    echo "Available Keybinding Profiles:"
    echo "════════════════════════════════════════════════════════════════"

    local current_profile
    current_profile=$(jq -r '.current_profile' "$KEYBIND_CONFIG")

    jq -r '.profiles | keys[]' "$KEYBIND_CONFIG" | while read -r profile; do
        if [[ "$profile" == "$current_profile" ]]; then
            echo "  $profile (active)"
        else
            echo "  $profile"
        fi
    done

    echo ""
    echo "Current profile: $current_profile"
}

# Switch to a different profile
keybind_profile_switch() {
    local profile="${1}"

    if [[ -z "$profile" ]]; then
        echo "Usage: keybind_profile_switch <profile>"
        echo ""
        echo "Available profiles:"
        keybind_profile_list
        return 1
    fi

    local profile_file="${KEYBIND_PROFILES_DIR}/${profile}.json"

    if [[ ! -f "$profile_file" ]]; then
        echo "Profile not found: $profile"
        return 1
    fi

    # Update current profile
    jq --arg profile "$profile" \
       '.current_profile = $profile | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$KEYBIND_CONFIG" > "${KEYBIND_CONFIG}.tmp" && \
        mv "${KEYBIND_CONFIG}.tmp" "$KEYBIND_CONFIG"

    echo "✓ Switched to profile: $profile"

    # Apply the new profile's keybindings
    keybind_apply
}

# Keybinding help
keybind_help() {
    cat << 'EOF'
Keybinding Management Commands:

  keybind_list [profile]           - List current keybindings
  keybind_set <key> <command>      - Set a keybinding
  keybind_remove <key>             - Remove a keybinding
  keybind_save [profile]           - Save current keybindings
  keybind_load <profile>           - Load keybindings from profile
  keybind_apply                    - Apply current profile keybindings
  keybind_export [file]            - Export keybindings to file
  keybind_import <file>            - Import keybindings from file
  keybind_profile_create <name>    - Create a new profile
  keybind_profile_delete <name>    - Delete a profile
  keybind_profile_list             - List available profiles
  keybind_profile_switch <name>    - Switch to a different profile
  keybind_help                     - Show this help message

Key Format Examples:
  Ctrl+Alt+D
  Ctrl+Shift+F
  Alt+1
  F12

Command Examples:
  inventory_menu
  func_recall
  bundle_deploy project_docs
  doc_lookup git

Examples:
  keybind_set "Ctrl+Alt+D" "inventory_menu"
  keybind_set "Ctrl+Shift+F" "func_recall"
  keybind_profile_create development
  keybind_profile_switch development
  keybind_save development
  keybind_load development
EOF
}

# Export functions
export -f keybind_list 2>/dev/null
export -f keybind_set 2>/dev/null
export -f keybind_remove 2>/dev/null
export -f keybind_save 2>/dev/null
export -f keybind_load 2>/dev/null
export -f keybind_apply 2>/dev/null
export -f keybind_export 2>/dev/null
export -f keybind_import 2>/dev/null
export -f keybind_profile_create 2>/dev/null
export -f keybind_profile_delete 2>/dev/null
export -f keybind_profile_list 2>/dev/null
export -f keybind_profile_switch 2>/dev/null
export -f keybind_help 2>/dev/null
