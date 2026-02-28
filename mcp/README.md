# MCP Server Configurations

This directory contains configurations for Model Context Protocol (MCP) servers.

## What is MCP?

MCP (Model Context Protocol) is an open protocol that enables AI assistants to connect to external tools and data sources. It allows AI models to:
- Access files and directories
- Execute commands
- Interact with databases
- Connect to APIs

## Available MCP Servers

### Core MCP Servers

| Server | Purpose | Status |
|--------|---------|--------|
| `filesystem` | Read/write files, list directories | TODO |
| `github` | Manage GitHub repos, issues, PRs | TODO |
| `docker` | Manage Docker containers | TODO |
| `postgres` | PostgreSQL database queries | TODO |
| `sqlite` | SQLite database queries | TODO |

## Quick Setup

### 1. Install MCP CLI
```bash
npm install -g @modelcontextprotocol/cli
```

### 2. Configure Servers
Copy template configs and update with your settings:

```bash
# GitHub MCP
cp mcp/github.template.json mcp/github.json
# Edit github.json with your token

# Filesystem MCP  
cp mcp/filesystem.template.json mcp/filesystem.json
# Edit filesystem.json with your paths
```

### 3. Start MCP Server
```bash
mcp serve mcp/github.json
```

## Environment Variables

Many MCP servers support environment variables for authentication:

```bash
# GitHub
export GITHUB_TOKEN="ghp_xxxx"

# Database
export DATABASE_URL="postgresql://user:pass@localhost/db"

# API Keys
export OPENAI_API_KEY="sk-xxxx"
```

## Integration with AI Tools

### Cline (VSCode)
Add MCP servers to Cline's configuration.

### Claude Desktop
Add to `~/Library/Application Support/Claude/claude_desktop_config.json`

### Ollama
MCP can connect to Ollama for local inference.

## Templates

See the `templates/` subdirectory for example configurations.

---

*For more info: https://modelcontextprotocol.io*
