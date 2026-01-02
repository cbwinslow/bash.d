#!/usr/bin/env bash
# Convenience helpers for Kilo Code installation and execution.
# GitHub: https://github.com/Kilo-Org/kilocode
# Docs: https://kilocode.ai/docs/
#
# Provided commands:
# - kilo_code_install_latest: installs the latest Kilo Code globally via npm.
# - kilo_code_install_homebrew: installs via homebrew (fallback)
# - kilo_code_install_source: installs from source (fallback)
# - kilo_code_latest: runs the latest Kilo Code using npx without a global install.

_kc_echo() { printf '[kilo-code] %s\n' "$*"; }
_kc_err() { printf '[kilo-code][error] %s\n' "$*" >&2; }
_kc_have() { command -v "$1" >/dev/null 2>&1; }

_kc_ensure_path() {
  local path_dir="$1"
  case ":$PATH:" in *":$path_dir:"*) ;; *) export PATH="$path_dir:$PATH";; esac
}

_kc_ensure_npm_prefix() {
  if ! _kc_have npm; then
    _kc_err "npm is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  
  local current
  current="$(npm config get prefix 2>/dev/null | tr -d '\r' || true)"
  if [[ -z "$current" || "$current" == "null" ]]; then current="/usr/local"; fi
  
  if [[ "$current" == "/usr"* ]] || [[ ! -w "$current" ]]; then
    mkdir -p "$HOME/.npm-global/bin"
    npm config set prefix "$HOME/.npm-global" >/dev/null 2>&1 || true
    _kc_ensure_path "$HOME/.npm-global/bin"
    _kc_echo "Adjusted npm prefix to $HOME/.npm-global"
  fi
}

# Primary installation method: npm
kilo_code_install_latest() {
  _kc_ensure_npm_prefix
  _kc_echo "Installing @kilocode/cli@latest globally via npm ..."
  if npm -g install @kilocode/cli@latest; then
    _kc_echo "Kilo Code installed. Try: kilocode --help"
    return 0
  else
    _kc_err "Failed to install @kilocode/cli via npm"
    return 1
  fi
}

# Fallback 1: Homebrew
kilo_code_install_homebrew() {
  if ! _kc_have brew; then
    _kc_err "Homebrew is not installed. Install it first: https://brew.sh/"
    return 1
  fi
  
  _kc_echo "Installing kilocode via Homebrew ..."
  if brew install kilocode; then
    _kc_echo "Kilo Code installed via Homebrew. Try: kilocode --help"
    return 0
  else
    _kc_err "Failed to install kilocode via Homebrew"
    return 1
  fi
}

# Fallback 2: Install from source
kilo_code_install_source() {
  if ! _kc_have git || ! _kc_have npm; then
    _kc_err "git and npm are required for source installation"
    return 1
  fi
  
  local temp_dir="$HOME/.kilo_code_build"
  _kc_echo "Installing Kilo Code from source ..."
  
  if git clone https://github.com/Kilo-Org/kilocode.git "$temp_dir"; then
    cd "$temp_dir" || return 1
    if npm install && npm run build && npm install -g .; then
      _kc_echo "Kilo Code installed from source. Try: kilocode --help"
      rm -rf "$temp_dir"
      return 0
    else
      _kc_err "Failed to build/install Kilo Code from source"
      cd - >/dev/null
      rm -rf "$temp_dir"
      return 1
    fi
  else
    _kc_err "Failed to clone Kilo Code repository"
    return 1
  fi
}

# Universal installer with fallbacks
kilo_code_install() {
  _kc_echo "Starting Kilo Code installation with fallbacks..."
  
  # Try npm first
  if kilo_code_install_latest; then
    return 0
  fi
  
  # Try homebrew
  if kilo_code_install_homebrew; then
    return 0
  fi
  
  # Try source installation
  if kilo_code_install_source; then
    return 0
  fi
  
  _kc_err "All installation methods failed. Please install manually."
  return 1
}

# npx @kilocode/cli@latest (no installation required)
kilo_code_latest() {
  if ! _kc_have npx; then
    _kc_err "npx is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  # -y to auto-consent to install when needed
  npx -y @kilocode/cli@latest "$@"
}

# Note: Helper functions are intentionally kept available for use