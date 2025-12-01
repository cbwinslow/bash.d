# shellcheck shell=bash
# Core helpers for bash.d

bashd_install_oh_my_bash() {
  local target="${OMB_DIR:-$HOME/.oh-my-bash}"
  if [[ -d "$target" ]]; then
    echo "Oh My Bash already present at $target"
    return 0
  fi
  if ! command -v git >/dev/null 2>&1; then
    echo "git is required to install Oh My Bash" >&2
    return 1
  fi
  if git clone https://github.com/ohmybash/oh-my-bash.git "$target"; then
    echo "Oh My Bash installed at $target"
    return 0
  else
    echo "Failed to install Oh My Bash at $target" >&2
    return 1
  fi
}

bashd_edit_local() {
  ${EDITOR:-vi} "$@"
}

bashd_reload() {
  # shellcheck disable=SC1090
  source "$BASHD_HOME/bashrc"
}

bashd_snapshot_state() {
  local snapshot
  snapshot="$BASHD_STATE_DIR/logs/state-$(date -u +"%Y%m%dT%H%M%SZ").txt"
  {
    echo "BASHD_HOME=$BASHD_HOME"
    echo "BASH_VERSION=$BASH_VERSION"
    echo "Loaded functions: $(compgen -A function | tr '\n' ' ')"
  } > "$snapshot"
  echo "State snapshot stored at $snapshot"
}
