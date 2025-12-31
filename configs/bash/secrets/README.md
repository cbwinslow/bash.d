# Bash Secrets Loader Template

This folder provides a repo-tracked template for sourcing the canonical secrets env.

## Install

```bash
mkdir -p ~/.config/bash/secrets
cp ~/bash.d/configs/bash/secrets/00-bashd-env.bash ~/.config/bash/secrets/00-bashd-env.bash
chmod 600 ~/.config/bash/secrets/00-bashd-env.bash
```

## Notes

- Canonical secrets file: `~/.bash_secrets.d/env/root.env`
- Do not commit secrets or `.env` files
