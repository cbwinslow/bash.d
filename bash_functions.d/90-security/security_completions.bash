#!/bin/bash
# Security and Anonymity Completions

_security_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main security commands
    if [[ "$cur" == -* ]]; then
        opts="--help --version --verbose --quiet"
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
        return 0
    fi
    
    # Subcommands
    case "$prev" in
        security|sec)
            opts="scan monitor ports detect_scans anonymity status logs dashboard install quick_check report lockdown toolkit"
            ;;
        security_scan|sec-scan)
            opts="--verbose --log-file --threshold"
            ;;
        security_monitor|sec-mon)
            opts="--daemon --interval --log-file"
            ;;
        security_ports|sec-ports)
            opts="--analyze --vulns --export"
            ;;
        security_anonymity|anon)
            opts="--tor --vpn --dns-leak-protection"
            ;;
        *)
            return 0
            ;;
    esac
    
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
}

# Network monitor completions
_network_monitor_completions() {
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    
    case "$cur" in
        -*)
            opts="--help --scan --monitor --analyze --detect --verbose --threshold"
            ;;
        *)
            opts="scan monitor analyze detect install help"
            ;;
    esac
    
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
}

# Port scanner completions
_port_scanner_completions() {
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    
    case "$cur" in
        -*)
            opts="--help --target --ports --verbose --output"
            ;;
        *)
            opts="detect analyze history interactive monitor help"
            ;;
    esac
    
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
}

# Register completions
complete -F _security_completions security
complete -F _security_completions sec
complete -F _network_monitor_completions network_security_monitor
complete -F _network_monitor_completions netmon
complete -F _port_scanner_completions port_scan_detector
complete -F _port_scanner_completions portscan