#!/usr/bin/env bash
# deploy_to_github.sh
# Package and push the bash_functions.d tree to GitHub repo `cbwinslow/bash.d`.
# Safe by default: run with --dry-run (default) to preview. Add --push to actually push.

set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [--remote GITURL] [--branch BRANCH] [--message MSG] [--push] [--src DIR] [--no-scan] [--force]

Options:
  --remote    git remote URL (default: git@github.com:cbwinslow/bash.d.git)
  --branch    branch name to push (default: main)
  --message   commit message (default: "chore: update bash.d from local bash_functions.d")
  --push      actually push to the remote (default: dry-run)
  --src       source directory to copy (default: current dir)
  --no-scan   skip pre-push secrets scan (off by default)
  --force     force push even if scan finds potential secrets
  -h, --help  show this help

Examples:
  # preview what would be done
  ./deploy_to_github.sh --src ~/bash_functions.d

  # actually create repo (with gh) and push
  ./deploy_to_github.sh --src ~/bash_functions.d --push
EOF
}

REMOTE="git@github.com:cbwinslow/bash.d.git"
BRANCH="main"
MSG="chore: update bash.d from local bash_functions.d"
PUSH=0
SRC_DIR="$(pwd)"
DO_SCAN=1
FORCE=0

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote) REMOTE="$2"; shift 2;;
    --branch) BRANCH="$2"; shift 2;;
    --message) MSG="$2"; shift 2;;
    --push) PUSH=1; shift;;
    --src) SRC_DIR="$2"; shift 2;;
    --no-scan) DO_SCAN=0; shift;;
    --force) FORCE=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

echo "deploy_to_github: src=$SRC_DIR remote=$REMOTE branch=$BRANCH push=$PUSH scan=$DO_SCAN force=$FORCE"

# checks
command -v git >/dev/null 2>&1 || { echo "git not found" >&2; exit 1; }

# prepare temp workspace
TMPROOT=$(mktemp -d)
cleanup() { rm -rf "$TMPROOT"; }
trap cleanup EXIT

DST="$TMPROOT/bash.d"
mkdir -p "$DST"

echo "Copying files from $SRC_DIR to $DST (excluding .git and docs/man)"
rsync -av --exclude='.git' --exclude='docs/man' --exclude='node_modules' --exclude='.DS_Store' "$SRC_DIR/" "$DST/" >/dev/null

# pre-push secrets scan function
scan_for_secrets() {
  local path="$1"
  local hits=0
  echo "Running secrets scan on $path ..."
  # Patterns to scan for; add more as needed
  declare -a patterns=(
    "AKIA[0-9A-Z]{16}"
    "ASIA[0-9A-Z]{16}"
    "A3T[A-Z0-9]{16}"
    "AIza[0-9A-Za-z_-]{35}"
    "(?i)aws_secret_access_key"
    "(?i)secret[_-]?(key|token|access|)"
    "-----BEGIN (RSA |OPENSSH |)PRIVATE KEY-----"
    "(?i)password\s*[:=]"
    "(?i)api[_-]?key\s*[:=]"
    "(?i)client_secret"
    "(?i)oauth[_-]?token"
  )

  # Use grep -P if available; fall back to basic grep
  local grep_cmd="grep -RIn"
  if command -v grep >/dev/null 2>&1 && grep -P "" <(printf '') 2>/dev/null; then
    grep_cmd="grep -RPn"
  fi

  for pat in "${patterns[@]}"; do
    if [[ "$grep_cmd" == "grep -RPn" ]]; then
      # perl regex
      hits_found=$(grep -RPn --exclude-dir=.git --exclude=docs --exclude=node_modules --binary-files=without-match -e "$pat" "$path" || true)
    else
      # basic grep without lookups; search for literal tokens if complex not supported
      # simplify pattern for basic grep
      simple=$(echo "$pat" | sed 's/\\\|\[.*\]//g' | sed 's/[^a-zA-Z0-9_\-]/ /g' | awk '{print $1}' )
      hits_found=$(grep -RIn --exclude-dir=.git --exclude=docs --exclude=node_modules --binary-files=without-match -e "$simple" "$path" || true)
    fi
    if [[ -n "$hits_found" ]]; then
      echo "Potential secret matches for pattern: $pat"
      echo "$hits_found" | sed -n '1,200p'
      hits=$((hits+1))
    fi
  done

  return $hits
}

# run scan if enabled
REPORT="$HOME/.bash_functions.d/deploy_scan_report.txt"
if [[ $DO_SCAN -eq 1 ]]; then
  # capture scan output
  scan_out=$(mktemp)
  if scan_for_secrets "$DST" > "$scan_out" 2>&1; then
    scan_result=0
  else
    scan_result=1
  fi
  if [[ -s "$scan_out" ]]; then
    # write report
    mkdir -p "$HOME/.bash_functions.d"
    printf "Secrets scan report generated at %s\n\n" "$(date -u)" > "$REPORT"
    cat "$scan_out" >> "$REPORT"
  fi
  if [[ $scan_result -ne 0 ]]; then
    echo "Secrets scan found potential issues (see $REPORT)."
    if [[ $FORCE -eq 1 ]]; then
      echo "--force provided; continuing despite findings. Be cautious."
    else
      echo "Aborting deploy. Inspect the report at $REPORT to review findings. Re-run with --force to override or fix secrets first."
      exit 3
    fi
  else
    echo "Secrets scan passed (no obvious matches)."
    # remove report if empty
    [[ -f "$REPORT" && ! -s "$REPORT" ]] && rm -f "$REPORT" || true
  fi
else
  echo "Secrets scan skipped (--no-scan)."
fi

pushd "$TMPROOT" >/dev/null

# initialize git
if [[ ! -d "$DST/.git" ]]; then
  git -C "$DST" init -b "$BRANCH"
fi

git -C "$DST" add --all
git -C "$DST" commit -m "$MSG" || echo "No changes to commit"

# check remote
REMOTE_NAME=origin
if git -C "$DST" remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
  echo "Remote $REMOTE_NAME already set"
else
  if command -v gh >/dev/null 2>&1 && [[ $PUSH -eq 1 ]]; then
    echo "Attempting to create remote repo via gh: $REMOTE"
    # try to extract owner/repo from REMOTE
    if [[ "$REMOTE" =~ :([^/]+)/([^/.]+)(\.git)?$ ]]; then
      OWNER=${BASH_REMATCH[1]}
      REPO=${BASH_REMATCH[2]}
      echo "Creating github repo $OWNER/$REPO via gh"
      gh repo create "$OWNER/$REPO" --private --confirm || true
    fi
    git -C "$DST" remote add "$REMOTE_NAME" "$REMOTE"
  else
    echo "Setting remote to $REMOTE (no gh create attempted)"
    git -C "$DST" remote add "$REMOTE_NAME" "$REMOTE" || true
  fi
fi

# preview what will be pushed
echo "\nPreview: git -C $DST log --oneline -n 5"
git -C "$DST" --no-pager log --oneline -n 5 || true

echo "\nPreview: git -C $DST remote -v"
git -C "$DST" remote -v || true

if [[ $PUSH -eq 1 ]]; then
  echo "Pushing to $REMOTE_NAME $BRANCH..."
  git -C "$DST" push -u "$REMOTE_NAME" "$BRANCH"
  echo "Push complete."
else
  echo "Dry-run only. To push changes, re-run with --push."
fi

popd >/dev/null

# final note
echo "Temporary working tree was: $TMPROOT (removed on exit)."
if [[ $PUSH -eq 0 ]]; then
  echo "Run with --push to actually push to GitHub. Ensure your SSH key or gh auth is set up."
fi

