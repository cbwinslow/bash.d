# GEMINI.md - bash.d

## Project Overview

This project, `bash.d`, is a comprehensive, enterprise-grade development ecosystem built as a shell-based framework. It is designed for modern workflows, data integration, and AI-powered automation. The ecosystem is managed through a central CLI tool, `bashd`, which provides a wide range of functionalities.

The project is structured into several components:

*   **Core:** The core logic of the `bash.d` ecosystem, providing essential functions for logging, error handling, configuration management, and plugin loading.
*   **Plugins:** An extensible architecture that allows for the integration of various data sources, AI tools, and cloud services.
*   **Platform:** A public-facing platform that includes a blog engine and a data portal.
*   **Infrastructure:** Infrastructure as Code (IaC) for managing cloud resources.
*   **Configuration:** A centralized configuration system for managing settings and secrets.
*   **Documentation:** A comprehensive set of documentation for users and contributors.

## Building and Running

For comprehensive setup instructions, please refer to the [Setup Guide](setup_guide.md).

The project is set up and managed through the `bashd` CLI.

### Initialization

To initialize the `bash.d` ecosystem with your profile, run:

```bash
./bashd init --email=<your-email> --domain=<your-domain>
```

### Running

The `bashd` CLI is the main entry point for all operations. Here are some examples:

*   **Check system status:** `./bashd status`
*   **Create a new blog post:** `./bashd blog create "My New Post"`
*   **Search for data:** `./bashd data search "some query"`
*   **Deploy the platform:** `./bashd platform deploy`

A full list of commands can be seen by running `./bashd help`.

## Development Conventions

The project follows a set of development conventions to ensure code quality and consistency.

*   **Shell Scripting:** All shell scripts are written in `bash` and follow strict coding standards (`set -euo pipefail`).
*   **Modularity:** The project is highly modular, with a core set of functions and a plugin-based architecture for extensibility.
*   **Configuration:** Configuration is managed through YAML files, with a clear separation of default settings and user-specific secrets.
*   **Documentation:** The project includes a comprehensive set of documentation, including a `README.md`, `CONTRIBUTING.md`, and a `docs` directory with more detailed information.
*   **Testing:** The project includes a `tests` directory, indicating that testing is an integral part of the development process. The `package.yaml` also mentions unit, integration, and e2e testing.
