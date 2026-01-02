#!/usr/bin/env bash
# debug_decorators.sh - Debug decorators and feature flags for bash_functions.d

# Feature flags
export DEBUG_BASH=${DEBUG_BASH:-0}
export TEST_MODE=${TEST_MODE:-0}
export LOG_LEVEL=${LOG_LEVEL:-INFO}

# Debug logger
debug_log() {
    local level="$1"
    shift
    if [[ "$DEBUG_BASH" == "1" ]] || [[ "$level" == "ERROR" ]]; then
        echo "[$(date +%Y-%m-%dT%H:%M:%S)] [$level] $*" >&2
    fi
}

# Decorator for function timing
time_decorator() {
    local func="$1"
    shift
    local start=$(date +%s%N)
    "$func" "$@"
    local end=$(date +%s%N)
    debug_log INFO "Function $func took $(( (end - start) / 1000000 )) ms"
}

# Decorator for error handling
error_decorator() {
    local func="$1"
    shift
    if "$func" "$@"; then
        debug_log INFO "Function $func succeeded"
    else
        debug_log ERROR "Function $func failed with exit code $?"
        return 1
    fi
}

# Lambda/delegate: run function with args
run_delegate() {
    local action="$1"
    local func="$2"
    shift 2
    case "$action" in
        debug)
            debug_log DEBUG "Running $func with args: $@"
            "$func" "$@"
            ;;
        test)
            echo "Testing $func..."
            if "$func" "$@"; then
                echo "✓ $func passed"
            else
                echo "✗ $func failed"
            fi
            ;;
        document)
            echo "Function: $func"
            echo "Args: $@"
            echo "Description: $(type "$func" | head -1)"
            ;;
        *)
            "$func" "$@"
            ;;
    esac
}

# Test runner
run_tests() {
    local test_funcs=("$@")
    for func in "${test_funcs[@]}"; do
        run_delegate test "$func"
    done
}

