# Agent Zero + Cloudflare Complete Setup Guide

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Detailed Setup](#detailed-setup)
5. [Cloudflare Agents Integration](#cloudflare-agents-integration)
6. [Advanced Features](#advanced-features)
7. [Troubleshooting](#troubleshooting)
8. [Maintenance](#maintenance)

## Overview

This guide helps you set up Agent Zero with Cloudflare Tunnels for secure remote access, plus optional integration with Cloudflare's AI Agents platform for enhanced functionality.

### What You'll Get
- **Agent Zero**: AI-powered assistant with multi-agent cooperation
- **Cloudflare Tunnels**: Secure remote access without port forwarding
- **Custom Domain**: Professional branding with SSL
- **Enhanced Security**: Zero Trust access model
- **Optional AI Integration**: Cloudflare Agents for extended capabilities

## Prerequisites

### Required
- Server/VPS with Docker support (minimum 2GB RAM, 1 CPU)
- Cloudflare account (free tier sufficient)
- Custom domain (recommended but optional)
- SSH access to your server
- Basic command-line knowledge

### Software Dependencies
- Docker and Docker Compose
- curl (usually pre-installed)
- Node.js and npm (for advanced features)

## Quick Start

### 1. Run the Automated Setup
```bash
# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/your-repo/setup-agent-zero-cloudflare.sh | bash

# Or clone and run manually
git clone https://github.com/your-repo/agent-zero-cloudflare.git
cd agent-zero-cloudflare
chmod +x setup-agent-zero-cloudflare.sh
./setup-agent-zero-cloudflare.sh
```

### 2. Follow the Prompts
The script will:
- Install dependencies
- Set up Cloudflare authentication
- Create Docker Compose configuration
- Deploy Agent Zero
- Configure Cloudflare Tunnel

### 3. Access Agent Zero
- **Local**: http://localhost:50001
- **Remote**: https://your-domain.com

## Detailed Setup

### Step 1: Server Preparation

#### Update System
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

#### Install Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Step 2: Cloudflare Setup

#### Domain Configuration
1. Sign up for Cloudflare at https://cloudflare.com
2. Add your domain to Cloudflare
3. Update nameservers to Cloudflare's nameservers
4. Wait for DNS propagation (usually < 1 hour)

#### API Token (Optional)
For automated setup, create an API token:
1. Go to Cloudflare Dashboard > My Profile > API Tokens
2. Create token with permissions:
   - Zone:Zone:Read
   - Zone:DNS:Edit
   - Account:Cloudflare Tunnel:Edit

### Step 3: Agent Zero Deployment

#### Method A: Automated Script
```bash
./setup-agent-zero-cloudflare.sh
```

#### Method B: Manual Setup

1. **Create Docker Compose file**:
```yaml
version: '3.8'

services:
  agent-zero:
    image: agent0ai/agent-zero:latest
    container_name: agent-zero
    ports:
      - "50001:80"
    environment:
      - NODE_ENV=production
    volumes:
      - agent-zero-data:/app/data
      - agent-zero-logs:/app/logs
    restart: unless-stopped

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared-tunnel
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    environment:
      - CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    restart: unless-stopped
    depends_on:
      - agent-zero

volumes:
  agent-zero-data:
  agent-zero-logs:
```

2. **Create .env file**:
```bash
# Cloudflare Tunnel Token
CLOUDFLARE_TUNNEL_TOKEN=your_token_here

# Optional: Custom Domain
CLOUDFLARE_DOMAIN=your-domain.com
```

3. **Deploy**:
```bash
docker-compose up -d
```

### Step 4: Cloudflare Tunnel Configuration

#### Method A: Script-based
```bash
./setup-agent-zero-cloudflare.sh tunnel
```

#### Method B: Manual

1. **Install cloudflared**:
```bash
# Linux
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Or download directly
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/
```

2. **Authenticate**:
```bash
cloudflared tunnel login
```

3. **Create Tunnel**:
```bash
cloudflared tunnel create agent-zero-tunnel
```

4. **Configure Tunnel**:
```bash
# Create config file
mkdir -p ~/.cloudflared
cat > ~/.cloudflared/config.yml << EOF
tunnel: your-tunnel-uuid
credentials-file: ~/.cloudflared/your-tunnel-uuid.json

ingress:
  - hostname: your-domain.com
    service: http://localhost:50001
  - service: http_status:404
EOF
```

5. **Generate Token**:
```bash
cloudflared tunnel token agent-zero-tunnel
```

6. **Add to .env file** and restart services.

## Cloudflare Agents Integration

### Overview
Cloudflare Agents extends Agent Zero with additional capabilities:
- Enhanced reasoning with Workers AI
- State management and persistence
- Real-time communication
- Scheduled tasks
- Web browsing integration

### Setup

#### 1. Install Dependencies
```bash
./setup-cloudflare-agents.sh install
```

#### 2. Create Agent Project
```bash
./setup-cloudflare-agents.sh project
```

#### 3. Deploy Integration
```bash
./setup-cloudflare-agents.sh deploy
```

#### 4. Start Bridge Service
```bash
cd agent-zero-enhanced
npm install
node bridge.js
```

### Features Added

#### Enhanced Reasoning
- Uses Cloudflare Workers AI models
- Provides step-by-step task analysis
- Improves decision-making capabilities

#### State Management
- Persistent conversation history
- Cross-session memory
- User preference storage

#### Real-time Communication
- WebSocket connections
- Live status updates
- Collaborative agent interactions

#### Scheduled Tasks
- Automated workflows
- Periodic maintenance
- Background processing

## Advanced Features

### 1. Custom Domain Setup

#### SSL Certificate
Cloudflare automatically provides free SSL certificates for your custom domain.

#### DNS Configuration
```
A    your-domain.com    your-server-ip
A    www                your-server-ip
CNAME  agent            your-domain.com
```

#### Subdomain for Agent
Configure a specific subdomain for Agent Zero:
```
agent.your-domain.com -> Cloudflare Tunnel
```

### 2. Security Enhancements

#### Cloudflare Access
```bash
# Enable Zero Trust access
# In Cloudflare Dashboard:
# 1. Go to Access > Applications
# 2. Add application for your domain
# 3. Configure authentication rules
# 4. Add policy for allowed users
```

#### Rate Limiting
```bash
# Configure rate limits
# In Cloudflare Dashboard:
# 1. Go to Security > WAF > Rate Limiting Rules
# 2. Create rule for Agent Zero endpoint
# 3. Set appropriate limits (e.g., 100 requests/minute)
```

#### IP Whitelisting
```bash
# Restrict access to specific IPs
# In Cloudflare Dashboard:
# 1. Go to Firewall > Rules
# 2. Create IP rule for your domain
# 3. Add allowed IP ranges
```

### 3. Monitoring and Analytics

#### Cloudflare Analytics
- Request volume and patterns
- Geographic distribution
- Error rates and types
- Performance metrics

#### Custom Monitoring
```bash
# Use the provided monitoring script
./monitor.sh

# Or set up automated monitoring
crontab -e
# Add: */5 * * * * /path/to/monitor.sh >> /var/log/agent-zero-monitor.log 2>&1
```

#### Health Checks
```bash
# Agent Zero health endpoint
curl http://localhost:50001/health

# Cloudflare Agent health endpoint
curl https://your-agent.your-subdomain.workers.dev/health
```

### 4. Backup and Recovery

#### Data Backup
```bash
# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/agent-zero"

mkdir -p $BACKUP_DIR

# Backup Docker volumes
docker run --rm -v agent-zero-data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/data_$DATE.tar.gz -C /data .
docker run --rm -v agent-zero-logs:/logs -v $BACKUP_DIR:/backup alpine tar czf /backup/logs_$DATE.tar.gz -C /logs .

# Backup configuration files
cp docker-compose.yml $BACKUP_DIR/docker-compose_$DATE.yml
cp .env $BACKUP_DIR/env_$DATE

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x backup.sh
```

#### Automated Backups
```bash
# Add to crontab
crontab -e
# Add: 0 2 * * * /path/to/backup.sh
```

## Troubleshooting

### Common Issues

#### 1. Agent Zero Not Starting
```bash
# Check logs
docker-compose logs agent-zero

# Check container status
docker ps -a | grep agent-zero

# Restart service
docker-compose restart agent-zero
```

#### 2. Cloudflare Tunnel Not Working
```bash
# Check cloudflared logs
docker-compose logs cloudflared

# Verify tunnel token
cloudflared tunnel info agent-zero-tunnel

# Test tunnel locally
cloudflared tunnel --url http://localhost:50001
```

#### 3. Domain Not Resolving
```bash
# Check DNS propagation
dig your-domain.com

# Verify nameservers
whois your-domain.com

# Check Cloudflare DNS settings
# In Cloudflare Dashboard > DNS
```

#### 4. Performance Issues
```bash
# Check system resources
docker stats
free -h
df -h

# Check network connectivity
ping your-domain.com
curl -I https://your-domain.com
```

### Debug Mode

#### Enable Debug Logging
```yaml
# In docker-compose.yml
services:
  agent-zero:
    environment:
      - DEBUG=true
      - LOG_LEVEL=debug
```

#### Verbose cloudflared
```bash
# Update cloudflared command
command: tunnel --no-autoupdate --loglevel debug run --token ${CLOUDFLARE_TUNNEL_TOKEN}
```

## Maintenance

### Regular Tasks

#### Weekly
- Check for Agent Zero updates
- Review Cloudflare analytics
- Verify backup integrity
- Monitor system resources

#### Monthly
- Update Docker images
- Review security policies
- Clean up old logs
- Performance optimization

#### Quarterly
- Security audit
- Capacity planning
- Disaster recovery testing
- Documentation updates

### Updates

#### Agent Zero Updates
```bash
# Pull latest image
docker-compose pull agent-zero

# Restart with new image
docker-compose up -d
```

#### Cloudflare Updates
```bash
# Update cloudflared
docker-compose pull cloudflared
docker-compose up -d
```

### Scaling

#### Horizontal Scaling
```yaml
# In docker-compose.yml
services:
  agent-zero:
    deploy:
      replicas: 3
    # ... other configuration
```

#### Resource Scaling
```yaml
# Increase resources
services:
  agent-zero:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

## Support

### Documentation
- [Agent Zero Documentation](https://github.com/agent0ai/agent-zero/blob/main/docs/README.md)
- [Cloudflare Tunnels Documentation](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/)
- [Cloudflare Agents Documentation](https://developers.cloudflare.com/agents/)

### Community
- [Agent Zero Discord](https://discord.gg/B8KZKNsPpj)
- [Cloudflare Community](https://community.cloudflare.com/)
- [GitHub Issues](https://github.com/agent0ai/agent-zero/issues)

### Professional Support
- Cloudflare Enterprise Support
- Agent Zero Premium Support (if available)
- Third-party consulting services

## Conclusion

This setup provides a secure, scalable, and feature-rich deployment of Agent Zero using Cloudflare's infrastructure. You now have:

- ✅ Secure remote access via Cloudflare Tunnels
- ✅ Professional domain with SSL
- ✅ Enhanced security features
- ✅ Optional AI agent integration
- ✅ Monitoring and backup systems
- ✅ Scalability options

Enjoy your enhanced Agent Zero deployment!