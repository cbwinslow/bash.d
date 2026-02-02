# AI Agent Guidelines

## Purpose
This directory contains the core functionality for the bash.d enterprise ecosystem. All core system functions, security management, cloud integrations, and data processing logic are implemented here.

## File Placement Rules
- `core.sh`: Main system functions and utilities
- `security.sh`: Bitwarden integration, credential management, encryption
- `cloudflare.sh`: Cloudflare API, R2 storage, Workers functions
- `oracle.sh`: Oracle Cloud free tier management
- `data_integrations.sh`: Unified data source connectors
- `web.sh`: Web server, API gateway, content delivery
- `ai.sh`: AI tool integrations and automation

## File Naming Conventions
- Use lowercase letters and underscores only
- Function names should be descriptive: `setup_bitwarden_mcp()`
- Variables should be prefixed: `BASHD_CLOUDFLARE_TOKEN`
- Constants should be uppercase: `readonly BASHD_VERSION="1.0.0"`

## Automation Instructions
- AI agents should source files in dependency order
- Always check for required dependencies before execution
- Use the logging functions from core.sh for all operations
- Validate all external API calls before execution
- Implement proper error handling with try/catch patterns

## Integration Points
- Depends on configuration from `../config/`
- Uses plugins from `../plugins/`
- Logs to central logging system
- Interfaces with infrastructure in `../infrastructure/`
- Processes data from `../data/`

## Context
This is the heart of the bash.d ecosystem. All major functionality flows through these core modules. They provide:
- System initialization and configuration management
- Security and credential orchestration
- Cloud provider abstraction
- Data source integration
- Web and API serving
- AI and automation capabilities

## Dependencies
- Must have `../config/default.yaml` for configuration
- Requires `../package.yaml` for metadata
- Expects logging functions to be available
- Needs external CLI tools installed (defined in package.yaml)

## Security Notes
- Never log sensitive information
- Use Bitwarden for all credential storage
- Implement proper encryption for data at rest
- Validate all inputs before processing
- Use secure channels for API communication