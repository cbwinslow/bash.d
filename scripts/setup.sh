#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "setup.sh is deprecated. Use unified_install.sh instead."
exec "${SCRIPT_DIR}/unified_install.sh" "$@"
