#!/bin/bash
git_status_all() {
    find . -type d -name .git | while read gitdir; do
        repo=$(dirname "$gitdir")
        echo "=== $repo ==="
        (cd "$repo" && git status -s)
        echo
    done
}
