# bash.d Search & Index System

A comprehensive system for organizing, indexing, and searching bash functions, aliases, and scripts in the bash.d repository.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands Reference](#commands-reference)
- [Usage Examples](#usage-examples)
- [Advanced Features](#advanced-features)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

## Overview

The bash.d Search & Index System provides:

- **Fast Indexing**: Build a searchable database of all repository content
- **Multiple Search Methods**: Unified search, pattern matching, fuzzy search, and content search
- **Smart Organization**: Sort by various criteria, categorize, and track usage
- **Easy Navigation**: Browse through search results with simple commands
- **Session Management**: Save and recall search sessions
- **Rich Metadata**: Extract and display comprehensive information about each function

## Installation

The search system is automatically loaded when you source bash.d. No manual installation required.

### Requirements

**Required:**
- `jq` - JSON processor for index operations

**Optional but Recommended:**
- `fzf` - For interactive fuzzy search
- `bat` or `pygmentize` - For syntax highlighting
- `ripgrep` (rg) - For faster content searches

Install on Ubuntu/Debian:
```bash
sudo apt install jq fzf bat ripgrep
```

Install on macOS:
```bash
brew install jq fzf bat ripgrep
```

## Quick Start

### 1. Build the Index

First time setup:
```bash
bashd_index_build
```

This creates a searchable database of all functions, aliases, and scripts.

### 2. Search for Something

```bash
# Search for docker-related items
bashd_search docker

# Use fuzzy search (interactive)
bashd_fuzzy docker

# Locate a specific function
bashd_locate docker_cleanup
```

### 3. Get Help

```bash
# General help
bashd_help

# Help for specific command
bashd_help search
bashd_help fuzzy
```

## Commands Reference

### Indexing Commands

| Command | Description | Example |
|---------|-------------|---------|
| `bashd_index_build` | Build complete index from scratch | `bashd_index_build` |
| `bashd_index_update` | Update index with recent changes | `bashd_index_update` |
| `bashd_index_stats` | Show index statistics | `bashd_index_stats` |
| `bashd_index_query <term>` | Query index directly | `bashd_index_query docker` |

**Aliases:** `bdi` (build), `bdiu` (update), `bdis` (stats)

### Search Commands

| Command | Description | Example |
|---------|-------------|---------|
| `bashd_search <term> [type]` | Unified search | `bashd_search docker functions` |
| `bashd_find <pattern> [where]` | Pattern-based file search | `bashd_find "docker*"` |
| `bashd_locate <name>` | Quick exact name lookup | `bashd_locate docker_cleanup` |
| `bashd_fuzzy [term]` | Interactive fuzzy search | `bashd_fuzzy network` |
| `bashd_grep <pattern> [context]` | Content search | `bashd_grep "TODO" 3` |

**Aliases:** `bds` (search), `bdf` (find), `bdl` (locate), `bdz` (fuzzy), `bdg` (grep)

### Utility Commands

| Command | Description | Example |
|---------|-------------|---------|
| `bashd_sort [criteria] [order] [type]` | Sort items | `bashd_sort size desc` |
| `bashd_describe <name> [source]` | Show detailed info | `bashd_describe docker_cleanup` |
| `bashd_recent [count] [type]` | Recently modified/used | `bashd_recent 20 modified` |
| `bashd_popular [count]` | Most frequently used | `bashd_popular 15` |
| `bashd_edit <name>` | Quick edit | `bashd_edit docker_cleanup` |

**Aliases:** `bde` (edit)

### Navigation Commands

| Command | Description | Example |
|---------|-------------|---------|
| `bashd_next` | Next search result | `bashd_next` |
| `bashd_prev` | Previous result | `bashd_prev` |
| `bashd_first` | First result | `bashd_first` |
| `bashd_last` | Last result | `bashd_last` |

### Session Management

| Command | Description | Example |
|---------|-------------|---------|
| `bashd_save <name>` | Save current session | `bashd_save docker_funcs` |
| `bashd_recall_session <name>` | Recall session | `bashd_recall_session docker_funcs` |

### Help System

| Command | Description | Example |
|---------|-------------|---------|
| `bashd_help [command]` | Get help | `bashd_help search` |
| `bashd_help_topics` | List help topics | `bashd_help_topics` |

**Alias:** `bdh` (help)

## Usage Examples

### Example 1: Finding Docker Functions

```bash
# Search for all docker-related items
$ bashd_search docker

# Results show functions, aliases, and scripts
# Navigate through results
$ bashd_next
$ bashd_prev

# Get detailed information
$ bashd_describe docker_cleanup

# Edit the function
$ bashd_edit docker_cleanup
```

### Example 2: Interactive Exploration

```bash
# Launch fuzzy search (requires fzf)
$ bashd_fuzzy

# Type to filter results in real-time
# Use arrow keys to navigate
# Press Enter to select and view details
# Choose action: view, edit, or source
```

### Example 3: Finding by Pattern

```bash
# Find all network-related files
$ bashd_find "network*"

# Find all git functions
$ bashd_find "git_*" functions

# Find all .sh files
$ bashd_find "*.sh" all
```

### Example 4: Content Search

```bash
# Find TODO comments
$ bashd_grep "TODO" 3

# Search for function definitions
$ bashd_grep "function.*docker"

# Find all uses of a variable
$ bashd_grep "DOCKER_HOST"
```

### Example 5: Sorting and Organization

```bash
# Sort functions alphabetically
$ bashd_sort name asc

# Show largest files
$ bashd_sort size desc

# Sort by modification date (newest first)
$ bashd_sort date desc all

# Sort by category
$ bashd_sort category asc
```

### Example 6: Working with Sessions

```bash
# Find and explore docker functions
$ bashd_search docker functions

# Save the search session
$ bashd_save my_docker_work

# Later, recall the session
$ bashd_recall_session my_docker_work

# Continue where you left off
$ bashd_next
```

### Example 7: Recent and Popular

```bash
# Show recently modified functions
$ bashd_recent 20

# Show recently used from history
$ bashd_recent 15 used

# Show most popular functions
$ bashd_popular 10
```

## Advanced Features

### Search Options

`bashd_search` supports multiple options:

```bash
# Verbose output with details
bashd_search -v docker

# Interactive mode
bashd_search -i docker

# Count matches only
bashd_search -c docker

# Search in specific types
bashd_search docker functions
bashd_search network aliases
bashd_search backup scripts
```

### Sort Criteria

Sort by various criteria:

- `name` - Alphabetically
- `size` - File size
- `date` - Modification date
- `lines` - Line count
- `category` - Category name
- `usage` - Usage frequency (if tracked)

```bash
bashd_sort size desc functions    # Largest functions
bashd_sort date desc all           # Most recently changed
bashd_sort lines desc              # Longest files
```

### Pattern Matching

Use wildcards in `bashd_find`:

- `*` - Match any characters
- `?` - Match single character
- `[]` - Match character set

```bash
bashd_find "docker*"          # docker_cleanup, docker_stats, etc.
bashd_find "test_?.sh"        # test_1.sh, test_2.sh, etc.
bashd_find "*[0-9]*.sh"       # Files with numbers
```

### Index Queries

Direct index queries for advanced users:

```bash
# Query specific term
bashd_index_query docker

# View index statistics
bashd_index_stats

# Update index after changes
bashd_index_update
```

## Configuration

### Environment Variables

```bash
# Set bash.d home directory (default: ~/.bash.d)
export BASHD_HOME="$HOME/.bash.d"

# Set index directory (default: $BASHD_HOME/.index)
export BASHD_INDEX_DIR="$BASHD_HOME/.index"

# Set index file location
export BASHD_INDEX_FILE="$BASHD_INDEX_DIR/master_index.json"

# Set editor for bashd_edit (default: $EDITOR or vim)
export EDITOR="nano"

# Set grep options for bashd_grep
export BASHD_GREP_OPTS="-i -E"
```

### Customization

Add to your `.bashrc` or `.bash_profile`:

```bash
# Auto-update index on shell start (optional)
# bashd_index_update >/dev/null 2>&1 &

# Customize search behavior
export BASHD_GREP_OPTS="-i -E -C 3"

# Set preferred editor
export EDITOR="code"  # VS Code
export EDITOR="nano"  # nano
export EDITOR="emacs" # Emacs
```

## Troubleshooting

### Index Not Found

```bash
# If you get "Index not found" errors:
bashd_index_build
```

### Missing Dependencies

```bash
# Check for missing dependencies
command -v jq || echo "jq not installed"
command -v fzf || echo "fzf not installed (optional)"

# Install on Ubuntu/Debian
sudo apt install jq fzf

# Install on macOS
brew install jq fzf
```

### Slow Searches

```bash
# Rebuild index for faster searches
bashd_index_build

# Update index after changes
bashd_index_update
```

### fzf Not Working

```bash
# Install fzf
sudo apt install fzf  # Ubuntu/Debian
brew install fzf      # macOS

# Or use non-interactive alternatives
bashd_search instead of bashd_fuzzy
```

### Completions Not Working

```bash
# Ensure bash-completion is installed
sudo apt install bash-completion

# Source the completions manually
source ~/.bash.d/completions/search_completions.bash

# Reload shell
source ~/.bashrc
```

## Performance Tips

1. **Build index once**: Run `bashd_index_build` after cloning or major changes
2. **Update incrementally**: Use `bashd_index_update` for small changes
3. **Use index-based searches**: Commands like `bashd_search` and `bashd_locate` are faster than `find`
4. **Save sessions**: Use `bashd_save` to preserve search results
5. **Use fuzzy search**: `bashd_fuzzy` is fastest for interactive exploration

## Integration with Existing Tools

The search system works alongside existing bash.d tools:

```bash
# Works with existing func_* commands
func_recall          # Still works
bashd_locate         # New, faster alternative

# Works with existing search
func_search          # Still works
bashd_search         # New, more comprehensive

# Enhanced functionality
bashd_fuzzy          # Interactive version
bashd_grep           # Content search with context
```

## Summary

The bash.d Search & Index System provides a complete solution for organizing and finding content in the bash.d repository. With multiple search methods, smart navigation, and rich metadata, it makes working with large bash function libraries efficient and intuitive.

**Key Benefits:**
- ⚡ Fast searches using index
- 🔍 Multiple search methods
- 📊 Rich metadata and statistics  
- 🎯 Smart navigation
- 💾 Session management
- 🎨 Syntax highlighting support
- ⌨️ Tab completion for all commands
- 📝 Comprehensive help system

For more help: `bashd_help` or `bashd_help <command>`
