#!/usr/bin/env bash
# ============================================================================
# Script Name: cbw-ai-cli-doctor.sh
# Date: 2025-12-31
# Author: ChatGPT (for Blaine Winslow / cbwinslow)
# Summary:
#   Robust installer + environment doctor for popular AI coding CLIs.
#   - Installs/repairs Node.js + npm global PATH issues (common cause of "it worked
#     yesterday but not today" errors).
#   - Optionally installs via NVM (recommended) or system packages.
#   - Installs and validates:
#       * OpenCode (opencode)              -> npm: opencode-ai
#       * Google Gemini CLI (gemini)       -> npm: @google/gemini-cli
#       * OpenAI Codex CLI (codex)         -> npm: @openai/codex
#       * Qwen Code (qwen)                 -> npm: @qwen-code/qwen-code
#       * Cline CLI (cline)                -> npm: cline
#       * Kilo Code CLI (kilocode)         -> npm: @kilocode/cli
#       * Aider (aider)                    -> pipx: aider-chat
#   - Adds safe, idempotent PATH fixes to ~/.bashrc and/or ~/.zshrc.
#   - Produces a post-run report with exact commands to test.
#
# Why this exists:
#   The #1 failure mode for these tools is npm global bin not being on PATH,
#   or Node being upgraded/downgraded (system node vs nvm node) which changes
#   where global packages live. This script standardizes on an explicit npm
#   global prefix and ensures PATH points at it.
#
# Inputs:
#   Flags (see --help)
# Outputs:
#   - Installs software and modifies shell RC files (backed up first)
#   - Log file at /tmp/CBW-ai-cli-doctor.log
#
# Security:
#   - No secrets are read or written.
#   - RC modifications are scoped to a clearly-marked block.
#   - Uses non-root installs for npm globals by default.
#
# Modification Log:
#   2025-12-31  Initial release
# ============================================================================

set -Eeuo pipefail

# ------------------------------ Constants -----------------------------------
SCRIPT_NAME="cbw-ai-cli-doctor.sh"
LOG_FILE="/tmp/CBW-ai-cli-doctor.log"
MARKER_BEGIN="# >>> CBW AI CLI DOCTOR BEGIN >>>"
MARKER_END="# <<< CBW AI CLI DOCTOR END <<<"

# Prefer a stable, user-owned npm prefix to avoid sudo/permission weirdness.
# This is the single biggest "npm installed but command not found" fix.
NPM_PREFIX_DEFAULT="$HOME/.local/share/npm-global"

# Node requirement for most of these CLIs (Cline requires Node >= 20)
MIN_NODE_MAJOR=20
PREFERRED_NODE_MAJOR=22

# Tools: name -> install method + command(s)
# Notes:
#   - We install CLIs only. Some brands also ship editor extensions; this script
#     can optionally install VS Code extensions if `code` is present.

# ------------------------------ Globals -------------------------------------
DRY_RUN=0
FORCE=0
NODE_METHOD="auto"   # auto|nvm|system|brew
SHELL_TARGETS="auto" # auto|bash|zsh|bash,zsh
INSTALL_VSCODE_EXT=0

# ------------------------------ Logging -------------------------------------
log() {
  local msg="$*"
  printf '%s %s\n' "[$(date +'%Y-%m-%d %H:%M:%S')]" "$msg" | tee -a "$LOG_FILE" >&2
}

die() {
  log "ERROR: $*"
  exit 1
}

run() {
  # Runs a command, respecting DRY_RUN.
  # Usage: run "cmd" "arg1" ...
  if [[ $DRY_RUN -eq 1 ]]; then
    log "DRY-RUN: $*"
    return 0
  fi
  log "RUN: $*"
  "$@" 2>&1 | tee -a "$LOG_FILE"
}

have() { command -v "$1" >/dev/null 2>&1; }

# ------------------------------ OS detect ----------------------------------
os_id="unknown"
os_like=""

