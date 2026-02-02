# Global Rules for bash.d Ecosystem

## 🎯 Core Principles

### 1. AI-First Architecture
- Every directory MUST contain an `agents.md` file
- All automation MUST follow agent guidelines
- AI agents SHOULD be able to navigate and understand the entire structure
- File placement MUST be predictable and documented

### 2. Security First
- NEVER hardcode credentials in any file
- ALWAYS use Bitwarden for credential management
- ALL sensitive data MUST be encrypted at rest
- ALL external communication MUST use HTTPS
- ALL user inputs MUST be validated and sanitized

### 3. Convention Over Configuration
- Use consistent naming conventions across all files
- Follow established patterns for new functionality
- Implement standard interfaces for all plugins
- Use YAML for configuration, JSON for data exchange
- Follow semantic versioning for all releases

### 4. Progressive Enhancement
- Start with simple, working functionality
- Add complexity only when needed
- Maintain backward compatibility when possible
- Provide clear migration paths for breaking changes
- Document all deprecation timelines

## 📁 Directory Structure Rules

### Mandatory Files
Every directory MUST contain:
1. `agents.md` - AI agent guidelines (MANDATORY)
2. `README.md` - Directory overview (RECOMMENDED)
3. `.gitignore` - Version control exclusions (RECOMMENDED)

### Naming Conventions
- Files: `lowercase_with_underscores.sh`
- Directories: `lowercase_with_underscores`
- Constants: `UPPERCASE_WITH_UNDERSCORES`
- Functions: `descriptive_action_noun()`
- Variables: `lowercase_with_underscores`
- Configuration: `kebab-case` for keys

### File Organization
- Core functionality in `src/`
- Extensible plugins in `plugins/`
- Data storage in `data/`
- Infrastructure in `infrastructure/`
- Platform code in `platform/`
- Configuration in `config/`

## 🔐 Security Requirements

### Credential Management
- ALL credentials stored in Bitwarden
- Use environment variables for runtime access
- Implement credential rotation policies
- Audit all credential access
- Use hardware authentication when available

### Data Protection
- Encrypt all sensitive data at rest
- Use secure channels for data transmission
- Implement proper data retention policies
- Follow GDPR and privacy regulations
- Validate all external data inputs

### Access Control
- Implement principle of least privilege
- Use role-based access control (RBAC)
- Log all access attempts and changes
- Implement proper session management
- Use multi-factor authentication

## 🚀 Development Standards

### Code Quality
- ALL scripts MUST pass shellcheck validation
- Implement proper error handling
- Use consistent logging throughout
- Write comprehensive tests for all functionality
- Document all functions and complex logic
- Follow DRY (Don't Repeat Yourself) principles

### Testing Requirements
- Unit tests for all functions
- Integration tests for component interactions
- End-to-end tests for complete workflows
- Performance tests for critical paths
- Security tests for all external interfaces
- Minimum 80% code coverage

### Documentation Standards
- Update documentation with every code change
- Include code examples in all documentation
- Use consistent formatting and style
- Provide troubleshooting sections
- Maintain changelog for all releases
- Include performance considerations

## 🌐 Integration Standards

### API Design
- Use RESTful principles for all APIs
- Implement proper HTTP status codes
- Use consistent response formats
- Implement rate limiting and throttling
- Provide comprehensive API documentation
- Use semantic versioning for API changes

### Data Integration
- Implement proper data validation
- Use caching for performance optimization
- Handle pagination for large datasets
- Implement retry logic for transient failures
- Use appropriate data formats (JSON, Parquet, CSV)
- Respect all API terms of service

### Cloud Integration
- Use Infrastructure as Code (IaC) principles
- Implement proper cost optimization
- Use tagging for resource management
- Implement proper backup strategies
- Use multi-region deployment for reliability
- Monitor all cloud resource usage

## 📊 Performance Standards

### Response Time Targets
- API responses: <200ms (95th percentile)
- Page load time: <2 seconds
- Database queries: <100ms average
- File processing: <30 seconds for typical files
- CLI commands: <5 seconds for common operations

### Scalability Requirements
- Handle 1000+ concurrent users
- Process 1TB+ of data monthly
- Support horizontal scaling
- Implement proper caching strategies
- Use CDN for content delivery
- Implement database sharding when needed

## 🔧 Maintenance Standards

### Regular Tasks
- Daily: Security scans and log review
- Weekly: Performance analysis and optimization
- Monthly: Dependency updates and patching
- Quarterly: Security audits and penetration testing
- Annually: Architecture review and optimization

### Backup Requirements
- Daily automated backups
- Weekly backup verification
- Monthly backup restoration testing
- Cross-region backup replication
- Immutable backup storage
- Clear backup retention policies

## 🚨 Compliance Requirements

### Standards Compliance
- SOC 2 Type II compliance for all systems
- GDPR compliance for user data handling
- CCPA compliance for California residents
- Industry-specific compliance as needed
- Regular compliance audits and reporting

### Legal Requirements
- Terms of Service for all public platforms
- Privacy Policy for all data collection
- Cookie Policy for web tracking
- Accessibility compliance (WCAG 2.1 AA)
- Data processing agreements for third-party services

## 🔄 Workflow Standards

### Development Workflow
1. Feature branch creation
2. Development with testing
3. Code review and approval
4. Integration testing
5. Staging deployment
6. Production deployment
7. Monitoring and rollback if needed

### Release Process
1. Version bump and changelog update
2. Documentation updates
3. Full test suite execution
4. Security scanning
5. Performance testing
6. Release deployment
7. Post-release monitoring

## 📝 Documentation Requirements

### Required Documentation
- README.md in every directory
- agents.md in every directory (MANDATORY)
- API documentation for all services
- Architecture documentation for complex systems
- Troubleshooting guides for common issues
- Contribution guidelines for open-source components

### Documentation Standards
- Use Markdown format with front matter
- Include table of contents for long documents
- Use code blocks with syntax highlighting
- Include diagrams for complex concepts
- Provide multiple learning paths
- Maintain version-specific documentation

---

**These rules are mandatory for all bash.d development and maintenance. Violations must be documented and approved.**