#!/usr/bin/env bash
# Ensure requested dev CLIs are installed and on PATH with idempotent behavior.
# Targets (best-effort due to naming ambiguity):
#  - opencode
#  - codex
#  - qwen-coder
#  - forgecode
#  - kilocode (aka "kilo code")
#  - cline
#  - roocode (aka "roo code")
#  - gemini-cli
#
# Strategy:
#  - If command exists, skip.
#  - Otherwise try (in order): npm -g, pipx, brew (if available), apt (Debian/Ubuntu).
#  - Adjust npm global prefix to $HOME/.npm-global when appropriate.
#  - Add $HOME/.local/bin and $HOME/.npm-global/bin to PATH for this run.
#  - Clean broken symlinks in common user bin dirs.

set -euo pipefail

log() { printf '[ensure] %s\n' "$*"; }
warn() { printf '[ensure][warn] %s\n' "$*" >&2; }
err() { printf '[ensure][error] %s\n' "$*" >&2; }

OS="$(uname -s 2>/dev/null || echo Unknown)"
ARCH="$(uname -m 2>/dev/null || echo Unknown)"

# Ensure PATH for this run
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"

have() { command -v "$1" >/dev/null 2>&1; }

# Configure npm global prefix if npm exists and prefix is system-owned
ensure_npm_prefix() {
  if ! have npm; then return 0; fi
  local current
  if ! current="$(npm config get prefix 2>/dev/null | tr -d '\r' || true)"; then current=""; fi
  if [[ -z "$current" || "$current" == "null" ]]; then current="/usr/local"; fi
  if [[ "$current" == "/usr"* ]] || [[ ! -w "$current" ]]; then
    mkdir -p "$HOME/.npm-global/bin"
    npm config set prefix "$HOME/.npm-global" >/dev/null 2>&1 || true
    export NPM_PREFIX_BIN="$HOME/.npm-global/bin"
    case ":$PATH:" in *":$NPM_PREFIX_BIN:"*) ;; *) export PATH="$NPM_PREFIX_BIN:$PATH";; esac
    log "Set npm global prefix to $HOME/.npm-global"
  fi
}

ensure_pipx() {
  if have pipx; then return 0; fi
  if have python3 && have python3 -m pip; then
    python3 -m pip install --user -q pipx || true
    if have pipx; then log "Installed pipx via pip"; return 0; fi
  fi
  return 1
}

ensure_brew() {
  if have brew; then return 0; fi
  # Try common Homebrew paths
  for p in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$p" ]]; then export PATH="$(dirname "$p"):$PATH"; return 0; fi
  done
  return 1
}

apt_update_once_done=false
apt_install() {
  local pkg="$1"
  if have apt-get; then
    if ! $apt_update_once_done; then sudo apt-get update -y || true; apt_update_once_done=true; fi
    sudo apt-get install -y "$pkg" || return 1
    return 0
  fi
  return 1
}

declare -A SUCCESS
declare -A ERROR

# tool schema: name|cmds(comma)|npm_pkg|pipx_pkg|brew_pkg|apt_pkg
TOOLS=(
  "opencode|opencode|opencode||opencode|"
  "codex|codex|codex||codex|"
  # Prefer the official qwen-code. Keep qwen-coder for compatibility.
  "qwen-code|qwen-code,qwen,qwencode|||qwen-code|"
  "qwen-coder|qwen-coder,qwencoder|qwen-coder||qwen-coder|"
  "forgecode|forgecode|forgecode@latest||forgecode|"
  "kilocode|kilocode,kilo-code,kilo|kilocode||kilocode|"
  "cline|cline|cline||cline|"
  # Roo Code (official repo: https://github.com/RooCodeInc/Roo-Code)
  # Prefer npm package name "roo-code@latest"; keep command candidates for flexibility
  "roocode|roocode,roo-code,roo|roo-code@latest||roo-code|"
  "gemini-cli|gemini,gemini-cli|gemini-cli|gemini-cli|gemini-cli|gemini-cli"
)

ensure_npm_prefix || true
ensure_pipx || true
ensure_brew || true