read_os_release() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    os_id="${ID:-unknown}"
    os_like="${ID_LIKE:-}"
  fi
}

is_debian_like() {
  [[ "$os_id" == "debian" || "$os_id" == "ubuntu" || "$os_like" == *"debian"* ]]
}

is_rhel_like() {
  [[ "$os_id" == "rhel" || "$os_id" == "fedora" || "$os_id" == "centos" || "$os_like" == *"rhel"* || "$os_like" == *"fedora"* ]]
}

is_arch_like() {
  [[ "$os_id" == "arch" || "$os_like" == *"arch"* ]]
}

# ------------------------------ Help ----------------------------------------
usage() {
  cat <<'EOF'
cbw-ai-cli-doctor.sh

Installs + validates common AI coding CLIs and fixes Node/npm PATH issues.

USAGE:
  ./cbw-ai-cli-doctor.sh [options]

OPTIONS:
  --dry-run                Print what would change; do not modify system.
  --force                  Reinstall tools even if already present.
  --node-method <m>        auto|nvm|system|brew   (default: auto)
  --shells <s>             auto|bash|zsh|bash,zsh (default: auto)
  --install-vscode-ext     If VS Code `code` CLI exists, install relevant extensions.
  --prefix <dir>           Set npm global prefix (default: ~/.local/share/npm-global)
  --help                   Show help.

NOTES:
  - Recommended mode is --node-method nvm because it prevents system package
    updates from breaking npm global installs.
EOF
}

NPM_PREFIX="$NPM_PREFIX_DEFAULT"

# ------------------------------ Arg parse -----------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    --node-method) NODE_METHOD="${2:-}"; shift 2 ;;
    --shells) SHELL_TARGETS="${2:-}"; shift 2 ;;
    --install-vscode-ext) INSTALL_VSCODE_EXT=1; shift ;;
    --prefix) NPM_PREFIX="${2:-}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1 (use --help)" ;;
  esac
done

# ------------------------------ Utilities -----------------------------------
backup_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  local ts
  ts="$(date +'%Y%m%d-%H%M%S')"
  run cp -a "$f" "${f}.cbw-bak.${ts}"
}

ensure_dir() {
  local d="$1"
  [[ -d "$d" ]] && return 0
  run mkdir -p "$d"
}

append_block_idempotent() {
  # Add a marked block to a shell rc file. If block exists, replace it.
  local rc="$1"
  local block="$2"

  ensure_dir "$(dirname "$rc")"
  [[ -f "$rc" ]] || { run touch "$rc"; }

  backup_file "$rc"

  if grep -qF "$MARKER_BEGIN" "$rc" 2>/dev/null; then
    log "Updating existing CBW block in $rc"
    if [[ $DRY_RUN -eq 1 ]]; then
      log "DRY-RUN: would replace CBW block in $rc"
      return 0
    fi
    # Remove existing block
    # Use perl for robust multiline edits.
    perl -0777 -i -pe 's/# >>> CBW AI CLI DOCTOR BEGIN >>>.*?# <<< CBW AI CLI DOCTOR END <<<\n?//sg' "$rc"
  else
    log "Adding CBW block to $rc"
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    log "DRY-RUN: would append CBW block to $rc"
    return 0
  fi

  {
    echo ""
    echo "$MARKER_BEGIN"
    echo "$block"
    echo "$MARKER_END"
  } >>"$rc"
}

