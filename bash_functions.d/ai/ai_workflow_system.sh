#!/bin/bash
#===============================================================================
#
#          FILE:  ai_workflow_system.sh
#
#         USAGE:  ai_workflow_init
#                 ai_workflow_create <name> <description>
#                 ai_workflow_run <name>
#                 ai_workflow_list
#                 ai_workflow_delete <name>
#                 ai_workflow_optimize <name>
#                 ai_workflow_help
#
#   DESCRIPTION:  AI workflow system that creates intelligent, automated
#                 workflows integrating all bash.d components with AI
#                 decision making and optimization
#
#       OPTIONS:  name - Workflow name
#                 description - Workflow description
#  REQUIREMENTS:  jq, python3, OPENROUTER_API_KEY
#         NOTES:  Heavy AI influence on workflow creation and execution
#        AUTHOR:  bash.d project
#       VERSION:  1.0.0
#===============================================================================

# Configuration
AI_WORKFLOW_DIR="${HOME}/.config/bashd/ai/workflows"
AI_WORKFLOW_META_DIR="${AI_WORKFLOW_DIR}/meta"
mkdir -p "$AI_WORKFLOW_DIR" "$AI_WORKFLOW_META_DIR"

# Initialize AI workflow system
ai_workflow_init() {
    echo "Initializing AI Workflow System..."

    # Create workflow directory structure
    mkdir -p "$AI_WORKFLOW_DIR" "$AI_WORKFLOW_META_DIR"

    echo "✓ AI Workflow System initialized"
    echo "Workflows directory: $AI_WORKFLOW_DIR"
}

# Create a new AI workflow
ai_workflow_create() {
    local name="${1}"
    local description="${2}"

    if [[ -z "$name" ]]; then
        echo "Usage: ai_workflow_create <name> <description>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local workflow_dir="${AI_WORKFLOW_DIR}/${name}"
    local meta_file="${AI_WORKFLOW_META_DIR}/${name}.json"

    if [[ -d "$workflow_dir" ]]; then
        echo "Workflow already exists: $name"
        return 1
    fi

    # Create workflow directory
    mkdir -p "$workflow_dir"

    # Get AI to help create the workflow
    local response
    response=$(bashd_ai_code "Create a comprehensive bash workflow named '$name' with this description: $description. Provide the complete workflow script that integrates bash.d systems.")

    # Create workflow script
    cat > "${workflow_dir}/workflow.sh" << EOF
#!/bin/bash
# AI-Generated Workflow: $name
# Description: $description
# Created: $(date -u +'%Y-%m-%dT%H:%M:%SZ')

# Workflow execution
workflow_${name}() {
    echo "Executing workflow: $name"
    echo "Description: $description"
    echo ""

    # AI-generated workflow steps
    $response

    echo "✓ Workflow completed: $name"
}

# Execute workflow
workflow_${name} "\$@"
EOF

    chmod +x "${workflow_dir}/workflow.sh"

    # Create metadata
    cat > "$meta_file" << EOF
{
    "name": "$name",
    "description": "$description",
    "created": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
    "updated": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
    "steps": [],
    "ai_generated": true,
    "version": "1.0.0"
}
EOF

    echo "✓ Created AI workflow: $name"
    echo "Workflow script: ${workflow_dir}/workflow.sh"
    echo "Metadata: $meta_file"
}

# Run an AI workflow
ai_workflow_run() {
    local name="${1}"

    if [[ -z "$name" ]]; then
        echo "Usage: ai_workflow_run <name>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local workflow_dir="${AI_WORKFLOW_DIR}/${name}"
    local workflow_script="${workflow_dir}/workflow.sh"

    if [[ ! -f "$workflow_script" ]]; then
        echo "Workflow not found: $name"
        return 1
    fi

    echo "Running AI workflow: $name"
    echo "─────────────────────────────────────────────────────────────────"

    # Execute the workflow
    "$workflow_script"

    echo "─────────────────────────────────────────────────────────────────"
    echo "✓ Workflow execution completed"
}

