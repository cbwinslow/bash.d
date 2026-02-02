#!/bin/bash
#===============================================================================
#
#          FILE:  ai_agent_system.sh
#
#         USAGE:  ai_agent_init
#                 ai_agent_configure
#                 ai_agent_automate <task>
#                 ai_agent_decide <question>
#                 ai_agent_optimize <system>
#                 ai_agent_monitor [start|stop|status]
#                 ai_agent_profile [create|switch|list] <profile>
#                 ai_agent_help
#
#   DESCRIPTION:  Comprehensive AI agent system with deep integration
#                 into all bash.d components, providing automation,
#                 decision making, and intelligent assistance
#
#       OPTIONS:  task - Task to automate
#                 question - Question for AI decision
#                 system - System to optimize
#                 profile - AI agent profile
#  REQUIREMENTS:  python3, jq, curl, OPENROUTER_API_KEY
#         NOTES:  Heavy AI influence on all bash.d operations
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Configuration
AI_CONFIG_DIR="${HOME}/.config/bashd/ai"
AI_PROFILES_DIR="${AI_CONFIG_DIR}/profiles"
AI_STATE_DIR="${HOME}/.cache/bashd/ai"
mkdir -p "$AI_CONFIG_DIR" "$AI_PROFILES_DIR" "$AI_STATE_DIR"

# AI Agent Configuration
AI_CONFIG_FILE="${AI_CONFIG_DIR}/config.json"
AI_CURRENT_PROFILE_FILE="${AI_CONFIG_DIR}/current_profile"

# Initialize AI agent system
ai_agent_init() {
    echo "Initializing AI Agent System..."

    # Create main configuration
    cat > "$AI_CONFIG_FILE" << 'EOF'
{
    "default_model": "openrouter/auto",
    "profiles": {
        "default": {
            "model": "openrouter/auto",
            "temperature": 0.7,
            "max_tokens": 2048,
            "system_prompt": "You are a highly intelligent bash automation assistant with deep knowledge of all bash.d systems."
        }
    },
    "integration": {
        "documentation": true,
        "connection": true,
        "yadm": true,
        "bundle": true,
        "inventory": true,
        "keybinding": true,
        "automation": true
    },
    "automation_level": "moderate",
    "learning_enabled": true,
    "memory_limit": 100
}
EOF

    # Set default profile
    echo "default" > "$AI_CURRENT_PROFILE_FILE"

    # Create AI state directory
    mkdir -p "$AI_STATE_DIR"

    echo "✓ AI Agent System initialized"
    echo "Configuration: $AI_CONFIG_FILE"
    echo "Current Profile: $(cat "$AI_CURRENT_PROFILE_FILE")"
}

# Configure AI agent settings
ai_agent_configure() {
    local key="${1}"
    local value="${2}"

    if [[ -z "$key" ]]; then
        echo "Usage: ai_agent_configure <key> <value>"
        echo ""
        echo "Available keys:"
        echo "  default_model <model>"
        echo "  automation_level <low|moderate|high>"
        echo "  learning_enabled <true|false>"
        echo "  memory_limit <number>"
        return 1
    fi

    # Update configuration
    jq --arg key "$key" --arg value "$value" \
       ".\"$key\" = \$value" \
       "$AI_CONFIG_FILE" > "${AI_CONFIG_FILE}.tmp" && \
        mv "${AI_CONFIG_FILE}.tmp" "$AI_CONFIG_FILE"

    echo "✓ Configured: $key = $value"
}