# ------------------------------ RC targets ----------------------------------
resolve_shell_targets() {
  local targets=()

  if [[ "$SHELL_TARGETS" == "auto" ]]; then
    # If the user's login shell is zsh, prioritize zsh. But we still often want
    # both, because people flip between shells.
    local login_shell
    login_shell="${SHELL:-}"
    if [[ "$login_shell" == *"zsh"* ]]; then
      targets+=("$HOME/.zshrc" "$HOME/.bashrc")
    else
      targets+=("$HOME/.bashrc" "$HOME/.zshrc")
    fi
  else
    IFS=',' read -r -a parts <<<"$SHELL_TARGETS"
    for p in "${parts[@]}"; do
      case "$p" in
        bash) targets+=("$HOME/.bashrc") ;;
        zsh) targets+=("$HOME/.zshrc") ;;
        *) die "Invalid --shells value: $SHELL_TARGETS" ;;
      esac
    done
  fi

  # De-dupe while preserving order
  local uniq=()
  local seen=""
  for t in "${targets[@]}"; do
    [[ "$seen" == *"|$t|"* ]] && continue
    seen+="|$t|"
    uniq+=("$t")
  done

  printf '%s\n' "${uniq[@]}"
}

# ------------------------------ Package install -----------------------------
install_system_deps() {
  log "Ensuring base dependencies: curl, git, python3, pip, pipx (where possible)"

  if have apt-get; then
    run sudo apt-get update -y
    run sudo apt-get install -y curl git ca-certificates python3 python3-pip python3-venv
    # pipx sometimes in apt repos
    if ! have pipx; then
      run sudo apt-get install -y pipx || true
    fi
  elif have dnf; then
    run sudo dnf install -y curl git ca-certificates python3 python3-pip
    if ! have pipx; then
      run sudo dnf install -y pipx || true
    fi
  elif have yum; then
    run sudo yum install -y curl git ca-certificates python3 python3-pip
    if ! have pipx; then
      run sudo yum install -y pipx || true
    fi
  elif have pacman; then
    run sudo pacman -Sy --noconfirm curl git ca-certificates python python-pip
    if ! have pipx; then
      run sudo pacman -S --noconfirm python-pipx || true
    fi
  elif have brew; then
    run brew install curl git python pipx || true
  else
    log "WARN: No known package manager found. Skipping system deps."
  fi

  # If pipx still missing, bootstrap via pip
  if ! have pipx; then
    log "pipx not found via system packages; bootstrapping with pip --user"
    run python3 -m pip install --user -U pip
    run python3 -m pip install --user -U pipx
    # Ensure pipx path is set later in RC block
  fi

  # Ensure pipx ensures its own PATH entries
  if have pipx; then
    run pipx ensurepath || true
  fi
}

# ------------------------------ Node management -----------------------------
node_major_version() {
  if ! have node; then
    echo 0
    return 0
  fi
  local v
  v="$(node --version 2>/dev/null || true)"
  v="${v#v}"
  echo "${v%%.*}"
}

install_node_with_nvm() {
  log "Installing/upgrading Node via NVM"

  ensure_dir "$HOME/.nvm"

  if [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
    # Official install script
    # NOTE: This downloads and runs a shell script from the internet.
    # You can inspect it first if desired.
    run bash -c 'curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
  else
    log "NVM already present"
  fi

  # shellcheck disable=SC1090
  if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    # Load nvm into current shell for this script run
    # shellcheck disable=SC1091
    source "$HOME/.nvm/nvm.sh"
  else
    die "NVM install did not produce $HOME/.nvm/nvm.sh"
  fi

  # Install preferred node
  run nvm install "$PREFERRED_NODE_MAJOR"
  run nvm alias default "$PREFERRED_NODE_MAJOR"
  run nvm use default
}

install_node_with_system_packages() {
  log "Installing/upgrading Node via system packages"

  # On many distros, repo node may be old. This is best-effort.
  if have apt-get; then
    run sudo apt-get update -y
    run sudo apt-get install -y nodejs npm || true
  elif have dnf; then
    run sudo dnf install -y nodejs npm || true
  elif have yum; then
    run sudo yum install -y nodejs npm || true
  elif have pacman; then
    run sudo pacman -S --noconfirm nodejs npm || true
  else
    die "No supported package manager for --node-method system"
  fi
}

install_node_with_brew() {
  have brew || die "Homebrew not found, cannot use --node-method brew"
  run brew install node
}

ensure_node_ok() {
  local major
  major="$(node_major_version)"

  if [[ "$major" -ge "$MIN_NODE_MAJOR" ]]; then
    log "Node is present and meets minimum version: node v$(node --version)"
    return 0
  fi

  log "Node missing or too old (found major=$major, need >=$MIN_NODE_MAJOR)."

  case "$NODE_METHOD" in
    auto)
      # Prefer nvm when possible
      install_node_with_nvm
      ;;
    nvm)
      install_node_with_nvm
      ;;
    system)
      install_node_with_system_packages
      ;;
    brew)
      install_node_with_brew
      ;;
    *)
      die "Invalid --node-method: $NODE_METHOD"
      ;;
  esac

  major="$(node_major_version)"
  [[ "$major" -ge "$MIN_NODE_MAJOR" ]] || die "Node install failed or is still too old. Found node major=$major"
}

