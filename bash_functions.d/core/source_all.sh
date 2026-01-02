# Source aliases and functions
if [[ -f "$HOME/.bash_functions.d/core/aliases.sh" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.bash_functions.d/core/aliases.sh"
fi
if [[ -f "$HOME/.bash_functions.d/core/functions.sh" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.bash_functions.d/core/functions.sh"
fi

# add ~/bash_functions.d/bin to PATH
mkdir -p "$HOME/.bash_functions.d/bin"
export PATH="$HOME/.bash_functions.d/bin:$PATH"
