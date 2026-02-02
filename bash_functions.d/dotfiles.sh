#!/bin/bash
#
# bash.d: A modular framework for bash.
#
# Copyright (c) 2024, C. "BW" Winslow <cbwinslow@gmail.com>
#
# This script provides a generalized procedure for setting up dotfiles with yadm.
#

# ---
#
# ## `setup_dotfiles`
#
# Initializes or clones a dotfiles repository using yadm.
#
# ### Parameters
#
# - `$1`: The URL of the git repository for the dotfiles.
#
# ### Usage
#
# ```bash
# setup_dotfiles "https://github.com/user/dots.git"
# ```
#
# ---

setup_dotfiles() {
    local repo_url="$1"

    if ! command -v yadm &> /dev/null; then
        echo "yadm could not be found. Please install yadm to continue."
        return 1
    fi

    if [ -z "$repo_url" ]; then
        echo "Error: No repository URL provided."
        return 1
    fi

    echo "Cloning dotfiles from $repo_url..."
    if yadm clone "$repo_url"; then
        echo "Dotfiles cloned successfully."
        echo "You can now manage your dotfiles with yadm."
    else
        echo "Error: Failed to clone dotfiles."
        return 1
    fi
}

