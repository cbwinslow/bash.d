# Security — bash.d

## Security Goals
- Keep sensitive data out of the repo (use Bitwarden)
- Enforce least privilege for production systems
- Harden the environment and automated deployments
- Monitor for anomalies and respond rapidly

## Secrets & Credentials
- Use Bitwarden for all secrets, avoid hardcoded passwords
- Rotate credentials regularly
- Store runtime secrets in secure runtime stores (Vault, Cloud KMS)

## Code & Infrastructure
- Run SAST and dependency scanning in CI
- Enforce secure defaults in IaC templates
- Use immutable infrastructure and reproducible builds

## Runtime
- Use TLS for all network traffic
- Enable strict Content Security Policies for the platform
- Implement logging, monitoring, and automated alerting

## Incident Response
- Maintain an incident response plan and runbooks
- Practice tabletop drills and postmortems

## Compliance
- Prepare for SOC2 and GDPR by design
- Implement access controls, audit logging, and PII minimization