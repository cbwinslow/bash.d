#!/bin/bash
# Themes and Appearance Collector Script
# Collects information about themes, fonts, and visual configurations
# Outputs JSON format

set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

command_exists() {
    command -v "$1" &> /dev/null
}

collect_fonts() {
    local fonts=()
    
    if command_exists fc-list; then
        while IFS= read -r font; do
            fonts+=("\"$font\"")
        done < <(fc-list : family | sort -u | head -50)
    fi
    
    echo "[$(IFS=,; echo "${fonts[*]}")]"
}

collect_gtk_theme() {
    if command_exists gsettings; then
        local gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
        local icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
        local cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'")
        
        echo "{
            \"gtk_theme\": \"$gtk_theme\",
            \"icon_theme\": \"$icon_theme\",
            \"cursor_theme\": \"$cursor_theme\"
        }"
    else
        echo "{}"
    fi
}

collect_terminal_info() {
    local terminal_emulator="${TERM:-unknown}"
    local colorterm="${COLORTERM:-unknown}"
    
    echo "{
        \"term\": \"$terminal_emulator\",
        \"colorterm\": \"$colorterm\",
        \"shell\": \"$SHELL\"
    }"
}

main() {
    log_info "Collecting themes and appearance information..."
    
    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$(hostname)",
    "fonts": $(collect_fonts),
    "gtk": $(collect_gtk_theme),
    "terminal": $(collect_terminal_info)
}
EOF
    
    log_info "Themes collection complete!"
}

main "$@"
