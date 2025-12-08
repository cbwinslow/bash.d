# OS Configuration Backup - Best Practices

## Backup Best Practices

### 1. Regular Backups

```bash
# Create a cron job for weekly backups
0 2 * * 0 /path/to/bash.d/os-config/backup-system.sh --auto

# Or use systemd timers
# Create /etc/systemd/system/os-backup.timer
[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

### 2. Naming Conventions

Use descriptive, dated names:
```bash
# Good
./backup-system.sh --name "production-$(date +%Y%m%d)"
./backup-system.sh --name "pre-upgrade-v2.1"
./backup-system.sh --name "baseline-2024-Q1"

# Avoid
./backup-system.sh --name "backup"
./backup-system.sh --name "test"
```

### 3. Storage and Retention

```bash
# Keep backups organized
/backup/
├── daily/
│   ├── monday/
│   ├── tuesday/
│   └── ...
├── weekly/
│   └── 2024-W48/
└── monthly/
    └── 2024-12/

# Retention policy example
# Daily: 7 days
# Weekly: 4 weeks  
# Monthly: 12 months
# Yearly: indefinite
```

### 4. Verification

Always verify backups after creation:
```bash
# Check metadata
cat os-config/bundles/latest/metadata.json

# Validate JSON files
for f in os-config/bundles/latest/*.json; do
    echo "Checking $f..."
    jq . "$f" > /dev/null && echo "✓ Valid" || echo "✗ Invalid"
done

# Validate cloud-init
cloud-init schema --config-file \
    os-config/bundles/latest/cloud-init-user-data.yaml
```

## Security Best Practices

### 1. Review Before Sharing

```bash
# Always review sensitive data before sharing
grep -r "password\|secret\|key\|token" os-config/bundles/latest/

# Check environment variables
jq '.environment.environment_variables[] | select(.name | contains("KEY"))' \
    os-config/bundles/latest/system.json
```

### 2. Encrypt Sensitive Backups

```bash
# Encrypt entire bundle
tar czf - os-config/bundles/production/ | \
    gpg --symmetric --cipher-algo AES256 \
    > production-backup.tar.gz.gpg

# Decrypt when needed
gpg --decrypt production-backup.tar.gz.gpg | \
    tar xzf -
```

### 3. Secure Storage

```bash
# Set restrictive permissions
chmod 700 os-config/bundles/
chmod 600 os-config/bundles/*/

# Use secure storage
# - Encrypted volumes
# - Cloud storage with encryption at rest
# - Backup vaults with access controls
```

### 4. Secrets Management

Never include secrets in backups. Use dedicated tools:
```bash
# Use environment variables at runtime
export DB_PASSWORD=$(cat /secure/path/password)

# Use secret management tools
# - HashiCorp Vault
# - AWS Secrets Manager
# - Azure Key Vault
# - Bitwarden CLI
```

## Restoration Best Practices

### 1. Test Restorations

```bash
# Test in a VM first
# 1. Create a test VM
# 2. Apply backup
# 3. Verify functionality
# 4. Document any issues

# Use dry-run mode
./os-config/restore-system.sh /path/to/bundle --dry-run
```

### 2. Staged Approach

```bash
# Restore in stages
# Stage 1: System packages
# Stage 2: Language packages (pip, npm)
# Stage 3: Configuration files
# Stage 4: Application setup
# Stage 5: Data restoration (separate process)

# Verify each stage
./scripts/verify-stage-1.sh
./scripts/verify-stage-2.sh
# ...
```

### 3. Documentation

Keep a restoration log:
```bash
# Create restoration log
cat > restoration-log-$(date +%Y%m%d).md << 'EOF'
# Restoration Log

## Date: $(date)
## Bundle: production-20241208
## Target: new-prod-server

### Stage 1: Packages
- [x] APT packages installed
- [x] Python packages installed
- [ ] NPM packages (had issues with package X)

### Issues
1. Package conflict: resolved by...
2. Missing dependency: installed manually

### Notes
- Server timezone set to UTC
- Docker configured with custom daemon.json
EOF
```

## Cloud Deployment Best Practices

### 1. Cloud-Init Validation

```bash
# Always validate before deployment
cloud-init schema --config-file user-data.yaml

# Test with cloud-init locally
# Ubuntu/Debian:
sudo cloud-init clean
sudo cloud-init init
sudo cloud-init modules --mode config
sudo cloud-init modules --mode final
```

### 2. Cloud Provider Specific

#### AWS EC2
```bash
# Use with user-data
aws ec2 run-instances \
    --image-id ami-xxxxx \
    --instance-type t3.micro \
    --user-data file://user-data.yaml

# Monitor cloud-init logs
ssh ubuntu@instance tail -f /var/log/cloud-init-output.log
```

#### Google Cloud
```bash
# Use metadata
gcloud compute instances create my-instance \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --metadata-from-file user-data=user-data.yaml
```

#### Azure
```bash
# Use custom-data
az vm create \
    --name myVM \
    --image UbuntuLTS \
    --custom-data user-data.yaml
```

### 3. Cloud-Init Best Practices

```yaml
#cloud-config
# Include logging
output: {all: '| tee -a /var/log/cloud-init-output.log'}

# Set timeout for commands
runcmd:
  - timeout 300 apt-get update
  - timeout 600 apt-get upgrade -y

# Add error handling
runcmd:
  - apt-get update || echo "Update failed" >> /var/log/setup-errors.log
  - apt-get install -y package || echo "Package install failed" >> /var/log/setup-errors.log

# Use final_message for completion notification
final_message: "System setup completed at $TIMESTAMP"
```

## Maintenance Best Practices

### 1. Regular Updates

```bash
# Update backup after major changes
- System upgrades
- New software installations
- Configuration changes
- Security updates

