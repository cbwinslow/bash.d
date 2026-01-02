Deploying bash_functions.d to GitHub (cbwinslow/bash.d)

This document explains how to package and push the `bash_functions.d` tree to your GitHub repository `cbwinslow/bash.d` using the provided script `deploy_to_github.sh`.

Prerequisites
- git installed and configured
- SSH key configured for GitHub (or gh CLI logged in)
- Optional: GitHub CLI (`gh`) if you want the script to create the remote repo automatically

Usage

Preview (dry-run, default):

```bash
# from within the bash_functions.d directory or passing --src
bash deploy_to_github.sh --src $(pwd)
```

Push (perform actual push):

```bash
bash deploy_to_github.sh --src ~/bash_functions.d --push
```

What the script does
- Copies your source tree to a temporary directory (excludes .git and docs/man by default)
- Initializes a git repo and commits the files
- If `--push` is provided and `gh` is available, attempts to create the remote repo and push
- If `--push` is not provided, shows a preview and leaves no changes on disk

Tips and safety
- Inspect the preview before pushing.
- If you want to preserve file ownership/permissions, run the script as your user (not root).
- The script attempts to be conservative and will not overwrite any remote unless you use `--push`.


