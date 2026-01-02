#!/usr/bin/env bash
# Setup script to integrate bash_functions into your shell and ensure dev CLIs.
# Usage:
#   bash setup.sh            # Apply shell integration and ensure tools
#   bash setup.sh --apply    # Only apply shell integration
#   bash setup.sh --ensure-tools  # Only ensure tools installation
#   bash setup.sh --uninstall     # Remove managed block from shell rc files

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
BASHRC="$HOME/.bashrc"
ZSHRC="$HOME/.zshrc"
BLOCK_BEGIN="# >>> bash_functions.d (managed) >>>"
BLOCK_END="# <<< bash_functions.d (managed) <<<"

log() { printf '[setup] %s\n' "$*"; }
warn() { printf '[setup][warn] %s\n' "$*" >&2; }
err() { printf '[setup][error] %s\n' "$*" >&2; }

ensure_line_block() {
  local rc_file="$1"
  local content="$2"
  [[ -e "$rc_file" ]] || { touch "$rc_file"; }
  # Remove old managed block if present
  if grep -qF "$BLOCK_BEGIN" "$rc_file" 2>/dev/null; then
    awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '
      $0==b {skip=1; next}
      $0==e {skip=0; next}
      skip!=1 {print $0}
    ' "$rc_file" >"$rc_file.tmp" && mv "$rc_file.tmp" "$rc_file"
  fi
  {
    echo "$BLOCK_BEGIN"
    echo "$content"
    echo "$BLOCK_END"
  } >> "$rc_file"
}

remove_line_block() {
  local rc_file="$1"
  [[ -e "$rc_file" ]] || return 0
  awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '
    $0==b {skip=1; next}
    $0==e {skip=0; next}
    skip!=1 {print $0}
  ' "$rc_file" >"$rc_file.tmp" && mv "$rc_file.tmp" "$rc_file"
}

path_exports() {
  cat <<EOF
# Add pipx and npm global bin to PATH (idempotent)
export PIPX_BIN_HOME="\${PIPX_BIN_HOME:-$HOME/.local/bin}"
export NPM_PREFIX_BIN="\${NPM_PREFIX_BIN:-$HOME/.npm-global/bin}"
case ":$PATH:" in *":$PIPX_BIN_HOME:"*) ;; *) export PATH="$PIPX_BIN_HOME:$PATH" ;; esac
case ":$PATH:" in *":$NPM_PREFIX_BIN:"*) ;; *) export PATH="$NPM_PREFIX_BIN:$PATH" ;; esac
# Common extra locations
for _p in "$HOME/.bun/bin" "$HOME/.cargo/bin" \
          "/opt/homebrew/bin" "/usr/local/bin" "$HOME/.poetry/bin"; do
  case ":$PATH:" in *":${_p}:"*) ;; *) PATH="${_p}:$PATH";; esac
done
unset _p

# Source all custom bash functions
if [ -r "$SCRIPT_DIR/source_all.sh" ]; then
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/source_all.sh"
fi
EOF
}

apply_integration() {
  local content
  content="$(path_exports)"
  if [ -n "${BASH_VERSION:-}" ]; then
    ensure_line_block "$BASHRC" "$content"
    log "Updated $BASHRC"
  fi
  if [ -f "$ZSHRC" ]; then
    ensure_line_block "$ZSHRC" "$content"
    log "Updated $ZSHRC"
  fi
}

ensure_tools() {
  if [ -x "$SCRIPT_DIR/ensure_devtools.sh" ]; then
    bash "$SCRIPT_DIR/ensure_devtools.sh" || warn "ensure_devtools.sh reported issues"
  else
    warn "ensure_devtools.sh not found or not executable"
  fi
}

uninstall_integration() {
  [ -f "$BASHRC" ] && remove_line_block "$BASHRC" && log "Removed block from $BASHRC"
  [ -f "$ZSHRC" ] && remove_line_block "$ZSHRC" && log "Removed block from $ZSHRC"
}

ACTION_APPLY=true
ACTION_TOOLS=true
if [ "${1:-}" = "--apply" ]; then ACTION_TOOLS=false; fi
if [ "${1:-}" = "--ensure-tools" ]; then ACTION_APPLY=false; fi
if [ "${1:-}" = "--uninstall" ]; then ACTION_APPLY=false; ACTION_TOOLS=false; uninstall_integration; exit 0; fi

if [ "$ACTION_APPLY" = true ]; then apply_integration; fi
if [ "$ACTION_TOOLS" = true ]; then ensure_tools; fi

log "Setup complete. Open a new shell or run: source \"$BASHRC\""
