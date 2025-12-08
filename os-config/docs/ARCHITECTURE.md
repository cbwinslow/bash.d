# OS Configuration Backup System - Architecture

## Overview

The OS Configuration Backup System is designed to capture, document, and recreate operating system configurations across machines. It follows a modular architecture with clear separation of concerns.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Backup Orchestrator                      │
│                   (backup-system.sh)                         │
│  - Coordinates collectors                                     │
│  - Generates bundles                                          │
│  - Creates metadata                                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
        ┌──────────────────────────────────────┐
        │                                       │
        ↓                                       ↓
┌──────────────────┐                  ┌──────────────────┐
│   Collectors      │                  │   Generators      │
│  (8 scripts)      │                  │  (cloud-init)     │
│  - packages       │                  │  - YAML format    │
│  - system         │                  │  - User data      │
│  - dotfiles       │                  │  - Setup guides   │
│  - tools          │                  │                   │
│  - databases      │                  │                   │
│  - containers     │                  │                   │
│  - repositories   │                  │                   │
│  - themes         │                  │                   │
└──────────────────┘                  └──────────────────┘
        ↓                                       ↓
┌─────────────────────────────────────────────────────────────┐
│                     Backup Bundle                            │
│  - JSON files (structured data)                              │
│  - cloud-init YAML (automation)                              │
│  - SETUP_GUIDE.md (human readable)                           │
│  - metadata.json (tracking)                                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
        ┌──────────────────────────────────────┐
        │                                       │
        ↓                                       ↓
┌──────────────────┐                  ┌──────────────────┐
│  Cloud Deploy    │                  │  Manual Restore   │
│  (cloud-init)    │                  │  (restore.sh)     │
│  - AWS           │                  │  - Package inst.  │
│  - GCP           │                  │  - Config apply   │
│  - Azure         │                  │  - Verification   │
│  - DigitalOcean  │                  │                   │
└──────────────────┘                  └──────────────────┘
```

## Component Descriptions

### 1. Collectors (`os-config/collectors/`)

Modular scripts that gather specific types of system information:

- **packages.sh**: Detects and lists packages from multiple package managers
  - Systems: apt, yum, pacman, brew, snap, flatpak
  - Languages: pip, npm, gem, cargo, go
  - Output: JSON with package names and versions

- **system.sh**: Captures OS and system configuration
  - OS version, kernel, architecture
  - Hardware info (CPU, memory, disks)
  - Users, groups, permissions
  - Services (systemd, sysv)
  - Cron jobs
  - Network configuration
  - Environment variables (sanitized)

- **dotfiles.sh**: Backs up configuration files
  - Shell configs (.bashrc, .zshrc)
  - Editor configs (.vimrc, .config/nvim)
  - Git configuration
  - SSH configs (excluding private keys)
  - Application configs

- **tools.sh**: Inventories development tools
  - Programming languages and versions
  - Build tools
  - Version control systems
  - Editors and IDEs
  - Utilities

- **databases.sh**: Identifies database installations
  - PostgreSQL, MySQL, MongoDB, Redis, SQLite
  - Versions and running status
  - Does NOT backup data (security)

- **containers.sh**: Documents container infrastructure
  - Docker/Podman containers and images
  - Kubernetes contexts
  - Docker Compose files
  - Networks and volumes

- **repositories.sh**: Catalogs Git repositories
  - Local repository paths
  - Remote URLs
  - Current branch
  - Commit status
  - Uncommitted changes

- **themes.sh**: Captures appearance settings
  - System fonts
  - GTK/Qt themes
  - Terminal emulator settings

### 2. Generators (`os-config/generators/`)

Transform collected data into deployment formats:

- **cloud-init-simple.sh**: Basic cloud-init configuration
  - Package installation commands
  - Directory creation
  - Basic environment setup
  - Safe and predictable

- **cloud-init.sh**: Advanced cloud-init generation
  - Extracts package lists from JSON
  - Generates runcmd sequences
  - Creates write_files sections
  - More comprehensive but complex

### 3. Orchestrator (`os-config/backup-system.sh`)

Main script that coordinates the backup process:

```bash
workflow:
  1. Validate prerequisites (jq, etc.)
  2. Create bundle directory
  3. Run all collectors → JSON files
  4. Generate cloud-init YAML
  5. Create setup guide
  6. Generate metadata
  7. Create "latest" symlink
```

### 4. Restoration (`os-config/restore-system.sh`)

Applies backed-up configuration to new systems:

```bash
workflow:
  1. Validate bundle
  2. Display bundle info
  3. Confirm with user
  4. Install APT packages (individually for security)
  5. Install pip packages
  6. Install npm packages
  7. Display manual steps
