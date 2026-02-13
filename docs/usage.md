# Usage Guide

This guide explains how to use the `bashd` command-line interface and the core features of the `bash.d` ecosystem.

## The `bashd` CLI

The `bashd` command is the main entry point for all operations in the `bash.d` ecosystem. It provides a unified interface for managing your shell environment, development projects, and more.

### Common Commands

- **`bashd status`**: Displays the current status of the `bash.d` ecosystem, including the versions of key tools and the state of your dotfiles.
- **`bashd setup`**: Runs the interactive setup process (by calling `scripts/unified_install.sh`).
- **`bashd blog create "My Post"`**: Creates a new blog post.
- **`bashd data search "query"`**: Searches for data across all integrated sources.
- **`bashd system sync-agents`**: Synchronizes the `agents.md` files in all directories from the master template. (This is a new command you can add to `bashd`.)

A full list of commands can be seen by running `bashd help`.

## Shell Environment

The `bash.d` ecosystem is designed to supercharge your shell environment. When you source the `~/.bashrc` file managed by this project, you get:

- **`bash-it` Framework**: A powerful community-driven framework for Bash with numerous aliases, completions, and functions. The default theme is `powerline-plain`.
- **Custom Functions**: All the `.sh` files in the `bash_functions.d` directory are automatically sourced, providing a rich set of custom tools and helpers.
- **Custom Aliases**: The `.bashrc` template includes a set of common aliases (like `ll` for `ls -alF`). You can add your own personal aliases to this file.

## Dotfile Management

Your dotfiles (like `~/.bashrc`, `~/.gitconfig`, etc.) are managed by `yadm`. This allows you to keep your personal configuration in a Git repository and easily apply it to new machines.

The `scripts/unified_install.sh` script guides you through the process of setting up `yadm` with your own dotfiles repository. See the `docs/setup_guide.md` for more details.

## AI Agent Integration

The `bash.d` project is designed to be understood and navigated by AI agents. Every directory contains an `agents.md` file that provides context and instructions for AI agents.

You can use the `scripts/system/sync_agents.sh` script to keep these files up-to-date with the master template in `docs/agents.template.md`.
