# Advanced modular bash profile
# Sets up directory-driven configuration, optional Oh My Bash, and AI assistant hooks.

export BASHD_HOME="${BASHD_HOME:-$HOME/.bash.d}"
export BASHD_REPO_ROOT="${BASHD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export BASHD_STATE_DIR="$BASHD_HOME/state"

bashd_ensure_layout() {
  local dirs=(bash_aliases.d bash_functions.d bash_env.d bash_prompt.d bash_completions.d bash_secrets.d bash_history.d ai state bin)
  for dir in "${dirs[@]}"; do
    mkdir -p "$BASHD_HOME/$dir"
  done
  mkdir -p "$BASHD_STATE_DIR/logs"
  if [[ ! -f "$BASHD_HOME/bash_history.d/.gitignore" ]]; then
    echo "*" > "$BASHD_HOME/bash_history.d/.gitignore"
  fi
  if [[ ! -f "$BASHD_HOME/bash_secrets.d/.gitignore" ]]; then
    echo "*" > "$BASHD_HOME/bash_secrets.d/.gitignore"
  fi
}

bashd_source_tree() {
  local dir
  for dir in bash_env.d bash_aliases.d bash_prompt.d bash_functions.d bash_completions.d; do
    if [[ -d "$BASHD_HOME/$dir" ]]; then
      for file in "$BASHD_HOME/$dir"/*.sh; do
        [[ -f "$file" ]] && source "$file"
      done
    fi
  done
}

bashd_load_secrets() {
  local secrets
  for secrets in "$BASHD_HOME"/bash_secrets.d/*.sh "$BASHD_HOME"/bash_secrets.d/*.env; do
    [[ -f "$secrets" ]] && source "$secrets"
  done
}

bashd_history_setup() {
  export HISTFILE="$BASHD_HOME/bash_history.d/.bash_history"
  export HISTSIZE=20000
  export HISTFILESIZE=40000
  shopt -s histappend
}

bashd_enable_self_heal() {
  if ! command -v bashd-self-heal >/dev/null 2>&1; then
    function bashd-self-heal() {
      bashd_ensure_layout
      if [[ -f "$BASHD_HOME/bash_functions.d/ai.sh" ]]; then
        bashd_ai_healthcheck
      fi
      [[ -f "$BASHD_HOME/bash_functions.d/core.sh" ]] && :
    }
  fi
  PROMPT_COMMAND="bashd-self-heal; $PROMPT_COMMAND"
}

bashd_maybe_use_oh_my_bash() {
  export OMB_DIR="${OMB_DIR:-$HOME/.oh-my-bash}"
  if [[ -d "$OMB_DIR" ]]; then
    export OSH_THEME="${OSH_THEME:-font}"
    source "$OMB_DIR/oh-my-bash.sh"
  elif [[ -f "$BASHD_HOME/bash_functions.d/core.sh" ]]; then
    # Provide a helper to install without doing network work during shell startup
    :
  fi
}

bashd_init() {
  bashd_ensure_layout
  bashd_load_secrets
  bashd_history_setup
  bashd_maybe_use_oh_my_bash
  bashd_source_tree
  bashd_enable_self_heal
}

bashd_init