install_via_npm() {
  local pkg="$1"
  if have npm; then npm -g install "$pkg" >/dev/null 2>&1 && return 0; fi
  return 1
}

install_via_pipx() {
  local pkg="$1"
  if have pipx; then pipx install --force "$pkg" >/dev/null 2>&1 && return 0; fi
  return 1
}

install_via_brew() {
  local pkg="$1"
  if have brew; then brew list "$pkg" >/dev/null 2>&1 || brew install "$pkg" >/dev/null 2>&1; return 0; fi
  return 1
}

attempt_install() {
  local name="$1" cmds="$2" npm_pkg="$3" pipx_pkg="$4" brew_pkg="$5" apt_pkg="$6"

  IFS=',' read -r -a cmdlist <<<"$cmds"
  for c in "${cmdlist[@]}"; do
    if [[ -n "$c" && "$c" != "null" ]] && have "$c"; then SUCCESS[$name]="present ($c)"; return 0; fi
  done

  local ok=false
  if [[ -n "$npm_pkg" ]]; then install_via_npm "$npm_pkg" && ok=true || ok=$ok; fi
  if [[ "$ok" = false && -n "$pipx_pkg" ]]; then install_via_pipx "$pipx_pkg" && ok=true || ok=$ok; fi
  if [[ "$ok" = false && -n "$brew_pkg" ]]; then install_via_brew "$brew_pkg" && ok=true || ok=$ok; fi
  if [[ "$ok" = false && -n "$apt_pkg" ]]; then apt_install "$apt_pkg" && ok=true || ok=$ok; fi

  # Recheck
  for c in "${cmdlist[@]}"; do
    if [[ -n "$c" && "$c" != "null" ]] && have "$c"; then SUCCESS[$name]="installed ($c)"; return 0; fi
  done

  # Special-case fallback: install qwen-code from GitHub if not available via registries
  if [[ "$name" == "qwen-code" ]]; then
    if have python3; then
      # Ensure pipx, then install from GitHub
      ensure_pipx || true
      if have pipx; then
        if pipx install --force "git+https://github.com/QwenLM/qwen-code.git" >/dev/null 2>&1; then
          for c in "${cmdlist[@]}"; do
            if [[ -n "$c" && "$c" != "null" ]] && have "$c"; then SUCCESS[$name]="installed from GitHub ($c)"; return 0; fi
          done
        fi
      fi
    fi
  fi

  ERROR[$name]="not found; tried npm=${npm_pkg:-none} pipx=${pipx_pkg:-none} brew=${brew_pkg:-none} apt=${apt_pkg:-none}"
  return 1
}

# Clean broken symlinks in common bin dirs
clean_broken_symlinks() {
  local cleaned=0
  for d in "$HOME/.local/bin" "$HOME/.npm-global/bin"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r -d '' link; do
      if [[ -L "$link" && ! -e "$link" ]]; then
        rm -f "$link" && cleaned=$((cleaned+1))
      fi
    done < <(find "$d" -xtype l -print0 2>/dev/null)
  done
  if (( cleaned > 0 )); then log "Removed $cleaned broken symlink(s) from user bin dirs"; fi
}

main() {
  for spec in "${TOOLS[@]}"; do
    IFS='|' read -r name cmds npm_pkg pipx_pkg brew_pkg apt_pkg <<<"$spec"
    log "Ensuring $name ..."
    if attempt_install "$name" "$cmds" "$npm_pkg" "$pipx_pkg" "$brew_pkg" "$apt_pkg"; then
      :
    else
      warn "$name installation unresolved"
    fi
  done

  clean_broken_symlinks || true

  echo
  log "Summary:"
  for spec in "${TOOLS[@]}"; do
    IFS='|' read -r name _ <<<"$spec"
    if [[ -n "${SUCCESS[$name]:-}" ]]; then
      printf '  - %-12s %s\n' "$name" "${SUCCESS[$name]}"
    else
      printf '  - %-12s %s\n' "$name" "${ERROR[$name]:-failed}"
    fi
  done
}

main "$@"
