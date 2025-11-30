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
  _bashd_ai_chat_wrapper "chat" "$@"
}

bashd_ai_debug() {
  _bashd_ai_chat_wrapper "debug" "$@"
}

bashd_ai_tldr() {
  _bashd_ai_chat_wrapper "tldr" "$@"
}

bashd_ai_code() {
  _bashd_ai_chat_wrapper "code" "$@"
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
