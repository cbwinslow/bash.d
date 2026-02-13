# Setup Guide

This guide explains how to set up the `bash.d` ecosystem on a new machine. The process involves two main steps:

1.  **Bootstrap your own dotfiles repository.**
2.  **Run the unified installer.**

## 1. Bootstrap Your Dotfiles Repository

The `bash.d` project includes a template for your personal dotfiles. This template includes a `.bashrc` file that is pre-configured to load `bash-it` and the custom functions from `bash.d`.

To create your own dotfiles repository from this template, run the following script:

```bash
./scripts/bootstrap_dotfiles.sh
```

This script will initialize a new Git repository in the `bash.d/dotfiles` directory.

After running the script, you need to:

1.  **Create a new, empty repository** on GitHub, GitLab, or another Git hosting service.
2.  **Add this as a remote** to your new local repository:
    ```bash
    cd bash.d/dotfiles
    git remote add origin <your-remote-url>
    ```
3.  **Push the repository:**
    ```bash
    git push -u origin master
    ```

You now have your own personal dotfiles repository, ready to be managed by `yadm`.

## 2. Run the Unified Installer

Once you have your dotfiles repository, you can run the unified installer. This interactive script will guide you through the process of installing `yadm` and cloning your dotfiles repository.

To run the installer:

```bash
./scripts/unified_install.sh
```

Follow the on-screen prompts. When asked for your dotfiles repository URL, enter the URL of the repository you created in the previous step.

The installer will:

- Install `yadm` if it's not already present.
- Clone your dotfiles repository to your home directory.
- Create a symlink from `~/bashd` to the `bash.d/bashd` executable.

## Completion

After the installer finishes, your shell environment will be fully configured. Your `~/.bashrc` will be managed by `yadm`, and it will source both `bash-it` and the `bash.d` custom functions.

You can now use the `bashd` command and enjoy your new, supercharged shell!
