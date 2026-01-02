#!/usr/bin/env bash
# Convenience helpers for Roo Code installation and execution.
# GitHub: https://github.com/RooCodeInc/Roo-Code
# Docs: https://roocode.ai/docs/
#
# Provided commands:
# - roo_code_install_latest: installs the latest Roo Code globally via npm.
# - roo_code_install_homebrew: installs via homebrew (fallback)
# - roo_code_install_source: installs from source (fallback)
# - roo_code_latest: runs the latest Roo Code using npx without a global install.

_rc_echo() { printf '[roo-code] %s\n' "$*"; }
_rc_err() { printf '[roo-code][error] %s\n' "$*" >&2; }
_rc_have() { command -v "$1" >/dev/null 2>&1; }

_rc_ensure_path() {
  local path_dir="$1"
  case ":$PATH:" in *":$path_dir:"*) ;; *) export PATH="$path_dir:$PATH";; esac
}

_rc_ensure_npm_prefix() {
  if ! _rc_have npm; then
    _rc_err "npm is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  
  local current
  current="$(npm config get prefix 2>/dev/null | tr -d '\r' || true)"
  if [[ -z "$current" || "$current" == "null" ]]; then current="/usr/local"; fi
  
  if [[ "$current" == "/usr"* ]] || [[ ! -w "$current" ]]; then
    mkdir -p "$HOME/.npm-global/bin"
    npm config set prefix "$HOME/.npm-global" >/dev/null 2>&1 || true
    _rc_ensure_path "$HOME/.npm-global/bin"
    _rc_echo "Adjusted npm prefix to $HOME/.npm-global"
  fi
}

# Primary installation method: npm
roo_code_install_latest() {
  _rc_ensure_npm_prefix
  _rc_echo "Installing roo-code@latest globally via npm ..."
  if npm -g install roo-code@latest; then
    _rc_echo "Roo Code installed. Try: roocode --help or roo-code --help"
    return 0
  else
    _rc_err "Failed to install roo-code@latest via npm"
    return 1
  fi
}

# Fallback 1: Homebrew
roo_code_install_homebrew() {
  if ! _rc_have brew; then
    _rc_err "Homebrew is not installed. Install it first: https://brew.sh/"
    return 1
  fi
  
  _rc_echo "Installing roo-code via Homebrew ..."
  if brew install roo-code; then
    _rc_echo "Roo Code installed via Homebrew. Try: roocode --help"
    return 0
  else
    _rc_err "Failed to install roo-code via Homebrew"
    return 1
  fi
}

# Fallback 2: Install from source
roo_code_install_source() {
  if ! _rc_have git || ! _rc_have npm; then
    _rc_err "git and npm are required for source installation"
    return 1
  fi
  
  local temp_dir="$HOME/.roo_code_build"
  _rc_echo "Installing Roo Code from source ..."
  
  if git clone https://github.com/RooCodeInc/Roo-Code.git "$temp_dir"; then
    cd "$temp_dir" || return 1
    if npm install && npm run build && npm install -g .; then
      _rc_echo "Roo Code installed from source. Try: roocode --help"
      rm -rf "$temp_dir"
      return 0
    else
      _rc_err "Failed to build/install Roo Code from source"
      cd - >/dev/null
      rm -rf "$temp_dir"
      return 1
    fi
  else
    _rc_err "Failed to clone Roo Code repository"
    return 1
  fi
}

# Universal installer with fallbacks
roo_code_install() {
  _rc_echo "Starting Roo Code installation with fallbacks..."
  
  # Try npm first
  if roo_code_install_latest; then
    return 0
  fi
  
  # Try homebrew
  if roo_code_install_homebrew; then
    return 0
  fi
  
  # Try source installation
  if roo_code_install_source; then
    return 0
  fi
  
  _rc_err "All installation methods failed. Please install manually."
  return 1
}

# npx roo-code@latest (no installation required)
roo_code_latest() {
  if ! _rc_have npx; then
    _rc_err "npx is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  # -y to auto-consent to install when needed
  npx -y roo-code@latest "$@"
}

# Note: Helper functions are intentionally kept available for use