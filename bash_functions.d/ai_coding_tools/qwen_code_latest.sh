#!/usr/bin/env bash
# Convenience helpers for installing and running Qwen Code from the official repo.
# GitHub: https://github.com/QwenLM/qwen-code
# Docs: https://qwenlm.github.io/qwen-code-docs/en/
#
# Provided commands:
# - qwen_code_install_latest: installs/updates the latest Qwen Code via npm.
# - qwen_code_install_homebrew: installs via homebrew (fallback)
# - qwen_code_install_source: installs from source (fallback)
# - qwen_code_install_pipx: installs via pipx (fallback)
# - qwen_code_update: forces a reinstall/update.
# - qwen_code: wrapper that runs the available Qwen Code CLI.

_qc_echo() { printf '[qwen-code] %s\n' "$*"; }
_qc_err() { printf '[qwen-code][error] %s\n' "$*" >&2; }
_qc_have() { command -v "$1" >/dev/null 2>&1; }

_qc_ensure_path() {
  local path_dir="$1"
  case ":$PATH:" in *":$path_dir:"*) ;; *) export PATH="$path_dir:$PATH";; esac
}

_qc_ensure_npm_prefix() {
  if ! _qc_have npm; then
    _qc_err "npm is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  
  local current
  current="$(npm config get prefix 2>/dev/null | tr -d '\r' || true)"
  if [[ -z "$current" || "$current" == "null" ]]; then current="/usr/local"; fi
  
  if [[ "$current" == "/usr"* ]] || [[ ! -w "$current" ]]; then
    mkdir -p "$HOME/.npm-global/bin"
    npm config set prefix "$HOME/.npm-global" >/dev/null 2>&1 || true
    _qc_ensure_path "$HOME/.npm-global/bin"
    _qc_echo "Adjusted npm prefix to $HOME/.npm-global"
  fi
}

_qc_ensure_pipx() {
  if _qc_have pipx; then return 0; fi
  if _qc_have python3 && python3 -m pip --version >/dev/null 2>&1; then
    python3 -m pip install --user -q pipx || true
    _qc_ensure_path "$HOME/.local/bin"
    if _qc_have pipx; then return 0; fi
  fi
  return 1
}

_qc_find_cmd() {
  # Return first matching command name
  for c in qwen-code qwen qwencode; do
    if _qc_have "$c"; then echo "$c"; return 0; fi
  done
  return 1
}

# Primary installation method: npm
qwen_code_install_latest() {
  _qc_ensure_npm_prefix
  _qc_echo "Installing @qwen-code/qwen-code@latest globally via npm ..."
  if npm -g install @qwen-code/qwen-code@latest; then
    local cmd
    cmd="$(_qc_find_cmd)" || true
    if [ -n "$cmd" ]; then
      _qc_echo "Installed. Try: $cmd --help"
      return 0
    else
      _qc_err "Installed but CLI not found on PATH. Ensure ~/.npm-global/bin is in PATH."
      return 1
    fi
  else
    _qc_err "Failed to install @qwen-code/qwen-code via npm"
    return 1
  fi
}

# Fallback 1: Homebrew
qwen_code_install_homebrew() {
  if ! _qc_have brew; then
    _qc_err "Homebrew is not installed. Install it first: https://brew.sh/"
    return 1
  fi
  
  _qc_echo "Installing qwen-code via Homebrew ..."
  if brew install qwen-code; then
    _qc_echo "Qwen Code installed via Homebrew. Try: qwen --help"
    return 0
  else
    _qc_err "Failed to install qwen-code via Homebrew"
    return 1
  fi
}

# Fallback 2: Install from source
qwen_code_install_source() {
  if ! _qc_have git || ! _qc_have npm; then
    _qc_err "git and npm are required for source installation"
    return 1
  fi
  
  local temp_dir="$HOME/.qwen_code_build"
  _qc_echo "Installing Qwen Code from source ..."
  
  if git clone https://github.com/QwenLM/qwen-code.git "$temp_dir"; then
    cd "$temp_dir" || return 1
    if npm install && npm install -g .; then
      _qc_echo "Qwen Code installed from source. Try: qwen --help"
      rm -rf "$temp_dir"
      return 0
    else
      _qc_err "Failed to build/install Qwen Code from source"
      cd - >/dev/null
      rm -rf "$temp_dir"
      return 1
    fi
  else
    _qc_err "Failed to clone Qwen Code repository"
    return 1
  fi
}

# Fallback 3: pipx installation
qwen_code_install_pipx() {
  if ! _qc_ensure_pipx; then
    _qc_err "pipx (and Python 3 with pip) is required. Install Python 3 first."
    return 1
  fi
  
  _qc_echo "Installing Qwen Code from GitHub via pipx ..."
  if pipx install --force "git+https://github.com/QwenLM/qwen-code.git"; then
    local cmd
    cmd="$(_qc_find_cmd)" || true
    if [ -n "$cmd" ]; then
      _qc_echo "Installed via pipx. Try: $cmd --help"
      return 0
    else
      _qc_err "Installed but CLI not found on PATH. Ensure ~/.local/bin is in PATH."
      return 1
    fi
  else
    _qc_err "Failed to install qwen-code via pipx"
    return 1
  fi
}

# Universal installer with fallbacks
qwen_code_install() {
  _qc_echo "Starting Qwen Code installation with fallbacks..."
  
  # Try npm first (recommended)
  if qwen_code_install_latest; then
    return 0
  fi
  
  # Try homebrew
  if qwen_code_install_homebrew; then
    return 0
  fi
  
  # Try source installation
  if qwen_code_install_source; then
    return 0
  fi
  
  # Try pipx
  if qwen_code_install_pipx; then
    return 0
  fi
  
  _qc_err "All installation methods failed. Please install manually."
  return 1
}

qwen_code_update() {
  qwen_code_install "$@"
}

qwen_code() {
  local cmd
  cmd="$(_qc_find_cmd)" || true
  if [ -z "$cmd" ]; then
    _qc_err "Qwen Code is not installed. Run: qwen_code_install"
    return 1
  fi
  "$cmd" "$@"
}

# npx @qwen-code/qwen-code@latest (no installation required)
qwen_code_latest() {
  if ! _qc_have npx; then
    _qc_err "npx is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  # -y to auto-consent to install when needed
  npx -y @qwen-code/qwen-code@latest "$@"
}

# Note: Helper functions are intentionally kept available for use