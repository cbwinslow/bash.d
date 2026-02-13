# Enhanced GitHub API & Cloudflare Storage System

A comprehensive suite of bash functions for GitHub repository management, Cloudflare R2 storage, and organized file management with robust error handling, automatic retries, and seamless integration.

## 🏗️ System Architecture

### Core Components

1. **Enhanced GitHub API Wrapper** (`tools/github_api_enhanced.sh`)
   - Repository creation (public/private) with descriptions
   - File commits with automatic folder creation
   - Repository listing with sorting/filtering
   - Robust error handling with rate limiting and retries
   - Bitwarden integration for secure credential management

2. **Cloudflare R2 Storage Wrapper** (`tools/cloudflare_storage.sh`)
   - S3-compatible API integration
   - File upload/download with compression
   - Directory synchronization
   - Automatic retry and error recovery
   - Bitwarden credential management

3. **File Management System** (`tools/file_manager.sh`)
   - Categorized file storage (agents, rules, tools, logs, todos, configs, memorys)
   - Automatic backup and versioning
   - Remote sync to GitHub/Cloudflare
   - JSON-based metadata indexing
   - Search and retrieval capabilities

4. **Quick Shell Functions** (`tools/quick_functions.sh`)
   - One-liner interfaces for common operations
   - Auto-template generation
   - Smart defaults and error handling
   - Integrated todo management

5. **Test Framework** (`tools/test_system.sh`)
   - Comprehensive integration testing
   - Dependency verification
   - Error handling validation
   - Auto-completion testing

## 🚀 Quick Start

### 1. Setup Credentials

Store your credentials in Bitwarden:

```bash
# GitHub Personal Access Token
bw create item github_pat \
  --username="your-github-username" \
  --password="your-pat-token"

# Cloudflare R2 Credentials  
bw create item cloudflare_r2 \
  --username="your-email@example.com" \
  --password="your-api-key" \
  --field="account_id=your-account-id" \
  --field="access_key=your-access-key" \
  --field="secret_key=your-secret-key"
```

### 2. Load the System

```bash
# Load all functions
source ~/bash_functions.d/tools/quick_functions.sh

# Check system status
quick_status
```

### 3. Basic Usage

```bash
# Create a private repository with backup
quick_repo my-awesome-project --private --backup

# Commit file to repository
quick_commit user/repo config/settings.json '{"debug": true}' --message='Add debug config'

# Upload file to cloud storage
quick_upload ./large-file.zip archives/backup.zip --compress

# Create agent configuration
quick_agent web-scraper --github=configs-repo --sync

# Add todo item
quick_todo "Implement authentication system" --list=backend-tasks --github=tasks-repo
```

## 📋 API Reference

### GitHub API Functions

#### `gh_create_repo <name> [options]`
Create a new GitHub repository.

**Options:**
- `--public`: Public repository (default)
- `--private`: Private repository
- `description="<text>"`: Repository description
- `--backup`: Create backup repository
- `--no-auto-init`: Don't initialize with README

**Examples:**
```bash
gh_create_repo my-project --public --description="My new project"
gh_create_repo secret-project --private --backup
```

#### `gh_commit_file <repo> <file_path> [content] [options]`
Commit or update a file in a repository.

**Options:**
- `--message="<text>"`: Commit message
- `--branch="<name>"`: Target branch (default: main)
- `--backup`: Create local backup

**Examples:**
```bash
gh_commit_file user/repo config/settings.json '{"debug": true}'
gh_commit_file user/repo docs/readme.md "# My Project" --message="Add README"
```

#### `gh_list_repos [options]`
List repositories with sorting and filtering.

**Options:**
- `--sort=<field>`: Sort by created, updated, pushed, full_name
- `--order=<direction>`: asc or desc
- `--type=<type>`: all, owner, member
- `--filter=<pattern>`: Filter by name pattern
- `--limit=<number>`: Limit results

**Examples:**
```bash
gh_list_repos --sort=updated --order=desc
gh_list_repos --filter=project --type=owner
```

### Cloudflare Functions

#### `cf_upload_file <bucket> <local_file> <remote_path> [options]`
Upload file to Cloudflare R2 bucket.

**Options:**
- `--compress`: Compress file before upload
- `--backup`: Create local backup
- `--overwrite`: Overwrite existing file

**Examples:**
```bash
cf_upload_file my-bucket ./data.json backup/data.json --compress
cf_upload_file my-bucket ./image.png assets/images/image.png
```

#### `cf_download_file <bucket> <remote_path> <local_file> [options]`
Download file from Cloudflare R2.

**Options:**
- `--overwrite`: Overwrite existing local file

**Examples:**
```bash
cf_download_file my-bucket backup/data.json ./restored_data.json
cf_download_file my-bucket assets/images/logo.png ./logo.png
```