# AI-driven automation for tasks
ai_agent_automate() {
    local task="${1}"

    if [[ -z "$task" ]]; then
        echo "Usage: ai_agent_automate <task>"
        echo ""
        echo "Example tasks:"
        echo "  'Create a markdown documentation bundle for my new project'"
        echo "  'Set up SSH monitoring and GitHub connection'"
        echo "  'Generate a Python project scaffold with AI assistance'"
        echo "  'Create keybindings for my most used functions'"
        return 1
    fi

    echo "AI Agent automating task: $task"

    # Get current profile
    local profile
    profile=$(cat "$AI_CURRENT_PROFILE_FILE" 2>/dev/null || echo "default")

    # Get AI response
    local response
    response=$(bashd_ai_code "Automate this task using bash.d systems: $task. Provide bash commands to execute.")

    # Execute the AI-generated commands
    echo "AI Response:"
    echo "─────────────────────────────────────────────────────────────────"
    echo "$response"
    echo "─────────────────────────────────────────────────────────────────"

    echo "Execute these commands? (y/n)"
    read -r confirmation

    if [[ "$confirmation" =~ ^[Yy] ]]; then
        echo "Executing AI-generated commands..."
        eval "$response"
        echo "✓ Task automated successfully"
    else
        echo "Cancelled AI automation"
    fi
}

# AI-driven decision making
ai_agent_decide() {
    local question="${1}"

    if [[ -z "$question" ]]; then
        echo "Usage: ai_agent_decide <question>"
        echo ""
        echo "Example questions:"
        echo "  'Which bundle should I use for this Python project?'"
        echo "  'What keybindings would be most efficient for my workflow?'"
        echo "  'How should I organize my dotfiles with YADM?'"
        return 1
    fi

    echo "AI Agent analyzing: $question"

    # Get AI decision
    local response
    response=$(bashd_ai_debug "Analyze this question and provide a detailed recommendation: $question")

    echo "AI Recommendation:"
    echo "─────────────────────────────────────────────────────────────────"
    echo "$response"
    echo "─────────────────────────────────────────────────────────────────"

    # Log the decision
    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') - $question" >> "$AI_STATE_DIR/decision_log.txt"
    echo "$response" >> "$AI_STATE_DIR/decision_log.txt"
    echo "" >> "$AI_STATE_DIR/decision_log.txt"

    echo "✓ Decision logged to: $AI_STATE_DIR/decision_log.txt"
}

# AI-driven system optimization
ai_agent_optimize() {
    local system="${1}"

    if [[ -z "$system" ]]; then
        echo "Usage: ai_agent_optimize <system>"
        echo ""
        echo "Systems to optimize:"
        echo "  documentation - Optimize documentation system"
        echo "  connection - Optimize connection management"
        echo "  yadm - Optimize YADM configuration"
        echo "  bundle - Optimize bundle management"
        echo "  inventory - Optimize inventory system"
        echo "  keybinding - Optimize keybinding setup"
        echo "  automation - Optimize automation workflows"
        echo "  all - Optimize all systems"
        return 1
    fi

    echo "AI Agent optimizing: $system"

    # Get AI optimization recommendations
    local response
    response=$(bashd_ai_code "Provide optimization recommendations for the bash.d $system system. Include specific configuration changes and improvements.")

    echo "AI Optimization Recommendations:"
    echo "─────────────────────────────────────────────────────────────────"
    echo "$response"
    echo "─────────────────────────────────────────────────────────────────"

    echo "Apply these optimizations? (y/n)"
    read -r confirmation

    if [[ "$confirmation" =~ ^[Yy] ]]; then
        echo "Applying AI-generated optimizations..."
        eval "$response"
        echo "✓ System optimized successfully"
    else
        echo "Cancelled AI optimization"
    fi
}

# AI agent monitoring system
ai_agent_monitor() {
    local action="${1:-status}"

    case "$action" in
        start)
            _ai_agent_monitor_start
            ;;
        stop)
            _ai_agent_monitor_stop
            ;;
        status)
            _ai_agent_monitor_status
            ;;
        *)
            echo "Usage: ai_agent_monitor [start|stop|status]"
            return 1
            ;;
    esac
}

