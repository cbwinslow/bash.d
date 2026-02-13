# Contributing to bash.d

Thank you for your interest in contributing to bash.d! This document provides guidelines and best practices for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Project Structure](#project-structure)
- [Adding New Features](#adding-new-features)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)

## 📜 Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect different opinions and experiences

## 🚀 Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/bash.d.git
   cd bash.d
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/cbwinslow/bash.d.git
   ```
4. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 🔧 Development Setup

### Prerequisites

- Bash 4.0 or later
- Git
- shellcheck (for linting)
- bats (for testing, optional)

### Setup Development Environment

```bash
# Install shellcheck
# Ubuntu/Debian
sudo apt-get install shellcheck

# macOS
brew install shellcheck

# Install development dependencies
./install.sh --no-omb

# Source bash.d in development mode
export BASHD_REPO_ROOT="$(pwd)"
source ./bashrc
```

## 📝 Coding Standards

### Shell Script Guidelines

1. **Shellcheck Compliance**: All scripts must pass shellcheck
   ```bash
   shellcheck -x yourfile.sh
   ```

2. **Script Headers**: Include headers in all files
   ```bash
   #!/bin/bash
   # File: feature_name.sh
   # Description: What this file does
   # Author: Your Name
   ```

3. **Function Naming**:
   - bash.d core functions: `bashd_function_name`
   - Module-specific functions: `module_function_name`
   - Use lowercase with underscores

4. **Error Handling**:
   ```bash
   # Use set flags for scripts
   set -euo pipefail
   
   # Check prerequisites
   if ! command -v required_command &>/dev/null; then
       echo "Error: required_command not found" >&2
       return 1
   fi
   ```

5. **Quoting**: Always quote variables
   ```bash
   # Good
   echo "Value: $var"
   rm -rf "${dir}/file"
   
   # Bad
   echo Value: $var
   rm -rf $dir/file
   ```

6. **Conditionals**: Use `[[ ]]` for tests
   ```bash
   # Good
   if [[ -f "$file" ]]; then
   
   # Avoid
   if [ -f $file ]; then
   ```

### Code Organization

1. **One Module Per File**: Each plugin, alias set, or function group in its own file
2. **Logical Grouping**: Organize by functionality (git, docker, network, etc.)
3. **Dependencies**: Document dependencies in file headers
4. **Exports**: Export functions for external use:
   ```bash
   export -f my_function 2>/dev/null
   ```

### Documentation

1. **Function Documentation**:
   ```bash
   # Description of what the function does
   # Arguments:
   #   $1 - First argument description
   #   $2 - Second argument description
   # Returns:
   #   0 on success, 1 on error
   # Example:
   #   my_function "arg1" "arg2"
   my_function() {
       local arg1="$1"
       local arg2="$2"
       # Implementation
   }
   ```

2. **Module Documentation**: Include metadata for bash-it compatibility
   ```bash
   cite about-plugin
   about-plugin 'Short description of plugin'
   ```

3. **Inline Comments**: Explain complex logic
   ```bash
   # Complex regex to match specific pattern
   if [[ "$value" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
   ```

## 📁 Project Structure

```
bash.d/
├── lib/                      # Core libraries (don't modify lightly)
├── plugins/                  # Plugin modules
├── aliases/                  # Alias definitions
├── completions/              # Bash completions
├── bash_functions.d/         # Function library (main development area)
│   ├── category/            # Organized by category
│   └── *.sh                 # Individual function files
├── bash_aliases.d/          # User custom aliases
├── bash_env.d/              # Environment configurations
└── tests/                   # Test files
```

## ➕ Adding New Features

### Adding a Plugin

1. Create file in `plugins/`:
   ```bash
   plugins/myplugin.plugin.bash
   ```

2. Add plugin header:
   ```bash
   #!/bin/bash
   # Plugin: myplugin
   # Description: What this plugin does
   
   cite about-plugin
   about-plugin 'Short description'
   
   # Plugin code here
   ```

3. Test the plugin:
   ```bash
   bashd-enable plugins myplugin
   # Test your plugin functions
   ```

### Adding Aliases

1. Create file in `aliases/`:
   ```bash
   aliases/mytool.aliases.bash
   ```

2. Add alias header:
   ```bash
   #!/bin/bash
   # Aliases for mytool
   
   cite about-alias
   about-alias 'mytool shortcuts'
   
   alias mt='mytool'
   alias mts='mytool status'
   ```

### Adding Functions

1. Create file in appropriate `bash_functions.d/` subdirectory:
   ```bash
   bash_functions.d/category/my_function.sh
   ```

2. Follow function template:
   ```bash
   #!/bin/bash
   # Function: my_function
   # Description: What it does
   # Usage: my_function <arg1> <arg2>
   
   my_function() {
       local arg1="$1"
       
       if [[ -z "$arg1" ]]; then
           echo "Usage: my_function <arg1>" >&2
           return 1
       fi
       
       # Function implementation
       echo "Processing: $arg1"
       return 0
   }
   
   export -f my_function 2>/dev/null
   ```

### Adding Completions

1. Create file in `completions/`:
   ```bash
   completions/mycommand.completion.bash
   ```

2. Add completion function:
   ```bash
   #!/bin/bash
   # Completions for mycommand
   
   _mycommand_complete() {
       local cur prev words cword
       _init_completion || return
       
       case "${prev}" in
           --option)
               COMPREPLY=($(compgen -W "value1 value2" -- "${cur}"))
               return 0
               ;;
       esac
       
       COMPREPLY=($(compgen -W "--help --version --option" -- "${cur}"))
   }
   
   complete -F _mycommand_complete mycommand
   ```

## 🧪 Testing

### Manual Testing

```bash
# Test in clean environment
bash --norc --noprofile

# Source bash.d
source /path/to/bash.d/bashrc

# Test your feature
your_function arg1 arg2

# Check for errors
echo $?
```

### Automated Testing

```bash
# Run existing tests
./scripts/test/test-bashrc.sh

# Test AI integration
./scripts/test/test-ai-integration.sh

# Check with shellcheck
find . -name "*.sh" -o -name "*.bash" | xargs shellcheck -x
```

### Integration Testing

```bash
# Test with bash-it
bash-it enable plugin bash.d
bashd-list

# Test with oh-my-bash
export OMB_DIR="$HOME/.oh-my-bash"
source ~/.bashrc
bashd-list
```

## 📤 Submitting Changes

### Before Submitting

1. **Test thoroughly**: Ensure your changes work
2. **Run shellcheck**: Fix all warnings
3. **Update documentation**: Update README if needed
4. **Check formatting**: Follow style guidelines
5. **Commit message**: Write clear commit messages

### Commit Message Format

```
type(scope): short description

Longer description if needed.

- Bullet points for details
- Reference issues: Fixes #123
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting changes
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

Examples:
```
feat(plugins): add kubernetes plugin

- Add kubectl aliases
- Add completion for kubectl commands
- Add helper functions for pod management

Fixes #42
```

### Pull Request Process

1. **Update from upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push to your fork**:
   ```bash
   git push origin feature/your-feature
   ```

3. **Create Pull Request**:
   - Go to GitHub and create PR
   - Fill in the PR template
   - Link related issues
   - Request review

4. **Address Review Comments**:
   - Make requested changes
   - Push updates to same branch
   - Respond to reviewers

5. **Merge**:
   - Maintainers will merge when approved
   - Delete your feature branch after merge

## 📚 Resources

- [Bash Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Shellcheck](https://www.shellcheck.net/)
- [bash-it Documentation](https://bash-it.readthedocs.io/)

## ❓ Questions?

- Open an issue for bugs
- Start a discussion for questions
- Join our community chat

## 🎉 Recognition

Contributors will be:
- Listed in README.md
- Mentioned in release notes
- Given credit in commit history

Thank you for contributing to bash.d! 🙏
