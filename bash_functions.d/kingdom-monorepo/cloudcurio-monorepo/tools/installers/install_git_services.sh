#!/usr/bin/env bash
set -euo pipefail
SCRIPT_NAME="install_git_services.sh"
LOG_FILE="/tmp/CBW-${SCRIPT_NAME}.log"
log() {
  local level="$1"; shift
  local msg="$*"
  printf '[%s] %s\n' "$level" "$msg" | tee -a "$LOG_FILE"
}
require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    log ERROR "This script must be run as root (sudo)."
    exit 1
  fi
}
ensure_docker() {
  if command -v docker >/dev/null 2>&1; then
    log INFO "Docker already installed."
    return
  fi
  log INFO "Installing Docker..."
  apt-get update -y
  apt-get install -y docker.io docker-compose-plugin
  systemctl enable --now docker
  log INFO "Docker installed and started."
}
ensure_compose() {
  if docker compose version >/dev/null 2>&1; then
    log INFO "'docker compose' is available."
    echo "docker compose"
    return
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    log INFO "'docker-compose' is available."
    echo "docker-compose"
    return
  fi
  log ERROR "Neither 'docker compose' nor 'docker-compose' is available."
  exit 1
}
write_compose_file() {
  local path="/opt/git-services/docker-compose.yml"
  mkdir -p /opt/git-services/gitlab/config \
           /opt/git-services/gitlab/logs \
           /opt/git-services/gitlab/data \
           /opt/git-services/forgejo/data
  if [[ -f "$path" ]]; then
    log INFO "docker-compose.yml already exists at $path (leaving as-is)."
    return
  fi
  cat >"$path" <<'EOF'
version: "3.9"
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: always
    hostname: gitlab.local
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.local'
    ports:
      - "8929:80"
      - "2224:22"
    volumes:
      - /opt/git-services/gitlab/config:/etc/gitlab
      - /opt/git-services/gitlab/logs:/var/log/gitlab
      - /opt/git-services/gitlab/data:/var/opt/gitlab
  forgejo:
    image: codeberg.org/forgejo/forgejo:latest
    container_name: forgejo
    restart: always
    environment:
      USER_UID: 1000
      USER_GID: 1000
      FORGEJO__server__ROOT_URL: http://forgejo.local:3000/
    ports:
      - "3001:3000"
    volumes:
      - /opt/git-services/forgejo/data:/data
EOF
  log INFO "Wrote /opt/git-services/docker-compose.yml"
}
bring_up_stack() {
  local compose_cmd
  compose_cmd="$(ensure_compose)"
  log INFO "Bringing up GitLab + Forgejo stack with: $compose_cmd"
  (cd /opt/git-services && $compose_cmd up -d)
  log INFO "Stack is starting. Initial startup (especially GitLab) may take several minutes."
  log INFO "GitLab:  http://<cbwdellr720-ip>:8929"
  log INFO "Forgejo: http://<cbwdellr720-ip>:3001"
}
main() {
  require_root
  ensure_docker
  write_compose_file
  bring_up_stack
}
main "$@"
