#!/usr/bin/env bash
# dotman - minimal dotfiles manager skeleton: add, encrypt (age/gpg), decrypt, push
set -euo pipefail

_dot_log() { printf '[dotman] %s\n' "$*" >&2; }

_dot_repo_dir="${HOME}/.dotfiles"
_dot_secrets_dir="$_dot_repo_dir/secrets"

dotman_init() {
  mkdir -p "$_dot_repo_dir" "$_dot_secrets_dir"
  git -C "$_dot_repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || git -C "$_dot_repo_dir" init
  _dot_log "Initialized dotfiles repo at $_dot_repo_dir"
}

dotman_add() {
  local src dest
  src="$1"; dest="${2:-$(basename "$src")}"
  mkdir -p "$_dot_repo_dir/dotfiles"
  cp -a "$src" "$_dot_repo_dir/dotfiles/$dest"
  (cd "$_dot_repo_dir" && git add -A && git commit -m "dotman: add $dest" )
  _dot_log "Added $src as $dest"
}

dotman_encrypt() {
  # dotman_encrypt <file> [--age <pubkey>] [--gpg <recip>]
  local file
  file="$1"; shift
  local method="age" pub=""
  while (("$#")); do
    case "$1" in
      --gpg) method=gpg; pub="$2"; shift 2;;
      --age) method=age; pub="$2"; shift 2;;
      *) shift;;
    esac
  done
  local out
  out="$_dot_secrets_dir/$(basename "$file").${method}.enc"
  if [[ "$method" == "age" ]]; then
    if ! command -v age >/dev/null 2>&1; then _dot_log "age missing"; return 3; fi
    age -r "$pub" -o "$out" "$file"
  else
    if ! command -v gpg >/dev/null 2>&1; then _dot_log "gpg missing"; return 4; fi
    gpg --output "$out" --encrypt --recipient "$pub" "$file"
  fi
  chmod 600 "$out"
  _dot_log "Encrypted $file -> $out"
}

dotman_decrypt() {
  local encfile out
  encfile="$1"; out="${2:-/tmp/$(basename -s .enc "$encfile")}"
  if [[ "$encfile" == *.age.enc ]]; then
    age -d -i ~/.config/something/age.key -o "$out" "$encfile" || { _dot_log "age decrypt failed"; return 3; }
  else
    gpg --output "$out" --decrypt "$encfile" || { _dot_log "gpg decrypt failed"; return 4; }
  fi
  chmod 600 "$out"
  _dot_log "Decrypted to $out"
}

# helper: commit secrets directory if changed
dotman_push() {
  local repo
  repo="$_dot_repo_dir"
  (cd "$repo" && git add -A && git commit -m "dotman: update" || true && git push || true)
}
