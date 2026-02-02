#!/bin/bash
#===============================================================================
#
#          FILE:  ai_config_manager.sh
#
#         USAGE:  ai_config_init
#                 ai_config_set <key> <value>
#                 ai_config_get <key>
#                 ai_config_integrate <system>
#                 ai_config_profile [create|switch|list] <profile>
#                 ai_config_help
#
#   DESCRIPTION:  AI configuration management system with deep integration
#                 into all bash.d components, providing centralized control
#                 and intelligent configuration
#
#       OPTIONS:  key - Configuration key
#                 value - Configuration value
#                 system - System to integrate
#                 profile - Configuration profile
#  REQUIREMENTS:  jq, python3
#         NOTES:  Heavy AI influence on configuration management
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Configuration
AI_CONFIG_DIR="${HOME}/.config/bashd/ai"
AI_CONFIG_FILE="${AI_CONFIG_DIR}/config.json"
AI_PROFILES_DIR="${AI_CONFIG_DIR}/profiles"
AI_STATE_DIR="${HOME}/.cache/bashd/ai"
mkdir -p "$AI_CONFIG_DIR" "$AI_PROFILES_DIR" "$AI_STATE_DIR"

# Initialize AI configuration system
ai_config_init() {
    echo "Initializing AI Configuration System..."

    # Create comprehensive configuration
    cat > "$AI_CONFIG_FILE" << 'EOF'
{
    "version": "1.0.0",
    "default_model": "openrouter/auto",
    "automation_level": "moderate",
    "learning_enabled": true,
    "memory_limit": 100,
    "integration": {
        "documentation": {
            "enabled": true,
            "priority": ["cheat.sh", "tldr", "man", "func"],
            "cache_enabled": true,
            "cache_limit": 1000
        },
        "connection": {
            "enabled": true,
            "monitor_interval": 60,
            "auto_reconnect": true,
            "services": ["github", "gitlab", "ssh"]
        },
        "yadm": {
            "enabled": true,
            "auto_encrypt": true,
            "encryption_rules": ["*.secret", "*.private", "*.key", "*.pem", ".ssh/*", ".aws/*"],
            "organization_rules": {
                "shell": [".bashrc", ".bash_profile", ".zshrc"],
                "editor": [".vimrc", ".nvim/", ".emacs.d/"],
                "dev": [".gitconfig", ".gitignore_global"],
                "system": [".tmux.conf", ".inputrc"]
            }
        },
        "bundle": {
            "enabled": true,
            "default_types": ["scripts", "keys", "commands", "sql", "markdown", "config"],
            "auto_deploy": false,
            "hotkey_support": true
        },
        "inventory": {
            "enabled": true,
            "quick_slots": 9,
            "hotkey_support": true,
            "auto_organize": false
        },
        "keybinding": {
            "enabled": true,
            "default_profile": "development",
            "profiles": ["development", "production", "testing"],
            "auto_apply": true
        },
        "automation": {
            "enabled": true,
            "template_dir": "~/.config/bashd/automation/templates",
            "scaffold_types": ["bash", "python", "node", "web", "docs", "generic"],
            "auto_document": true
        }
    },
    "profiles": {
        "default": {
            "model": "openrouter/auto",
            "temperature": 0.7,
            "max_tokens": 2048,
            "system_prompt": "You are a highly intelligent bash automation assistant with deep knowledge of all bash.d systems."
        }
    },
    "current_profile": "default",
    "ai_agents": {
        "documentation_agent": {
            "enabled": true,
            "model": "openrouter/auto",
            "specialization": "documentation"
        },
        "automation_agent": {
            "enabled": true,
            "model": "openrouter/auto",
            "specialization": "automation"
        },
        "decision_agent": {
            "enabled": true,
            "model": "openrouter/auto",
            "specialization": "decision_making"
        }
    }
}
EOF

    echo "✓ AI Configuration System initialized"
    echo "Configuration: $AI_CONFIG_FILE"
}

