# CBW SSH Suite

This suite builds **complete SSH connection profiles** for your machines so you can:
- Generate per-machine keypairs (ed25519)
- Wire up `authorized_keys` based on who is allowed to SSH where
- Generate per-machine `config` files with sane defaults
- Optionally pre-fill `known_hosts` via `ssh-keyscan`
- Integrate overlay networks (ZeroTier / NetBird) into host definitions

## Components

- `cbw_ssh_profile_builder.py`  
  Core Python engine that reads a YAML topology and emits per-machine SSH bundles under an output directory.

- `cbw_ssh_suite_runner.sh`  
  Orchestrator that validates the environment and calls the Python builder. Optional `--zip-out` to archive results.

- `cbw_ssh_profile_generator.sh`  
  Single-host helper that builds a profile folder for one machine using ZeroTier / NetBird discovery.

- `cbw_bubbletea_wish_tui_main.go`  
  Charmbracelet-based TUI skeleton (Bubble Tea + Bubbles + Lip Gloss + Wish) you can extend into a full SSH dashboard.

- `ssh_topology.example.yaml`  
  Example topology file for use with the suite.

## Quickstart

1. Install requirements:

   ```bash
   sudo apt-get install -y openssh-client ssh-keygen python3 python3-pip
   python3 -m pip install --user pyyaml
   ```

2. Copy and edit the topology:

   ```bash
   cp ssh_topology.example.yaml ssh_topology.yaml
   $EDITOR ssh_topology.yaml
   ```

3. Run the suite runner:

   ```bash
   chmod +x cbw_ssh_suite_runner.sh
   ./cbw_ssh_suite_runner.sh --topology ssh_topology.yaml --output-dir ssh_profiles
   ```

4. For each machine, copy its folder to `~/.ssh` on that machine:

   ```bash
   # Example for cbwdellr720
   scp -r ssh_profiles/cbwdellr720 user@cbwdellr720:~/.ssh-temp
   # Then on remote host, move and fix perms.
   ```

## Optional: Build the TUI

Inside this directory:

```bash
go mod init github.com/cbwinslow/cbw-ssh-suite
go get github.com/charmbracelet/bubbletea@latest \
       github.com/charmbracelet/bubbles@latest \
       github.com/charmbracelet/lipgloss@latest \
       github.com/charmbracelet/wish@latest

go build -o cbw-tui cbw_bubbletea_wish_tui_main.go
./cbw-tui
```

Or as an SSH TUI:

```bash
./cbw-tui --ssh-server  # on server
ssh -p 23234 user@server  # from client
```

## Safety Notes

- Always review generated profiles before copying into production `~/.ssh`.
- Private keys are created with `0600` permissions; keep the suite directory safe.
- Use `--dry-run` first when testing new topologies.
