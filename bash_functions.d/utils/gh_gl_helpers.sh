#!/usr/bin/env bash
# GitHub and GitLab helpers: auth env helpers, API wrappers, listing, mass ops,
# and mirror functions to sync repos across GitHub <-> GitLab.
#
# Functions (high level):
#   gh_token_set <TOKEN>                      # export GH_TOKEN safely
#   gl_token_set <TOKEN> [--host gitlab.com]  # export GITLAB_TOKEN and GITLAB_HOST
#   gh_api <endpoint> [jq-filter]
#   gl_api <endpoint> [jq-filter]
#   gh_list_repos_user <user>
#   gh_list_repos_org <org>
#   gl_list_projects_user <username>
#   gl_list_group_projects <group_path>
#   gh_for_each_repo <user|org> -- run '<cmd>' [--archive] [--visibility public|private|all]
#   mirror_github_to_gitlab <gh_user_or_org> <gl_namespace> [--host gitlab.com]
#   mirror_gitlab_to_github <gl_namespace> <gh_user_or_org> [--host gitlab.com]
#
# Notes:
# - Requires jq and git. gh CLI is optional; falls back to curl.
# - Tokens are read from GH_TOKEN (or GITHUB_TOKEN) and GITLAB_TOKEN.
# - For GitLab self-hosted, set GITLAB_HOST or pass --host.

set -euo pipefail

_gg_log() { printf '[gh_gl_helpers] %s\n' "$*" >&2; }

gh_token_set() {
  local t="$1"
  [[ -n "$t" ]] || { _gg_log "token required"; return 2; }
  export GH_TOKEN="$t"
  export GITHUB_TOKEN="$t"
  _gg_log "GH token set in env (GH_TOKEN/GITHUB_TOKEN)"
}

