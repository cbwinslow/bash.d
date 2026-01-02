---
title: gh_gl_helpers.sh
---
GitHub and GitLab helpers: auth env helpers, API wrappers, listing, mass ops,
and mirror functions to sync repos across GitHub <-> GitLab.

Functions (high level):
  gh_token_set <TOKEN>                      # export GH_TOKEN safely
  gl_token_set <TOKEN> [--host gitlab.com]  # export GITLAB_TOKEN and GITLAB_HOST
  gh_api <endpoint> [jq-filter]
  gl_api <endpoint> [jq-filter]
  gh_list_repos_user <user>
  gh_list_repos_org <org>
  gl_list_projects_user <username>
  gl_list_group_projects <group_path>
  gh_for_each_repo <user|org> -- run '<cmd>' [--archive] [--visibility public|private|all]
  mirror_github_to_gitlab <gh_user_or_org> <gl_namespace> [--host gitlab.com]
  mirror_gitlab_to_github <gl_namespace> <gh_user_or_org> [--host gitlab.com]

Notes:
- Requires jq and git. gh CLI is optional; falls back to curl.
- Tokens are read from GH_TOKEN (or GITHUB_TOKEN) and GITLAB_TOKEN.
- For GitLab self-hosted, set GITLAB_HOST or pass --host.
