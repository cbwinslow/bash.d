#!/usr/bin/env bash
# Gather scripts from the filesystem, optionally rename (AI/heuristic), organize,
# and add them to a target repo folder. Supports copy or move.
#
# Key functions:
#   gather_scripts_copy --from <PATH> [--to <DIR>] [--pattern "*.sh"] [--ai] [--rename] [--organize]
#   gather_scripts_move --from <PATH> [--to <DIR>] [--pattern "*.sh"] [--ai] [--rename] [--organize]
#   organize_scripts_ai <DIR>
#   ai_suggest_name <FILE>
#   upload_gathered --src <DIR> --repo-path <SUBDIR> --msg "commit message" [--force]
#
# Notes:
# - AI rename uses OpenRouter if OPENROUTER_API_KEY is present. Falls back to heuristic.
# - Secrets are not sent: only file basename and a short summary (first lines sans content-like strings).
# - Uses gh_add_and_commit (from gh_helpers.sh) when available.

set -euo pipefail

_gs_log() { printf '[gather_scripts] %s\n' "$*" >&2; }

_gs_tmp() { mktemp -d 2>/dev/null || mktemp -d -t gs; }

_gs_is_script() {
  # returns 0 if a file looks like a script
  local f="$1"
  [[ -f "$f" ]] || return 1
  if [[ "$f" == *.sh ]] || head -n1 "$f" 2>/dev/null | grep -qE '^#!.*/(bash|sh|zsh|python|node|env)'; then
    return 0
  fi
  return 1
}

_gs_safe_summary() {
  # Produce a short, safe summary without long tokens
  local f="$1"
  # Take first 20 lines, strip lines with likely secrets/long tokens
  head -n 20 "$f" 2>/dev/null \
    | sed -E 's/[A-Za-z0-9_\-]{32,}/[REDACTED]/g' \
    | awk 'length($0) < 240' \
    | sed -E 's/(password|secret|token|key)=.*/\1=[REDACTED]/Ig'
}

ai_suggest_name() {
  # ai_suggest_name <file>
  # Outputs a suggested basename (without path). Falls back to heuristic.
  local f="$1"
  local base ext
  base=$(basename "$f")
  ext="${base##*.}"
  [[ "$ext" == "$base" ]] && ext="sh" # default

  if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
    local prompt summary model
    model="qwen/qwen-2.5-coder:32b-instruct" # small and coding-focused
    summary=$(_gs_safe_summary "$f" | tail -n +1)
    prompt="You are to propose a concise, kebab-case filename for a script based on summary lines. Reply with only the filename stem without extension. Example: 'docker-clean' or 'git-sync-all'. Summary:\n${summary}\nCurrent name: ${base}\nReturn only the name, no quotes, max 5 words."
    local resp name
    resp=$(curl -sS https://openrouter.ai/api/v1/chat/completions \
      -H "Authorization: Bearer ${OPENROUTER_API_KEY}" \
      -H 'Content-Type: application/json' \
      -d "{\"model\":\"${model}\",\"messages\":[{\"role\":\"user\",\"content\":$(printf %s "$prompt" | jq -Rs .)}],\"max_tokens\":24}") || true
    name=$(printf '%s' "$resp" | jq -r '.choices[0].message.content' 2>/dev/null | head -n1 | tr ' A-Z' '-a-z' | tr -cd 'a-z0-9-') || true
    if [[ -n "${name:-}" ]]; then
      printf '%s.%s\n' "$name" "$ext"
      return 0
    fi
  fi
  # Heuristic fallback: use first comment words or shebang
  local shebang first_comment stem
  shebang=$(head -n1 "$f" 2>/dev/null | sed -E 's/^#!.*\/(\w+).*/\1/')
  first_comment=$(grep -m1 -E '^[#;].{6,}' "$f" 2>/dev/null | sed -E 's/^[#;]+\s*//')
  stem=$(printf '%s %s' "$shebang" "$first_comment" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9 \-_' | sed -E 's/\s+/-/g' | awk -F- '{print $1"-"$2"-"$3}' | sed -E 's/-+$//')
  [[ -z "$stem" ]] && stem="script"
  printf '%s.%s\n' "$stem" "$ext"
}

_gs_ensure_dir() { mkdir -p "$1"; }

_gs_copy_or_move() {
  # _gs_copy_or_move copy|move from_dir to_dir pattern do_rename do_organize
  local mode from to pattern do_rename do_org
  mode="$1"; from="$2"; to="$3"; pattern="$4"; do_rename="$5"; do_org="$6"
  _gs_ensure_dir "$to"
  local files tmp
  tmp=$(_gs_tmp)
  # Find candidates
  if [[ -n "$pattern" ]]; then
    find "$from" -type f -name "$pattern" >"$tmp/files" 2>/dev/null || true
  else
    find "$from" -type f -print0 2>/dev/null | xargs -0 -I{} bash -c '[[ -f "$1" ]] && head -n1 "$1" 2>/dev/null | grep -q "^#!" && echo "$1"' _ {} >"$tmp/files" || true
  fi

  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    _gs_is_script "$f" || continue
    local dest_name
    if [[ "$do_rename" == "1" ]]; then
      dest_name=$(ai_suggest_name "$f")
    else
      dest_name=$(basename "$f")
    fi
    local dest="$to/$dest_name"
    if [[ "$mode" == "copy" ]]; then
      cp -v "$f" "$dest" >&2 || true
    else
      mv -v "$f" "$dest" >&2 || true
    fi
    chmod u+rw,go-rwx "$dest" 2>/dev/null || true
  done <"$tmp/files"

  if [[ "$do_org" == "1" ]]; then
    organize_scripts_ai "$to"
  fi
}

gather_scripts_copy() {
  local from to pattern ai rename organize
  from="${1:-}"; [[ "$from" == "--from" ]] && { from="$2"; shift 2; } || true
  to=".gathered"; pattern="*.sh"; ai=0; rename=0; organize=0
  while (("$#")); do
    case "$1" in
      --from) from="$2"; shift 2 ;;
      --to) to="$2"; shift 2 ;;
      --pattern) pattern="$2"; shift 2 ;;
      --ai) ai=1; shift ;;
      --rename) rename=1; shift ;;
      --organize) organize=1; shift ;;
      *) shift ;;
    esac
  done
  [[ -n "$from" ]] || { _gs_log "--from required"; return 2; }
  _gs_copy_or_move copy "$from" "$to" "$pattern" "$rename" "$organize"
}