# Set AI configuration value
ai_config_set() {
    local key="${1}"
    local value="${2}"

    if [[ -z "$key" ]]; then
        echo "Usage: ai_config_set <key> <value>"
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

# Get AI configuration value
ai_config_get() {
    local key="${1}"

    if [[ -z "$key" ]]; then
        echo "Usage: ai_config_get <key>"
        return 1
    fi

    local value
    value=$(jq -r ".\"$key\"" "$AI_CONFIG_FILE" 2>/dev/null)

    if [[ "$value" == "null" ]]; then
        echo "Key not found: $key"
        return 1
    fi

    echo "$value"
}

# Integrate AI with specific system
ai_config_integrate() {
    local system="${1}"

    if [[ -z "$system" ]]; then
        echo "Usage: ai_config_integrate <system>"
        echo ""
        echo "Systems to integrate:"
        echo "  documentation - Integrate with documentation system"
        echo "  connection - Integrate with connection management"
        echo "  yadm - Integrate with YADM system"
        echo "  bundle - Integrate with bundle management"
        echo "  inventory - Integrate with inventory system"
        echo "  keybinding - Integrate with keybinding system"
        echo "  automation - Integrate with automation system"
        echo "  all - Integrate with all systems"
        return 1
    fi

    echo "Integrating AI with $system system..."

    # Update integration configuration
    jq --arg system "$system" \
       ".integration.\"$system\".enabled = true" \
       "$AI_CONFIG_FILE" > "${AI_CONFIG_FILE}.tmp" && \
        mv "${AI_CONFIG_FILE}.tmp" "$AI_CONFIG_FILE"

    echo "✓ AI integrated with $system system"
}

# AI configuration profile management
ai_config_profile() {
    local action="${1}"
    local profile="${2}"

    case "$action" in
        create)
            _ai_config_profile_create "$profile"
            ;;
        switch)
            _ai_config_profile_switch "$profile"
            ;;
        list)
            _ai_config_profile_list
            ;;
        *)
            echo "Usage: ai_config_profile [create|switch|list] <profile>"
            return 1
            ;;
    esac
}

# Create AI configuration profile
_ai_config_profile_create() {
    local profile="${1}"

    if [[ -z "$profile" ]]; then
        echo "Usage: ai_config_profile create <profile>"
        return 1
    fi

    local profile_file="${AI_PROFILES_DIR}/${profile}.json"

    if [[ -f "$profile_file" ]]; then
        echo "Profile already exists: $profile"
        return 1
    fi

    echo "Creating AI configuration profile: $profile"

    # Get AI to help create the profile
    local response
    response=$(bashd_ai_code "Create a comprehensive JSON configuration profile for AI system integration named '$profile'. Include settings for all bash.d systems (documentation, connection, yadm, bundle, inventory, keybinding, automation).")

    echo "$response" > "$profile_file"

    # Add to main config
    jq --arg profile "$profile" \
       '.profiles[$profile] = {} | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$AI_CONFIG_FILE" > "${AI_CONFIG_FILE}.tmp" && \
        mv "${AI_CONFIG_FILE}.tmp" "$AI_CONFIG_FILE"

    echo "✓ Created AI configuration profile: $profile"
    echo "Profile file: $profile_file"
}

# Switch AI configuration profile
_ai_config_profile_switch() {
    local profile="${1}"

    if [[ -z "$profile" ]]; then
        echo "Usage: ai_config_profile switch <profile>"
        return 1
    fi

    local profile_file="${AI_PROFILES_DIR}/${profile}.json"

    if [[ ! -f "$profile_file" ]]; then
        echo "Profile not found: $profile"
        return 1
    fi

    # Update current profile
    jq --arg profile "$profile" \
       '.current_profile = $profile | .updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
       "$AI_CONFIG_FILE" > "${AI_CONFIG_FILE}.tmp" && \
        mv "${AI_CONFIG_FILE}.tmp" "$AI_CONFIG_FILE"

    echo "✓ Switched to AI configuration profile: $profile"
}

