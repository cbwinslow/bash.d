#!/usr/bin/env python3
# cbw_ssh_profile_builder.py
# Author: cbwinslow + ChatGPT (GPT-5.1 Thinking)
# Date: 2025-11-22
#
# Summary:
#   Build a complete SSH profile for each machine in a small network.
#   For each machine defined in a YAML topology file, this script:
#     - Generates (or reuses) an SSH keypair (ed25519 by default)
#     - Builds a machine-specific authorized_keys file based on allow_ssh_from rules
#     - Builds a machine-specific SSH config file with Host entries for its targets
#     - Optionally pre-populates known_hosts using ssh-keyscan
#   The output is a folder tree you can copy/sync into each machine's ~/.ssh.
#
# Inputs:
#   - YAML topology file describing machines and access rules
#   - Optional: existing ~/.ssh/config and known_hosts for seeding
#
# Outputs:
#   - Per-machine subdirectories containing:
#       id_ed25519_<name> (private key)
#       id_ed25519_<name>.pub (public key)
#       authorized_keys
#       config
#       known_hosts (optional, if ssh-keyscan works)
#
# Usage (examples):
#   python cbw_ssh_profile_builder.py --topology ssh_topology.yaml --output-dir ./ssh_profiles
#   python cbw_ssh_profile_builder.py --topology ssh_topology.yaml --output-dir ./ssh_profiles --dry-run
#
# Parameters (CLI):
#   --topology   : Path to topology YAML file (required)
#   --output-dir : Directory to place generated per-machine folders (default: ./ssh_profiles)
#   --force      : Overwrite existing keys/config (otherwise they are reused)
#   --no-scan    : Skip ssh-keyscan and do not generate known_hosts
#   --dry-run    : Compute everything but don't write files or shell out
#   --verbose    : Extra logging to console
#
# Modification Log:
#   - 2025-11-22: Initial version generated.
#
# Notes:
#   - Requires: Python 3.8+, PyYAML, ssh-keygen, optionally ssh-keyscan, zerotier-cli, netbird
#   - zerotier-cli / netbird are used only as helpers to enrich IP data if available.
#     The core of the logic works purely from the YAML topology.
#
from __future__ import annotations

import argparse
import dataclasses
import logging
import os
import shutil
import stat
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional

try:
    import yaml  # type: ignore[import]
except ImportError as exc:  # pragma: no cover - import error handling
    print("ERROR: PyYAML is required. Install with: pip install pyyaml", file=sys.stderr)
    raise

LOG_PATH = Path("/tmp/CBW-ssh-profile-builder.log")


def setup_logging(verbose: bool = False) -> None:
    """Configure logging to both file and console.

    Logs go to /tmp/CBW-ssh-profile-builder.log and optionally to stdout if verbose.
    """
    log_level = logging.DEBUG if verbose else logging.INFO
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)

    handlers: List[logging.Handler] = []

    file_handler = logging.FileHandler(LOG_PATH, encoding="utf-8")
    file_handler.setLevel(log_level)
    file_handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
    handlers.append(file_handler)

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(log_level)
    console_handler.setFormatter(logging.Formatter("[%(levelname)s] %(message)s"))
    handlers.append(console_handler)

    logging.basicConfig(level=log_level, handlers=handlers)


@dataclasses.dataclass
class Machine:
    """Representation of a single machine in the SSH topology.

    Attributes:
        name: Logical name (e.g. cbwdellr720).
        user: SSH username for this machine.
        ips: Dictionary of IPs, keyed by type (e.g. 'lan', 'zerotier', 'netbird').
        ssh_port: SSH port number.
        identity_name: Base name for the identity file (no path), e.g. 'id_ed25519_cbwdellr720'.
        allow_ssh_from: List of machine names allowed to SSH INTO this machine.
        ssh_targets: Optional explicit list of machine names this machine will ssh TO.
    """
    name: str
    user: str
    ips: Dict[str, str]
    ssh_port: int = 22
    identity_name: Optional[str] = None
    allow_ssh_from: List[str] = dataclasses.field(default_factory=list)
    ssh_targets: List[str] = dataclasses.field(default_factory=list)

    def preferred_host(self) -> Optional[str]:
        """Pick a 'best' host/IP for SSH based on available IP types.

        Preference order: lan -> zerotier -> netbird -> first arbitrary.
        """
        for key in ("lan", "zerotier", "netbird"):
            if key in self.ips:
                return self.ips[key]
        # fallback: any IP
        return next(iter(self.ips.values()), None)


