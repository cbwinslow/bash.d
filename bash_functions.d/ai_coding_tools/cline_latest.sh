#!/usr/bin/env bash
# Convenience helpers for Cline installation and execution.
# GitHub: https://github.com/cline/cline
# Docs: https://cline.bot/docs/
#
# Provided commands:
# - cline_install_latest: installs the latest Cline globally via npm.
# - cline_install_homebrew: installs via homebrew (fallback)
# - cline_install_source: installs from source (fallback)
# - cline_latest: runs the latest Cline using npx without a global install.

_cl_echo() { printf '[cline] %s\n' "$*"; }
_cl_err() { printf '[cline][error] %s\n' "$*" >&2; }
_cl_have() { command -v "$1" >/dev/null 2>&1; }

_cl_ensure_path() {
  local path_dir="$1"
  case ":$PATH:" in *":$path_dir:"*) ;; *) export PATH="$path_dir:$PATH";; esac
}

_cl_ensure_npm_prefix() {
  if ! _cl_have npm; then
    _cl_err "npm is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  
  local current
  current="$(npm config get prefix 2>/dev/null | tr -d '\r' || true)"
  if [[ -z "$current" || "$current" == "null" ]]; then current="/usr/local"; fi
  
  if [[ "$current" == "/usr"* ]] || [[ ! -w "$current" ]]; then
    mkdir -p "$HOME/.npm-global/bin"
    npm config set prefix "$HOME/.npm-global" >/dev/null 2>&1 || true
    _cl_ensure_path "$HOME/.npm-global/bin"
    _cl_echo "Adjusted npm prefix to $HOME/.npm-global"
  fi
}

# Primary installation method: npm
cline_install_latest() {
  _cl_ensure_npm_prefix
  _cl_echo "Installing cline@latest globally via npm ..."
  if npm -g install cline@latest; then
    _cl_echo "Cline installed. Try: cline --help"
    return 0
  else
    _cl_err "Failed to install cline via npm"
    return 1
  fi
}

# Fallback 1: Homebrew
cline_install_homebrew() {
  if ! _cl_have brew; then
    _cl_err "Homebrew is not installed. Install it first: https://brew.sh/"
    return 1
  fi
  
  _cl_echo "Installing cline via Homebrew ..."
  if brew install cline; then
    _cl_echo "Cline installed via Homebrew. Try: cline --help"
    return 0
  else
    _cl_err "Failed to install cline via Homebrew"
    return 1
  fi
}

# Fallback 2: Install from source
cline_install_source() {
  if ! _cl_have git || ! _cl_have npm; then
    _cl_err "git and npm are required for source installation"
    return 1
  fi
  
  local temp_dir="$HOME/.cline_build"
  _cl_echo "Installing Cline from source ..."
  
  if git clone https://github.com/cline/cline.git "$temp_dir"; then
    cd "$temp_dir" || return 1
    if npm install && npm run build && npm install -g .; then
      _cl_echo "Cline installed from source. Try: cline --help"
      rm -rf "$temp_dir"
      return 0
    else
      _cl_err "Failed to build/install Cline from source"
      cd - >/dev/null
      rm -rf "$temp_dir"
      return 1
    fi
  else
    _cl_err "Failed to clone Cline repository"
    return 1
  fi
}

# Universal installer with fallbacks
cline_install() {
  _cl_echo "Starting Cline installation with fallbacks..."
  
  # Try npm first
  if cline_install_latest; then
    return 0
  fi
  
  # Try homebrew
  if cline_install_homebrew; then
    return 0
  fi
  
  # Try source installation
  if cline_install_source; then
    return 0
  fi
  
  _cl_err "All installation methods failed. Please install manually."
  return 1
}

# npx cline@latest (no installation required)
cline_latest() {
  if ! _cl_have npx; then
    _cl_err "npx is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  # -y to auto-consent to install when needed
  npx -y cline@latest "$@"
}

# Note: Helper functions are intentionally kept available for use