# Start AI monitoring
_ai_agent_monitor_start() {
    local pid_file="${AI_STATE_DIR}/monitor.pid"

    if [[ -f "$pid_file" && -d "/proc/$(cat "$pid_file")" ]]; then
        echo "AI monitor is already running (PID: $(cat "$pid_file"))"
        return 0
    fi

    echo "Starting AI agent monitor..."
    echo "Monitor started at $(date)" >> "$AI_STATE_DIR/monitor.log"

    # Start background process
    (
        while true; do
            _ai_agent_monitor_check
            sleep 300  # Check every 5 minutes
        done
    ) > /dev/null 2>&1 &

    echo $! > "$pid_file"
    echo "AI monitor started (PID: $!)"

    # Add to cleanup
    trap "_ai_agent_monitor_stop" EXIT
}

# Stop AI monitoring
_ai_agent_monitor_stop() {
    local pid_file="${AI_STATE_DIR}/monitor.pid"

    if [[ -f "$pid_file" && -d "/proc/$(cat "$pid_file")" ]]; then
        echo "Stopping AI monitor (PID: $(cat "$pid_file"))"
        kill "$(cat "$pid_file")" 2>/dev/null
        rm -f "$pid_file"
        echo "AI monitor stopped"
    else
        echo "AI monitor is not running"
    fi
}

# Check AI monitor status
_ai_agent_monitor_status() {
    local pid_file="${AI_STATE_DIR}/monitor.pid"

    if [[ -f "$pid_file" && -d "/proc/$(cat "$pid_file")" ]]; then
        echo "AI monitor is running (PID: $(cat "$pid_file"))"
        echo "Log: $AI_STATE_DIR/monitor.log"
        tail -5 "$AI_STATE_DIR/monitor.log" 2>/dev/null || echo "No log entries yet"
    else
        echo "AI monitor is not running"
    fi
}

# AI monitoring check function
_ai_agent_monitor_check() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Check AI health
    if ! bashd_ai_healthcheck >/dev/null 2>&1; then
        echo "[$timestamp] AI health check failed" >> "$AI_STATE_DIR/monitor.log"
        return 1
    fi

    # Analyze recent commands for optimization opportunities
    local recent_commands
    recent_commands=$(history | tail -20 | grep -v "ai_agent")

    if [[ -n "$recent_commands" ]]; then
        local analysis
        analysis=$(bashd_ai_debug "Analyze these recent commands for optimization opportunities:\n\n$recent_commands")

        echo "[$timestamp] Optimization analysis completed" >> "$AI_STATE_DIR/monitor.log"
        echo "$analysis" >> "$AI_STATE_DIR/optimization.log"
    fi

    # Check system integration
    if system_status >/dev/null 2>&1; then
        echo "[$timestamp] System integration check passed" >> "$AI_STATE_DIR/monitor.log"
    else
        echo "[$timestamp] System integration check failed" >> "$AI_STATE_DIR/monitor.log"
    fi
}

# AI agent profile management
ai_agent_profile() {
    local action="${1}"
    local profile="${2}"

    case "$action" in
        create)
            _ai_agent_profile_create "$profile"
            ;;
        switch)
            _ai_agent_profile_switch "$profile"
            ;;
        list)
            _ai_agent_profile_list
            ;;
        *)
            echo "Usage: ai_agent_profile [create|switch|list] <profile>"
            return 1
            ;;
    esac
}

# Create AI agent profile
_ai_agent_profile_create() {
    local profile="${1}"

    if [[ -z "$profile" ]]; then
        echo "Usage: ai_agent_profile create <profile>"
        return 1
    fi

    local profile_file="${AI_PROFILES_DIR}/${profile}.json"

    if [[ -f "$profile_file" ]]; then
        echo "Profile already exists: $profile"
        return 1
    fi

    echo "Creating AI profile: $profile"

    # Get AI to help create the profile
    local response
    response=$(bashd_ai_code "Create a JSON configuration for an AI agent profile named '$profile' that would be optimal for bash automation tasks. Include model, temperature, max_tokens, and system_prompt fields.")

    echo "$response" > "$profile_file"

    # Add to main config
    jq --arg profile "$profile" \
       '.profiles[$profile] = {} | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$AI_CONFIG_FILE" > "${AI_CONFIG_FILE}.tmp" && \
        mv "${AI_CONFIG_FILE}.tmp" "$AI_CONFIG_FILE"

    echo "✓ Created AI profile: $profile"
    echo "Profile file: $profile_file"
}

