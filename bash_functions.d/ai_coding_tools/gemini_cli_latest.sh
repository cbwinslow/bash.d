#!/usr/bin/env bash
# Convenience helpers for Google Gemini CLI installation and execution.
# GitHub: https://github.com/google-gemini/gemini-cli
# Docs: https://codelabs.developers.google.com/gemini-cli-hands-on
#
# Provided commands:
# - gemini_cli_install_latest: installs the latest Gemini CLI globally via npm.
# - gemini_cli_install_homebrew: installs via homebrew (fallback)
# - gemini_cli_install_source: installs from source (fallback)
# - gemini_cli_latest: runs the latest Gemini CLI using npx without a global install.

_gc_echo() { printf '[gemini-cli] %s\n' "$*"; }
_gc_err() { printf '[gemini-cli][error] %s\n' "$*" >&2; }
_gc_have() { command -v "$1" >/dev/null 2>&1; }

_gc_ensure_path() {
  local path_dir="$1"
  case ":$PATH:" in *":$path_dir:"*) ;; *) export PATH="$path_dir:$PATH";; esac
}

_gc_ensure_npm_prefix() {
  if ! _gc_have npm; then
    _gc_err "npm is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  
  local current
  current="$(npm config get prefix 2>/dev/null | tr -d '\r' || true)"
  if [[ -z "$current" || "$current" == "null" ]]; then current="/usr/local"; fi
  
  if [[ "$current" == "/usr"* ]] || [[ ! -w "$current" ]]; then
    mkdir -p "$HOME/.npm-global/bin"
    npm config set prefix "$HOME/.npm-global" >/dev/null 2>&1 || true
    _gc_ensure_path "$HOME/.npm-global/bin"
    _gc_echo "Adjusted npm prefix to $HOME/.npm-global"
  fi
}

# Primary installation method: npm
gemini_cli_install_latest() {
  _gc_ensure_npm_prefix
  _gc_echo "Installing @google/gemini-cli@latest globally via npm ..."
  if npm -g install @google/gemini-cli@latest; then
    _gc_echo "Gemini CLI installed. Try: gemini --help"
    return 0
  else
    _gc_err "Failed to install @google/gemini-cli via npm"
    return 1
  fi
}

# Fallback 1: Homebrew
gemini_cli_install_homebrew() {
  if ! _gc_have brew; then
    _gc_err "Homebrew is not installed. Install it first: https://brew.sh/"
    return 1
  fi
  
  _gc_echo "Installing gemini-cli via Homebrew ..."
  if brew install gemini-cli; then
    _gc_echo "Gemini CLI installed via Homebrew. Try: gemini --help"
    return 0
  else
    _gc_err "Failed to install gemini-cli via Homebrew"
    return 1
  fi
}

# Fallback 2: Install from source
gemini_cli_install_source() {
  if ! _gc_have git || ! _gc_have npm; then
    _gc_err "git and npm are required for source installation"
    return 1
  fi
  
  local temp_dir="$HOME/.gemini_cli_build"
  _gc_echo "Installing Gemini CLI from source ..."
  
  if git clone https://github.com/google-gemini/gemini-cli.git "$temp_dir"; then
    cd "$temp_dir" || return 1
    if npm install && npm run build && npm install -g .; then
      _gc_echo "Gemini CLI installed from source. Try: gemini --help"
      rm -rf "$temp_dir"
      return 0
    else
      _gc_err "Failed to build/install Gemini CLI from source"
      cd - >/dev/null
      rm -rf "$temp_dir"
      return 1
    fi
  else
    _gc_err "Failed to clone Gemini CLI repository"
    return 1
  fi
}

# Universal installer with fallbacks
gemini_cli_install() {
  _gc_echo "Starting Gemini CLI installation with fallbacks..."
  
  # Try npm first
  if gemini_cli_install_latest; then
    return 0
  fi
  
  # Try homebrew
  if gemini_cli_install_homebrew; then
    return 0
  fi
  
  # Try source installation
  if gemini_cli_install_source; then
    return 0
  fi
  
  _gc_err "All installation methods failed. Please install manually."
  return 1
}

# npx @google/gemini-cli@latest (no installation required)
gemini_cli_latest() {
  if ! _gc_have npx; then
    _gc_err "npx is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  # -y to auto-consent to install when needed
  npx -y @google/gemini-cli@latest "$@"
}

# Note: Helper functions are intentionally kept available for use