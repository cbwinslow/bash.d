#!/bin/bash
set -euo pipefail

# This script bootstraps a new dotfiles repository from the template in bash.d/dotfiles.

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(dirname "$SCRIPT_DIR")"
readonly DOTFILES_DIR="$ROOT_DIR/dotfiles"

print_header() {
    cat << 'EOF'
Dotfiles Repository Bootstrap
==============================
EOF
}

info() {
    echo "[info] $*"
}

main() {
    print_header

    cd "$DOTFILES_DIR"

    if [ -d ".git" ]; then
        info "A Git repository already exists in $DOTFILES_DIR."
    else
        info "Initializing new Git repository in $DOTFILES_DIR..."
        git init
        git add .
        git commit -m "Initial commit: Bootstrap from bash.d template"
        info "Git repository created."
    fi

    echo
    info "Next steps:"
    info "1. Create a new, empty repository on GitHub or GitLab."
    info "2. Add it as a remote to this new repository:"
    info "   cd $DOTFILES_DIR"
    info "   git remote add origin <your-remote-url>"
    info "3. Push the repository:"
    info "   git push -u origin master"
    info "4. Run the main installer and use your new dotfiles repository:"
    info "   $ROOT_DIR/scripts/unified_install.sh"
}

main "$@"
