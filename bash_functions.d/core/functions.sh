# Common shell functions for bash_functions.d

# source this file from your ~/.bashrc to get helpers

# safe cd and list
cdf() { mkdir -p "$1" && cd "$1" || return $?; }

# quick add and commit for repo root
bf_add_commit() {
  msg=${1:-"chore: update from local"}
  git add --all && git commit -m "$msg" || echo "nothing to commit"
}

# open editor on a file creating parent dir
bf_edit() {
  file="$1"
  mkdir -p "$(dirname "$file")"
  ${EDITOR:-vi} "$file"
}

# secrets tool wrapper placeholder (uses bw cli)
bf_secret_get() {
  if ! command -v bw >/dev/null 2>&1; then
    echo "bw CLI not installed"
    return 1
  fi
  name="$1"
  if [[ -z "$name" ]]; then echo "usage: bf_secret_get <name>"; return 2; fi
  # unlock session if necessary
  if [[ -z "${BW_SESSION:-}" ]]; then
    echo "No BW_SESSION found; unlocking interactively"
    BW_SESSION=$(bw unlock --raw)
    export BW_SESSION
  fi
  bw get password "$name" 2>/dev/null || bw get item "$name" 2>/dev/null
}

# fuzzy search in repo files (ripgrep if available)
bf_find() {
  pattern="$1"
  if command -v rg >/dev/null 2>&1; then
    rg --hidden -S "$pattern" || true
  else
    grep -RIn --exclude-dir=.git --exclude-dir=node_modules "$pattern" . || true
  fi
}
