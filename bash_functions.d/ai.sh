# shellcheck shell=bash
# AI agent wrappers for bash.d

bashd_ai_healthcheck() {
  local missing=()
  [[ -z "$OPENROUTER_API_KEY" ]] && missing+=("OPENROUTER_API_KEY")
  command -v python3 >/dev/null 2>&1 || missing+=("python3")
  if (( ${#missing[@]} > 0 )); then
    echo "AI prerequisites missing: ${missing[*]}" >&2
    return 1
  fi
  return 0
}

_bashd_ai_chat_wrapper() {
    local mode="$1"
    shift
    bashd_ai_healthcheck || return 1
    python3 "$BASHD_REPO_ROOT/ai/agent.py" chat --mode "$mode" "$*"
}

bashd_ai_chat() {

}

bashd_ai_publish_function() {
  bashd_ai_healthcheck || return 1
  local fn="$1"
  if [[ -z "$fn" ]]; then
    echo "Usage: bashd_ai_publish_function <function-name>" >&2
    return 1
  fi
  local body
  body=$(declare -f "$fn")
  if [[ -z "$body" ]]; then
    echo "Function $fn not found" >&2
    return 1
  fi
  python3 "$BASHD_REPO_ROOT/ai/agent.py" publish-function "$fn" "$body"
}

bashd_ai_reward() {
  # Lightweight reinforcement hook: append reinforcement signal for offline tuning
  local signal="${1:-positive}"
  echo "Reinforcement: $signal" >> "$BASHD_STATE_DIR/logs/reinforcement.log"
}

# Explain the last command that was run
bashd_ai_explain_last() {
  bashd_ai_healthcheck || return 1
  local last_cmd
  last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')
  if [[ -z "$last_cmd" ]]; then
    echo "No previous command found" >&2
    return 1
  fi
  bashd_ai_tldr "Explain what this command does: $last_cmd"
}

# Suggest a fix for an error in the last command
bashd_ai_fix() {
  bashd_ai_healthcheck || return 1
  local error_output="$1"
  local last_cmd
  last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')
  if [[ -z "$error_output" ]]; then
    echo "Usage: bashd_ai_fix '<error message>'" >&2
    return 1
  fi
  bashd_ai_debug "$(printf 'Command: %s\n\nError: %s\n\nSuggest a fix.' "$last_cmd" "$error_output")"
}

# Generate a bash function from a description
bashd_ai_generate_function() {
  bashd_ai_healthcheck || return 1
  local description="$1"
  local name="${2:-my_function}"
  if [[ -z "$description" ]]; then
    echo "Usage: bashd_ai_generate_function '<description>' [function_name]" >&2
    return 1
  fi
  bashd_ai_code "Generate a bash function named '$name' that: $description. Include proper error handling and documentation comments."
}

# Show available AI commands
bashd_ai_help() {
  cat << 'EOF'
bashd AI agent commands:

  bashd_ai_chat <prompt>       - General chat with AI assistant
  bashd_ai_debug <prompt>      - Debug assistance for shell issues
  bashd_ai_tldr <prompt>       - Get concise command explanations
  bashd_ai_code <prompt>       - Generate code snippets
  bashd_ai_explain_last        - Explain the last command you ran
  bashd_ai_fix '<error>'       - Get suggestions to fix an error
  bashd_ai_generate_function '<desc>' [name]  - Generate a bash function
  bashd_ai_publish_function <fn>  - Publish a function to a repo
  bashd_ai_reward [signal]     - Log reinforcement feedback
  bashd_ai_healthcheck         - Check AI prerequisites
  bashd_ai_help                - Show this help message

Environment variables:
  OPENROUTER_API_KEY  - Required for AI interactions
  BASHD_AI_MODEL      - Model to use (default: openrouter/auto)
EOF
}

# Show recent AI interaction logs
bashd_ai_history() {
  local count="${1:-5}"
  local log
  if [[ -d "$BASHD_STATE_DIR/logs" ]]; then
    while read -r log; do
      echo "=== $(basename "$log") ==="
      head -n 20 "$log"
      echo ""
    done < <(find "$BASHD_STATE_DIR/logs" -name 'ai-*.md' -type f | sort -r | head -n "$count")
  else
    echo "No AI interaction logs found" >&2
  fi
}