```

## Data Flow

### Backup Flow
```
System → Collectors → JSON → Bundle → Storage
                               ↓
                         cloud-init.yaml
                               ↓
                         SETUP_GUIDE.md
```

### Restore Flow
```
Bundle → Validation → Package Installation
                  ↓
            Manual Steps Guide
                  ↓
          Dotfile Restoration
```

## Design Principles

### 1. Modularity
- Each collector is independent
- Can run collectors individually
- Easy to add new collectors

### 2. Idempotency
- Running backup multiple times is safe
- Collectors don't modify system
- Read-only operations

### 3. Security
- Filters sensitive data (passwords, keys)
- No private keys in backups
- Package installation uses proper quoting
- Validates inputs

### 4. Portability
- Standard bash (POSIX-compatible where possible)
- Uses common tools (jq, tar)
- Works on multiple distributions

### 5. AI-Friendly
- Structured JSON output
- Clear, consistent format
- Human-readable documentation included
- Metadata for context

### 6. Cloud-Native
- cloud-init compatible
- Works with major cloud providers
- Automated deployment support

## File Formats

### JSON Structure (Collectors)
```json
{
  "timestamp": "ISO 8601 datetime",
  "hostname": "system hostname",
  "specific_data": {
    // Collector-specific fields
  }
}
```

### Bundle Metadata
```json
{
  "backup_name": "identifier",
  "timestamp": "ISO 8601 datetime",
  "hostname": "source system",
  "created_by": "username",
  "os": "operating system",
  "bundle_path": "full path",
  "files": ["list", "of", "files"]
}
```

### Cloud-Init Format
```yaml
#cloud-config
package_update: true
package_upgrade: true
packages:
  - package1
  - package2
runcmd:
  - command1
  - command2
write_files:
  - path: /path/to/file
    content: |
      file content
```

## Error Handling

- **Collectors**: Continue on non-fatal errors, log warnings
- **Orchestrator**: Stops on critical errors (missing jq, etc.)
- **Restoration**: Asks for confirmation, logs all actions

## Testing Strategy

- **Unit Tests**: Individual collector validation
- **Integration Tests**: Full backup → restore workflow
- **Dry-Run Mode**: Preview without modifications
- **Collector Tests**: `test-collectors.sh` validates outputs

## Extension Points

### Adding New Collectors
1. Create script in `collectors/`
2. Output valid JSON to stdout
3. Log info/warnings to stderr
4. Make executable
5. Add to `backup-system.sh`

### Adding New Generators
1. Create script in `generators/`
2. Accept bundle directory as argument
3. Output to stdout
4. Make executable

### Adding New Package Managers
1. Add function to `packages.sh`
2. Follow existing pattern
3. Return empty if not available
4. Use jq for JSON formatting

## Performance Considerations

- Collectors run sequentially (simple, reliable)
- Large package lists handled efficiently
- Repository search depth limited (default 3)
- Environment variables filtered early

## Security Model

### What Gets Backed Up
- Package lists (public information)
- Configuration file structure
- Tool versions
- System metadata

### What Doesn't Get Backed Up
- Passwords or secrets
- Private SSH keys
- API tokens
- Database credentials
- Sensitive environment variables

### Restoration Security
- Packages installed individually (no shell injection)
- User confirmation required
- All actions logged
- Dry-run mode available

## Future Enhancements

Potential improvements:
- Parallel collector execution
- Differential backups
- Encrypted bundles
- Remote storage integration
- Scheduled backups
- Restoration verification tests
- Custom collector plugins
- Web dashboard
- Ansible playbook generation
- Terraform configuration generation

## Dependencies

### Required
- bash 4.0+
- jq (JSON processing)
- tar (for tarball creation)
- Common Unix tools (grep, awk, sed)

### Optional
- Package managers (detected at runtime)
- git (for repository scanning)
- docker/podman (for container info)
- systemctl (for service info)

## Compatibility

### Tested On
- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- CentOS/RHEL 8, 9 (partial)
- macOS (with Homebrew)

### Cloud Providers
- AWS EC2
- Google Cloud Compute
- Azure VMs
- DigitalOcean Droplets
- Linode
- Local VMs (with cloud-init)

## References

- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Cloud-Init Examples](https://cloudinit.readthedocs.io/en/latest/topics/examples.html)
- [POSIX Shell Standards](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
- [JSON Format (RFC 8259)](https://tools.ietf.org/html/rfc8259)