@dataclasses.dataclass
class Topology:
    machines: Dict[str, Machine]


def load_topology(path: Path) -> Topology:
    """Load topology from YAML file into a Topology object.

    Expected basic schema:
    machines:
      cbwdellr720:
        user: cbwinslow
        ips:
          lan: 192.168.4.10
          zerotier: 172.28.131.81
        ssh_port: 22
        identity_name: id_ed25519_cbwdellr720
        allow_ssh_from:
          - cbwhpz
        ssh_targets:
          - cbwhpz
    """
    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    if not isinstance(data, dict) or "machines" not in data:
        raise ValueError("Topology file must contain a 'machines' mapping")

    machines_raw = data["machines"]
    if not isinstance(machines_raw, dict):
        raise ValueError("'machines' must be a mapping of name -> machine config")

    machines: Dict[str, Machine] = {}

    for name, cfg in machines_raw.items():
        if not isinstance(cfg, dict):
            raise ValueError(f"Machine entry for {name!r} must be a mapping")
        user = cfg.get("user")
        if not user:
            raise ValueError(f"Machine {name!r} missing required field 'user'")
        ips_cfg = cfg.get("ips", {})
        if not isinstance(ips_cfg, dict):
            raise ValueError(f"Machine {name!r} field 'ips' must be a mapping")
        ips: Dict[str, str] = {str(k): str(v) for k, v in ips_cfg.items()}

        ssh_port = int(cfg.get("ssh_port", 22))
        identity_name = cfg.get("identity_name") or f"id_ed25519_{name}"
        allow_ssh_from = cfg.get("allow_ssh_from") or []
        ssh_targets = cfg.get("ssh_targets") or []

        if not isinstance(allow_ssh_from, list) or not all(isinstance(x, str) for x in allow_ssh_from):
            raise ValueError(f"Machine {name!r} field 'allow_ssh_from' must be a list of strings")
        if not isinstance(ssh_targets, list) or not all(isinstance(x, str) for x in ssh_targets):
            raise ValueError(f"Machine {name!r} field 'ssh_targets' must be a list of strings")

        machines[name] = Machine(
            name=name,
            user=str(user),
            ips=ips,
            ssh_port=ssh_port,
            identity_name=str(identity_name),
            allow_ssh_from=list(allow_ssh_from),
            ssh_targets=list(ssh_targets),
        )

    logging.info("Loaded topology for %d machines from %s", len(machines), path)
    return Topology(machines=machines)


def which(cmd: str) -> Optional[str]:
    """Return absolute path to a command if it exists, else None."""
    return shutil.which(cmd)


def run_command(cmd: List[str], timeout: int = 15) -> subprocess.CompletedProcess:
    """Run a command with logging and error handling.

    Raises subprocess.CalledProcessError on non-zero exit.
    """
    logging.debug("Running command: %s", " ".join(cmd))
    try:
        proc = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=True,
            text=True,
        )
        logging.debug("Command stdout: %s", proc.stdout.strip())
        if proc.stderr.strip():
            logging.debug("Command stderr: %s", proc.stderr.strip())
        return proc
    except subprocess.CalledProcessError as exc:
        logging.error("Command failed (%s): %s", exc.returncode, " ".join(cmd))
        logging.error("stderr: %s", exc.stderr.strip())
        raise
    except subprocess.TimeoutExpired as exc:
        logging.error("Command timed out: %s", " ".join(cmd))
        raise


def safe_write(path: Path, content: str, mode: str = "w", chmod: Optional[int] = None, dry_run: bool = False) -> None:
    """Write content to a file with optional chmod, honoring dry-run."""
    if dry_run:
        logging.info("[DRY-RUN] Would write file: %s", path)
        return

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open(mode, encoding="utf-8") as f:
        f.write(content)
    if chmod is not None:
        path.chmod(chmod)
    logging.info("Wrote file: %s", path)


def ensure_dir_permissions(path: Path, dry_run: bool = False) -> None:
    """Ensure a directory exists with mode 700."""
    if dry_run:
        logging.info("[DRY-RUN] Would ensure directory: %s (mode 700)", path)
        return
    path.mkdir(parents=True, exist_ok=True)
    path.chmod(stat.S_IRWXU)


