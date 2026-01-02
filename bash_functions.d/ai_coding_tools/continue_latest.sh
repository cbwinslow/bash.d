#!/usr/bin/env bash
# Continue AI Coding Assistant Installer
# GitHub: https://github.com/continuedev/continue
# NPM: https://www.npmjs.com/package/@continuedev/continue
#
# Comprehensive installer with install/uninstall/reinstall/update procedures

_cont_echo() { printf '[continue] %s\n' "$*"; }
_cont_err() { printf '[continue][error] %s\n' "$*" >&2; }
_cont_warn() { printf '[continue][warn] %s\n' "$*" >&2; }
_cont_have() { command -v "$1" >/dev/null 2>&1; }

_cont_ensure_path() {
  local path_dir="$1"
  case ":$PATH:" in *":$path_dir:"*) ;; *) export PATH="$path_dir:$PATH";; esac
}

_cont_ensure_npm_prefix() {
  if ! _cont_have npm; then
    _cont_err "npm is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi

  local current
  current="$(npm config get prefix 2>/dev/null | tr -d '\r' || true)"
  if [[ -z "$current" || "$current" == "null" ]]; then current="/usr/local"; fi

  if [[ "$current" == "/usr"* ]] || [[ ! -w "$current" ]]; then
    mkdir -p "$HOME/.npm-global/bin"
    npm config set prefix "$HOME/.npm-global" >/dev/null 2>&1 || true
    _cont_ensure_path "$HOME/.npm-global/bin"
    _cont_echo "Adjusted npm prefix to $HOME/.npm-global"
  fi
}

# Primary installation method: npm
_continue_install_latest() {
  _cont_ensure_npm_prefix
  _cont_echo "Installing @continuedev/continue@latest globally via npm ..."
  if npm -g install @continuedev/continue@latest; then
    _cont_echo "Continue installed. Try: continue --help"
    return 0
  else
    _cont_err "Failed to install @continuedev/continue via npm"
    return 1
  fi
}

# Install specific version
_continue_install_version() {
  local version="$1"
  _cont_ensure_npm_prefix
  _cont_echo "Installing @continuedev/continue@$version via npm ..."
  if npm -g install "@continuedev/continue@$version"; then
    _cont_echo "Continue v$version installed. Try: continue --help"
    return 0
  else
    _cont_err "Failed to install @continuedev/continue@$version"
    return 1
  fi
}

# Homebrew installation (if available)
_continue_install_homebrew() {
  if ! _cont_have brew; then
    _cont_err "Homebrew is not installed. Install it first: https://brew.sh/"
    return 1
  fi

  _cont_echo "Installing continue via Homebrew ..."
  if brew install continue; then
    _cont_echo "Continue installed via Homebrew. Try: continue --help"
    return 0
  else
    _cont_err "Failed to install continue via Homebrew"
    return 1
  fi
}

# Install from source
_continue_install_source() {
  if ! _cont_have git || ! _cont_have npm; then
    _cont_err "git and npm are required for source installation"
    return 1
  fi

  local temp_dir="$HOME/.continue_build"
  _cont_echo "Installing Continue from source ..."

  if git clone https://github.com/continuedev/continue.git "$temp_dir"; then
    cd "$temp_dir" || return 1
    if npm install && npm run build && npm install -g .; then
      _cont_echo "Continue installed from source. Try: continue --help"
      rm -rf "$temp_dir"
      return 0
    else
      _cont_err "Failed to build/install Continue from source"
      cd - >/dev/null
      rm -rf "$temp_dir"
      return 1
    fi
  else
    _cont_err "Failed to clone Continue repository"
    return 1
  fi
}

# Uninstall procedure
_continue_uninstall() {
  _cont_echo "Uninstalling Continue..."
  
  # Try npm uninstall
  if npm -g uninstall @continuedev/continue 2>/dev/null; then
    _cont_echo "Continue uninstalled via npm"
    return 0
  fi
  
  # Try Homebrew uninstall
  if _cont_have brew && brew list | grep -q "^continue$"; then
    if brew uninstall continue; then
      _cont_echo "Continue uninstalled via Homebrew"
      return 0
    fi
  fi
  
  # Manual cleanup
  local npm_prefix=$(npm config get prefix 2>/dev/null)
  if [[ -f "$npm_prefix/bin/continue" ]]; then
    rm -f "$npm_prefix/bin/continue"
    _cont_echo "Continue binary removed from $npm_prefix/bin/"
  fi
  
  _cont_echo "Continue uninstallation complete"
  return 0
}

# Reinstall procedure
_continue_reinstall() {
  _cont_echo "Reinstalling Continue..."
  
  # Uninstall first
  _continue_uninstall
  
  # Clean npm cache
  npm cache clean --force 2>/dev/null || true
  
  # Install fresh
  continue_install "$@"
}

# Update procedure
_continue_update() {
  _cont_echo "Updating Continue..."
  
  # Try npm update
  if npm -g update @continuedev/continue 2>/dev/null; then
    _cont_echo "Continue updated to latest version"
    return 0
  else
    # If update fails, do a fresh install
    _cont_echo "Update failed, doing fresh install..."
    _continue_reinstall
  fi
}

# Check installation status
_continue_status() {
  local status="not installed"
  local version=""
  local location=""
  
  # Check npm installation
  if npm -g list @continuedev/continue 2>/dev/null | grep -q "@continuedev/continue@"; then
    status="installed via npm"
    version=$(npm -g list @continuedev/continue 2>/dev/null | grep "@continuedev/continue@" | head -1 | sed 's/.*@//' | sed 's/ .*//')
    location=$(npm config get prefix 2>/dev/null)
  # Check Homebrew installation
  elif _cont_have brew && brew list | grep -q "^continue$"; then
    status="installed via Homebrew"
    version=$(brew info continue 2>/dev/null | grep "stable" | sed 's/.*: //' || echo "unknown")
    location=$(brew --prefix continue 2>/dev/null || echo "unknown")
  # Check manual installation
  elif _cont_have continue; then
    status="installed (manual)"
    version=$(continue --version 2>/dev/null || echo "unknown")
    location=$(which continue 2>/dev/null || echo "unknown")
  fi
  
  printf "  Continue: %s" "$status"
  if [[ -n "$version" ]]; then
    printf " (v%s)" "$version"
  fi
  printf "\n"
  
  if [[ -n "$location" ]] && [[ "$location" != "unknown" ]]; then
    printf "    Location: %s\n" "$location"
  fi
}

# Universal installer with fallbacks
continue_install() {
  local version="$1"
  
  _cont_echo "Starting Continue installation${version:+@$version} with fallbacks..."

  # Install specific version if requested
  if [[ -n "$version" ]]; then
    if _continue_install_version "$version"; then
      return 0
    fi
  fi

  # Try npm first
  if _continue_install_latest; then
    return 0
  fi

  # Try Homebrew
  if _continue_install_homebrew; then
    return 0
  fi

  # Try source installation
  if _continue_install_source; then
    return 0
  fi

  _cont_err "All installation methods failed. Please install manually."
  return 1
}

# npx method (no installation required)
continue_latest() {
  if ! _cont_have npx; then
    _cont_err "npx is required. Please install Node.js first: https://nodejs.org/"
    return 1
  fi
  # -y to auto-consent to install when needed
  npx -y @continuedev/continue@latest "$@"
}

# Alias for compatibility
_continue_install() {
  continue_install "$@"
}

# Clean up local helpers from global namespace
# (Leave functions available for use by proxy)
unset -f _cont_echo _cont_err _cont_warn _cont_have _cont_ensure_path _cont_ensure_npm_prefix 2>/dev/null || true