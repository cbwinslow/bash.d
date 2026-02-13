# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Created a `bin` directory for executable scripts.
- Created a `dotfiles` directory containing a template `.bashrc` for `yadm` management.
- Integrated the `bash-it` framework via the dotfiles template.
- Created `docs/agents.template.md` as the master template for `agents.md` files.
- Created `scripts/system/sync_agents.sh` to synchronize the `agents.md` template across all directories.
- Created `scripts/bootstrap_dotfiles.sh` to help users create their own dotfiles repository from the template.
- Created `docs/setup_guide.md` to document the new setup process.
- Created `docs/usage.md` to explain how to use the `bashd` CLI and other features.
- Created this `docs/changelog.md`.

### Changed
- Reorganized the project structure by moving most root-level markdown files to the `docs` directory.
- Updated `README.md` to reflect the new directory structure and documentation location.
- Replaced all existing `agents.md` files with the new, consistent template.
