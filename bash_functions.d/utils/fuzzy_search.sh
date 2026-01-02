#!/usr/bin/env bash
# Fuzzy search wrapper using ripgrep + fzf or python fallback

set -euo pipefail

_fsearch_log() { printf '[fsearch] %s\n' "$*" >&2; }

fsearch() {
  local query path
  query="$1"; path="${2:-.}"
  if command -v rg >/dev/null 2>&1; then
    if command -v fzf >/dev/null 2>&1; then
      rg --no-ignore-vcs -n --hidden --color never "$query" "$path" | fzf --ansi --phony
    else
      rg --no-ignore-vcs -n --hidden --color never "$query" "$path" | head -n 200
    fi
  else
    # fallback to grep
    grep -RIn --exclude-dir=.git --line-number --color=never "$query" "$path" | head -n 200
  fi
}

fsearch_inspect() {
  local file line
  file="$1"; line="${2:-1}"
  sed -n "$((line-5)),$((line+5))p" "$file"
}

