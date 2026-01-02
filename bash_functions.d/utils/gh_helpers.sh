#!/usr/bin/env bash
# GitHub/git helpers: add and commit files into repo, with safety checks

set -euo pipefail

_gh_log() { printf '[gh_helpers] %s\n' "$*" >&2; }

_gh_repo_root() {
  local d
  d="$(pwd)"
  while [[ "$d" != "/" && -n "$d" ]]; do
    if [[ -d "$d/.git" ]]; then
      printf '%s' "$d"
      return 0
    fi
    d=$(dirname "$d")
  done
  return 1
}

_gh_scan_for_secrets() {
  # simple heuristic: high-entropy strings or common secret names
  local file
  file="$1"
  # deny if AWS_SECRET or PRIVATE_KEY or long base64-like strings
  if grep -E -n "(AWS_SECRET|AWS_SECRET_ACCESS_KEY|PRIVATE_KEY|SECRET_KEY|BEGIN RSA PRIVATE KEY|BEGIN PRIVATE KEY)" "$file" >/dev/null 2>&1; then
    return 1
  fi
  # entropy check: base64-like long strings
  if grep -E -n "[A-Za-z0-9_\-]{40,}" "$file" >/dev/null 2>&1; then
    return 2
  fi
  return 0
}

gh_add_and_commit() {
  # gh_add_and_commit <srcfile> --msg "message" --path subdir [--force]
  local src msg path force=0
  src="$1"; shift
  while (("$#")); do
    case "$1" in
      --msg) msg="$2"; shift 2;;
      --path) path="$2"; shift 2;;
      --force) force=1; shift;;
      *) shift;;
    esac
  done
  if [[ -z "${msg:-}" || -z "${path:-}" ]]; then
    _gh_log "--msg and --path required"; return 2
  fi
  if [[ ! -f "$src" ]]; then
    _gh_log "src file not found: $src"; return 3
  fi
  local repo
  repo=$(_gh_repo_root) || { _gh_log "Not inside a git repo"; return 4; }
  local destdir
  destdir="$repo/$path"
  mkdir -p "$destdir"
  cp -v "$src" "$destdir/"
  local dest
  dest="$destdir/$(basename "$src")"
  # scan for secrets
  _gh_scan_for_secrets "$dest"
  local scanres=$?
  if [[ $scanres -ne 0 && $force -eq 0 ]]; then
    _gh_log "Refusing to commit file; sensitive content detected (scan code $scanres). Use --force to override.";
    rm -f "$dest";
    return 5
  fi
  (cd "$repo" && git add -A "$path" && git commit -m "$msg")
  _gh_log "Committed $dest to repo"
}
