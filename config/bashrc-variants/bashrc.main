# shellcheck shell=bash
# Advanced modular bash profile
# Sets up directory-driven configuration, optional Oh My Bash, bash-it, and AI assistant hooks.

export BASHD_HOME="${BASHD_HOME:-$HOME/.bash.d}"
export BASHD_REPO_ROOT="${BASHD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export BASHD_STATE_DIR="$BASHD_HOME/state"
export BASHD_ENABLED_DIR="${BASHD_HOME}/enabled"

bashd_ensure_layout() {
  local dirs=(bash_aliases.d bash_functions.d bash_env.d bash_prompt.d bash_completions.d bash_secrets.d bash_history.d ai state bin enabled plugins aliases completions themes lib)
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

bashd_load_core_libs() {
  # Load core library functions first
  if [[ -d "${BASHD_REPO_ROOT}/lib" ]]; then
    for lib in "${BASHD_REPO_ROOT}/lib"/*.sh "${BASHD_REPO_ROOT}/lib"/*.bash; do
      # shellcheck disable=SC1090
      [[ -f "$lib" ]] && source "$lib"
    done
  fi
}

bashd_source_tree() {
  local dir
  for dir in bash_env.d bash_aliases.d bash_prompt.d bash_functions.d bash_completions.d; do
    if [[ -d "$BASHD_HOME/$dir" ]]; then
      for file in "$BASHD_HOME/$dir"/*.sh; do
        # shellcheck disable=SC1090
        [[ -f "$file" ]] && source "$file"
      done
    fi
  done
}

bashd_load_repo_modules() {
  # Load modules from repository (plugins, aliases, completions)
  # These are in the repo and provide the module system
  
  # Load from repo plugins directory
  if [[ -d "${BASHD_REPO_ROOT}/plugins" ]]; then
    for plugin in "${BASHD_REPO_ROOT}/plugins"/*.bash "${BASHD_REPO_ROOT}/plugins"/*.sh; do
      # shellcheck disable=SC1090
      [[ -f "$plugin" ]] && source "$plugin"
    done
  fi
  
  # Load from repo aliases directory
  if [[ -d "${BASHD_REPO_ROOT}/aliases" ]]; then
    for alias_file in "${BASHD_REPO_ROOT}/aliases"/*.bash "${BASHD_REPO_ROOT}/aliases"/*.sh; do
      # shellcheck disable=SC1090
      [[ -f "$alias_file" ]] && source "$alias_file"
    done
  fi
  
  # Load from repo completions directory
  if [[ -d "${BASHD_REPO_ROOT}/completions" ]]; then
    for completion in "${BASHD_REPO_ROOT}/completions"/*.bash "${BASHD_REPO_ROOT}/completions"/*.sh; do
      # shellcheck disable=SC1090
      [[ -f "$completion" ]] && source "$completion"
    done
  fi
  
  # Load from repo bash_functions.d with recursive sourcing
  if [[ -d "${BASHD_REPO_ROOT}/bash_functions.d" ]]; then
    # Load top-level function files first
    for func in "${BASHD_REPO_ROOT}/bash_functions.d"/*.sh; do
      # shellcheck disable=SC1090
      [[ -f "$func" ]] && source "$func"
    done
    
    # Then load from subdirectories
    for category_dir in "${BASHD_REPO_ROOT}/bash_functions.d"/*/; do
      if [[ -d "$category_dir" ]]; then
        for func in "${category_dir}"*.sh; do
          # shellcheck disable=SC1090
          [[ -f "$func" ]] && source "$func"
        done
      fi
    done
  fi
}

bashd_load_secrets() {
  local secrets
  for secrets in "$BASHD_HOME"/bash_secrets.d/*.sh "$BASHD_HOME"/bash_secrets.d/*.env; do
    # shellcheck disable=SC1090
    [[ -f "$secrets" ]] && source "$secrets"
  done
}

bashd_history_setup() {
  export HISTFILE="$BASHD_HOME/bash_history.d/.bash_history"
  export HISTSIZE=20000
  export HISTFILESIZE=40000
  shopt -s histappend
}

bashd_prompt_hook() {
  # Lightweight history sync
  history -a
}

bashd_maybe_use_oh_my_bash() {
  export OMB_DIR="${OMB_DIR:-$HOME/.oh-my-bash}"
  if [[ -d "$OMB_DIR" ]]; then
    export OSH_THEME="${OSH_THEME:-font}"
    # shellcheck disable=SC1091
    source "$OMB_DIR/oh-my-bash.sh"
  elif [[ -f "$BASHD_HOME/bash_functions.d/core.sh" ]]; then
    # Provide a helper to install without doing network work during shell startup
    :
  fi
}

bashd_init() {
  bashd_ensure_layout
  
  # Load core libraries first (includes module manager)
  bashd_load_core_libs
  
  # Initialize module system
  if type -t bashd_module_init &>/dev/null; then
    bashd_module_init
  fi
  
  # Check for bash-it integration
  if type -t bashd_init_bash_it &>/dev/null; then
    bashd_init_bash_it
  fi
  
  bashd_load_secrets
  bashd_history_setup
  bashd_maybe_use_oh_my_bash
  
  # Load user customizations from $BASHD_HOME
  bashd_source_tree
  
  # Load repository modules (plugins, aliases, completions, functions)
  bashd_load_repo_modules
  
  # Load enabled modules (if module system is active)
  if type -t bashd_module_load_enabled &>/dev/null; then
    bashd_module_load_enabled
  fi
  
  # Run AI healthcheck once at startup (non-blocking)
  if type -t bashd_ai_healthcheck &>/dev/null; then
    bashd_ai_healthcheck 2>/dev/null || true
  fi
  
  # Add lightweight prompt hook for history only
  PROMPT_COMMAND="bashd_prompt_hook; ${PROMPT_COMMAND:-}"
}

bashd_init
