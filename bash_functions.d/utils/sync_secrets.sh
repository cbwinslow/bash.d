#!/bin/bash
sync_secrets() {
    if command -v sync-secrets &> /dev/null; then
        sync-secrets
    else
        echo "sync-secrets command not found. Please install it first."
    fi
}
