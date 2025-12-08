# OS Configuration Backup and Portability System

A comprehensive system for backing up, documenting, and recreating operating system configurations across machines. This system provides cloud-init compatible configurations and AI-agent-friendly documentation for system reproduction.

## 🎯 Overview

This system allows you to:
- **Backup** your current OS configuration (packages, configs, dotfiles, etc.)
- **Document** your system setup in a structured, AI-readable format
- **Recreate** your OS environment on another machine using cloud-init or manual scripts
- **Share** your setup configuration with team members or AI agents

## 📁 Directory Structure

```
os-config/
├── collectors/          # Scripts to gather system information
│   ├── packages.sh      # Collect installed packages (apt, pip, npm, etc.)
│   ├── dotfiles.sh      # Backup dotfiles and configs
│   ├── system.sh        # System information and settings
│   ├── tools.sh         # Installed tools and programs
│   ├── databases.sh     # Database configurations
│   ├── containers.sh    # Docker/Podman containers and images
│   ├── repositories.sh  # Git repositories and versions
│   └── themes.sh        # Themes, fonts, and appearance
├── generators/          # Scripts to generate cloud-init configs
│   ├── cloud-init.sh    # Generate cloud-init YAML
│   └── bundle.sh        # Create portable bundle
├── templates/           # Template files for various configs
├── cloud-init/          # Cloud-init formatted configurations
│   ├── user-data/       # User data configurations
│   ├── meta-data/       # Instance metadata
│   └── vendor-data/     # Vendor-specific data
├── bundles/             # Generated portable bundles
└── docs/                # Documentation and guides
```

## 🚀 Quick Start

### 1. Backup Current System

```bash
# Run the main backup script
./os-config/backup-system.sh

# This will generate:
# - os-config/bundles/backup-YYYYMMDD-HHMMSS/
# - os-config/cloud-init/user-data/backup-YYYYMMDD-HHMMSS.yaml
```

### 2. Review Generated Configurations

```bash
# View the cloud-init configuration
cat os-config/cloud-init/user-data/latest.yaml

# View collected system information
cat os-config/bundles/latest/system-info.json
```

### 3. Restore on New Machine

```bash
# Option A: Using cloud-init (recommended for cloud VMs)
# Copy user-data file to cloud provider or use with cloud-init

# Option B: Using restoration script
./os-config/restore-system.sh os-config/bundles/latest/

# Option C: Manually using the generated documentation
cat os-config/bundles/latest/SETUP_GUIDE.md
```

## 📦 What Gets Backed Up

### Package Managers
- **APT/DPKG** - Debian/Ubuntu packages
- **YUM/DNF** - Red Hat/Fedora packages
- **Homebrew** - macOS packages
- **Pacman** - Arch Linux packages
- **pip/pip3** - Python packages
- **npm** - Node.js packages
- **gem** - Ruby packages
- **cargo** - Rust packages
- **go** - Go modules

### Configuration Files
- Dotfiles (`.bashrc`, `.zshrc`, `.vimrc`, etc.)
- Shell configurations
- SSH configurations
- Git configurations
- Application configs from `~/.config/`

### System Information
- OS version and distribution
- Kernel version
- Hardware information
- Installed services
- User accounts and groups
- Cron jobs and systemd timers
- Environment variables

### Development Environment
- Docker containers and images
- Databases (PostgreSQL, MySQL, MongoDB, Redis)
- Git repositories (local and remote URLs)
- Development tools and SDKs
- IDE configurations

### Appearance and UI
- Terminal themes
- Shell prompts
- Installed fonts
- GTK/Qt themes
- Icon themes

## 🛠️ Collectors

Each collector script can be run independently:

```bash
# Collect package information
./os-config/collectors/packages.sh > packages.json

# Backup dotfiles
./os-config/collectors/dotfiles.sh > dotfiles.tar.gz

# Get system information
./os-config/collectors/system.sh > system-info.json

# List installed tools
./os-config/collectors/tools.sh > tools.json

# Collect database info
./os-config/collectors/databases.sh > databases.json

# List containers
./os-config/collectors/containers.sh > containers.json

# List git repositories
./os-config/collectors/repositories.sh > repositories.json

# Backup themes and fonts
./os-config/collectors/themes.sh > themes.json
```

