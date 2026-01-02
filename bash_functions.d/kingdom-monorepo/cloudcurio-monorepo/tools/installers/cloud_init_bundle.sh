#!/usr/bin/env bash
set -euo pipefail
SCRIPT_NAME="cloud_init_bundle.sh"
LOG_FILE="/tmp/CBW-${SCRIPT_NAME}.log"
log(){ local level="$1"; shift; local msg="$*"; printf '[%s] %s\n' "$level" "$msg" | tee -a "$LOG_FILE"; }
write_if_missing(){ local path="$1"; local content="$2"; if [[ -f "$path" ]]; then log INFO "Exists: $path"; return; fi; mkdir -p "$(dirname "$path")"; printf '%s\n' "$content" >"$path"; log INFO "Wrote: $path"; }
main(){
  local root="cloudcurio-monorepo"
  if [[ ! -d "$root" ]]; then log ERROR "Run from dir containing '$root'."; exit 1; fi
  local cloud_init_path="$root/infra/cloud-init/cloudcurio-base.yaml"
  local autoinstall_path="$root/infra/ubuntu-autoinstall/ubuntu-server-autoinstall.yaml"
  read -r -d '' CLOUD_INIT_CONTENT <<'EOF'
#cloud-config
users:
  - name: cbwinslow
    gecos: CloudCurio Admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-ed25519 AAAA...your_key_here
package_update: true
package_upgrade: true
packages:
  - git
  - htop
  - curl
  - wget
  - python3
  - python3-pip
  - neovim
runcmd:
  - [ bash, -c, "echo 'Welcome to CloudCurio base VM' > /etc/motd" ]
  - [ bash, -c, "mkdir -p /opt/cloudcurio" ]
EOF
  read -r -d '' AUTOINSTALL_CONTENT <<'EOF'
version: 1
identity:
  hostname: cloudcurio-vm
  username: cbwinslow
  password: "$6$changeme$..."  # TODO: hashed password
ssh:
  install-server: true
  authorized-keys:
    - ssh-ed25519 AAAA...your_key_here
storage:
  layout:
    name: direct
packages:
  - git
  - htop
  - curl
  - wget
  - python3
  - python3-pip
late-commands:
  - curtin in-target --target=/target -- bash -c "echo 'CloudCurio autoinstall complete' > /etc/motd"
EOF
  write_if_missing "$cloud_init_path" "$CLOUD_INIT_CONTENT"
  write_if_missing "$autoinstall_path" "$AUTOINSTALL_CONTENT"
  log INFO "Templates generated. Customize keys/passwords before use."
}
main "$@"
