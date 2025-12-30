# Template loader for bash.d secrets env (copy to ~/.config/bash/secrets/)
# Single source of truth: ~/.bash_secrets.d/env/root.env

env_file="$HOME/.bash_secrets.d/env/root.env"

if [[ -f "$env_file" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
fi