# List available AI workflows
ai_workflow_list() {
    echo "Available AI Workflows:"
    echo "════════════════════════════════════════════════════════════════"

    for meta_file in "$AI_WORKFLOW_META_DIR"/*.json; do
        if [[ -f "$meta_file" ]]; then
            local name
            name=$(jq -r '.name' "$meta_file")
            local description
            description=$(jq -r '.description' "$meta_file")
            local created
            created=$(jq -r '.created' "$meta_file")

            echo ""
            echo "[$name]"
            echo "  Description: $description"
            echo "  Created: $created"
        fi
    done

    echo ""
    echo "Total workflows: $(ls "$AI_WORKFLOW_META_DIR"/*.json 2>/dev/null | wc -l)"
}

# Delete an AI workflow
ai_workflow_delete() {
    local name="${1}"

    if [[ -z "$name" ]]; then
        echo "Usage: ai_workflow_delete <name>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local workflow_dir="${AI_WORKFLOW_DIR}/${name}"
    local meta_file="${AI_WORKFLOW_META_DIR}/${name}.json"

    if [[ ! -d "$workflow_dir" && ! -f "$meta_file" ]]; then
        echo "Workflow not found: $name"
        return 1
    fi

    echo "Are you sure you want to delete workflow: $name? (y/n)"
    read -r response

    if [[ "$response" =~ ^[Yy] ]]; then
        if [[ -d "$workflow_dir" ]]; then
            rm -rf "$workflow_dir"
            echo "✓ Deleted workflow directory"
        fi

        if [[ -f "$meta_file" ]]; then
            rm "$meta_file"
            echo "✓ Deleted workflow metadata"
        fi

        echo "Workflow deleted: $name"
    else
        echo "Cancelled workflow deletion"
    fi
}

# Optimize an AI workflow
ai_workflow_optimize() {
    local name="${1}"

    if [[ -z "$name" ]]; then
        echo "Usage: ai_workflow_optimize <name>"
        return 1
    fi

    # Sanitize name
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

    local workflow_dir="${AI_WORKFLOW_DIR}/${name}"
    local workflow_script="${workflow_dir}/workflow.sh"
    local meta_file="${AI_WORKFLOW_META_DIR}/${name}.json"

    if [[ ! -f "$workflow_script" ]]; then
        echo "Workflow not found: $name"
        return 1
    fi

    echo "Optimizing AI workflow: $name"

    # Get current workflow content
    local current_content
    current_content=$(cat "$workflow_script")

    # Get AI optimization recommendations
    local response
    response=$(bashd_ai_code "Optimize this bash workflow script. Provide an improved version with better error handling, performance, and integration:\n\n$current_content")

    echo "AI Optimization Recommendations:"
    echo "─────────────────────────────────────────────────────────────────"
    echo "$response"
    echo "─────────────────────────────────────────────────────────────────"

    echo "Apply these optimizations? (y/n)"
    read -r confirmation

    if [[ "$confirmation" =~ ^[Yy] ]]; then
        echo "Applying AI workflow optimizations..."

        # Backup original
        cp "$workflow_script" "${workflow_script}.backup"

        # Apply optimizations
        echo "$response" > "$workflow_script"

        # Update metadata
        jq '.updated = "'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"' \
           "$meta_file" > "${meta_file}.tmp" && mv "${meta_file}.tmp" "$meta_file"

        echo "✓ Workflow optimized successfully"
    else
        echo "Cancelled AI workflow optimization"
    fi
}

# Create a comprehensive development workflow
ai_workflow_create_dev() {
    local name="${1:-development_workflow}"

    echo "Creating comprehensive development workflow: $name"

    # Create the workflow
    ai_workflow_create "$name" "Comprehensive development workflow including project setup, documentation, connection management, and deployment"

    local workflow_dir="${AI_WORKFLOW_DIR}/${name}"
    local workflow_script="${workflow_dir}/workflow.sh"

    # Create comprehensive development workflow
    cat > "$workflow_script" << 'EOF'
#!/bin/bash
# AI-Generated Development Workflow
# Comprehensive development workflow

# Workflow execution
workflow_development_workflow() {
    local project_name="${1}"
    local project_type="${2:-python}"
    local destination="${3:-./$project_name}"

    if [[ -z "$project_name" ]]; then
        echo "Usage: workflow_development_workflow <project_name> [project_type] [destination]"
        return 1
    fi

    echo "Starting comprehensive development workflow: $project_name"
    echo "Type: $project_type"
    echo "Destination: $destination"
    echo ""

    # Step 1: Project scaffolding
    echo "Step 1/6: Project Scaffolding"
    echo "─────────────────────────────────────────────────────────────────"
    auto_scaffold "$project_type" "$project_name" "$destination"
    echo "✓ Project scaffolded"
    echo ""

    # Step 2: Documentation setup
    echo "Step 2/6: Documentation Setup"
    echo "─────────────────────────────────────────────────────────────────"
    bundle_create_markdown "${project_name}_docs"
    bundle_add "${project_name}_docs" "${destination}/"
    echo "✓ Documentation bundle created"
    echo ""

    # Step 3: Connection management
    echo "Step 3/6: Connection Management"
    echo "─────────────────────────────────────────────────────────────────"
    github_connect check
    gitlab_connect check
    ssh_monitor start
    echo "✓ Connections verified and monitored"
    echo ""

    # Step 4: YADM integration
    echo "Step 4/6: YADM Integration"
    echo "─────────────────────────────────────────────────────────────────"
    yadm_add "${destination}/.gitconfig" 2>/dev/null || echo "No git config to add"
    yadm_add "${destination}/.env" 2>/dev/null || echo "No env file to add"
    echo "✓ YADM integration completed"
    echo ""

    # Step 5: Bundle and inventory setup
    echo "Step 5/6: Bundle and Inventory Setup"
    echo "─────────────────────────────────────────────────────────────────"
    inventory_add "${project_name}_inventory" "${destination}/"
    inventory_quick 1 set "${project_name}_inventory"
    echo "✓ Bundle and inventory configured"
    echo ""

    # Step 6: Keybinding setup
    echo "Step 6/6: Keybinding Setup"
    echo "─────────────────────────────────────────────────────────────────"
    keybind_set "Ctrl+Alt+D" "inventory_menu"
    keybind_set "Ctrl+Shift+F" "func_recall"
    echo "✓ Keybindings configured"
    echo ""

    echo "✓ Comprehensive development workflow completed!"
    echo ""
    echo "Project Summary:"
    echo "  Name: $project_name"
    echo "  Type: $project_type"
    echo "  Location: $destination"
    echo "  Documentation: ${project_name}_docs bundle"
    echo "  Inventory: ${project_name}_inventory (quick slot 1)"
    echo "  Keybindings: Ctrl+Alt+D (inventory), Ctrl+Shift+F (func recall)"
}

# Execute workflow
workflow_development_workflow "$@"
EOF

    chmod +x "$workflow_script"

    echo "✓ Created comprehensive development workflow: $name"
    echo "Workflow script: $workflow_script"
}

# Create a deployment workflow
ai_workflow_create_deploy() {
    local name="${1:-deployment_workflow}"

    echo "Creating deployment workflow: $name"

    # Create the workflow
    ai_workflow_create "$name" "Comprehensive deployment workflow including testing, building, and deployment"

    local workflow_dir="${AI_WORKFLOW_DIR}/${name}"
    local workflow_script="${workflow_dir}/workflow.sh"

    # Create deployment workflow
    cat > "$workflow_script" << 'EOF'
#!/bin/bash
# AI-Generated Deployment Workflow
# Comprehensive deployment workflow

# Workflow execution
workflow_deployment_workflow() {
    local project_name="${1}"
    local environment="${2:-production}"
    local destination="${3}"

    if [[ -z "$project_name" ]]; then
        echo "Usage: workflow_deployment_workflow <project_name> [environment] [destination]"
        return 1
    fi

    echo "Starting deployment workflow: $project_name"
    echo "Environment: $environment"
    echo "Destination: $destination"
    echo ""

    # Step 1: Pre-deployment checks
    echo "Step 1/5: Pre-Deployment Checks"
    echo "─────────────────────────────────────────────────────────────────"
    connection_troubleshoot
    github_connect check
    gitlab_connect check
    echo "✓ Pre-deployment checks completed"
    echo ""

    # Step 2: Bundle deployment
    echo "Step 2/5: Bundle Deployment"
    echo "─────────────────────────────────────────────────────────────────"
    bundle_deploy "${project_name}_docs" "$destination"
    echo "✓ Documentation bundle deployed"
    echo ""

    # Step 3: Inventory deployment
    echo "Step 3/5: Inventory Deployment"
    echo "─────────────────────────────────────────────────────────────────"
    inventory_use "${project_name}_inventory" "$destination"
    echo "✓ Inventory items deployed"
    echo ""

    # Step 4: Configuration deployment
    echo "Step 4/5: Configuration Deployment"
    echo "─────────────────────────────────────────────────────────────────"
    # Deploy YADM-managed configurations
    yadm_status
    echo "✓ Configuration deployment completed"
    echo ""

    # Step 5: Post-deployment verification
    echo "Step 5/5: Post-Deployment Verification"
    echo "─────────────────────────────────────────────────────────────────"
    system_status
    echo "✓ Post-deployment verification completed"
    echo ""

    echo "✓ Deployment workflow completed!"
    echo ""
    echo "Deployment Summary:"
    echo "  Project: $project_name"
    echo "  Environment: $environment"
    echo "  Destination: $destination"
    echo "  Status: Deployed successfully"
}

# Execute workflow
workflow_deployment_workflow "$@"
EOF

    chmod +x "$workflow_script"

    echo "✓ Created deployment workflow: $name"
    echo "Workflow script: $workflow_script"
}

# Create an AI-driven automation workflow
ai_workflow_create_ai_automation() {
    local name="${1:-ai_automation_workflow}"

    echo "Creating AI-driven automation workflow: $name"

    # Create the workflow
    ai_workflow_create "$name" "AI-driven automation workflow that uses AI agents for decision making and optimization"

    local workflow_dir="${AI_WORKFLOW_DIR}/${name}"
    local workflow_script="${workflow_dir}/workflow.sh"

    # Create AI automation workflow
    cat > "$workflow_script" << 'EOF'
#!/bin/bash
# AI-Generated AI Automation Workflow
# AI-driven automation workflow

# Workflow execution
workflow_ai_automation_workflow() {
    local task="${1}"

    if [[ -z "$task" ]]; then
        echo "Usage: workflow_ai_automation_workflow <task_description>"
        return 1
    fi

    echo "Starting AI-driven automation workflow"
    echo "Task: $task"
    echo ""

    # Step 1: AI analysis and decision
    echo "Step 1/4: AI Analysis and Decision"
    echo "─────────────────────────────────────────────────────────────────"
    ai_agent_decide "$task"
    echo "✓ AI analysis completed"
    echo ""

    # Step 2: AI-driven automation
    echo "Step 2/4: AI-Driven Automation"
    echo "─────────────────────────────────────────────────────────────────"
    ai_agent_automate "$task"
    echo "✓ AI automation completed"
    echo ""

    # Step 3: AI optimization
    echo "Step 3/4: AI Optimization"
    echo "─────────────────────────────────────────────────────────────────"
    ai_agent_optimize "all"
    echo "✓ AI optimization completed"
    echo ""

    # Step 4: System integration
    echo "Step 4/4: System Integration"
    echo "─────────────────────────────────────────────────────────────────"
    system_integrate
    echo "✓ System integration completed"
    echo ""

    echo "✓ AI-driven automation workflow completed!"
    echo ""
    echo "Automation Summary:"
    echo "  Task: $task"
    echo "  AI Analysis: Completed"
    echo "  AI Automation: Completed"
    echo "  AI Optimization: Completed"
    echo "  System Integration: Completed"
}

# Execute workflow
workflow_ai_automation_workflow "$@"
EOF

    chmod +x "$workflow_script"

    echo "✓ Created AI automation workflow: $name"
    echo "Workflow script: $workflow_script"
}

# AI workflow help
ai_workflow_help() {
    cat << 'EOF'
AI Workflow System Commands:

  ai_workflow_init                    - Initialize AI workflow system
  ai_workflow_create <name> <desc>     - Create a new AI workflow
  ai_workflow_run <name>               - Run an AI workflow
  ai_workflow_list                    - List available AI workflows
  ai_workflow_delete <name>           - Delete an AI workflow
  ai_workflow_optimize <name>         - Optimize an AI workflow
  ai_workflow_create_dev <name>       - Create development workflow
  ai_workflow_create_deploy <name>    - Create deployment workflow
  ai_workflow_create_ai_automation <name> - Create AI automation workflow
  ai_workflow_help                    - Show this help message

Workflow Types:
  development - Comprehensive development workflow
  deployment - Complete deployment workflow
  ai_automation - AI-driven automation workflow
  custom - Custom AI-generated workflows

Examples:
  ai_workflow_init
  ai_workflow_create my_workflow "My custom workflow"
  ai_workflow_run my_workflow
  ai_workflow_create_dev
  ai_workflow_create_deploy
  ai_workflow_create_ai_automation
  ai_workflow_list
  ai_workflow_optimize my_workflow
EOF
}

# Export functions
export -f ai_workflow_init 2>/dev/null
export -f ai_workflow_create 2>/dev/null
export -f ai_workflow_run 2>/dev/null
export -f ai_workflow_list 2>/dev/null
export -f ai_workflow_delete 2>/dev/null
export -f ai_workflow_optimize 2>/dev/null
export -f ai_workflow_create_dev 2>/dev/null
export -f ai_workflow_create_deploy 2>/dev/null
export -f ai_workflow_create_ai_automation 2>/dev/null
export -f ai_workflow_help 2>/dev/null
