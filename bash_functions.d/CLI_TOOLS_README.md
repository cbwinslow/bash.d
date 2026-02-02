# AI CLI Tools Installation Suite

This directory contains comprehensive installation scripts for multiple AI CLI tools with robust error handling, environmental adaptation, and multiple installation methods.

## Available Installation Scripts

### 1. Cline CLI
**Script**: `install_cline.sh`
**Description**: Cline AI coding assistant CLI
**Installation Methods**:
- Direct download (recommended)
- Package manager
- AI agent installation (experimental)
- Docker container
- Source build

### 2. Gemini CLI
**Script**: `install_gemini.sh`
**Description**: Google Gemini AI CLI tool
**Installation Methods**:
- npm installation (recommended)
- Docker container
- Source build

### 3. Mistral CLI
**Script**: `install_mistral.sh`
**Description**: Mistral AI CLI tool
**Installation Methods**:
- pip installation (recommended)
- Docker container
- Source build

### 4. Qwen-Code CLI
**Script**: `install_qwen.sh`
**Description**: Qwen-Code AI coding assistant
**Installation Methods**:
- Ollama model installation (recommended)
- Docker container
- Source build

### 5. OpenCode CLI
**Script**: `install_opencode.sh`
**Description**: OpenCode coding assistant
**Installation Methods**:
- Wrapper script (recommended)
- Docker container
- Source build

### 6. Kilo-Code CLI
**Script**: `install_kilo.sh`
**Description**: Kilo-Code coding assistant
**Installation Methods**:
- Wrapper script (recommended)
- Docker container
- Source build

### 7. Agent-Zero CLI
**Script**: `install_agentzero.sh`
**Description**: Agent-Zero multi-purpose AI agent
**Installation Methods**:
- Wrapper script (recommended)
- Docker container
- Source build

## Features Across All Scripts

### Robust Error Handling
- Comprehensive error trapping with `trap` mechanism
- Detailed logging to `~/.toolname/install.log`
- Cleanup on failure (removes partial downloads)
- Recovery options menu for failed installations
- Graceful fallback mechanisms

### Environmental Adaptation
- Automatic system detection (OS, architecture, shell)
- Package manager detection (APT, YUM, DNF, Homebrew, Pacman)
- Dependency checking and installation
- Docker environment detection
- PATH management and configuration

### User Experience
- Color-coded output (red for errors, green for success, etc.)
- Interactive prompts with clear options
- Progress feedback and status messages
- Configuration file creation
- Comprehensive help and manual instructions

### Installation Methods
1. **Primary Method**: Package manager (npm, pip, etc.)
2. **Container Method**: Docker setup
3. **Source Method**: Build from source code
4. **Fallback Methods**: Automatic fallback to alternative methods

## Usage Instructions

### Individual Tool Installation

```bash
# Make script executable
chmod +x bash_functions.d/install_<tool>.sh

# Run installation script
./bash_functions.d/install_<tool>.sh

# The script will guide you through installation method selection
```

### Available Tools

1. **Cline**: `./bash_functions.d/install_cline.sh`
2. **Gemini**: `./bash_functions.d/install_gemini.sh`
3. **Mistral**: `./bash_functions.d/install_mistral.sh`

## Installation Methods Explained

### 1. Package Manager Installation (Recommended)
- Uses system package manager (npm, pip, etc.)
- Fastest and most reliable method
- Automatic dependency resolution

### 2. Docker Container Installation
- Runs tool in isolated Docker container
- No system dependency conflicts
- Easy cleanup and management
- Creates convenient aliases

### 3. Source Build Installation
- Builds from official source code
- Most customizable option
- Requires build tools (git, make, etc.)
- Advanced users only

## Technical Details

### System Requirements
- **Cline**: curl/wget, git, jq (optional)
- **Gemini**: Node.js, npm
- **Mistral**: Python 3, pip

### Installation Locations
- Binaries: `~/.local/bin/`
- Configuration: `~/.toolname/`
- Logs: `~/.toolname/install.log`

## Error Recovery

All scripts include comprehensive error recovery:
- Automatic cleanup on failure
- Recovery options menu
- Detailed logging
- Manual installation instructions
- Alternative method suggestions

## Configuration

Each tool creates a configuration file:
- Cline: `~/.cline/config.json`
- Gemini: `~/.gemini/config.json`
- Mistral: `~/.mistral/config.json`

## Logging

Detailed installation logs are saved:
- Cline: `~/.cline/install.log`
- Gemini: `~/.gemini/install.log`
- Mistral: `~/.mistral/install.log`

## Future Tools Planned

Based on research, these additional tools are planned:

### 4. Qwen-Code CLI
- Ollama integration
- Multiple model support
- Docker containers

### 5. Codex CLI
- Research-based approach
- Wrapper script if no official CLI

### 6. Kilo Code CLI
- Research and development

### 7. OpenCode CLI
- Research and development

## Support

For issues with any installation:
1. Check the detailed logs in `~/.toolname/install.log`
2. Use the recovery options provided by each script
3. Refer to the manual installation instructions
4. Check official documentation links

## License

All scripts are open-source and can be freely used and modified.
