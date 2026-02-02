# AI Agent Guidelines

## Purpose
This directory contains environment-specific configurations, secrets management, and system settings for different deployment environments.

## File Placement Rules
- `default.yaml`: Default configuration for all environments
- `development.yaml`: Development environment settings
- `production.yaml`: Production environment settings
- `secrets.yaml.example`: Template for secrets (never commit actual secrets)
- `environments/`: Environment-specific sub-configurations
- `schemas/`: Configuration validation schemas

## File Naming Conventions
- Config files: `environment.yaml`
- Secret templates: `secrets.yaml.example`
- Schema files: `config_schema.json`
- Environment files: `env_name.yaml`
- Override files: `local.yaml` (gitignored)

## Automation Instructions
- AI agents should validate configuration against schemas
- Never commit actual secrets to version control
- Use environment variables for sensitive data
- Implement proper configuration inheritance
- Validate all configuration values before use
- Use Bitwarden for secret management

## Integration Points
- Read by all bash.d components
- Used by infrastructure deployment scripts
- Referenced by platform configuration
- Integrated with Bitwarden for secrets
- Used by CI/CD pipelines

## Context
This directory provides configuration management for entire bash.d ecosystem. It ensures:
- Consistent configuration across environments
- Secure secret management
- Validation of all settings
- Easy environment switching
- Configuration inheritance and overrides
- Integration with external services

## Configuration Structure
```yaml
# Base configuration structure
system:
  name: "bash.d"
  version: "1.0.0"
  environment: "development"
  
user:
  email: "blaine.winslow@gmail.com"
  domain: "cloudcurio.cc"
  
cloudflare:
  account_id: "${CLOUDFLARE_ACCOUNT_ID}"
  zone_id: "${CLOUDFLARE_ZONE_ID}"
  api_token: "${CLOUDFLARE_API_TOKEN}"
  
oracle:
  region: "us-ashburn-1"
  compartment_id: "${ORACLE_COMPARTMENT_ID}"
  
github:
  username: "cbwinslow"
  token: "${GITHUB_TOKEN}"
  
bitwarden:
  server: "https://bitwarden.com"
  email: "blaine.winslow@gmail.com"
  client_id: "${BITWARDEN_CLIENT_ID}"
```

## Security Standards
- Use environment variables for all secrets
- Implement proper configuration validation
- Use separate configs per environment
- Never log sensitive configuration values
- Implement configuration encryption for production
- Use Bitwarden for shared secret management

## Environment Management
- **Development**: Local development with debug enabled
- **Staging**: Pre-production testing environment
- **Production**: Live environment with full security
- **Testing**: Isolated environment for automated tests

## Configuration Validation
- Validate required fields are present
- Check data types and formats
- Validate URLs and endpoints
- Check credential format and validity
- Validate integration settings
- Test connectivity to external services