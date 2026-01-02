#!/usr/bin/env bash
# Convenience helpers for Forgecode installation and execution.
# GitHub: https://github.com/antinomyhq/forge
# Docs: https://forgecode.dev/docs/installation/
#
# Provided commands:
# - forgecode_install_latest: installs the latest Forgecode globally via npm.
# - forgecode_install_homebrew: installs via homebrew (fallback)
# - forgecode_install_source: installs from source (fallback)
# - forgecode_latest: runs the latest Forgecode using npx without a global install.

_fc_echo() { printf '[forgecode] %s\n' "$*"; }
_fc_err() { printf '[forgecode][error] %s\n' "$*" >&2; }
_fc_have() { command -v "$1" >/dev/null 2>&1; }

_fc_ensure_path() {
  local path_dir="$1"
  case ":$PATH:" in *":$path_dir:"*) ;; *) export PATH="$path_dir:$PATH";; esac
}

_fc_ensure_npm_prefix() {
  if ! _fc_have npm; then
    _fc_err "npm is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  
  local current
  current="$(npm config get prefix 2>/dev/null | tr -d '\r' || true)"
  if [[ -z "$current" || "$current" == "null" ]]; then current="/usr/local"; fi
  
  if [[ "$current" == "/usr"* ]] || [[ ! -w "$current" ]]; then
    mkdir -p "$HOME/.npm-global/bin"
    npm config set prefix "$HOME/.npm-global" >/dev/null 2>&1 || true
    _fc_ensure_path "$HOME/.npm-global/bin"
    _fc_echo "Adjusted npm prefix to $HOME/.npm-global"
  fi
}

# Primary installation method: npm
forgecode_install_latest() {
  _fc_ensure_npm_prefix
  _fc_echo "Installing forgecode@latest globally via npm ..."
  if npm -g install forgecode@latest; then
    _fc_echo "Forgecode installed. Try: forgecode --help"
    return 0
  else
    _fc_err "Failed to install forgecode@latest via npm"
    _fc_err "Trying fallback installation methods..."
    return 1
  fi
}

# Fallback 1: Homebrew
forgecode_install_homebrew() {
  if ! _fc_have brew; then
    _fc_err "Homebrew is not installed. Install it first: https://brew.sh/"
    return 1
  fi
  
  _fc_echo "Installing forgecode via Homebrew ..."
  if brew install forgecode; then
    _fc_echo "Forgecode installed via Homebrew. Try: forgecode --help"
    return 0
  else
    _fc_err "Failed to install forgecode via Homebrew"
    return 1
  fi
}

# Fallback 2: Install from source
forgecode_install_source() {
  if ! _fc_have git || ! _fc_have npm; then
    _fc_err "git and npm are required for source installation"
    return 1
  fi
  
  local temp_dir="$HOME/.forgecode_build"
  _fc_echo "Installing forgecode from source ..."
  
  if git clone https://github.com/antinomyhq/forge.git "$temp_dir"; then
    cd "$temp_dir" || return 1
    if npm install && npm run build && npm install -g .; then
      _fc_echo "Forgecode installed from source. Try: forgecode --help"
      rm -rf "$temp_dir"
      return 0
    else
      _fc_err "Failed to build/install forgecode from source"
      cd - >/dev/null
      rm -rf "$temp_dir"
      return 1
    fi
  else
    _fc_err "Failed to clone forgecode repository"
    return 1
  fi
}

# Universal installer with fallbacks
forgecode_install() {
  _fc_echo "Starting forgecode installation with fallbacks..."
  
  # Try npm first
  if forgecode_install_latest; then
    return 0
  fi
  
  # Try homebrew
  if forgecode_install_homebrew; then
    return 0
  fi
  
  # Try source installation
  if forgecode_install_source; then
    return 0
  fi
  
  _fc_err "All installation methods failed. Please install manually."
  return 1
}

# npx forgecode@latest (no installation required)
forgecode_latest() {
  if ! _fc_have npx; then
    _fc_err "npx is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  # -y to auto-consent to install when needed
  npx -y forgecode@latest "$@"
}

# Note: Helper functions are intentionally kept available for use