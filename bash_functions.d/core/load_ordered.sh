set -euo pipefail
BASEDIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

_dirs=("$BASEDIR/core" "$BASEDIR/core/agents" "$BASEDIR/tools" "$BASEDIR/completions" "$BASEDIR/tui")

for d in "${_dirs[@]}"; do
  if [[ -d "$d" ]]; then
    for f in "$d"/*.sh; do
      [[ -e "$f" ]] || continue
      # shellcheck disable=SC1090
      source "$f"
    done
  fi
done

# source top-level aliases and functions
if [[ -f "$BASEDIR/core/aliases.sh" ]]; then
  source "$BASEDIR/core/aliases.sh"
fi
if [[ -f "$BASEDIR/core/functions.sh" ]]; then
  source "$BASEDIR/core/functions.sh"
fi
if [[ -f "$BASEDIR/core/debug_decorators.sh" ]]; then
  source "$BASEDIR/core/debug_decorators.sh"
fi

# Source enabled plugins environment if present (PATH prepends and init scripts)
ENABLED_ENV="$BASEDIR/plugins/enabled_env.sh"
if [[ -f "$ENABLED_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$ENABLED_ENV"
fi