# Version your backups
./backup-system.sh --name "v1.0-baseline"
# Make changes
./backup-system.sh --name "v1.1-after-docker-install"
```

### 2. Cleanup Old Backups

```bash
# Automated cleanup script
#!/bin/bash
BACKUP_DIR="/path/to/os-config/bundles"
KEEP_DAYS=30

find "$BACKUP_DIR" -type d -name "backup-*" -mtime +$KEEP_DAYS -exec rm -rf {} \;
```

### 3. Audit Trail

```bash
# Keep a changelog
cat >> os-config/CHANGELOG.md << EOF
## $(date +%Y-%m-%d) - v1.2
### Added
- PostgreSQL 15 database
- Redis cache server

### Changed
- Upgraded Node.js from 18 to 20
- Updated nginx configuration

### Removed
- Legacy Python 2.7 packages
EOF
```

## Team Collaboration Best Practices

### 1. Shared Baselines

```bash
# Create team baseline
./backup-system.sh --name "team-dev-baseline-2024"

# Document in README
cat >> README.md << 'EOF'
## Development Environment Setup

Use the team baseline to set up your environment:
```bash
./os-config/restore-system.sh bundles/team-dev-baseline-2024/
```
EOF
```

### 2. Environment Profiles

```bash
# Create profiles for different roles
./backup-system.sh --name "frontend-developer"
./backup-system.sh --name "backend-developer"
./backup-system.sh --name "devops-engineer"
./backup-system.sh --name "data-scientist"
```

### 3. Documentation

```bash
# Document custom configurations
cat > os-config/docs/CUSTOM_SETUP.md << 'EOF'
# Custom Configuration

## Additional Steps Not in Backup

1. Install proprietary software
   ```bash
   # Obtain license from...
   # Install from...
   ```

2. Configure VPN
   ```bash
   # Get VPN config from...
   ```

3. Set up SSH keys
   ```bash
   # Generate new key
   ssh-keygen -t ed25519
   # Add to GitHub/GitLab
   ```
EOF
```

## AI Agent Integration Best Practices

### 1. Context Provision

```bash
# Provide clear context to AI
"I have a system backup in os-config/bundles/production/ 
containing:
- packages.json: All installed packages
- system.json: OS configuration
- tools.json: Development tools

Please help me:
1. Identify security vulnerabilities in outdated packages
2. Suggest optimizations
3. Generate a migration script to Ubuntu 24.04"
```

### 2. Structured Queries

```bash
# Be specific in requests
"Based on packages.json, create:
1. A requirements.txt with Python packages
2. A package.json with npm packages
3. An install script that handles both"

# Not: "Help me with my packages"
```

### 3. Validation

```bash
# Always validate AI-generated scripts
bash -n generated-script.sh  # Syntax check
shellcheck generated-script.sh  # Linting
./generated-script.sh --dry-run  # Test run
```

## Troubleshooting Best Practices

### 1. Enable Verbose Logging

```bash
# Run collectors with full output
bash -x os-config/collectors/packages.sh 2>&1 | tee packages-debug.log

# Run backup with debugging
bash -x os-config/backup-system.sh --name "debug-test" 2>&1 | tee backup-debug.log
```

### 2. Validate Dependencies

```bash
# Check required tools
for tool in jq tar git docker; do
    command -v $tool &>/dev/null && echo "✓ $tool" || echo "✗ $tool missing"
done
```

### 3. Common Issues

```bash
# Issue: Collectors fail silently
# Solution: Check stderr output
bash os-config/collectors/system.sh 2>&1 | tee system-output.log

# Issue: JSON validation fails
# Solution: Use jq to find errors
jq . packages.json

# Issue: Cloud-init doesn't work
# Solution: Check cloud-init logs on target
ssh ubuntu@server "tail -f /var/log/cloud-init-output.log"
```

## Performance Best Practices

### 1. Optimize Collection

```bash
# Limit repository search depth
./os-config/collectors/repositories.sh 2  # Only 2 levels deep

# Exclude large directories
export EXCLUDE_DIRS="/var/cache /tmp"

# Use parallel processing (advanced)
# Run independent collectors in parallel
```

### 2. Compress Bundles

```bash
# Compress old bundles
tar czf backups/bundle-2024-11.tar.gz os-config/bundles/2024-11-*/

# Use better compression for archival
tar cJf backups/bundle-2024-11.tar.xz os-config/bundles/2024-11-*/
```

### 3. Incremental Backups

```bash
# Track changes between backups
diff -r bundles/baseline/ bundles/latest/ > changes.diff

# Only backup changed collectors
# (Advanced: implement in backup-system.sh)
```

## Compliance and Auditing

### 1. Audit Logging

```bash
# Log all backup operations
./backup-system.sh --name "production" 2>&1 | \
    tee -a /var/log/os-backup-audit.log
```

### 2. Retention Policies

```bash
# Implement retention per compliance requirements
# Example: SOC 2, HIPAA, GDPR

# Automated retention management
./scripts/enforce-retention-policy.sh \
    --keep-daily 30 \
    --keep-weekly 52 \
    --keep-monthly 84 \
    --keep-yearly 10
```

### 3. Change Tracking

```bash
# Git-track backup metadata for change history
cd os-config/bundles/
git init
git add */metadata.json
git commit -m "Backup metadata for compliance"
```

## Summary Checklist

- [ ] Regular automated backups scheduled
- [ ] Backups tested in non-production environment
- [ ] Sensitive data reviewed and excluded
- [ ] Backups stored securely and encrypted
- [ ] Restoration procedures documented
- [ ] Team members trained on backup/restore process
- [ ] Compliance requirements met
- [ ] Retention policy implemented and automated
- [ ] Audit trail maintained
- [ ] Documentation kept up-to-date