gl_token_set() {
  local t host="${GITLAB_HOST:-gitlab.com}"
  t="$1"; shift || true
  while ((${#})); do
    case "$1" in
      --host) host="$2"; shift 2;;
      *) shift;;
    esac
  done
  [[ -n "$t" ]] || { _gg_log "token required"; return 2; }
  export GITLAB_TOKEN="$t"
  export GITLAB_HOST="$host"
  _gg_log "GitLab token set for host $host"
}

_gh_api_curl() {
  local ep="$1"; shift || true
  local url="https://api.github.com${ep}"
  curl -fsSL "$url" \
    -H "Authorization: Bearer ${GH_TOKEN:-${GITHUB_TOKEN:-}}" \
    -H 'Accept: application/vnd.github+json'
}

gh_api() {
  local ep="$1"; shift || true
  local filter="${1:-}"
  if command -v gh >/dev/null 2>&1; then
    if [[ -n "$filter" ]]; then
      gh api "$ep" --paginate | jq -r "$filter"
    else
      gh api "$ep" --paginate
    fi
  else
    if [[ -n "$filter" ]]; then
      _gh_api_curl "$ep" | jq -r "$filter"
    else
      _gh_api_curl "$ep"
    fi
  fi
}

gl_api() {
  local ep="$1"; shift || true
  local filter="${1:-}"
  local host="${GITLAB_HOST:-gitlab.com}"
  local url="https://${host}/api/v4${ep}"
  if [[ -n "$filter" ]]; then
    curl -fsSL "$url" -H "PRIVATE-TOKEN: ${GITLAB_TOKEN:-}" | jq -r "$filter"
  else
    curl -fsSL "$url" -H "PRIVATE-TOKEN: ${GITLAB_TOKEN:-}"
  fi
}

gh_list_repos_user() { gh_api "/users/$1/repos?per_page=100&type=all" '.[] | .full_name'; }
gh_list_repos_org()  { gh_api "/orgs/$1/repos?per_page=100&type=all"  '.[] | .full_name'; }

gl_list_projects_user() {
  local u="$1"
  gl_api "/users?username=${u}" '.[0].id' | xargs -I{} bash -c 'gl_api "/users/{}/projects?per_page=100" ".[] | .path_with_namespace"'
}

gl_list_group_projects() {
  local g="$1"
  local enc
  enc=$(python3 - <<PY 2>/dev/null || echo "$g"
import urllib.parse,sys
print(urllib.parse.quote(sys.argv[1], safe=""))
PY
"$g")
  gl_api "/groups/${enc}/projects?per_page=100" '.[] | .path_with_namespace'
}

gh_for_each_repo() {
  # gh_for_each_repo <user|org> -- run '<command>' [--visibility ...] [--archive]
  local who cmd vis="all" include_archived=0
  who="$1"; shift
  [[ "$1" == "--" ]] && shift
  [[ "$1" == "run" ]] && shift
  cmd="$1"; shift || true
  while ((${#})); do
    case "$1" in
      --visibility) vis="$2"; shift 2;;
      --archive) include_archived=1; shift;;
      *) shift;;
    esac
  done
  local tmp; tmp=$(mktemp -d)
  local repos
  repos=$(gh_list_repos_org "$who" 2>/dev/null || gh_list_repos_user "$who" 2>/dev/null || true)
  [[ -n "$repos" ]] || { _gg_log "No repos found for $who"; return 0; }
  while IFS= read -r full; do
    [[ -n "$full" ]] || continue
    _gg_log "Processing $full"
    (cd "$tmp" && rm -rf repo && git clone --depth 1 "https://github.com/${full}.git" repo >/dev/null 2>&1 || true
      cd repo 2>/dev/null || exit 0
      bash -lc "$cmd")
  done <<<"$repos"
}

_gg_git_mirror_push() {
  # _gg_git_mirror_push <source_git_url> <dest_git_url>
  local src="$1" dst="$2"
  local tmp; tmp=$(mktemp -d)
  (cd "$tmp" && git clone --mirror "$src" mirror && cd mirror && git remote add dest "$dst" && git push --mirror dest)
}

mirror_github_to_gitlab() {
  # mirror_github_to_gitlab <gh_user_or_org> <gl_namespace> [--host gitlab.com]
  local gh_ns gl_ns host="${GITLAB_HOST:-gitlab.com}"
  gh_ns="$1"; gl_ns="$2"; shift 2 || true
  while ((${#})); do
    case "$1" in
      --host) host="$2"; shift 2;;
      *) shift;;
    esac
  done
  local repos
  repos=$(gh_list_repos_org "$gh_ns" 2>/dev/null || gh_list_repos_user "$gh_ns" 2>/dev/null)
  [[ -n "$repos" ]] || { _gg_log "No GitHub repos for $gh_ns"; return 2; }
  local gh_pat="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
  local gl_pat="${GITLAB_TOKEN:-}"
  [[ -n "$gl_pat" ]] || { _gg_log "GITLAB_TOKEN required"; return 3; }
  while IFS= read -r full; do
    [[ -n "$full" ]] || continue
    local name; name=$(basename "$full")
    local src dst
    if [[ -n "$gh_pat" ]]; then
      src="https://${gh_pat}@github.com/${full}.git"
    else
      src="https://github.com/${full}.git"
    fi
    dst="https://oauth2:${gl_pat}@${host}/${gl_ns}/${name}.git"
    _gg_log "Mirroring ${full} -> ${gl_ns}/${name}"
    _gg_git_mirror_push "$src" "$dst" || _gg_log "Failed mirror for $full"
  done <<<"$repos"
}

mirror_gitlab_to_github() {
  # mirror_gitlab_to_github <gl_namespace> <gh_user_or_org> [--host gitlab.com]
  local gl_ns gh_ns host="${GITLAB_HOST:-gitlab.com}"
  gl_ns="$1"; gh_ns="$2"; shift 2 || true
  while ((${#})); do
    case "$1" in
      --host) host="$2"; shift 2;;
      *) shift;;
    esac
  done
  local gl_pat="${GITLAB_TOKEN:-}" gh_pat="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
  [[ -n "$gh_pat" ]] || { _gg_log "GH_TOKEN/GITHUB_TOKEN required"; return 3; }
  local projects; projects=$(gl_list_group_projects "$gl_ns" 2>/dev/null || gl_list_projects_user "$gl_ns" 2>/dev/null)
  [[ -n "$projects" ]] || { _gg_log "No GitLab projects for $gl_ns"; return 2; }
  while IFS= read -r full; do
    [[ -n "$full" ]] || continue
    local name; name=$(basename "$full")
    local src dst
    src="https://oauth2:${gl_pat}@${host}/${full}.git"
    dst="https://${gh_pat}@github.com/${gh_ns}/${name}.git"
    _gg_log "Mirroring ${full} -> ${gh_ns}/${name}"
    _gg_git_mirror_push "$src" "$dst" || _gg_log "Failed mirror for $full"
  done <<<"$projects"
}

gh_search_profile() {
  # gh_search_profile <user>
  local u="$1"
  _gg_log "Collecting profile for $u"
  gh_api "/users/${u}" '{login, name, followers, following, public_repos, public_gists, bio, blog, company, location}'
  _gg_log "Top repositories by stars:"
  gh_api "/users/${u}/repos?per_page=100" '.[] | {name, stargazers_count} | select(.stargazers_count>0) | .name + ":" + (.stargazers_count|tostring)' | sort -t: -k2 -nr | head -n 10 || true
}