#### `cf_sync_directory <bucket> <local_dir> <remote_prefix> [options]`
Sync directory to Cloudflare R2.

**Options:**
- `--delete`: Delete remote files not in local directory
- `--compress`: Compress files during upload

**Examples:**
```bash
cf_sync_directory my-bucket ./assets assets/ --compress
cf_sync_directory my-bucket ./backup backup/ --delete
```

### File Management Functions

#### `fm_store_file <category> <filename> <content> [options]`
Store file in categorized system.

**Categories:** agents, rules, tools, logs, todos, configs, memorys

**Options:**
- `--github=<repo>`: Sync to GitHub repository
- `--cloudflare=<bucket>`: Sync to Cloudflare bucket
- `--backup`: Create backup before operation
- `--compress`: Compress file for storage

**Examples:**
```bash
fm_store_file agents web-scraper "# Web Scraper Config"
fm_store_file rules code-style "/* Style Guidelines */" --github=configs-repo
```

#### `fm_retrieve_file <category> <filename> [options]`
Retrieve file from storage system.

**Options:**
- `--github=<repo>`: Retrieve from GitHub
- `--cloudflare=<bucket>`: Retrieve from Cloudflare

**Examples:**
```bash
fm_retrieve_file agents web-scraper
fm_retrieve_file todos backend-tasks --github=tasks-repo
```

#### `fm_list_files [category] [options]`
List files in category or show all categories.

**Options:**
- `--versions`: Show file version history
- `--backups`: Show backup files
- `--github=<repo>`: Include GitHub sync status
- `--cloudflare=<bucket>`: Include Cloudflare sync status

**Examples:**
```bash
fm_list_files agents --versions
fm_list_files --show-all --github=configs-repo
```

### Quick Functions

#### `quick_repo <name> [options]`
Quick repository creation with smart defaults.

**Examples:**
```bash
quick_repo my-project --private --backup
quick_repo public-site --public
```

#### `quick_commit <repo> <file> <content> [options]`
Quick file commit with automatic commit messages.

**Examples:**
```bash
quick_commit user/repo config.json '{"debug": true}'
quick_commit user/repo README.md "# My Project"
```

#### `quick_agent <name> [content] [options]`
Create agent configuration with template.

**Examples:**
```bash
quick_agent web-scraper
quick_agent data-processor --github=configs-repo --sync
```

#### `quick_rule <name> [content] [options]`
Create rule definition with template.

**Examples:**
```bash
quick_rule code-style
quick_rule security-guidelines --github=rules-repo
```

#### `quick_config <name> [content] [options]`
Create configuration file with template.

**Examples:**
```bash
quick_config app-settings
quick_config database --github=configs-repo --sync
```

#### `quick_todo <task> [options]`
Add task to todo list.

**Examples:**
```bash
quick_todo "Fix authentication bug" --list=backend-tasks
quick_todo "Add unit tests" --list=frontend-tasks --github=tasks-repo
```

## 🔧 Configuration

### Environment Variables

```bash
# GitHub Configuration
export FM_DEFAULT_GITHUB_REPO="your-configs-repo"

# Cloudflare Configuration  
export FM_DEFAULT_CLOUDFLARE_BUCKET="your-bucket"

# File Manager Configuration
export FM_AUTO_SYNC="true"          # Auto-sync to remote
export FM_ENABLE_VERSIONING="true"    # Enable file versioning
export FM_MAX_VERSIONS="10"          # Max versions per file
export FM_BACKUP_ENABLED="true"       # Enable local backups

# System Configuration
export BASH_FUNCTIONS_DIR="$HOME/bash_functions.d"
export FM_ROOT_DIR="$HOME/.file_manager"
```

### Bitwarden Integration

Store credentials securely in Bitwarden:

1. **GitHub PAT** (`github_pat` entry)
   - Field: `password` = your GitHub Personal Access Token

2. **Cloudflare R2** (`cloudflare_r2` entry)
   - Field: `password` = API Key
   - Custom Field: `account_id` = Account ID
   - Custom Field: `access_key` = Access Key ID  
   - Custom Field: `secret_key` = Secret Access Key

## 🧪 Testing

### Run Test Suite

```bash
# Comprehensive system test
./bash_functions.d/tools/test_system.sh

# Individual component tests
source bash_functions.d/tools/github_api_enhanced.sh && gh_config
source bash_functions.d/tools/cloudflare_storage.sh && cf_config  
source bash_functions.d/tools/file_manager.sh && fm_config
source bash_functions.d/tools/quick_functions.sh && quick_status
```

### Test Categories

1. **Dependency Verification**: Check all required tools
2. **Function Availability**: Verify all functions are loaded
3. **Error Handling**: Test error cases and recovery
4. **Integration Testing**: Cross-component functionality
5. **Auto-completion**: Tab completion verification
6. **Configuration**: Config validation and display

