#!/usr/bin/env bash
# Master installer for all AI coding tools
# This script provides a unified interface to install all supported AI coding tools
#
# Usage: ai_tools_install [tool_name]
#   tool_name: optional, install specific tool only
#   If no tool_name provided, shows menu of available tools

_ai_echo() { printf '[ai-tools] %s\n' "$*"; }
_ai_err() { printf '[ai-tools][error] %s\n' "$*" >&2; }
_ai_have() { command -v "$1" >/dev/null 2>&1; }

# Source all individual tool installers
_ai_source_installers() {
  local script_dir="$(dirname "${BASH_SOURCE[0]}")"
  
  # Source each installer script
  for installer in "$script_dir"/*.sh; do
    if [[ -f "$installer" && "$installer" != *"$(basename "${BASH_SOURCE[0]}")"* ]]; then
      source "$installer"
    fi
  done
}

# Show available tools menu
_ai_show_menu() {
  _ai_echo "Available AI Coding Tools:"
  echo
  echo "1. Forgecode    - AI pair programmer for Claude, GPT, and more"
  echo "2. Qwen Code    - Coding agent from Alibaba's Qwen team"
  echo "3. Roo Code     - Whole dev team of AI agents"
  echo "4. Gemini CLI   - Google's Gemini coding assistant"
  echo "5. Codex CLI    - OpenAI's Codex coding assistant"
  echo "6. Kilo Code    - Open source AI coding assistant"
  echo "7. Cline        - Autonomous coding agent"
  echo "8. All Tools    - Install all available tools"
  echo "9. Exit"
  echo
  echo -n "Select option [1-9]: "
}

# Install specific tool
_ai_install_tool() {
  local tool="$1"
  local tool_name=""
  local install_func=""
  
  case "$tool" in
    1|forgecode|forge)
      tool_name="Forgecode"
      install_func="forgecode_install"
      ;;
    2|qwen|qwen-code)
      tool_name="Qwen Code"
      install_func="qwen_code_install"
      ;;
    3|roo|roo-code)
      tool_name="Roo Code"
      install_func="roo_code_install"
      ;;
    4|gemini|gemini-cli)
      tool_name="Gemini CLI"
      install_func="gemini_cli_install"
      ;;
    5|codex|codex-cli)
      tool_name="Codex CLI"
      install_func="codex_install"
      ;;
    6|kilo|kilo-code)
      tool_name="Kilo Code"
      install_func="kilo_code_install"
      ;;
    7|cline)
      tool_name="Cline"
      install_func="cline_install"
      ;;
    8|all)
      _ai_install_all
      return $?
      ;;
    *)
      _ai_err "Unknown tool: $tool"
      return 1
      ;;
  esac
  
  # Check if tool is already installed
  local command_name=""
  case $tool in
    1|forgecode) command_name="forgecode" ;;
    2|qwen-code) command_name="qwen" ;;
    3|roo-code) command_name="roocode" ;;
    4|gemini-cli) command_name="gemini" ;;
    5|codex-cli) command_name="codex" ;;
    6|kilo-code) command_name="kilocode" ;;
    7|cline) command_name="cline" ;;
  esac
  
  if [[ -n "$command_name" ]] && _ai_have "$command_name"; then
    _ai_echo "✓ $tool_name is already installed"
    return 0
  fi
  
  _ai_echo "Installing $tool_name..."
  if $install_func; then
    _ai_echo "$tool_name installed successfully!"
    return 0
  else
    _ai_err "Failed to install $tool_name"
    return 1
  fi
}

# Install all tools
_ai_install_all() {
  _ai_echo "Installing all AI coding tools..."
  
  local tools=(
    "forgecode:forgecode_install:forgecode"
    "qwen_code:qwen_code_install:qwen"
    "roo_code:roo_code_install:roocode"
    "gemini_cli:gemini_cli_install:gemini"
    "codex:codex_install:codex"
    "kilo_code:kilo_code_install:kilocode"
    "cline:cline_install:cline"
  )
  
  local failed_tools=()
  local skipped_tools=()
  
  for tool_config in "${tools[@]}"; do
    local tool_name="${tool_config%:*:*}"
    local rest="${tool_config#*:}"
    local install_func="${rest%:*}"
    local command="${rest#*:}"
    
    # Check if tool is already installed
    if _ai_have "$command"; then
      _ai_echo "✓ $tool_name is already installed, skipping..."
      skipped_tools+=("$tool_name")
      continue
    fi
    
    _ai_echo "Installing $tool_name..."
    if ! $install_func; then
      failed_tools+=("$tool_name")
    else
      _ai_echo "✓ $tool_name installed successfully"
    fi
  done
  
  if [[ ${#failed_tools[@]} -gt 0 ]]; then
    _ai_err "Failed to install: ${failed_tools[*]}"
    return 1
  fi
  
  if [[ ${#skipped_tools[@]} -gt 0 ]]; then
    _ai_echo "Already installed (skipped): ${skipped_tools[*]}"
  fi
  
  _ai_echo "All tools installation complete!"
  return 0
}

# Check which tools are already installed
_ai_check_installed() {
  _ai_echo "Checking installed AI coding tools..."
  echo
  
  local tools=(
    "forgecode:forgecode"
    "qwen_code:qwen"
    "roo_code:roocode"
    "gemini_cli:gemini"
    "codex:codex"
    "kilo_code:kilocode"
    "cline:cline"
  )
  
  for tool_config in "${tools[@]}"; do
    local tool_name="${tool_config%:*}"
    local command="${tool_config#*:}"
    
    if _ai_have "$command"; then
      echo "✓ $tool_name is installed"
    else
      echo "✗ $tool_name is not installed"
    fi
  done
}

# Main function
ai_tools_install() {
  local tool="$1"
  
  # Source all installers
  _ai_source_installers
  
  # If tool specified, install it directly
  if [[ -n "$tool" ]]; then
    if [[ "$tool" == "check" ]]; then
      _ai_check_installed
      return 0
    elif [[ "$tool" == "help" ]] || [[ "$tool" == "--help" ]] || [[ "$tool" == "-h" ]]; then
      _ai_echo "Usage: ai_tools_install [tool_name|check|help]"
      echo
      echo "Commands:"
      echo "  forgecode     Install Forgecode"
      echo "  qwen-code     Install Qwen Code"
      echo "  roo-code      Install Roo Code"
      echo "  gemini-cli    Install Gemini CLI"
      echo "  codex-cli     Install Codex CLI"
      echo "  kilo-code     Install Kilo Code"
      echo "  cline         Install Cline"
      echo "  all           Install all tools"
      echo "  check         Check which tools are installed"
      echo "  help          Show this help"
      return 0
    else
      _ai_install_tool "$tool"
      return $?
    fi
  fi
  
  # Show interactive menu
  while true; do
    _ai_show_menu
    read -r choice
    echo
    
    case "$choice" in
      1) _ai_install_tool "forgecode" ;;
      2) _ai_install_tool "qwen-code" ;;
      3) _ai_install_tool "roo-code" ;;
      4) _ai_install_tool "gemini-cli" ;;
      5) _ai_install_tool "codex-cli" ;;
      6) _ai_install_tool "kilo-code" ;;
      7) _ai_install_tool "cline" ;;
      8) _ai_install_tool "all" ;;
      9) break ;;
      *) _ai_err "Invalid option. Please select 1-9." ;;
    esac
    
    echo
    echo -n "Press Enter to continue..."
    read -r
    clear
  done
}

# Note: Helper functions are intentionally kept available for use