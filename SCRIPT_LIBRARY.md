# bash.d Script Library

This document provides a comprehensive index of all scripts and utilities in the bash.d ecosystem.

## 📁 New Scripts Created

### Core Automation Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/inventory.sh` | System inventory - packages, repos, scripts | `./scripts/inventory.sh {all\|packages\|repos\|scripts}` |
| `scripts/backup.sh` | Full system backup to GitHub/R2 | `./scripts/backup.sh {full\|quick\|restore\|status}` |
| `scripts/conversation_logger.sh` | Log AI terminal conversations | `./scripts/conversation_logger.sh {new\|upload\|list\|status}` |
| `apis/api_manager.sh` | Unified API interface | `./apis/api_manager.sh {github\|cloudflare\|test\|status}` |
| `scripts/ai_agent.sh` | AI agent automation via Ollama | `./scripts/ai_agent.sh {chat\|code\|script\|debug\|review}` |

### GitHub Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `.github/workflows/backup.yml` | Daily 2AM / Manual | Automated system backup |

---

## 📦 Quick Start

### 1. Run Full Inventory
```bash
cd ~/bash.d
./scripts/inventory.sh all
```

### 2. Backup Everything
```bash
# Set your GitHub token first
export BACKUP_GITHUB_TOKEN="ghp_xxxx"

# Full backup
./scripts/backup.sh full

# Quick backup (scripts + configs only)
./scripts/backup.sh quick
```

### 3. Log AI Conversations
```bash
# Set token to auto-upload
export CONVERSATION_GITHUB_TOKEN="ghp_xxxx"

# Start new conversation log
./scripts/conversation_logger.sh new cline "My Session"

# Upload all pending logs
./scripts/conversation_logger.sh upload
```

### 4. Use AI Agents
```bash
# Chat with AI
./scripts/ai_agent.sh chat

# Generate code
./scripts/ai_agent.sh code "create a REST API" python

# Debug an error
./scripts/ai_agent.sh debug "permission denied" "writing to /tmp"

# Review code
./scripts/ai_agent.sh review ~/bash.d/scripts/backup.sh
```

### 5. Manage APIs
```bash
# Set tokens
export GITHUB_TOKEN="ghp_xxxx"
export CLOUDFLARE_API_TOKEN="xxxx"

# Check status
./apis/api_manager.sh status

# List GitHub repos
./apis/api_manager.sh github repos

# List Cloudflare DNS
./apis/api_manager.sh cloudflare dns

# Test connections
./apis/api_manager.sh test
```

---

## 📋 Inventory System

The inventory system (`scripts/inventory.sh`) collects:

- **npm** - Global packages
- **pip** - Python packages  
- **Homebrew** - macOS packages
- **apt** - Debian packages
- **Go** - Go modules
- **Cargo** - Rust packages
- **GitHub** - Repository list
- **Local repos** - All git repos in ~/
- **Scripts** - All .sh files in bash.d
- **Configs** - YAML/JSON configs
- **Docker** - Containers, images, volumes
- **System** - OS info, tools available

Output location: `inventory/` directory with timestamped files.

---

## 🔄 Backup System

The backup system (`scripts/backup.sh`) creates:

1. **Dotfiles** - From `dotfiles/` and `~/`
2. **Configurations** - YAML/JSON configs
3. **Scripts** - All bash scripts
4. **Packages** - Installed package lists
5. **Keys** - SSH/GPG public key metadata (NOT private keys)
6. **Docker** - Compose files and configs

**Features:**
- Compressed tar.gz archives
- SHA256 checksums
- GitHub upload via API
- Cloudflare R2 upload support
- Manifest generation
- Restore capability

---

## 💬 Conversation Logger

Automatically logs AI terminal sessions to `conversation-logs/`.

**Features:**
- Auto-detects AI tool (Cline, Claude, Cursor, etc.)
- Markdown format with metadata
- Auto-upload to GitHub
- Cleanup old logs
- Date-based organization

---

## 🤖 AI Agent System

Uses Ollama for local AI inference. Available models:
- `llama3.2:3b` - Fast, general purpose
- `qwen3:4b` - Good coding abilities
- `deepseek-r1:7b` - Reasoning model
- `dolphin3:latest` - Dolphin model
- `qwen3-vl:4b` - Vision model

**Agents:**
- `chat` - Interactive chat
- `code` - Code generation
- `script` - Bash script generation
- `debug` - Error analysis
- `explain` - Code explanation
- `research` - Topic research
- `bash` - Find commands
- `review` - Code review
- `workflow` - Multi-step planning
- `custom` - Custom prompts

---

## 🌐 API Manager

Unified interface for:
- **GitHub** - Repos, issues, files, workflows
- **Cloudflare** - DNS, Workers, Pages, zones

---

## 🔧 Configuration

### Environment Variables

```bash
# Backup
export BACKUP_GITHUB_TOKEN="ghp_xxxx"
export BACKUP_R2_ENABLED="true"
export R2_ENDPOINT="https://xxxx.r2.cloudflarestorage.com"
export R2_ACCESS_KEY="xxxx"
export R2_SECRET_KEY="xxxx"

# Conversations
export CONVERSATION_GITHUB_TOKEN="ghp_xxxx"
export CONVERSATION_AUTO_UPLOAD="true"

# APIs
export GITHUB_TOKEN="ghp_xxxx"
export CLOUDFLARE_API_TOKEN="xxxx"
export CLOUDFLARE_ACCOUNT_ID="xxxx"
export CLOUDFLARE_ZONE_ID="xxxx"

# AI
export OLLAMA_MODEL="qwen3:4b"
```

---

## 📂 Directory Structure

```
bash.d/
├── apis/
│   └── api_manager.sh          # API management
├── conversation-logs/           # AI conversation logs
├── .github/workflows/
│   └── backup.yml              # GitHub Actions backup
├── inventory/                   # System inventory
│   ├── backups/                 # Backup archives
│   ├── pip_*.txt               # pip packages
│   ├── npm_global_*.txt        # npm packages
│   └── ...
├── mcp/                        # MCP configurations (TODO)
├── scripts/
│   ├── ai_agent.sh             # AI agents
│   ├── backup.sh               # Backup system
│   ├── conversation_logger.sh  # Conversation logging
│   └── inventory.sh            # System inventory
└── ...
```

---

## 🚀 Common Workflows

### New System Setup
```bash
# 1. Clone bash.d
git clone https://github.com/cbwinslow/bash.d.git ~/bash.d

# 2. Run inventory to see current state
./scripts/inventory.sh all

# 3. Install packages from inventory (on new system)
./inventory/install_all_*.sh
```

### Daily Backup
```bash
# Automatic via GitHub Actions, or manual:
./scripts/backup.sh full
```

### Log AI Session
```bash
# Start logging
./scripts/conversation_logger.sh new clane "Project setup"

# Work with AI...

# Upload when done
./scripts/conversation_logger.sh upload
```

### Use AI for Help
```bash
# Generate a script
./scripts/ai_agent.sh script "backup files to S3"

# Debug an error
./scripts/ai_agent.sh debug "exit code 1" "running docker build"

# Review code
./scripts/ai_agent.sh review my_script.sh
```

---

## 📝 Notes

- All scripts require `bash` and common tools (`curl`, `jq`)
- Some features require API tokens (GitHub, Cloudflare)
- Ollama must be running for AI agents
- Backup system supports both GitHub and Cloudflare R2
- Conversation logs can auto-cleanup after 30 days

---

*Last updated: $(date)*
