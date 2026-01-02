# AI Coding Tools - Simple & Clean

A clean, simple setup for AI coding tools using **Direnv + NVM**.

## 🚀 Quick Start

```bash
# Setup once
./setup_direnv_nvm.sh

# Use anytime
cd /home/cbwinslow/bash_functions.d/ai_coding_tools
forgecode --version
qwen-code --version
cline version
```

## 📋 Available Tools

| Tool | Command | Description |
|------|---------|-------------|
| **Forgecode** | `forgecode` | AI pair programmer |
| **Qwen Code** | `qwen-code` | Alibaba's coding agent |
| **Codex** | `codex` | OpenAI's coding assistant |
| **Kilo Code** | `kilo-code` | Open source AI assistant |
| **Cline** | `cline` | Autonomous coding agent |
| **Continue** | `continue` | VS Code extension CLI |

## 🛠️ Installation Commands

```bash
# Install individual tools
install-forgecode
install-qwen-code
install-codex
install-kilo-code
install-cline
install-continue

# Master management
ai-tools check
ai-tools install forgecode
ai-tools install all
```

## ⚙️ How It Works

1. **Direnv** automatically loads environment when you enter the directory
2. **NVM** manages Node.js versions
3. **NPX** runs tools without installation
4. **Lazy loading** - installers only load when needed

## 📁 Files (Clean & Minimal)

- `.envrc` - Environment configuration (auto-loaded by direnv)
- `setup_direnv_nvm.sh` - One-time setup script
- `ai_tools_install.sh` - Master installer
- `*_latest.sh` - Individual tool installers
- `README.md` - This file

## 🧹 Cleanup Done

Removed all complex proxy systems, test files, and redundant loaders. Now you have:

- ✅ Fast shell startup
- ✅ Auto-loading environment
- ✅ Simple commands
- ✅ Clean directory structure

## 🎯 Benefits

- **No more slow shell startup**
- **No more complex bashrc modifications**
- **Auto-load/unload environments**
- **Clean, minimal setup**
- **Easy to maintain**

**That's it! Simple, clean, and working.** 🚀