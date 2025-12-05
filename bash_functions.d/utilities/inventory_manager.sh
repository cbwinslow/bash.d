#!/bin/bash
#===============================================================================
#
#          FILE:  inventory_manager.sh
#
#         USAGE:  inventory_add <name> <file> [files...]
#                 inventory_list [name]
#                 inventory_use <name> [destination]
#                 inventory_remove <name> <file> [files...]
#                 inventory_delete <name>
#                 inventory_quick <slot> <command>
#                 inventory_help
#
#   DESCRIPTION:  Quick inventory and slot system for rapid access to
#                 frequently used bundles, commands, and files
#
#       OPTIONS:  name - Inventory item name
#                 slot - Quick slot number (1-9)
#                 file - Files to add/remove
#                 destination - Where to use inventory item
#  REQUIREMENTS:  jq, fzf (optional)
#         NOTES:  Inventory items are stored in ~/.inventory/
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Configuration
INVENTORY_DIR="${HOME}/.inventory"
INVENTORY_META_DIR="${HOME}/.inventory/meta"
QUICK_SLOTS_FILE="${HOME}/.inventory/quick_slots.json"
mkdir -p "$INVENTORY_DIR" "$INVENTORY_META_DIR"

# Initialize quick slots if not exists
if [[ ! -f "$QUICK_SLOTS_FILE" ]]; then
    echo '{}' > "$QUICK_SLOTS_FILE"
fi

