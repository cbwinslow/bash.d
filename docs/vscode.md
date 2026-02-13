# VS Code Setup & Tips for bash.d

This document provides recommended VS Code settings, extensions, and workspace tips to work on bash.d.

## Recommended Extensions
- ShellCheck — shell script linting
- EditorConfig — consistent editor settings
- Prettier — formatting (when applicable)
- Markdown All in One — improved markdown authoring
- GitLens — git history and insights

## Workspace Recommendations
- Open the repo at the project root for proper path resolution
- Use a `settings.json` workspace file to enable shellcheck and lint-on-save

## Useful Commands
- Lint shell scripts:
```bash
shellcheck scripts/*.sh src/*.sh
```
- Run setup:
```bash
./scripts/setup.sh
```

## Tips
- Use the integrated terminal for CLI tasks and to run `./bashd` commands
- Use GitLens to track major changes made across multiple modules
- Add task definitions in `.vscode/tasks.json` for common dev tasks