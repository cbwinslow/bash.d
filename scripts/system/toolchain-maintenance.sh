#!/usr/bin/env bash
# Maintains Node.js, pnpm, npm, bun, and Homebrew via Volta/Homebrew and keeps PATH entries in sync.
# Script is modular; each update function ensures the requested tool is installed/updated, validates its
# install location, and pushes the corresponding bin directory onto PATH (persisting the change in
# common shell profiles).
set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="toolchain-maintenance"
readonly PROFILE_TARGETS=("$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc")
readonly VOLTA_BIN="$HOME/.volta/bin"
readonly VOLTA_HOME="$HOME/.volta"

log() {
  printf "[%s] %s\n" "$SCRIPT_NAME" "$*"
}

error() {
  printf "[%s] ERROR: %s\n" "$SCRIPT_NAME" "$*" >&2
  exit 1
}

canonical_path() {
  local candidate="$1"
  if command -v realpath &>/dev/null; then
    realpath -m "$candidate"
  elif command -v readlink &>/dev/null; then
    readlink -m "$candidate"
  else
    printf "%s" "$candidate"
  fi
}

ensure_path_entry() {
  local entry marker profile canonical
  entry="$1"
  canonical="$(canonical_path "$entry")"
  if [[ -z "$canonical" || ! -d "$canonical" ]]; then
    log "Skipping PATH entry for $entry (missing directory)."
    return 0
  fi
  # Remove existing occurrences of this path before prepending so order stays consistent.
  local current_segments new_path
  IFS=':' read -ra current_segments <<< "$PATH"
  new_path="$canonical"
  for segment in "${current_segments[@]}"; do
    [[ -z "$segment" || "$segment" == "$canonical" ]] && continue
    new_path="$new_path:$segment"
  done
  export PATH="$new_path"
  log "Ensured $canonical leads PATH for this session."
  marker="# bash.d path entry for $canonical"
  for profile in "${PROFILE_TARGETS[@]}"; do
    if [[ ! -e "$profile" ]]; then
      touch "$profile"
    fi
    if ! grep -Fq "$marker" "$profile"; then
      {
        printf "\n%s\nexport PATH=\"%s:\$PATH\"\n" "$marker" "$canonical"
      } >> "$profile"
      log "Persisted PATH entry for $canonical in $profile."
    fi
  done
}

validate_binary() {
  local name version
  name="$1"
  if ! command -v "$name" &>/dev/null; then
    error "$name is not available after install/update."
  fi
  version="$("$name" --version 2>&1 | head -n 1)"
  log "$name $(printf "%s" "$version" | tr -d '\n')"
}

ensure_volta() {
  if command -v volta &>/dev/null; then
    log "Volta already installed."
  else
    log "Installing Volta (required for node/pnpm/npm/bun)."
    if ! command -v curl &>/dev/null; then
      error "curl is required to install Volta."
    fi
    curl -fsSL https://get.volta.sh | bash -s -- --skip-setup
    log "Volta install script completed; run 'source $HOME/.volta/bin/activate' or restart your shell if needed."
  fi
  ensure_path_entry "$VOLTA_BIN"
  # rehash so new entries are visible immediately
  if command -v hash &>/dev/null; then
    hash -r
  fi
}

validate_install_location() {
  local name expected
  name="$1"
  expected="$2"
  local binary
  binary="$(command -v "$name" 2>/dev/null || true)"
  if [[ -z "$binary" ]]; then
    error "$name is missing after installation."
  fi
  if [[ "$binary" != "$expected"* ]]; then
    log "$name binary is $binary but expected prefix $expected."
    return 1
  fi
  log "$name is installed under $expected."
}

load_brew_env() {
  if command -v brew &>/dev/null; then
    eval "$(/usr/bin/env brew shellenv)"
    return 0
  fi
  local candidates=(
    "/opt/homebrew/bin/brew"
    "/home/linuxbrew/.linuxbrew/bin/brew"
    "/usr/local/bin/brew"
  )
  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done
  return 1
}

update_homebrew() {
  log "Ensuring Homebrew is installed and up to date."
  if ! command -v curl &>/dev/null; then
    error "curl is required to install Homebrew."
  fi
  if ! command -v brew &>/dev/null; then
    log "Homebrew not detected; running install script."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || \
      error "Homebrew install failed."
  else
    log "Homebrew already installed."
  fi
  if ! load_brew_env; then
    error "Unable to load Homebrew environment."
  fi
  local prefix
  prefix="$(brew --prefix)"
  ensure_path_entry "$prefix/bin"
  ensure_path_entry "$prefix/sbin"
  log "Running 'brew update && brew upgrade'."
  brew update
  brew upgrade
  validate_binary brew
  validate_install_location brew "$prefix"
}

update_node() {
  log "Updating Node.js via Volta."
  ensure_volta
  ensure_path_entry "$VOLTA_BIN"
  volta install node@latest
  validate_binary node
  validate_install_location node "$VOLTA_HOME"
}

update_npm() {
  log "Syncing npm via Volta."
  ensure_volta
  ensure_path_entry "$VOLTA_BIN"
  volta install npm@latest
  validate_binary npm
  validate_install_location npm "$VOLTA_HOME"
}

update_pnpm() {
  log "Syncing pnpm via Volta."
  ensure_volta
  ensure_path_entry "$VOLTA_BIN"
  volta install pnpm@latest
  validate_binary pnpm
  validate_install_location pnpm "$VOLTA_HOME"
}

update_bun() {
  log "Syncing bun via Volta."
  ensure_volta
  ensure_path_entry "$VOLTA_BIN"
  volta install bun@latest
  validate_binary bun
  validate_install_location bun "$VOLTA_HOME"
}

summarize_toolchain() {
  log "Final toolchain versions:"
  for bin in node npm pnpm bun brew; do
    if command -v "$bin" &>/dev/null; then
      printf "  - %s %s\n" "$bin" "$("$bin" --version 2>/dev/null | head -n 1)"
    else
      printf "  - %s (missing)\n" "$bin"
    fi
  done
}

main() {
  update_homebrew
  update_node
  update_npm
  update_pnpm
  update_bun
  summarize_toolchain
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
