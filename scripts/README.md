# Scripts Directory

This directory contains various scripts for managing the multi-agentic system.

## Agent Generation

### simple_agent_generator.py ✅ (WORKING)
Use this script to generate agents. It's a simplified, working version that generates functional agent files.

```bash
python3 scripts/simple_agent_generator.py
```

Currently generates 10 agents as proof of concept. Can be easily extended to generate more.

### generate_agents.py ⚠️ (NEEDS FIXES)
This script contains definitions for all 100 agents but has f-string syntax issues that need to be resolved. The definitions are complete and can be used as reference.

**Known Issues:**
- Complex f-string nesting causing syntax errors
- Needs refactoring to use simpler string formatting

**To Fix:**
- Replace complex f-strings with simple string concatenation
- Or use template strings instead of f-strings
- Reference simple_agent_generator.py for working pattern

## Installation Scripts

### install/install_docker.sh ✅
Installs Docker and Docker Compose using official .deb packages.

```bash
./scripts/install/install_docker.sh
```

Requirements: Ubuntu/Debian, sudo privileges

### install/setup_environment.sh ✅
Complete environment setup including Python venv, dependencies, and configurations.

```bash
./scripts/install/setup_environment.sh
```

## System Management

### start_system.sh ✅
Quick start script for launching all services.

```bash
./scripts/start_system.sh
```

This script:
- Checks prerequisites
- Pulls Docker images
- Starts all services
- Verifies health
- Displays access information

## Usage Pattern

For a fresh setup:

```bash
# 1. Install Docker
./scripts/install/install_docker.sh

# 2. Setup environment
./scripts/install/setup_environment.sh

# 3. Configure API keys
nano .env

# 4. Start system
./scripts/start_system.sh
```

## Development

All scripts are:
- Executable (chmod +x applied)
- Well-documented with comments
- Include error handling
- Provide colored output for clarity

## Contributing

When adding new scripts:
1. Follow the existing patterns
2. Add proper error handling
3. Include usage documentation
4. Make scripts executable
5. Update this README
