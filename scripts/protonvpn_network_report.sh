#!/usr/bin/env bash
set -u

# Generate a concise network/VPN diagnostic report for Proton VPN.
# The report is written to scripts/output with a timestamped filename.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
report_dir="${script_dir}/output"
timestamp="$(date +%Y%m%d_%H%M%S)"
report_path="${report_dir}/protonvpn_network_report_${timestamp}.txt"

mkdir -p "${report_dir}"

print_section() {
  printf "\n==== %s ====\n" "$1"
}

run_cmd() {
  local label="$1"
  local cmd="$2"
  print_section "${label}"
  printf "$ %s\n" "${cmd}"
  # shellcheck disable=SC2086
  eval ${cmd} 2>&1 || printf "(command exited with status %s)\n" "$?"
}

run_if_exists() {
  local bin="$1"
  local label="$2"
  local cmd="$3"
  if command -v "${bin}" >/dev/null 2>&1; then
    run_cmd "${label}" "${cmd}"
  else
    print_section "${label}"
    printf "(missing: %s)\n" "${bin}"
  fi
}

{
  print_section "Report Metadata"
  date
  printf "Host: %s\n" "$(hostname)"
  printf "User: %s\n" "$(whoami)"
  printf "Kernel: %s\n" "$(uname -r)"
  if [ -f /etc/os-release ]; then
    printf "OS:\n"
    cat /etc/os-release
  fi

  if command -v rg >/dev/null 2>&1; then
    run_cmd "Environment Proxy Settings" "env | rg -i '(_proxy=|_PROXY=)' || true"
  else
    run_cmd "Environment Proxy Settings" "env | grep -Ei '(_proxy=|_PROXY=)' || true"
  fi

  run_cmd "IP Addresses" "ip -brief addr"
  run_cmd "Routes" "ip route"

  run_if_exists "nmcli" "NetworkManager General" "nmcli general status"
  run_if_exists "nmcli" "NetworkManager Devices" "nmcli device status"
  run_if_exists "nmcli" "NetworkManager Connections" "nmcli connection show"

  run_cmd "systemd-resolved Status" "systemctl --no-pager --full status systemd-resolved"
  run_if_exists "resolvectl" "resolvectl Status" "resolvectl status"
  run_cmd "resolv.conf" "ls -l /etc/resolv.conf && cat /etc/resolv.conf"
  run_cmd "systemd-resolved config" "test -f /etc/systemd/resolved.conf && cat /etc/systemd/resolved.conf || echo '(missing /etc/systemd/resolved.conf)'"

  run_cmd "NetworkManager system connections (names only)" "ls -la /etc/NetworkManager/system-connections 2>/dev/null || echo '(no access or missing)'"

  run_if_exists "protonvpn" "Proton VPN CLI Version" "protonvpn --version"
  run_if_exists "protonvpn" "Proton VPN CLI Status" "protonvpn status"

  run_cmd "Proton VPN systemd units" "systemctl --no-pager --full list-unit-files | rg -i 'proton|vpn' || true"
  run_cmd "Proton VPN daemon status" "systemctl --no-pager --full status proton-vpn-daemon || true"
  run_cmd "Proton VPN local agent status" "systemctl --no-pager --full status protonvpn-local-agent || true"

  run_if_exists "wg" "WireGuard Status" "wg show"
  run_if_exists "wg-quick" "WireGuard Quick List" "wg-quick show all"
  run_if_exists "openvpn" "OpenVPN Version" "openvpn --version"

  run_cmd "VPN/Proton config dirs (depth 3)" "find /etc -maxdepth 3 -type d \\( -iname '*proton*' -o -iname '*vpn*' -o -iname '*wireguard*' -o -iname '*openvpn*' \\) 2>/dev/null | sort -u"
  run_cmd "VPN/Proton config files (depth 3)" "find /etc -maxdepth 3 -type f \\( -iname '*.ovpn' -o -iname '*.conf' -o -iname '*.ini' -o -iname '*.json' -o -iname '*proton*' -o -iname '*vpn*' -o -iname '*wireguard*' -o -iname '*openvpn*' \\) 2>/dev/null | sort -u"
} | tee "${report_path}"

printf "\nReport saved to: %s\n" "${report_path}"
