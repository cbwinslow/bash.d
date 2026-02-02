# AI Agent Guidelines

## Purpose
This directory contains extensible plugins for bash.d ecosystem. Each plugin provides integration with external services, data sources, or AI tools.

## File Placement Rules
- `github.sh`: GitHub API integration, repository management
- `gitlab.sh`: GitLab API integration, CI/CD pipelines
- `google.sh`: Google APIs, Drive, Sheets, Docs integration
- `government.sh`: Government data sources (FBI, Congress, etc.)
- `legislation.sh`: Legislative data (OpenStates, OpenLegislation)
- `ai_tools.sh`: AI tool integrations (Gemini, Kilo, Cline, etc.)
- `opencode.sh`: OpenCode.ai integration and development
- `cloudflare.sh`: Cloudflare services integration
- `oracle.sh`: Oracle Cloud free tier management

## File Naming Conventions
- Plugin files should be named after the service: `service.sh`
- Function names: `service_action_description()`
- Variables: `BASHD_SERVICE_CONFIG_KEY`
- Constants: `BASHD_SERVICE_API_ENDPOINT`

## Automation Instructions
- AI agents should auto-discover available plugins
- Load plugins dynamically based on configuration
- Each plugin must implement standard interface:
  - `plugin_init()`: Initialize plugin
  - `plugin_status()`: Show connection status
  - `plugin_config()`: Configure plugin
  - `plugin_cleanup()`: Cleanup resources

## Integration Points
- Plugins read configuration from `../config/`
- They use security functions from `../src/security.sh`
- They log through central logging system
- They can call other plugins for data exchange
- They register with the main CLI system

## Context
Plugins provide the extensibility layer for bash.d. They allow:
- Easy addition of new data sources
- Integration with any API-based service
- Modular architecture for maintainability
- Community contributions and extensions
- A/B testing of different integrations

## Plugin Template
Each plugin should follow this structure:
```bash
# Plugin metadata
readonly PLUGIN_NAME="service_name"
readonly PLUGIN_VERSION="1.0.0"
readonly PLUGIN_DEPENDENCIES="curl,jq"

# Required functions
plugin_init() {
    # Initialize plugin
}

plugin_status() {
    # Show connection status
}

plugin_config() {
    # Configure plugin settings
}

plugin_cleanup() {
    # Cleanup plugin resources
}
```

## Security Notes
- Never hardcode credentials in plugins
- Use Bitwarden for all credential storage
- Implement proper rate limiting for API calls
- Validate all external data before processing
- Use secure HTTPS connections only
- Implement proper error handling for API failures

## Data Source Specifics
- Government sources: Implement pagination and caching
- AI tools: Handle API rate limits carefully
- Cloud providers: Use official SDKs when available
- Social platforms: Respect API terms of service
- Financial data: Implement proper data validation