gather_scripts_move() {
  local from to pattern ai rename organize
  from="${1:-}"; [[ "$from" == "--from" ]] && { from="$2"; shift 2; } || true
  to=".gathered"; pattern="*.sh"; ai=0; rename=0; organize=0
  while (("$#")); do
    case "$1" in
      --from) from="$2"; shift 2 ;;
      --to) to="$2"; shift 2 ;;
      --pattern) pattern="$2"; shift 2 ;;
      --ai) ai=1; shift ;;
      --rename) rename=1; shift ;;
      --organize) organize=1; shift ;;
      *) shift ;;
    esac
  done
  [[ -n "$from" ]] || { _gs_log "--from required"; return 2; }
  _gs_copy_or_move move "$from" "$to" "$pattern" "$rename" "$organize"
}

organize_scripts_ai() {
  # organize scripts into subfolders by content keywords (heuristic to avoid sending code)
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  local f topic sub
  for f in "$dir"/*; do
    [[ -f "$f" ]] || continue
    topic=$(head -n 30 "$f" 2>/dev/null | tr 'A-Z' 'a-z')
    sub="misc"
    grep -qE 'docker|container|compose' <<<"$topic" && sub=docker
    grep -qE '\bkubectl|k8s|kube' <<<"$topic" && sub=k8s
    grep -qE '\bgit\b|github|gitlab' <<<"$topic" && sub=git
    grep -qE 'aws|gcloud|azure' <<<"$topic" && sub=cloud
    grep -qE 'network|port|tcp|udp|ping' <<<"$topic" && sub=net
    mkdir -p "$dir/$sub"
    mv -n "$f" "$dir/$sub/" 2>/dev/null || true
  done
}

upload_gathered() {
  # upload_gathered --src <DIR> --repo-path <SUBDIR> --msg "message" [--force]
  local src path msg force=0
  while (("$#")); do
    case "$1" in
      --src) src="$2"; shift 2 ;;
      --repo-path) path="$2"; shift 2 ;;
      --msg) msg="$2"; shift 2 ;;
      --force) force=1; shift ;;
      *) shift ;;
    esac
  done
  [[ -n "${src:-}" && -n "${path:-}" && -n "${msg:-}" ]] || { _gs_log "--src/--repo-path/--msg required"; return 2; }
  local f
  for f in "$src"/**; do
    [[ -f "$f" ]] || continue
    if command -v gh_add_and_commit >/dev/null 2>&1; then
      gh_add_and_commit "$f" --path "$path" --msg "$msg" ${force:+--force} || true
    else
      # fallback: plain git add/commit at repo root
      local repo
      repo=$(git rev-parse --show-toplevel 2>/dev/null || true)
      [[ -n "$repo" ]] || { _gs_log "not inside a git repo"; return 3; }
      mkdir -p "$repo/$path"
      cp -v "$f" "$repo/$path/" >&2
      (cd "$repo" && git add "$path/$(basename "$f")" && git commit -m "$msg") || true
    fi
  done
}