# Add items to inventory
inventory_add() {
    local name="${1}"
    local files=("${@:2}")

    if [[ -z "$name" || ${#files[@]} -eq 0 ]]; then
        echo "Usage: inventory_add <name> <file> [files...]"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local inventory_dir="${INVENTORY_DIR}/${name}"
    local meta_file="${INVENTORY_META_DIR}/${name}.json"

    if [[ -d "$inventory_dir" ]]; then
        echo "Inventory item already exists: $name"
        return 1
    fi

    # Create inventory directory
    mkdir -p "$inventory_dir"

    # Create metadata
    cat > "$meta_file" << EOF
{
    "name": "$name",
    "type": "inventory",
    "created": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
    "updated": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
    "files": [],
    "description": "",
    "hotkey": "",
    "quick_slot": "",
    "version": "1.0.0"
}
EOF

    local added_count=0
    local failed_count=0

    for file in "${files[@]}"; do
        if [[ ! -f "$file" && ! -d "$file" ]]; then
            echo "File/directory not found: $file"
            ((failed_count++))
            continue
        fi

        local dest_file="${inventory_dir}/$(basename "$file")"

        # Copy file to inventory
        if cp -r "$file" "$dest_file"; then
            echo "✓ Added to inventory: $file -> $dest_file"
            ((added_count++))

            # Update metadata
            local filename=$(basename "$file")
            jq --arg file "$filename" \
               '.files += [$file] | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
               "$meta_file" > "${meta_file}.tmp" && mv "${meta_file}.tmp" "$meta_file"
        else
            echo "✗ Failed to add: $file"
            ((failed_count++))
        fi
    done

    echo "Added $added_count files to inventory, failed $failed_count files"
}

# List inventory items
inventory_list() {
    local name="${1}"

    if [[ -z "$name" ]]; then
        # List all inventory items
        echo "Quick Inventory Items:"
        echo "════════════════════════════════════════════════════════════════"

        for meta_file in "$INVENTORY_META_DIR"/*.json; do
            if [[ -f "$meta_file" ]]; then
                local name
                name=$(jq -r '.name' "$meta_file")
                local file_count
                file_count=$(jq '.files | length' "$meta_file")
                local quick_slot
                quick_slot=$(jq -r '.quick_slot' "$meta_file")
                local hotkey
                hotkey=$(jq -r '.hotkey' "$meta_file")

                echo ""
                echo "[$name]"
                echo "  Files: $file_count"
                if [[ -n "$quick_slot" && "$quick_slot" != "null" ]]; then
                    echo "  Quick Slot: $quick_slot"
                fi
                if [[ -n "$hotkey" && "$hotkey" != "null" ]]; then
                    echo "  Hotkey: $hotkey"
                fi
            fi
        done

        echo ""
        echo "Quick Slots:"
        echo "════════════════════════════════════════════════════════════════"

        # Show quick slots
        for slot in {1..9}; do
            local item
            item=$(jq -r ".\"$slot\"" "$QUICK_SLOTS_FILE" 2>/dev/null || echo "null")
            if [[ "$item" != "null" ]]; then
                echo "  Slot $slot: $item"
            else
                echo "  Slot $slot: (empty)"
            fi
        done

        echo ""
        echo "Total inventory items: $(ls "$INVENTORY_META_DIR"/*.json 2>/dev/null | wc -l)"
    else
        # List specific inventory item contents
        local meta_file="${INVENTORY_META_DIR}/${name}.json"

        if [[ ! -f "$meta_file" ]]; then
            echo "Inventory item not found: $name"
            return 1
        fi

        local inventory_dir="${INVENTORY_DIR}/${name}"

        echo "Inventory Item: $name"
        echo "════════════════════════════════════════════════════════════════"

        # Show metadata
        jq '.' "$meta_file"

        echo ""
        echo "Files:"
        echo "─────────────────────────────────────────────────────────────────"

        if [[ -d "$inventory_dir" ]]; then
            find "$inventory_dir" -type f | while read -r file; do
                local rel_file
                rel_file=$(echo "$file" | sed "s|$inventory_dir/||")
                local size
                size=$(du -h "$file" | cut -f1)
                echo "  $rel_file ($size)"
            done
        else
            echo "  (no files)"
        fi
    fi
}

# Use inventory item (deploy to destination)
inventory_use() {
    local name="${1}"
    local destination="${2:-./}"

    if [[ -z "$name" ]]; then
        echo "Usage: inventory_use <name> [destination]"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local inventory_dir="${INVENTORY_DIR}/${name}"
    local meta_file="${INVENTORY_META_DIR}/${name}.json"

    if [[ ! -d "$inventory_dir" ]]; then
        echo "Inventory item not found: $name"
        return 1
    fi

    if [[ ! -f "$meta_file" ]]; then
        echo "Inventory metadata not found: $meta_file"
        return 1
    fi

    # Create destination directory
    mkdir -p "$destination"

    echo "Using inventory item: $name to $destination"

    # Copy all files
    local used_count=0
    local failed_count=0

    find "$inventory_dir" -type f | while read -r file; do
        local rel_file
        rel_file=$(echo "$file" | sed "s|$inventory_dir/||")
        local dest_file="${destination}/${rel_file}"

        # Create subdirectories if needed
        mkdir -p "$(dirname "$dest_file")"

        if cp "$file" "$dest_file"; then
            echo "✓ Used: $rel_file"
            ((used_count++))
        else
            echo "✗ Failed to use: $rel_file"
            ((failed_count++))
        fi
    done

    echo "Used $used_count files, failed $failed_count files"
    echo "Inventory item used to: $destination"
}

# Remove files from inventory item
inventory_remove() {
    local name="${1}"
    local files=("${@:2}")

    if [[ -z "$name" || ${#files[@]} -eq 0 ]]; then
        echo "Usage: inventory_remove <name> <file> [files...]"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local inventory_dir="${INVENTORY_DIR}/${name}"
    local meta_file="${INVENTORY_META_DIR}/${name}.json"

    if [[ ! -d "$inventory_dir" ]]; then
        echo "Inventory item not found: $name"
        return 1
    fi

    if [[ ! -f "$meta_file" ]]; then
        echo "Inventory metadata not found: $meta_file"
        return 1
    fi

    local removed_count=0
    local failed_count=0

    for file in "${files[@]}"; do
        local inventory_file="${inventory_dir}/$(basename "$file")"

        if [[ ! -f "$inventory_file" ]]; then
            echo "File not found in inventory: $file"
            ((failed_count++))
            continue
        fi

        if rm "$inventory_file"; then
            echo "✓ Removed from inventory: $file"

            # Update metadata
            local filename=$(basename "$file")
            jq --arg file "$filename" \
               '.files -= [$file] | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
               "$meta_file" > "${meta_file}.tmp" && mv "${meta_file}.tmp" "$meta_file"

            ((removed_count++))
        else
            echo "✗ Failed to remove: $file"
            ((failed_count++))
        fi
    done

    echo "Removed $removed_count files from inventory, failed $failed_count files"
}

# Delete inventory item completely
inventory_delete() {
    local name="${1}"

    if [[ -z "$name" ]]; then
        echo "Usage: inventory_delete <name>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local inventory_dir="${INVENTORY_DIR}/${name}"
    local meta_file="${INVENTORY_META_DIR}/${name}.json"

    if [[ ! -d "$inventory_dir" && ! -f "$meta_file" ]]; then
        echo "Inventory item not found: $name"
        return 1
    fi

    echo "Are you sure you want to delete inventory item: $name? (y/n)"
    read -r response

    if [[ "$response" =~ ^[Yy] ]]; then
        if [[ -d "$inventory_dir" ]]; then
            rm -rf "$inventory_dir"
            echo "✓ Deleted inventory directory"
        fi

        if [[ -f "$meta_file" ]]; then
            rm "$meta_file"
            echo "✓ Deleted inventory metadata"
        fi

        # Remove from quick slots if present
        local quick_slot
        quick_slot=$(jq -r '.quick_slot' "$meta_file" 2>/dev/null || echo "")
        if [[ -n "$quick_slot" && "$quick_slot" != "null" ]]; then
            jq "del(.\"$quick_slot\")" "$QUICK_SLOTS_FILE" > "${QUICK_SLOTS_FILE}.tmp" && \
                mv "${QUICK_SLOTS_FILE}.tmp" "$QUICK_SLOTS_FILE"
            echo "✓ Removed from quick slot $quick_slot"
        fi

        echo "Inventory item deleted: $name"
    else
        echo "Cancelled inventory deletion"
    fi
}

# Quick slot management
inventory_quick() {
    local slot="${1}"
    local command="${2}"

    if [[ -z "$slot" ]]; then
        echo "Usage: inventory_quick <slot> [command]"
        echo ""
        echo "Slots: 1-9"
        echo "Commands:"
        echo "  set <name>    - Set quick slot to inventory item"
        echo "  use [dest]    - Use quick slot item"
        echo "  list         - List quick slot contents"
        echo "  clear        - Clear quick slot"
        return 1
    fi

    # Validate slot
    if [[ ! "$slot" =~ ^[1-9]$ ]]; then
        echo "Invalid slot: $slot (must be 1-9)"
        return 1
    fi

    if [[ -z "$command" ]]; then
        # List quick slot contents
        local item
        item=$(jq -r ".\"$slot\"" "$QUICK_SLOTS_FILE" 2>/dev/null || echo "null")

        if [[ "$item" != "null" ]]; then
            echo "Quick Slot $slot: $item"
            inventory_list "$item"
        else
            echo "Quick Slot $slot: (empty)"
        fi
        return 0
    fi

    case "$command" in
        set)
            local name="${3}"

            if [[ -z "$name" ]]; then
                echo "Usage: inventory_quick $slot set <name>"
                return 1
            fi

            # Sanitize name
            name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

            local meta_file="${INVENTORY_META_DIR}/${name}.json"

            if [[ ! -f "$meta_file" ]]; then
                echo "Inventory item not found: $name"
                return 1
            fi

            # Update quick slots
            jq --arg item "$name" \
               ".\"$slot\" = \$item" \
               "$QUICK_SLOTS_FILE" > "${QUICK_SLOTS_FILE}.tmp" && \
                mv "${QUICK_SLOTS_FILE}.tmp" "$QUICK_SLOTS_FILE"

            # Update inventory item metadata
            jq --arg slot "$slot" \
               '.quick_slot = $slot | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
               "$meta_file" > "${meta_file}.tmp" && mv "${meta_file}.tmp" "$meta_file"

            echo "✓ Set quick slot $slot to: $name"
            ;;
        use)
            local name
            name=$(jq -r ".\"$slot\"" "$QUICK_SLOTS_FILE" 2>/dev/null || echo "")

            if [[ -z "$name" ]]; then
                echo "Quick slot $slot is empty"
                return 1
            fi

            local destination="${4:-./}"
            inventory_use "$name" "$destination"
            ;;
        list)
            inventory_quick "$slot"
            ;;
        clear)
            # Clear quick slot
            jq "del(.\"$slot\")" "$QUICK_SLOTS_FILE" > "${QUICK_SLOTS_FILE}.tmp" && \
                mv "${QUICK_SLOTS_FILE}.tmp" "$QUICK_SLOTS_FILE"

            # Find and update inventory item
            local name
            name=$(jq -r ".\"$slot\"" "$QUICK_SLOTS_FILE" 2>/dev/null || echo "")

            if [[ -n "$name" ]]; then
                local meta_file="${INVENTORY_META_DIR}/${name}.json"
                if [[ -f "$meta_file" ]]; then
                    jq '.quick_slot = "" | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
                       "$meta_file" > "${meta_file}.tmp" && mv "${meta_file}.tmp" "$meta_file"
                fi
            fi

            echo "✓ Cleared quick slot $slot"
            ;;
        *)
            echo "Unknown command: $command"
            return 1
            ;;
    esac
}

# Set inventory item hotkey
inventory_hotkey() {
    local name="${1}"
    local hotkey="${2}"

    if [[ -z "$name" ]]; then
        echo "Usage: inventory_hotkey <name> <hotkey>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local meta_file="${INVENTORY_META_DIR}/${name}.json"

    if [[ ! -f "$meta_file" ]]; then
        echo "Inventory item not found: $name"
        return 1
    fi

    if [[ -z "$hotkey" ]]; then
        echo "Current hotkey: $(jq -r '.hotkey' "$meta_file")"
        echo "Enter new hotkey for inventory item '$name':"
        read -r hotkey
    fi

    jq --arg key "$hotkey" \
       '.hotkey = $key | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$meta_file" > "${meta_file}.tmp" && mv "${meta_file}.tmp" "$meta_file"

    echo "✓ Updated hotkey for inventory item: $name -> $hotkey"
}

# Quick inventory menu (portable access)
inventory_menu() {
    echo "Quick Inventory Menu"
    echo "════════════════════════════════════════════════════════════════"

    echo ""
    echo "Quick Slots (1-9):"
    for slot in {1..9}; do
        local item
        item=$(jq -r ".\"$slot\"" "$QUICK_SLOTS_FILE" 2>/dev/null || echo "null")
        if [[ "$item" != "null" ]]; then
            echo "  $slot) $item"
        else
            echo "  $slot) (empty)"
        fi
    done

    echo ""
    echo "Options:"
    echo "  s <slot> <name>  - Set quick slot"
    echo "  u <slot> [dest]  - Use quick slot"
    echo "  l <slot>         - List quick slot"
    echo "  c <slot>         - Clear quick slot"
    echo "  a <name> <file>  - Add to inventory"
    echo "  d <name>         - Use inventory item"
    echo "  r <name> <file>  - Remove from inventory"
    echo "  x <name>         - Delete inventory item"
    echo "  q               - Quit"
    echo ""

    while true; do
        echo -n "> "
        read -r input

        if [[ -z "$input" ]]; then
            continue
        fi

        case "$input" in
            q)
                break
                ;;
            s*)
                local slot="${input:2:1}"
                local name="${input:4}"

                if [[ ! "$slot" =~ ^[1-9]$ ]]; then
                    echo "Invalid slot: $slot"
                    continue
                fi

                if [[ -z "$name" ]]; then
                    echo "Usage: s <slot> <name>"
                    continue
                fi

                inventory_quick "$slot" set "$name"
                ;;
            u*)
                local slot="${input:2:1}"
                local dest="${input:4}"

                if [[ ! "$slot" =~ ^[1-9]$ ]]; then
                    echo "Invalid slot: $slot"
                    continue
                fi

                if [[ -z "$dest" ]]; then
                    dest="."
                fi

                inventory_quick "$slot" use "$dest"
                ;;
            l*)
                local slot="${input:2:1}"

                if [[ ! "$slot" =~ ^[1-9]$ ]]; then
                    echo "Invalid slot: $slot"
                    continue
                fi

                inventory_quick "$slot" list
                ;;
            c*)
                local slot="${input:2:1}"

                if [[ ! "$slot" =~ ^[1-9]$ ]]; then
                    echo "Invalid slot: $slot"
                    continue
                fi

                inventory_quick "$slot" clear
                ;;
            a*)
                local name="${input:2}"
                local file="${input#* }"

                if [[ -z "$name" || -z "$file" ]]; then
                    echo "Usage: a <name> <file>"
                    continue
                fi

                inventory_add "$name" "$file"
                ;;
            d*)
                local name="${input:2}"
                local dest="${input#* }"

                if [[ -z "$name" ]]; then
                    echo "Usage: d <name> [destination]"
                    continue
                fi

                if [[ -z "$dest" ]]; then
                    dest="."
                fi

                inventory_use "$name" "$dest"
                ;;
            r*)
                local name="${input:2}"
                local file="${input#* }"

                if [[ -z "$name" || -z "$file" ]]; then
                    echo "Usage: r <name> <file>"
                    continue
                fi

                inventory_remove "$name" "$file"
                ;;
            x*)
                local name="${input:2}"

                if [[ -z "$name" ]]; then
                    echo "Usage: x <name>"
                    continue
                fi

                inventory_delete "$name"
                ;;
            *)
                echo "Unknown command: $input"
                ;;
        esac
    done
}

# Inventory help
inventory_help() {
    cat << 'EOF'
Quick Inventory Commands:

  inventory_add <name> <file>...    - Add files to inventory
  inventory_list [name]             - List inventory items or contents
  inventory_use <name> [dest]        - Use inventory item
  inventory_remove <name> <file>... - Remove files from inventory
  inventory_delete <name>           - Delete inventory item
  inventory_quick <slot> [cmd]       - Manage quick slots (1-9)
  inventory_hotkey <name> <key>     - Set inventory item hotkey
  inventory_menu                    - Interactive inventory menu
  inventory_help                    - Show this help message

Quick Slot Commands:
  inventory_quick <slot> set <name>   - Set quick slot to inventory item
  inventory_quick <slot> use [dest]   - Use quick slot item
  inventory_quick <slot> list         - List quick slot contents
  inventory_quick <slot> clear        - Clear quick slot

Examples:
  inventory_add project_docs rules.md agents.md
  inventory_list project_docs
  inventory_use project_docs ~/projects/new_project/
  inventory_quick 1 set project_docs
  inventory_quick 1 use
  inventory_menu
EOF
}

# Export functions
export -f inventory_add 2>/dev/null
export -f inventory_list 2>/dev/null
export -f inventory_use 2>/dev/null
export -f inventory_remove 2>/dev/null
export -f inventory_delete 2>/dev/null
export -f inventory_quick 2>/dev/null
export -f inventory_hotkey 2>/dev/null
export -f inventory_menu 2>/dev/null
export -f inventory_help 2>/dev/null
