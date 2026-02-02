# AI Agent Guidelines

## Purpose
This directory contains Infrastructure as Code for all cloud resources. Includes Terraform and Pulumi configurations for Oracle Cloud free tier, Cloudflare setup, and DNS management for cloudcurio.cc.

## File Placement Rules
- `cloudflare/`: Cloudflare Workers, R2 storage, DNS, CDN configuration
- `oracle/`: Oracle Cloud free tier resources, compute instances, storage
- `terraform/`: Terraform configurations for all providers
- `pulumi/`: Pulumi infrastructure as code
- `dns/`: Domain management, SSL certificates, routing rules
- `kubernetes/`: K8s manifests, deployment configurations
- `docker/`: Dockerfiles, compose files, container configs

## File Naming Conventions
- Terraform: `provider_service.tf`, `variables.tf`, `outputs.tf`
- Pulumi: `index.ts`, `Pulumi.yaml`, `stack.yaml`
- Docker: `Dockerfile`, `docker-compose.yml`, `.dockerignore`
- K8s: `namespace.yaml`, `deployment.yaml`, `service.yaml`
- Scripts: `deploy_provider.sh`, `setup_service.sh`

## Automation Instructions
- AI agents should validate infrastructure before deployment
- Use remote state management for all IaC
- Implement proper secret management via Bitwarden
- Use infrastructure testing before production deployment
- Implement proper tagging for resource management
- Use cost optimization for cloud resources

## Integration Points
- Reads configuration from `../config/`
- Uses credentials from Bitwarden integration
- Deploys to cloud providers defined in configuration
- Logs all deployment activities
- Integrates with CI/CD from GitHub/GitLab

## Context
This directory defines all cloud infrastructure for bash.d ecosystem. It provides:
- Automated provisioning of development and production environments
- Infrastructure as Code for reproducibility
- Cost optimization through free tier usage
- Global content delivery via CDN
- Scalable architecture for future growth
- Disaster recovery through infrastructure automation

## Provider Specifics
- **Cloudflare**: Primary hosting, CDN, serverless functions
- **Oracle**: Free tier compute, storage, database
- **GitHub**: Container registry, pages, actions
- **GitLab**: CI/CD, container registry
- **DNS**: Domain management for cloudcurio.cc

## Security Standards
- Use HTTPS for all infrastructure endpoints
- Implement proper network security groups
- Use IAM roles instead of access keys
- Encrypt all storage volumes
- Implement proper backup strategies
- Use WAF and DDoS protection
- Regular security audits of infrastructure

## Cost Optimization
- Prioritize free tier resources
- Use auto-scaling to minimize costs
- Implement proper resource tagging
- Regular cost monitoring and alerts
- Use spot instances when possible
- Implement proper cleanup of unused resources

## Environment Management
- Separate environments: dev, staging, production
- Use environment-specific configurations
- Implement proper secret management per environment
- Use blue-green deployments for production
- Maintain infrastructure parity between environments