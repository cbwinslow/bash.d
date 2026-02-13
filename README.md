# bash.d - Enterprise Development Ecosystem

## 🎯 Overview
bash.d is a comprehensive, enterprise-grade development ecosystem designed for modern workflows, data integration, and AI-powered automation.

## 🚀 Quick Start
```bash
# Clone and setup
git clone https://gitlab.com/cbwinslow/bash.d.git ~/bash.d
cd ~/bash.d
./scripts/unified_install.sh

# Initialize with your profile
./bashd init --email=blaine.winslow@gmail.com --domain=cloudcurio.cc
```

## 📁 Directory Structure
```
bash.d/
├── 📄 package.yaml                 # Package metadata & dependencies
├── 📄 bashd                       # Main CLI entry point
├── 📁 bin/                         # Executable scripts
├── 📁 dotfiles/                    # Dotfiles managed by yadm
├── 📁 src/                        # Core functionality
├── 📁 plugins/                     # Extensible data source plugins
├── 📁 data/                        # Data storage & processing
├── 📁 infrastructure/               # Infrastructure as Code
├── 📁 platform/                    # Your public platform
├── 📁 config/                      # Configuration management
├── 📁 tests/                       # Integrated testing
├── 📁 docs/                        # Unified documentation
└── 📁 scripts/                     # Setup & maintenance scripts

## 📚 Documentation

The project's documentation is located in the `docs/` directory. Key documents include:

- `docs/project_summary.md` — High-level project description and goals.
- `docs/features.md` — List of features and planned improvements.
- `docs/srs.md` — A living software requirements specification.
- `docs/CONTRIBUTING.md` — Contribution guidelines and workflow.
- `docs/architecture.md` — An overview of the system architecture.
- `docs/security.md` — Details on the security model.

If you are new, start by reading the `README.md`, then review the documents in the `docs/` directory to get oriented.
```

## 🏗️ Core Components

### 🔐 Security & Credentials
- **Bitwarden Integration**: Automated credential management with master password CBW89pass
- **MCP Server**: Model Context Protocol for AI agents
- **Encryption**: GPG + Age for file encryption
- **Hardware Auth**: YubiKey support

### ☁️ Cloud Infrastructure
- **Cloudflare**: Primary hosting (cloudcurio.cc)
- **Oracle Cloud**: Free tier infrastructure
- **GitHub/GitLab**: Repository management
- **R2 Storage**: Unlimited file storage

### 📊 Data Integration
- **Government Sources**: Congress.gov, GovInfo.gov, FBI.gov
- **Legislation**: OpenStates.org, OpenLegislation.org
- **AI Tools**: OpenCode.ai, Gemini, VSCode, Windsurf
- **Census/ACS**: Demographic and survey data

### 🌐 Public Platform
- **Blog Engine**: Markdown-based content management
- **Data Portal**: Public data interface with pagination
- **API Gateway**: Unified API for all data sources
- **Search**: Full-text search across all content

## 🤖 AI-Powered Features
- **Content Generation**: AI-assisted writing
- **Data Analysis**: Automated insights and patterns
- **Code Generation**: Multiple AI model integration
- **Automation**: Intelligent task automation

## 🛠️ Development Tools
- **CLI Interface**: Unified command-line interface
- **Plugin System**: Extensible architecture
- **Testing**: Integrated unit, integration, and E2E tests
- **Documentation**: Auto-generated and always current

## 📈 Enterprise Features
- **High Availability**: 99.9% uptime target
- **Security**: Zero-trust architecture
- **Scalability**: Auto-scaling infrastructure
- **Compliance**: SOC 2, GDPR ready
- **Monitoring**: Real-time analytics and alerting

## 🔧 Quick Commands
```bash
# Setup everything
./bashd setup

# Manage content
./bashd blog create "My New Post"
./bashd data sync --source=census
./bashd platform deploy

# AI integration
./bashd ai generate --type=blog --topic="data analysis"
./bashd ai analyze --data-source=congress

# Infrastructure
./bashd infra deploy --provider=cloudflare
./bashd infra status --provider=oracle
```

## 📈 Enterprise Features
- **High Availability**: 99.9% uptime target
- **Security**: Zero-trust architecture
- **Scalability**: Auto-scaling infrastructure
- **Compliance**: SOC 2, GDPR ready
- **Monitoring**: Real-time analytics and alerting

## 🤝 Contributing
This is an open-Source ecosystem. Contributions welcome!
- Fork the repository
- Create a feature branch
- Submit a pull request
- Follow the contribution guidelines

## 📄 License
MIT License - see LICENSE file for details

---
*Built with ❤️ for modern development workflows*
