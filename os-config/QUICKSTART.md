# OS Configuration Backup - Quick Start Guide

## 🚀 5-Minute Setup

### Step 1: Backup Your System

```bash
cd /path/to/bash.d
./os-config/backup-system.sh
```

This creates a complete backup of your system configuration in `os-config/bundles/latest/`.

### Step 2: View the Results

```bash
# See what was collected
ls -lh os-config/bundles/latest/

# View package list
cat os-config/bundles/latest/packages.json | jq '.package_managers[] | .manager'

# View system info
cat os-config/bundles/latest/system.json | jq '.os_info'

# Check cloud-init configuration
cat os-config/bundles/latest/cloud-init-user-data.yaml
```

### Step 3: Use Your Backup

**Option A: Cloud-Init (for new VMs)**
```bash
# Copy to cloud provider
cp os-config/bundles/latest/cloud-init-user-data.yaml ~/user-data.yaml

# Use when creating new VM instance
# AWS: --user-data file://user-data.yaml
# GCP: --metadata-from-file user-data=user-data.yaml
# Azure: --custom-data user-data.yaml
```

**Option B: Manual Restoration**
```bash
# On the new machine
./os-config/restore-system.sh os-config/bundles/latest/

# Follow the manual steps shown
cat os-config/bundles/latest/SETUP_GUIDE.md
```

**Option C: Share with AI Agent**
```bash
# All JSON files are AI-friendly
# Example: Ask an AI to recreate your environment
"Please read these files and help me set up a new development machine:
- os-config/bundles/latest/system.json
- os-config/bundles/latest/packages.json
- os-config/bundles/latest/tools.json"
```

## 📦 What Gets Backed Up?

- ✅ **Packages**: apt, pip, npm, brew, cargo, go, snap, flatpak, gem
- ✅ **System**: OS info, users, services, cron jobs, network config
- ✅ **Dotfiles**: .bashrc, .vimrc, .gitconfig, SSH configs, etc.
- ✅ **Tools**: git, docker, kubectl, programming languages
- ✅ **Databases**: PostgreSQL, MySQL, MongoDB, Redis, SQLite
- ✅ **Containers**: Docker/Podman containers and images
- ✅ **Repositories**: Local git repositories with status
- ✅ **Themes**: Fonts, terminal themes, GTK themes

## 🎯 Common Use Cases

### 1. Team Onboarding
```bash
# Create backup
./os-config/backup-system.sh --name "dev-environment-2024"

# Share with team
tar -czf dev-env.tar.gz os-config/bundles/dev-environment-2024/
# Upload to shared location
```

### 2. Disaster Recovery
```bash
# Set up automated backups
echo "0 2 * * 0 /path/to/bash.d/os-config/backup-system.sh --auto" | crontab -

# Restore after disaster
./os-config/restore-system.sh os-config/bundles/latest/
```

### 3. Multi-Environment Setup
```bash
# Backup production
./os-config/backup-system.sh --name "production"

# Apply to staging
scp -r os-config/bundles/production/ staging:/tmp/
ssh staging "cd /tmp && ./os-config/restore-system.sh production/"
```

### 4. Migration to Cloud
```bash
# Create backup on old server
./os-config/backup-system.sh --name "on-premise-server"

# Use cloud-init on new cloud VM
# The backup includes a ready-to-use cloud-init file!
```

## 🔧 Advanced Options

### Named Backups
```bash
./os-config/backup-system.sh --name "before-upgrade"
./os-config/backup-system.sh --name "production-baseline"
```

### Custom Output Directory
```bash
./os-config/backup-system.sh --output-dir /backup/location
```

### Dry Run (See What Would Be Collected)
```bash
./os-config/backup-system.sh --dry-run
```

### Test Collectors
```bash
./os-config/test-collectors.sh
```

## 🤖 AI Agent Integration

### For AI Assistants
Each bundle contains:
1. **Structured JSON**: Machine-readable configuration data
2. **Setup Guide**: Natural language instructions
3. **Cloud-Init**: Automation script
4. **Metadata**: Backup details and tracking

### Example AI Prompt
```
"I have a system backup in os-config/bundles/latest/ with these files:
- system.json (OS and hardware info)
- packages.json (all installed packages)
- tools.json (development tools)

Please create a script to recreate this environment on Ubuntu 24.04."
```

## 📖 Need More Help?

- Full documentation: [README.md](README.md)
- Cloud-init examples: [templates/cloud-init-example.yaml](templates/cloud-init-example.yaml)
- Restoration guide: See `SETUP_GUIDE.md` in any backup bundle

## ⚠️ Important Notes

1. **Secrets**: Sensitive data (passwords, API keys) is filtered out
2. **Review**: Always review backups before sharing
3. **Update**: Re-run backup after major system changes
4. **Storage**: Backups are in `os-config/bundles/` (excluded from git)

## 🎉 That's It!

You now have a portable, AI-friendly backup of your system configuration!