# Switch AI agent profile
_ai_agent_profile_switch() {
    local profile="${1}"

    if [[ -z "$profile" ]]; then
        echo "Usage: ai_agent_profile switch <profile>"
        return 1
    fi

    local profile_file="${AI_PROFILES_DIR}/${profile}.json"

    if [[ ! -f "$profile_file" ]]; then
        echo "Profile not found: $profile"
        return 1
    fi

    # Update current profile
    echo "$profile" > "$AI_CURRENT_PROFILE_FILE"

    # Update main config
    jq --arg profile "$profile" \
       '.current_profile = $profile | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$AI_CONFIG_FILE" > "${AI_CONFIG_FILE}.tmp" && \
        mv "${AI_CONFIG_FILE}.tmp" "$AI_CONFIG_FILE"

    echo "✓ Switched to AI profile: $profile"
}

# List AI agent profiles
_ai_agent_profile_list() {
    echo "Available AI Profiles:"
    echo "════════════════════════════════════════════════════════════════"

    local current_profile
    current_profile=$(cat "$AI_CURRENT_PROFILE_FILE" 2>/dev/null || echo "")

    for profile_file in "$AI_PROFILES_DIR"/*.json; do
        if [[ -f "$profile_file" ]]; then
            local profile
            profile=$(basename "$profile_file" .json)

            if [[ "$profile" == "$current_profile" ]]; then
                echo "  $profile (active)"
            else
                echo "  $profile"
            fi
        fi
    done

    echo ""
    echo "Current profile: $current_profile"
}

# AI-enhanced documentation workflow
ai_agent_doc() {
    local command="${1}"

    if [[ -z "$command" ]]; then
        echo "Usage: ai_agent_doc <command>"
        return 1
    fi

    echo "AI-enhanced documentation for: $command"

    # Get AI-enhanced documentation
    local response
    response=$(bashd_ai_tldr "Provide comprehensive documentation for the '$command' command including examples, best practices, and common pitfalls.")

    echo "AI Documentation:"
    echo "════════════════════════════════════════════════════════════════"
    echo "$response"
    echo "════════════════════════════════════════════════════════════════"

    # Cache the AI-enhanced documentation
    doc_cache "$command"

    echo "✓ AI-enhanced documentation cached"
}

# AI-enhanced connection management
ai_agent_connect() {
    local service="${1:-github}"

    echo "AI-enhanced connection management for: $service"

    # Get AI connection recommendations
    local response
    response=$(bashd_ai_debug "Provide connection troubleshooting and optimization recommendations for $service service. Include specific commands to test and improve the connection.")

    echo "AI Connection Recommendations:"
    echo "════════════════════════════════════════════════════════════════"
    echo "$response"
    echo "════════════════════════════════════════════════════════════════"

    echo "Apply these recommendations? (y/n)"
    read -r confirmation

    if [[ "$confirmation" =~ ^[Yy] ]]; then
        echo "Applying AI connection recommendations..."
        eval "$response"
        echo "✓ Connection optimized"
    else
        echo "Cancelled AI connection recommendations"
    fi
}

# AI-enhanced bundle management
ai_agent_bundle() {
    local task="${1}"

    if [[ -z "$task" ]]; then
        echo "Usage: ai_agent_bundle <task>"
        echo ""
        echo "Example tasks:"
        echo "  'Create the optimal bundle structure for a Python web project'"
        echo "  'Suggest bundle organization for my development workflow'"
        echo "  'Generate bundle hotkey assignments'"
        return 1
    fi

    echo "AI-enhanced bundle management: $task"

    # Get AI bundle recommendations
    local response
    response=$(bashd_ai_code "Provide recommendations for this bundle management task: $task. Include specific bundle_create, bundle_add, and bundle_hotkey commands.")

    echo "AI Bundle Recommendations:"
    echo "════════════════════════════════════════════════════════════════"
    echo "$response"
    echo "════════════════════════════════════════════════════════════════"

    echo "Execute these bundle commands? (y/n)"
    read -r confirmation

    if [[ "$confirmation" =~ ^[Yy] ]]; then
        echo "Executing AI bundle recommendations..."
        eval "$response"
        echo "✓ Bundle management completed"
    else
        echo "Cancelled AI bundle recommendations"
    fi
}

# AI-enhanced inventory management
ai_agent_inventory() {
    local task="${1}"

    if [[ -z "$task" ]]; then
        echo "Usage: ai_agent_inventory <task>"
        echo ""
        echo "Example tasks:"
        echo "  'Organize my inventory for maximum efficiency'"
        echo "  'Suggest quick slot assignments for my workflow'"
        echo "  'Create inventory items for my current project'"
        return 1
    fi

    echo "AI-enhanced inventory management: $task"

    # Get AI inventory recommendations
    local response
    response=$(bashd_ai_code "Provide recommendations for this inventory management task: $task. Include specific inventory_add, inventory_quick, and inventory_hotkey commands.")

    echo "AI Inventory Recommendations:"
    echo "════════════════════════════════════════════════════════════════"
    echo "$response"
    echo "════════════════════════════════════════════════════════════════"

    echo "Execute these inventory commands? (y/n)"
    read -r confirmation

    if [[ "$confirmation" =~ ^[Yy] ]]; then
        echo "Executing AI inventory recommendations..."
        eval "$response"
        echo "✓ Inventory management completed"
    else
        echo "Cancelled AI inventory recommendations"
    fi
}

# AI-enhanced keybinding management
ai_agent_keybind() {
    local task="${1}"

    if [[ -z "$task" ]]; then
        echo "Usage: ai_agent_keybind <task>"
        echo ""
        echo "Example tasks:"
        echo "  'Create optimal keybindings for my workflow'"
        echo "  'Suggest keybindings for my most used functions'"
        echo "  'Organize keybinding profiles for different projects'"
        return 1
    fi

    echo "AI-enhanced keybinding management: $task"

    # Get AI keybinding recommendations
    local response
    response=$(bashd_ai_code "Provide recommendations for this keybinding task: $task. Include specific keybind_set and keybind_profile commands.")

    echo "AI Keybinding Recommendations:"
    echo "════════════════════════════════════════════════════════════════"
    echo "$response"
    echo "════════════════════════════════════════════════════════════════"

    echo "Execute these keybinding commands? (y/n)"
    read -r confirmation

    if [[ "$confirmation" =~ ^[Yy] ]]; then
        echo "Executing AI keybinding recommendations..."
        eval "$response"
        echo "✓ Keybinding management completed"
    else
        echo "Cancelled AI keybinding recommendations"
    fi
}

# AI-enhanced automation workflows
ai_agent_automate_workflow() {
    local workflow="${1}"

    if [[ -z "$workflow" ]]; then
        echo "Usage: ai_agent_automate_workflow <workflow>"
        echo ""
        echo "Example workflows:"
        echo "  'Create a complete project setup workflow'"
        echo "  'Automate my daily development routine'"
        echo "  'Generate a deployment workflow for my application'"
        return 1
    fi

    echo "AI-enhanced workflow automation: $workflow"

    # Get AI workflow recommendations
    local response
    response=$(bashd_ai_code "Create a comprehensive automation workflow for: $workflow. Include specific commands using bash.d systems (auto_scaffold, bundle_deploy, inventory_use, etc.).")

    echo "AI Workflow Recommendations:"
    echo "════════════════════════════════════════════════════════════════"
    echo "$response"
    echo "════════════════════════════════════════════════════════════════"

    echo "Execute this workflow? (y/n)"
    read -r confirmation

    if [[ "$confirmation" =~ ^[Yy] ]]; then
        echo "Executing AI workflow recommendations..."
        eval "$response"
        echo "✓ Workflow automation completed"
    else
        echo "Cancelled AI workflow recommendations"
    fi
}

# AI agent help
ai_agent_help() {
    cat << 'EOF'
AI Agent System Commands:

  ai_agent_init                    - Initialize AI agent system
  ai_agent_configure <key> <value> - Configure AI agent settings
  ai_agent_automate <task>          - AI-driven task automation
  ai_agent_decide <question>       - AI-driven decision making
  ai_agent_optimize <system>       - AI-driven system optimization
  ai_agent_monitor [start|stop|status] - AI monitoring system
  ai_agent_profile [create|switch|list] <profile>
  ai_agent_doc <command>           - AI-enhanced documentation
  ai_agent_connect <service>       - AI-enhanced connection management
  ai_agent_bundle <task>           - AI-enhanced bundle management
  ai_agent_inventory <task>        - AI-enhanced inventory management
  ai_agent_keybind <task>          - AI-enhanced keybinding management
  ai_agent_automate_workflow <workflow> - AI-enhanced workflow automation
  ai_agent_help                    - Show this help message

  # NEW: AI Agent Monitoring & Registration
  ai_agent_register <name> <specialization> - Register new AI agent
  ai_agent_unregister <name>       - Unregister AI agent
  ai_agent_list                   - List all registered agents
  ai_agent_vitals <name>          - Get agent vitals
  ai_agent_feedback <name> <feedback> - Provide feedback to agent
  ai_agent_tui                    - Launch AI agent monitoring TUI

AI Profiles:
  Create, switch, and manage different AI agent profiles for various tasks

AI Integration:
  Deep integration with all bash.d systems for comprehensive automation

Examples:
  ai_agent_init
  ai_agent_register "my_custom_agent" "custom_automation"
  ai_agent_list
  ai_agent_tui
  ai_agent_automate "Create a markdown documentation bundle"
  ai_agent_decide "Which bundle should I use for this project?"
  ai_agent_optimize documentation
  ai_agent_monitor start
  ai_agent_profile create development
  ai_agent_doc git
  ai_agent_connect github
  ai_agent_bundle "Create optimal bundle structure"
  ai_agent_inventory "Organize my inventory"
  ai_agent_keybind "Create optimal keybindings"
  ai_agent_automate_workflow "Daily development routine"
EOF
}

# AI Agent Registration System
ai_agent_register() {
    local name="${1}"
    local specialization="${2}"

    if [[ -z "$name" || -z "$specialization" ]]; then
        echo "Usage: ai_agent_register <name> <specialization>"
        echo ""
        echo "Example specializations:"
        echo "  automation, documentation, decision, monitoring, custom"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    # Check if agent already exists
    if jq -e ".ai_agents | has(\"$name\")" "$AI_CONFIG_FILE" >/dev/null 2>&1; then
        echo "Agent already registered: $name"
        return 1
    fi

    echo "Registering AI agent: $name (specialization: $specialization)"

    # Add agent to configuration
    jq --arg name "$name" \
       --arg specialization "$specialization" \
       '.ai_agents[$name] = {
           "enabled": true,
           "specialization": $specialization,
           "model": "openrouter/auto",
           "vitals": {
               "status": "unknown",
               "last_check": null,
               "response_time": 0,
               "success_rate": 0,
               "memory_usage": 0,
               "cpu_usage": 0,
               "tasks_completed": 0,
               "errors": 0,
               "warnings": 0
           }
       }' "$AI_CONFIG_FILE" > "${AI_CONFIG_FILE}.tmp" && \
        mv "${AI_CONFIG_FILE}.tmp" "$AI_CONFIG_FILE"

    # Create agent-specific monitoring directory
    local agent_dir="${AI_STATE_DIR}/agents/${name}"
    mkdir -p "$agent_dir"

    # Create initial vitals log
    local vitals_log="${agent_dir}/vitals.log"
    echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Agent registered: $name" > "$vitals_log"
    echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Specialization: $specialization" >> "$vitals_log"

    echo "✓ Registered AI agent: $name"
    echo "Specialization: $specialization"
    echo "Vitals log: $vitals_log"
}

# Unregister AI agent
ai_agent_unregister() {
    local name="${1}"

    if [[ -z "$name" ]]; then
        echo "Usage: ai_agent_unregister <name>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    # Check if agent exists
    if ! jq -e ".ai_agents | has(\"$name\")" "$AI_CONFIG_FILE" >/dev/null 2>&1; then
        echo "Agent not found: $name"
        return 1
    fi

    echo "Unregistering AI agent: $name"

    # Remove agent from configuration
    jq "del(.ai_agents[\"$name\"])" "$AI_CONFIG_FILE" > "${AI_CONFIG_FILE}.tmp" && \
        mv "${AI_CONFIG_FILE}.tmp" "$AI_CONFIG_FILE"

    # Remove agent directory
    local agent_dir="${AI_STATE_DIR}/agents/${name}"
    if [[ -d "$agent_dir" ]]; then
        rm -rf "$agent_dir"
        echo "✓ Removed agent directory"
    fi

    echo "✓ Unregistered AI agent: $name"
}

# List all registered AI agents
ai_agent_list() {
    echo "Registered AI Agents:"
    echo "════════════════════════════════════════════════════════════════"

    local agent_count=0
    local enabled_count=0

    # Get agents from config
    if [[ -f "$AI_CONFIG_FILE" ]]; then
        local agents
        agents=$(jq -r '.ai_agents | to_entries[] | "\(.key) \(.value.enabled) \(.value.specialization)"' "$AI_CONFIG_FILE" 2>/dev/null)

        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                local name
                local enabled
                local specialization
                read -r name enabled specialization <<< "$line"

                echo ""
                echo "Agent: $name"
                echo "  Status: $(if [[ "$enabled" == "true" ]]; then echo "✓ Enabled"; else echo "✗ Disabled"; fi)"
                echo "  Specialization: $specialization"

                if [[ "$enabled" == "true" ]]; then
                    ((enabled_count++))
                fi
                ((agent_count++))
            fi
        done <<< "$agents"
    fi

    echo ""
    echo "Total Agents: $agent_count"
    echo "Enabled Agents: $enabled_count"
}

# Get AI agent vitals
ai_agent_vitals() {
    local name="${1}"

    if [[ -z "$name" ]]; then
        echo "Usage: ai_agent_vitals <name>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    # Check if agent exists
    if ! jq -e ".ai_agents | has(\"$name\")" "$AI_CONFIG_FILE" >/dev/null 2>&1; then
        echo "Agent not found: $name"
        return 1
    fi

    echo "AI Agent Vitals: $name"
    echo "════════════════════════════════════════════════════════════════"

    # Get vitals from config
    local vitals
    vitals=$(jq -r ".ai_agents[\"$name\"].vitals" "$AI_CONFIG_FILE" 2>/dev/null)

    if [[ -n "$vitals" ]]; then
        echo "$vitals" | jq '.'
    else
        echo "No vitals data available for $name"
    fi

    # Show recent vitals log
    local agent_dir="${AI_STATE_DIR}/agents/${name}"
    local vitals_log="${agent_dir}/vitals.log"

    if [[ -f "$vitals_log" ]]; then
        echo ""
        echo "Recent Vitals Log:"
        echo "─────────────────────────────────────────────────────────────────"
        tail -10 "$vitals_log"
    fi
}

# Provide feedback to AI agent
ai_agent_feedback() {
    local name="${1}"
    local feedback="${2}"

    if [[ -z "$name" ]]; then
        echo "Usage: ai_agent_feedback <name> <feedback>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    # Check if agent exists
    if ! jq -e ".ai_agents | has(\"$name\")" "$AI_CONFIG_FILE" >/dev/null 2>&1; then
        echo "Agent not found: $name"
        return 1
    fi

    if [[ -z "$feedback" ]]; then
        echo "Please provide feedback for agent: $name"
        return 1
    fi

    echo "Providing feedback to agent: $name"

    # Create agent directory if it doesn't exist
    local agent_dir="${AI_STATE_DIR}/agents/${name}"
    mkdir -p "$agent_dir"

    # Log feedback
    local feedback_log="${agent_dir}/feedback.log"
    echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] FEEDBACK: $feedback" >> "$feedback_log"

    # Also log to main feedback log
    echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $name: $feedback" >> "$AI_STATE_DIR/agent_feedback.log"

    # Provide AI-driven optimization feedback
    local response
    response=$(bashd_ai_debug "Analyze this feedback for AI agent $name and provide optimization recommendations: $feedback")

    echo "AI Optimization Recommendations:"
    echo "─────────────────────────────────────────────────────────────────"
    echo "$response"
    echo "─────────────────────────────────────────────────────────────────"

    echo "✓ Feedback provided to agent: $name"
    echo "Feedback log: $feedback_log"
}

# Launch AI agent monitoring TUI
ai_agent_tui() {
    local python_cmd="python3"
    local tui_script="${HOME}/bash.d/ai/ai_agent_monitor_tui.py"

    # Check if Python is available
    if ! command -v "$python_cmd" >/dev/null 2>&1; then
        echo "Error: Python3 is required to run the AI agent monitoring TUI"
        return 1
    fi

    # Check if TUI script exists
    if [[ ! -f "$tui_script" ]]; then
        echo "Error: AI agent monitoring TUI script not found: $tui_script"
        return 1
    fi

    echo "Launching AI Agent Monitoring TUI..."
    echo "Controls: ↑/↓ to select agent, Q to quit, F for feedback, R to refresh, O to optimize"

    # Launch the TUI
    "$python_cmd" "$tui_script"

    echo "AI Agent Monitoring TUI closed"
}

# Export functions
export -f ai_agent_init 2>/dev/null
export -f ai_agent_configure 2>/dev/null
export -f ai_agent_automate 2>/dev/null
export -f ai_agent_decide 2>/dev/null
export -f ai_agent_optimize 2>/dev/null
export -f ai_agent_monitor 2>/dev/null
export -f _ai_agent_monitor_start 2>/dev/null
export -f _ai_agent_monitor_stop 2>/dev/null
export -f _ai_agent_monitor_status 2>/dev/null
export -f _ai_agent_monitor_check 2>/dev/null
export -f ai_agent_profile 2>/dev/null
export -f _ai_agent_profile_create 2>/dev/null
export -f _ai_agent_profile_switch 2>/dev/null
export -f _ai_agent_profile_list 2>/dev/null
export -f ai_agent_doc 2>/dev/null
export -f ai_agent_connect 2>/dev/null
export -f ai_agent_bundle 2>/dev/null
export -f ai_agent_inventory 2>/dev/null
export -f ai_agent_keybind 2>/dev/null
export -f ai_agent_automate_workflow 2>/dev/null
export -f ai_agent_help 2>/dev/null
export -f ai_agent_register 2>/dev/null
export -f ai_agent_unregister 2>/dev/null
export -f ai_agent_list 2>/dev/null
export -f ai_agent_vitals 2>/dev/null
export -f ai_agent_feedback 2>/dev/null
export -f ai_agent_tui 2>/dev/null
