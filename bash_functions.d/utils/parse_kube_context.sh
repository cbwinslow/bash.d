#!/bin/bash
parse_kube_context() {
    if command -v kubectl &> /dev/null; then
        local context=$(kubectl config current-context 2>/dev/null)
        local namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
        if [ -n "$context" ]; then
            echo " (k8s:$context${namespace:+:$namespace})"
        fi
    fi
}