def generate_keypair_for_machine(machine: Machine, base_dir: Path, force: bool = False, dry_run: bool = False) -> Path:
    """Generate (or reuse) SSH keypair for the machine.

    Returns the path to the private key file.
    """
    identity_name = machine.identity_name or f"id_ed25519_{machine.name}"
    priv_key = base_dir / identity_name
    pub_key = base_dir / f"{identity_name}.pub"

    if priv_key.exists() and pub_key.exists() and not force:
        logging.info("Reusing existing keypair for %s at %s", machine.name, priv_key)
        return priv_key

    if dry_run:
        logging.info("[DRY-RUN] Would generate keypair for %s at %s", machine.name, priv_key)
        return priv_key

    if which("ssh-keygen") is None:
        raise RuntimeError("ssh-keygen not found in PATH; cannot generate keys")

    cmd = [
        "ssh-keygen",
        "-t",
        "ed25519",
        "-N",
        "",
        "-C",
        f"{machine.user}@{machine.name}",
        "-f",
        str(priv_key),
    ]
    run_command(cmd)
    # Set restrictive permissions
    priv_key.chmod(stat.S_IRUSR | stat.S_IWUSR)
    pub_key.chmod(stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP | stat.S_IROTH)
    logging.info("Generated new keypair for %s at %s", machine.name, priv_key)
    return priv_key


def read_public_key(path: Path) -> str:
    """Read a public key file as a single line."""
    with path.open("r", encoding="utf-8") as f:
        return f.read().strip()


def build_authorized_keys(topology: Topology, profiles_dir: Path, dry_run: bool = False) -> None:
    """Build authorized_keys for each machine based on allow_ssh_from.

    For each target machine T, authorized_keys contains the public keys of all machines
    whose name appears in T.allow_ssh_from.
    """
    pubkeys: Dict[str, str] = {}
    for m in topology.machines.values():
        identity_name = m.identity_name or f"id_ed25519_{m.name}"
        pub_path = profiles_dir / m.name / f"{identity_name}.pub"
        if not pub_path.exists():
            logging.warning("Public key for %s not found at %s; skipping for authorized_keys", m.name, pub_path)
            continue
        pubkeys[m.name] = read_public_key(pub_path)

    for m in topology.machines.values():
        lines: List[str] = []
        for src_name in m.allow_ssh_from:
            pub = pubkeys.get(src_name)
            if not pub:
                logging.warning("No public key found for %s referenced in allow_ssh_from of %s", src_name, m.name)
                continue
            comment = f"{src_name}_to_{m.name}"
            if pub.endswith(comment):
                line = pub
            else:
                line = f"{pub} {comment}"
            lines.append(line)

        content = "\n".join(lines) + ("\n" if lines else "")
        ak_path = profiles_dir / m.name / "authorized_keys"
        safe_write(ak_path, content, chmod=stat.S_IRUSR | stat.S_IWUSR, dry_run=dry_run)


def build_ssh_config(topology: Topology, profiles_dir: Path, dry_run: bool = False) -> None:
    """Build SSH config for each machine, listing its ssh_targets.

    If a machine has no explicit ssh_targets, we infer targets as those
    machines where this machine appears in their allow_ssh_from.
    """
    reverse_targets: Dict[str, List[str]] = {name: [] for name in topology.machines}
    for m in topology.machines.values():
        for src in m.allow_ssh_from:
            reverse_targets.setdefault(src, []).append(m.name)

    for m in topology.machines.values():
        targets = list(m.ssh_targets)
        if not targets:
            targets = reverse_targets.get(m.name, [])

        lines: List[str] = []
        for tgt_name in targets:
            tgt = topology.machines.get(tgt_name)
            if not tgt:
                logging.warning("Machine %s lists unknown ssh target %s", m.name, tgt_name)
                continue
            host = tgt.preferred_host()
            if not host:
                logging.warning("Target machine %s has no IPs defined; skipping", tgt_name)
                continue

            identity_name = m.identity_name or f"id_ed25519_{m.name}"
            priv_key_rel = f"~/.ssh/{identity_name}"
            lines.extend(
                [
                    f"Host {tgt.name}",
                    f"  HostName {host}",
                    f"  User {tgt.user}",
                    f"  Port {tgt.ssh_port}",
                    f"  IdentityFile {priv_key_rel}",
                    "  IdentitiesOnly yes",
                    "",
                ]
            )

        content = "\n".join(lines).rstrip() + ("\n" if lines else "")
        cfg_path = profiles_dir / m.name / "config"
        safe_write(cfg_path, content, chmod=stat.S_IRUSR | stat.S_IWUSR, dry_run=dry_run)