# ------------------------------ npm PATH doctor ------------------------------
write_shell_block() {
  # We set:
  #   - NPM_CONFIG_PREFIX to NPM_PREFIX
  #   - PATH includes NPM_PREFIX/bin
  #   - (If installed) NVM loads early
  #   - pipx user bin path (~/.local/bin) present
  cat <<EOF
# Node/NPM global prefix to avoid sudo installs + PATH mystery
export NPM_CONFIG_PREFIX="${NPM_PREFIX}"

# Put user bins first (pipx, user installs)
if [ -d "\$HOME/.local/bin" ]; then
  export PATH="\$HOME/.local/bin:\$PATH"
fi

# Put npm global bins on PATH
if [ -d "\$NPM_CONFIG_PREFIX/bin" ]; then
  export PATH="\$NPM_CONFIG_PREFIX/bin:\$PATH"
fi

# NVM (if installed)
export NVM_DIR="\$HOME/.nvm"
if [ -s "\$NVM_DIR/nvm.sh" ]; then
  . "\$NVM_DIR/nvm.sh"  # loads nvm
fi
if [ -s "\$NVM_DIR/bash_completion" ]; then
  . "\$NVM_DIR/bash_completion"  # optional
fi
EOF
}

ensure_npm_prefix_configured() {
  ensure_dir "$NPM_PREFIX"

  # Set npm prefix for this session too
  if have npm; then
    run npm config set prefix "$NPM_PREFIX"

    # Corepack gives pnpm/yarn stable installs when needed.
    # (Not required for these CLIs, but prevents "pnpm not found" future pain.)
    run corepack enable || true
  else
    die "npm not found even after Node setup"
  fi
}

fix_shell_profiles() {
  local block
  block="$(write_shell_block)"

  while IFS= read -r rc; do
    append_block_idempotent "$rc" "$block"
  done < <(resolve_shell_targets)
}

# ------------------------------ Installer helpers ----------------------------
install_npm_global() {
  # Usage: install_npm_global <package> <binary_name>
  local pkg="$1"
  local bin="$2"

  if have "$bin" && [[ $FORCE -eq 0 ]]; then
    log "OK: $bin already present"
    return 0
  fi

  log "Installing npm package: $pkg (bin: $bin)"
  run npm install -g "$pkg"
}

install_pipx_pkg() {
  # Usage: install_pipx_pkg <package> <binary>
  local pkg="$1"
  local bin="$2"

  if have "$bin" && [[ $FORCE -eq 0 ]]; then
    log "OK: $bin already present"
    return 0
  fi

  have pipx || die "pipx missing; cannot install $pkg"

  # If package exists and --force, reinstall.
  if [[ $FORCE -eq 1 ]]; then
    run pipx reinstall "$pkg" || run pipx install "$pkg"
  else
    run pipx install "$pkg"
  fi
}