## ☁️ Cloud-Init Integration

The system generates cloud-init compatible configurations that can be used with:
- AWS EC2
- Google Cloud Compute
- Azure VMs
- DigitalOcean Droplets
- Linode
- Local VMs (using cloud-init locally)

### Cloud-Init User Data Example

```yaml
#cloud-config
package_update: true
package_upgrade: true

packages:
  - git
  - vim
  - docker.io
  - python3-pip

runcmd:
  - pip3 install numpy pandas
  - npm install -g typescript
  - systemctl enable docker

write_files:
  - path: /home/ubuntu/.bashrc
    content: |
      # Custom bashrc
      export PS1='\u@\h:\w\$ '
```

## 🤖 AI Agent Integration

The system is designed to be AI-agent friendly:

### 1. Structured JSON Output
All collectors output JSON for easy parsing:
```json
{
  "timestamp": "2025-12-08T01:00:00Z",
  "hostname": "my-machine",
  "packages": {
    "apt": ["git", "vim", "docker.io"],
    "pip": ["numpy", "pandas"]
  }
}
```

### 2. Natural Language Documentation
Each bundle includes a `SETUP_GUIDE.md` with:
- Step-by-step instructions
- Explanations of installed software
- Configuration details
- Troubleshooting tips

### 3. Automated Setup Scripts
Generated scripts that can be executed by AI agents:
```bash
#!/bin/bash
# Auto-generated setup script
# Can be executed by AI agents

install_packages() {
    apt-get update
    apt-get install -y git vim docker.io
}

install_python_packages() {
    pip3 install numpy pandas
}

# ... more setup functions
```

## 📝 Usage Examples

### Example 1: Backup for Team Onboarding

```bash
# Create a backup of your development environment
./os-config/backup-system.sh --name "dev-environment-v1"

# Share the bundle with team members
tar -czf dev-env.tar.gz os-config/bundles/dev-environment-v1/
```

### Example 2: Disaster Recovery

```bash
# Regular automated backups
crontab -e
# Add: 0 2 * * 0 /path/to/os-config/backup-system.sh --auto

# Restore after system failure
./os-config/restore-system.sh os-config/bundles/latest/
```

### Example 3: Multi-Environment Setup

```bash
# Backup production server config
./os-config/backup-system.sh --name "production"

# Apply to staging server
scp -r os-config/bundles/production/ staging-server:~/
ssh staging-server './os-config/restore-system.sh ~/production/'
```

## 🔒 Security Considerations

### What NOT to Include
- Passwords and API keys
- SSH private keys
- Authentication tokens
- Database credentials
- Personal sensitive data

### Best Practices
- Use `.gitignore` to exclude sensitive files
- Store secrets in a password manager
- Use environment variables for credentials
- Encrypt sensitive backup bundles
- Review generated configs before sharing

## 🧪 Testing

```bash
# Test backup in dry-run mode
./os-config/backup-system.sh --dry-run

# Validate generated cloud-init
cloud-init schema --config-file os-config/cloud-init/user-data/latest.yaml

# Test collectors individually
./os-config/test-collectors.sh
```

## 🤝 Contributing

To add a new collector:

1. Create a script in `collectors/`
2. Output JSON to stdout
3. Include error handling
4. Document the collector
5. Add to the main backup script

## 📚 Additional Resources

- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [cloud-init Examples](https://cloudinit.readthedocs.io/en/latest/topics/examples.html)
- [Best Practices for System Configuration](./docs/best-practices.md)

## 🐛 Troubleshooting

### Common Issues

**Issue**: Permission denied when running collectors
```bash
# Solution: Make scripts executable
chmod +x os-config/collectors/*.sh
chmod +x os-config/*.sh
```

**Issue**: Cloud-init validation fails
```bash
# Solution: Check YAML syntax
yamllint os-config/cloud-init/user-data/latest.yaml
```

**Issue**: Missing packages during restore
```bash
# Solution: Check package names for your distribution
# Update the package list in the bundle
```

## 📄 License

This system is part of the bash.d project and follows the same license.

## 🙏 Acknowledgments

Inspired by:
- cloud-init
- Ansible
- Terraform
- dotfiles management tools
- Infrastructure as Code principles
