#!/bin/bash
# Unified Menu Launcher - Text-based menu for bash.d

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

BASHD_DIR="$HOME/bash.d"

# Menu items: "Display Name|Command|Description"
SYSTEM_ITEMS=(
    "Analyze System|bash $BASHD_DIR/scripts/system_analyzer.sh|Analyze processes & memory"
    "System Monitor|bash $BASHD_DIR/scripts/monitor.sh|Continuous monitoring with alerts"
    "AI System Agent|bash $BASHD_DIR/scripts/ai_sys_agent.sh analyze|AI-powered analysis"
)

INVENTORY_ITEMS=(
    "System Inventory|bash $BASHD_DIR/scripts/inventory.sh|List all packages & configs"
    "Full Backup|bash $BASHD_DIR/scripts/backup.sh full|Full system backup"
    "Quick Backup|bash $BASHD_DIR/scripts/backup.sh quick|Quick backup"
)

AI_ITEMS=(
    "AI Agent|bash $BASHD_DIR/scripts/ai_agent.sh|General AI assistant"
    "AI Chat|bash $BASHD_DIR/scripts/ai_agent.sh chat|Start AI chat"
    "AI Code|bash $BASHD_DIR/scripts/ai_agent.sh code|AI code helper"
)

API_ITEMS=(
    "GitHub API|bash $BASHD_DIR/apis/api_manager.sh github|GitHub API tools"
    "Cloudflare API|bash $BASHD_DIR/apis/api_manager.sh cloudflare|Cloudflare tools"
)

TELEMETRY_ITEMS=(
    "View Telemetry DB|docker exec -it telemetry-postgres psql -U cbwinslow -d telemetry|PostgreSQL telemetry"
    "Start Collector|cd $BASHD_DIR/telemetry && source .venv/bin/activate && python3 -m telemetry.collector|Start metrics collector"
)

show_menu() {
    local title="$1"
    shift
    local items=("$@")
    
    echo -e "${CYAN}━━━ $title ━━━${NC}"
    
    local i=1
    for item in "${items[@]}"; do
        IFS='|' read -r name cmd desc <<< "$item"
        echo -e "  ${GREEN}$i)${NC} ${BOLD}$name${NC} - $desc"
        ((i++))
    done
    
    echo ""
}

run_choice() {
    local items=("$@")
    local choice
    
    echo -ne "${YELLOW}Choose option: ${NC}"
    read choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#items[@]} ]; then
        local idx=$((choice - 1))
        IFS='|' read -r name cmd desc <<< "${items[$idx]}"
        
        echo -e "\n${MAGENTA}Running: $cmd${NC}\n"
        eval "$cmd"
    else
        echo -e "${RED}Invalid choice${NC}"
    fi
}

main_menu() {
    while true; do
        clear
        echo -e "${BLUE}"
        echo "╔═══════════════════════════════════════════════════╗"
        echo "║           🎯 bash.d Launcher                     ║"
        echo "╚═══════════════════════════════════════════════════╝"
        echo -e "${NC}"
        
        echo -e "${YELLOW}Select a category:${NC}\n"
        echo -e "  ${GREEN}1)${NC} System Tools"
        echo -e "  ${GREEN}2)${NC} Inventory & Backup"
        echo -e "  ${GREEN}3)${NC} AI Agents"
        echo -e "  ${GREEN}4)${NC} API & Cloud"
        echo -e "  ${GREEN}5)${NC} Telemetry"
        echo -e "  ${GREEN}6)${NC} Run sys-analyze"
        echo -e "  ${GREEN}7)${NC} Quick Commands"
        echo -e "  ${GREEN}q)${NC} Quit"
        echo ""
        
        echo -ne "${CYAN}Choice: ${NC}"
        read choice
        
        case $choice in
            1)
                show_menu "System Tools" "${SYSTEM_ITEMS[@]}"
                run_choice "${SYSTEM_ITEMS[@]}"
                ;;
            2)
                show_menu "Inventory & Backup" "${INVENTORY_ITEMS[@]}"
                run_choice "${INVENTORY_ITEMS[@]}"
                ;;
            3)
                show_menu "AI Agents" "${AI_ITEMS[@]}"
                run_choice "${AI_ITEMS[@]}"
                ;;
            4)
                show_menu "API & Cloud" "${API_ITEMS[@]}"
                run_choice "${API_ITEMS[@]}"
                ;;
            5)
                show_menu "Telemetry" "${TELEMETRY_ITEMS[@]}"
                run_choice "${TELEMETRY_ITEMS[@]}"
                ;;
            6)
                echo -e "\n${MAGENTA}Running system analyzer...${NC}\n"
                bash "$BASHD_DIR/scripts/system_analyzer.sh"
                ;;
            7)
                echo -e "${CYAN}Quick Commands:${NC}"
                echo "  inventory    - System inventory"
                echo "  backup       - Backup system"
                echo "  ai           - AI agent"
                echo "  sys-analyze  - Analyze system"
                echo "  sysmon       - Monitor system"
                echo "  ai-sys       - AI system agent"
                ;;
            q|Q)
                echo -e "${GREEN}Goodbye!${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                ;;
        esac
        
        echo ""
        echo -ne "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Run main menu
main_menu
