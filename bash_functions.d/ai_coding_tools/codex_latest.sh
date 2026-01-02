#!/usr/bin/env bash
# Convenience helpers for OpenAI Codex CLI installation and execution.
# GitHub: https://github.com/openai/codex
# Docs: https://developers.openai.com/codex/cli/
#
# Provided commands:
# - codex_install_latest: installs the latest Codex CLI globally via npm.
# - codex_install_homebrew: installs via homebrew (fallback)
# - codex_install_source: installs from source (fallback)
# - codex_latest: runs the latest Codex CLI using npx without a global install.

_cx_echo() { printf '[codex-cli] %s\n' "$*"; }
_cx_err() { printf '[codex-cli][error] %s\n' "$*" >&2; }
_cx_have() { command -v "$1" >/dev/null 2>&1; }

_cx_ensure_path() {
  local path_dir="$1"
  case ":$PATH:" in *":$path_dir:"*) ;; *) export PATH="$path_dir:$PATH";; esac
}

_cx_ensure_npm_prefix() {
  if ! _cx_have npm; then
    _cx_err "npm is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  
  local current
  current="$(npm config get prefix 2>/dev/null | tr -d '\r' || true)"
  if [[ -z "$current" || "$current" == "null" ]]; then current="/usr/local"; fi
  
  if [[ "$current" == "/usr"* ]] || [[ ! -w "$current" ]]; then
    mkdir -p "$HOME/.npm-global/bin"
    npm config set prefix "$HOME/.npm-global" >/dev/null 2>&1 || true
    _cx_ensure_path "$HOME/.npm-global/bin"
    _cx_echo "Adjusted npm prefix to $HOME/.npm-global"
  fi
}

# Primary installation method: npm
codex_install_latest() {
  _cx_ensure_npm_prefix
  _cx_echo "Installing @openai/codex@latest globally via npm ..."
  if npm -g install @openai/codex@latest; then
    _cx_echo "Codex CLI installed. Try: codex --help"
    return 0
  else
    _cx_err "Failed to install @openai/codex via npm"
    return 1
  fi
}

# Fallback 1: Homebrew
codex_install_homebrew() {
  if ! _cx_have brew; then
    _cx_err "Homebrew is not installed. Install it first: https://brew.sh/"
    return 1
  fi
  
  _cx_echo "Installing codex via Homebrew ..."
  if brew install codex; then
    _cx_echo "Codex CLI installed via Homebrew. Try: codex --help"
    return 0
  else
    _cx_err "Failed to install codex via Homebrew"
    return 1
  fi
}

# Fallback 2: Install from source
codex_install_source() {
  if ! _cx_have git || ! _cx_have npm; then
    _cx_err "git and npm are required for source installation"
    return 1
  fi
  
  local temp_dir="$HOME/.codex_build"
  _cx_echo "Installing Codex CLI from source ..."
  
  if git clone https://github.com/openai/codex.git "$temp_dir"; then
    cd "$temp_dir" || return 1
    if npm install && npm run build && npm install -g .; then
      _cx_echo "Codex CLI installed from source. Try: codex --help"
      rm -rf "$temp_dir"
      return 0
    else
      _cx_err "Failed to build/install Codex CLI from source"
      cd - >/dev/null
      rm -rf "$temp_dir"
      return 1
    fi
  else
    _cx_err "Failed to clone Codex CLI repository"
    return 1
  fi
}

# Fallback 3: Open-codex (community fork)
codex_install_open_codex() {
  _cx_echo "Installing open-codex (community fork) via npm ..."
  if npm -g install open-codex; then
    _cx_echo "Open-codex installed. Try: open-codex --help"
    return 0
  else
    _cx_err "Failed to install open-codex via npm"
    return 1
  fi
}

# Universal installer with fallbacks
codex_install() {
  _cx_echo "Starting Codex CLI installation with fallbacks..."
  
  # Try npm first
  if codex_install_latest; then
    return 0
  fi
  
  # Try homebrew
  if codex_install_homebrew; then
    return 0
  fi
  
  # Try source installation
  if codex_install_source; then
    return 0
  fi
  
  # Try open-codex fork
  if codex_install_open_codex; then
    return 0
  fi
  
  _cx_err "All installation methods failed. Please install manually."
  return 1
}

# npx @openai/codex@latest (no installation required)
codex_latest() {
  if ! _cx_have npx; then
    _cx_err "npx is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  # -y to auto-consent to install when needed
  npx -y @openai/codex@latest "$@"
}

# Note: Helper functions are intentionally kept available for use