## 🔒 Security Features

- **Secure Credential Storage**: Bitwarden integration with encrypted storage
- **No Hardcoded Secrets**: All secrets loaded from secure vault
- **Path Validation**: Directory traversal prevention
- **Rate Limiting**: Respectful API usage with automatic retries
- **Backup Protection**: Local backups before modifications
- **Audit Logging**: Comprehensive logging of all operations
- **Input Sanitization**: Validation of all user inputs

## 📁 Directory Structure

```
bash.d/
├── bash_functions.d/
│   └── tools/
│       ├── github_api_enhanced.sh      # GitHub API wrapper
│       ├── cloudflare_storage.sh        # Cloudflare R2 wrapper  
│       ├── file_manager.sh             # File management system
│       ├── quick_functions.sh           # Quick shell functions
│       └── test_system.sh              # Test framework
└── README_SYSTEM.md                    # This documentation
```

### File Manager Structure

```
~/.file_manager/
├── agents/           # Agent configurations
├── rules/            # Rule definitions
├── tools/            # Tool configurations  
├── logs/             # Log files
├── todos/            # Todo lists
├── configs/          # Configuration files
├── memorys/          # Memory dumps
├── .metadata/
│   └── index.json   # File index and metadata
├── .versions/         # File version history
└── .backups/          # Local backups
```

## 🚀 Advanced Usage

### Batch Operations

```bash
# Create multiple repositories
for repo in project-api project-web project-mobile; do
    quick_repo $repo --private --backup
done

# Sync all configurations
fm_sync_category configs --github=configs-repo --cloudflare=configs-bucket

# Upload multiple files with compression
for file in *.json; do
    quick_upload $file backups/$(basename $file) --compress
done
```

### Workflow Integration

```bash
# Complete project setup
quick_repo $PROJECT_NAME --private --backup
quick_config $PROJECT_NAME --github=$PROJECT_NAME --sync
quick_agent scraper-agent --github=$PROJECT_NAME --sync
quick_todo "Initial setup" --list=$PROJECT_NAME

# Deploy to production
quick_commit $PROJECT_NAME build/app.json "$(cat build/app.json)"
quick_upload $PROJECT_NAME dist/$PROJECT_NAME.tar.gz releases/ --compress
```

## 🛠️ Troubleshooting

### Common Issues

1. **Authentication Failures**
   ```bash
   # Check Bitwarden status
   bw status
   
   # Test credentials
   gh_config  # or cf_config
   ```

2. **Rate Limiting**
   - Built-in automatic retries with exponential backoff
   - Configure `GITHUB_MAX_RETRIES` and `GITHUB_RETRY_DELAY`
   - Monitor logs in `~/.logs/github_api/`

3. **File Path Issues**
   - Use relative paths only
   - No directory traversal (`../`, `/etc/passwd`)
   - Automatic folder creation for commits

4. **Dependency Issues**
   ```bash
   # Check required tools
   which curl jq gzip openssl
   
   # Install missing dependencies
   # Ubuntu/Debian: apt install curl jq gzip openssl
   # macOS: brew install curl jq gzip openssl
   ```

### Debug Mode

```bash
# Enable debug logging
export DEBUG_BASH=1
export FM_DEBUG=1
export GITHUB_DEBUG=1

# Check logs
tail -f ~/.logs/github_api/github_$(date +%Y%m%d).log
tail -f ~/.logs/cloudflare_r2/cloudflare_$(date +%Y%m%d).log
tail -f ~/.file_manager/logs/file_manager.log
```

## 📈 Performance

- **Concurrent Operations**: Rate limiting prevents API abuse
- **Caching**: Local caching for API responses
- **Compression**: Optional gzip compression for storage
- **Batch Processing**: Efficient bulk operations
- **Connection Reuse**: Persistent connections where possible

## 🤝 Contributing

### Adding New Functions

1. **Follow Naming Convention**: `category_function_name`
2. **Add Comprehensive Error Handling**: Check all return codes
3. **Include Logging**: Use category-specific logging functions
4. **Add Tests**: Update `test_system.sh`
5. **Update Documentation**: Add to this README
6. **Auto-complete**: Update completion functions

### Code Style

- **Strict Mode**: `set -euo pipefail`
- **Function Documentation**: Comprehensive header comments
- **Error Handling**: Always check return codes
- **Variable Naming**: Clear, descriptive names
- **Quote Variables**: Always quote `"${variable}"`

---

**Version**: 1.0.0  
**Created**: 2025-01-08  
**Author**: bash.d project  
**License**: MIT

For issues, feature requests, or contributions, please refer to the main bash.d repository.