validate_cmd() {
  local bin="$1"
  local verflag="${2:---version}"

  if ! have "$bin"; then
    log "FAIL: $bin not found on PATH"
    return 1
  fi

  # Some tools use --version, others -V.
  if "$bin" "$verflag" >/dev/null 2>&1; then
    log "PASS: $bin responds to $verflag"
    "$bin" "$verflag" 2>&1 | head -n 3 | tee -a "$LOG_FILE" >/dev/null || true
  else
    # Try a fallback
    if "$bin" -V >/dev/null 2>&1; then
      log "PASS: $bin responds to -V"
    else
      log "WARN: $bin found but version check failed (might require auth first)"
    fi
  fi
}

# ------------------------------ VS Code extensions ---------------------------
install_vscode_extension() {
  local ext_id="$1"
  have code || { log "VS Code 'code' CLI not found; skipping extension $ext_id"; return 0; }

  # If code is present, attempt to install.
  log "Installing VS Code extension: $ext_id"
  run code --install-extension "$ext_id" --force || true
}

# ------------------------------ Main ----------------------------------------
main() {
  : >"$LOG_FILE" || true
  log "Starting $SCRIPT_NAME"

  read_os_release
  log "Detected OS: id=$os_id like=$os_like"

  install_system_deps
  ensure_node_ok
  ensure_npm_prefix_configured
  fix_shell_profiles

  # Recompute PATH for current run too
  export NPM_CONFIG_PREFIX="$NPM_PREFIX"
  export PATH="$NPM_CONFIG_PREFIX/bin:$HOME/.local/bin:$PATH"

  # Install CLIs
  # OpenCode install options include curl script + npm; we standardize on npm here.
  install_npm_global "opencode-ai@latest" "opencode"
  install_npm_global "@google/gemini-cli" "gemini"
  install_npm_global "@openai/codex" "codex"
  install_npm_global "@qwen-code/qwen-code@latest" "qwen"
  install_npm_global "cline" "cline"
  install_npm_global "@kilocode/cli" "kilocode"

  install_pipx_pkg "aider-chat" "aider"

  # Optional VS Code extension installs (only if requested)
  if [[ $INSTALL_VSCODE_EXT -eq 1 ]]; then
    # Notes:
    #  - Roo Code is primarily a VS Code extension (not a CLI).
    #  - Cline and Kilo Code also have extensions.
    # Extension IDs can vary by marketplace; these are best-effort.
    # If you use VSCodium/OpenVSX, you may need manual install.

    # Roo Code (official docs describe marketplace search; extension id may vary)
    # We'll attempt both a likely marketplace ID and fall back gracefully.
    install_vscode_extension "RooVeterinaryInc.roo-code"

    # Cline extension (official repo is cline/cline; marketplace id commonly 'cline.cline')
    install_vscode_extension "cline.cline"

    # Kilo Code extension
    install_vscode_extension "kilo-code.kilo-code"
  fi

  # Validate
  log "Validating installs (PATH + basic version checks)"
  validate_cmd node --version || true
  validate_cmd npm --version || true

  validate_cmd opencode --version || true
  validate_cmd gemini --version || true
  validate_cmd codex --version || true
  validate_cmd qwen --version || true
  validate_cmd cline --version || true
  validate_cmd kilocode --version || true
  validate_cmd aider --version || true

  # Post-run guidance
  cat <<EOF | tee -a "$LOG_FILE" >&2

==============================================================================
DONE. Next steps (important):

1) Reload your shell so PATH updates apply:
   - Bash:  source ~/.bashrc
   - Zsh:   source ~/.zshrc
   (or just open a new terminal)

2) Quick smoke tests:
   opencode
   gemini
   codex
   qwen --version
   cline
   kilocode
   aider --help

3) If you still see "command not found" after sourcing rc files:
   echo "\$PATH" | tr ':' '\n' | nl | sed -n '1,40p'
   which -a opencode gemini codex qwen cline kilocode aider || true

Log:
  $LOG_FILE
==============================================================================
EOF

  log "All set. If any tool still fails, paste the last ~80 lines of $LOG_FILE and the output of: which -a <tool>"
}

main "$@"
