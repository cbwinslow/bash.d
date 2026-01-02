#!/usr/bin/env bash
# PATH helpers and PATH ordering rules
set -euo pipefail

# prefer user's go bin / cargo / node global bins
[[ -d "$HOME/go/bin" ]] && PATH="$HOME/go/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && PATH="$HOME/.cargo/bin:$PATH"
[[ -d "$HOME/.npm-global/bin" ]] && PATH="$HOME/.npm-global/bin:$PATH"
export PATH

