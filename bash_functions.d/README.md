# Cline Installation Script

This directory contains the Cline installation script with multiple installation methods and robust error handling.

## Features

- **Multiple Installation Methods**:
  - Direct download (recommended)
  - Package manager installation (if available)
  - AI agent installation (experimental)
  - Docker container setup
  - Build from source

- **Robust Error Handling**:
  - Comprehensive error trapping and recovery
  - Detailed logging
  - Cleanup on failure
  - Recovery options

- **Environmental Adaptation**:
  - Automatic system detection (OS, architecture, shell)
  - Package manager detection
  - Dependency checking and installation
  - Docker environment detection

- **User Experience**:
  - Color-coded output
  - Interactive prompts
  - Progress feedback
  - Configuration management

## Usage

### Direct Execution

```bash
./bash_functions.d/install_cline.sh
```

### Source the Script

```bash
source bash_functions.d/install_cline.sh
```

### Run with Specific Method

The script will prompt you to choose an installation method:

1. **Direct Download** (Recommended) - Downloads binary directly
2. **Package Manager** - Uses system package manager if available
3. **AI Agent Installation** - Uses AI agent to install (experimental)
4. **Docker** - Runs Cline in Docker container
5. **Source Build** - Build from source (advanced)

## Installation Methods

### 1. Direct Download

Downloads the Cline binary directly from GitHub releases and installs it to `~/.local/bin/cline`.

### 2. Package Manager

Attempts to install Cline using the system package manager (APT, Homebrew, etc.). Falls back to direct download if package not found.

### 3. AI Agent Installation

Uses AI agents like Ollama or Docker-based AI containers to perform the installation. This is experimental and requires:

- Ollama installed, or
- Docker available

### 4. Docker Setup

Sets up Cline to run in a Docker container. Creates an alias for easy access.

### 5. Source Build

Builds Cline from source code. Requires:
- Git
- Make
- C compiler (gcc or clang)

## Configuration

The script creates a configuration file at `~/.cline/config.json` with default settings.

## Logging

All installation activities are logged to `~/.cline/install.log`.

## Error Recovery

If installation fails, the script provides recovery options:
- Retry with different method
- Show manual installation instructions
- View detailed logs
- Exit

## Requirements

- Bash shell
- curl or wget
- git (for some methods)
- jq (optional, for JSON processing)

## License

This script is open-source and can be freely used and modified.

## Support

For issues or questions, please refer to the detailed logs or use the recovery options provided by the script.