# List AI configuration profiles
_ai_config_profile_list() {
    echo "Available AI Configuration Profiles:"
    echo "════════════════════════════════════════════════════════════════"

    local current_profile
    current_profile=$(jq -r '.current_profile' "$AI_CONFIG_FILE" 2>/dev/null || echo "")

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

# AI configuration status
ai_config_status() {
    echo "AI Configuration Status:"
    echo "════════════════════════════════════════════════════════════════"

    # Show current configuration
    echo ""
    echo "Current Configuration:"
    jq '.' "$AI_CONFIG_FILE" | head -30

    echo ""
    echo "Integration Status:"
    jq '.integration' "$AI_CONFIG_FILE"

    echo ""
    echo "AI Agents Status:"
    jq '.ai_agents' "$AI_CONFIG_FILE"
}

# AI configuration help
ai_config_help() {
    cat << 'EOF'
AI Configuration Management Commands:

  ai_config_init                    - Initialize AI configuration system
  ai_config_set <key> <value>        - Set AI configuration value
  ai_config_get <key>                - Get AI configuration value
  ai_config_integrate <system>      - Integrate AI with specific system
  ai_config_profile [cmd] <profile> - AI configuration profile management
  ai_config_status                  - Show AI configuration status
  ai_config_help                    - Show this help message

  # NEW: AI Agent Monitoring Integration
  ai_config_add_monitoring         - Add monitoring configuration to agents
  ai_config_setup_logging           - Setup comprehensive logging system
  ai_config_enable_feedback        - Enable feedback system for agents

Configuration Keys:
  default_model <model>             - Set default AI model
  automation_level <level>          - Set automation level (low/moderate/high)
  learning_enabled <bool>           - Enable/disable learning
  memory_limit <number>             - Set memory limit

Integration Systems:
  documentation, connection, yadm, bundle, inventory, keybinding, automation, all

Examples:
  ai_config_init
  ai_config_add_monitoring
  ai_config_setup_logging
  ai_config_set default_model "openrouter/auto"
  ai_config_get automation_level
  ai_config_integrate documentation
  ai_config_profile create development
  ai_config_status
EOF
}

# Add monitoring configuration to AI agents
ai_config_add_monitoring() {
    echo "Adding monitoring configuration to AI agents..."

    # Update configuration to include monitoring for all agents
    jq '.ai_agents |= with_entries(
        .value += {
            "monitoring": {
                "enabled": true,
                "interval": 30,
                "metrics": ["response_time", "success_rate", "memory_usage", "cpu_usage"],
                "alert_thresholds": {
                    "response_time": 2.0,
                    "success_rate": 0.8,
                    "memory_usage": 200,
                    "cpu_usage": 20
                }
            }
        }
    )' "$AI_CONFIG_FILE" > "${AI_CONFIG_FILE}.tmp" && \
        mv "${AI_CONFIG_FILE}.tmp" "$AI_CONFIG_FILE"

    echo "✓ Added monitoring configuration to all AI agents"
}

# Setup comprehensive logging system
ai_config_setup_logging() {
    echo "Setting up comprehensive logging system..."

    # Create logging directories
    local log_dir="${AI_STATE_DIR}/logs"
    mkdir -p "$log_dir/agents"
    mkdir -p "$log_dir/feedback"
    mkdir -p "$log_dir/alerts"
    mkdir -p "$log_dir/performance"

    # Create main log files
    touch "$log_dir/agent_monitor.log"
    touch "$log_dir/agent_feedback.log"
    touch "$log_dir/agent_alerts.log"
    touch "$log_dir/agent_performance.log"

    # Update configuration with logging settings
    jq '.logging = {
        "enabled": true,
        "log_level": "info",
        "log_rotation": "daily",
        "max_log_size": "10MB",
        "log_files": {
            "monitor": "'"${log_dir}/agent_monitor.log"'",
            "feedback": "'"${log_dir}/agent_feedback.log"'",
            "alerts": "'"${log_dir}/agent_alerts.log"'",
            "performance": "'"${log_dir}/agent_performance.log"'"
        }
    }' "$AI_CONFIG_FILE" > "${AI_CONFIG_FILE}.tmp" && \
        mv "${AI_CONFIG_FILE}.tmp" "$AI_CONFIG_FILE"

    echo "✓ Comprehensive logging system setup complete"
    echo "Log directory: $log_dir"
}

# Enable feedback system for agents
ai_config_enable_feedback() {
    echo "Enabling feedback system for AI agents..."

    # Update configuration to enable feedback for all agents
    jq '.ai_agents |= with_entries(
        .value += {
            "feedback": {
                "enabled": true,
                "feedback_log": "'"${AI_STATE_DIR}/logs/feedback/${.key}_feedback.log"'",
                "optimization_suggestions": true,
                "auto_optimize": false
            }
        }
    )' "$AI_CONFIG_FILE" > "${AI_CONFIG_FILE}.tmp" && \
        mv "${AI_CONFIG_FILE}.tmp" "$AI_CONFIG_FILE"

    # Create feedback logs for existing agents
    local agents
    agents=$(jq -r '.ai_agents | keys[]' "$AI_CONFIG_FILE" 2>/dev/null)

    for agent in $agents; do
        local feedback_log="${AI_STATE_DIR}/logs/feedback/${agent}_feedback.log"
        touch "$feedback_log"
        echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] Feedback system enabled for agent: $agent" > "$feedback_log"
    done

    echo "✓ Feedback system enabled for all AI agents"
}

# Export functions
export -f ai_config_init 2>/dev/null
export -f ai_config_set 2>/dev/null
export -f ai_config_get 2>/dev/null
export -f ai_config_integrate 2>/dev/null
export -f ai_config_profile 2>/dev/null
export -f _ai_config_profile_create 2>/dev/null
export -f _ai_config_profile_switch 2>/dev/null
export -f _ai_config_profile_list 2>/dev/null
export -f ai_config_status 2>/dev/null
export -f ai_config_help 2>/dev/null
export -f ai_config_add_monitoring 2>/dev/null
export -f ai_config_setup_logging 2>/dev/null
export -f ai_config_enable_feedback 2>/dev/null
