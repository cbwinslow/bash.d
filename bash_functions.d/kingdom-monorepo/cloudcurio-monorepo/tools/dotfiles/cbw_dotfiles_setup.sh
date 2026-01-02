#!/usr/bin/env bash
set -euo pipefail
SCRIPT_NAME="cbw_dotfiles_setup.sh"
LOG_FILE="/tmp/CBW-${SCRIPT_NAME}.log"
log(){ local level="$1"; shift; local msg="$*"; printf '[%s] %s\n' "$level" "$msg" | tee -a "$LOG_FILE"; }
main(){
  local target_dir="$HOME/dev/dotfiles"
  local repo_url="https://github.com/cbwinslow/cbw-dotfiles.git"
  mkdir -p "$(dirname "$target_dir")"
  if [[ -d "$target_dir/.git" ]]; then
    log INFO "Dotfiles repo already present, pulling updates..."
    git -C "$target_dir" pull --ff-only || log ERROR "Failed to pull; check manually."
  elif [[ -d "$target_dir" ]]; then
    log ERROR "Directory $target_dir exists but is not a git repo."
  else
    log INFO "Cloning dotfiles into $target_dir..."
    git clone "$repo_url" "$target_dir"
  fi
  log INFO "Dotfiles bootstrap complete."
}
main "$@"