def build_known_hosts(topology: Topology, profiles_dir: Path, dry_run: bool = False) -> None:
    """Populate known_hosts using ssh-keyscan if available."""
    ssh_keyscan = which("ssh-keyscan")
    if ssh_keyscan is None:
        logging.warning("ssh-keyscan not found; skipping known_hosts generation")
        return

    for m in topology.machines.values():
        lines: List[str] = []
        hosts: List[str] = []
        for tgt_name in m.ssh_targets or []:
            tgt = topology.machines.get(tgt_name)
            if not tgt:
                continue
            host = tgt.preferred_host()
            if host and host not in hosts:
                hosts.append(host)

        if not hosts:
            continue

        for host in hosts:
            if dry_run:
                logging.info("[DRY-RUN] Would ssh-keyscan %s for machine %s", host, m.name)
                continue
            try:
                proc = subprocess.run(
                    [ssh_keyscan, "-t", "ed25519", host],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    check=True,
                    timeout=10,
                )
                if proc.stdout.strip():
                    lines.append(proc.stdout.strip())
            except subprocess.CalledProcessError as exc:
                logging.warning("ssh-keyscan failed for %s (%s): %s", host, m.name, exc.returncode, exc.stderr.strip())
            except subprocess.TimeoutExpired:
                logging.warning("ssh-keyscan timed out for %s (%s)", host, m.name)

        if not lines:
            continue

        content = "\n".join(lines) + "\n"
        kh_path = profiles_dir / m.name / "known_hosts"
        safe_write(kh_path, content, chmod=stat.S_IRUSR | stat.S_IWUSR, dry_run=dry_run)


def enrich_ips_with_overlays(topology: Topology) -> None:
    """Best-effort enrichment of IP data using zerotier-cli and netbird."""
    if which("zerotier-cli") is not None:
        try:
            proc = subprocess.run(
                ["zerotier-cli", "listpeers"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=10,
                check=True,
            )
            for line in proc.stdout.splitlines():
                parts = line.split()
                if len(parts) < 6:
                    continue
                address = parts[-1]
                logging.debug("zerotier peer discovered: %s", address)
        except Exception as exc:
            logging.warning("Failed to query zerotier-cli: %s", exc)

    if which("netbird") is not None:
        try:
            proc = subprocess.run(
                ["netbird", "status"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=10,
                check=True,
            )
            logging.debug("netbird status:\n%s", proc.stdout)
        except Exception as exc:
            logging.warning("Failed to query netbird: %s", exc)


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build per-machine SSH profiles (keys, config, authorized_keys, known_hosts)."
    )
    parser.add_argument(
        "--topology",
        required=True,
        help="Path to topology YAML file.",
    )
    parser.add_argument(
        "--output-dir",
        default="./ssh_profiles",
        help="Directory to write per-machine profiles (default: ./ssh_profiles).",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing keys/config if they already exist.",
    )
    parser.add_argument(
        "--no-scan",
        action="store_true",
        help="Skip ssh-keyscan and do not generate known_hosts.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Compute everything but don't write files or shell out to ssh-keygen/ssh-keyscan.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging.",
    )
    return parser.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> int:
    args = parse_args(argv)
    setup_logging(verbose=args.verbose)

    topology_path = Path(args.topology).expanduser().resolve()
    output_dir = Path(args.output_dir).expanduser().resolve()

    logging.info("Using topology: %s", topology_path)
    logging.info("Output directory: %s", output_dir)
    if args.dry_run:
        logging.info("DRY-RUN mode enabled: no files will be written and key generation will be skipped.")

    if not topology_path.exists():
        logging.error("Topology file does not exist: %s", topology_path)
        return 1

    try:
        topology = load_topology(topology_path)
    except Exception as exc:
        logging.exception("Failed to load topology: %s", exc)
        return 1

    enrich_ips_with_overlays(topology)

    for m in topology.machines.values():
        machine_dir = output_dir / m.name
        ensure_dir_permissions(machine_dir, dry_run=args.dry_run)
        try:
            generate_keypair_for_machine(m, machine_dir, force=args.force, dry_run=args.dry_run)
        except Exception as exc:
            logging.error("Failed to generate keypair for %s: %s", m.name, exc)

    try:
        build_authorized_keys(topology, output_dir, dry_run=args.dry_run)
        build_ssh_config(topology, output_dir, dry_run=args.dry_run)
        if not args.no_scan:
            build_known_hosts(topology, output_dir, dry_run=args.dry_run)
    except Exception as exc:
        logging.exception("Failed while building profiles: %s", exc)
        return 1

    logging.info("SSH profiles generated successfully in %s", output_dir)
    logging.info("You can now copy each machine's folder into ~/.ssh on that machine.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
