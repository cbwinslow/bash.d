#!/bin/bash
# Database Information Collector Script
# Detects installed databases and their configurations
# Outputs JSON format

set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

command_exists() {
    command -v "$1" &> /dev/null
}

check_postgres() {
    if command_exists psql; then
        local version=$(psql --version 2>/dev/null | awk '{print $3}')
        local status="unknown"
        if systemctl is-active postgresql &>/dev/null; then
            status="running"
        elif pgrep -x postgres &>/dev/null; then
            status="running"
        else
            status="stopped"
        fi
        echo "{\"installed\": true, \"version\": \"$version\", \"status\": \"$status\"}"
    else
        echo "{\"installed\": false}"
    fi
}

check_mysql() {
    if command_exists mysql; then
        local version=$(mysql --version 2>/dev/null | awk '{print $5}' | sed 's/,//')
        local status="unknown"
        if systemctl is-active mysql &>/dev/null || systemctl is-active mariadb &>/dev/null; then
            status="running"
        elif pgrep -x mysqld &>/dev/null; then
            status="running"
        else
            status="stopped"
        fi
        echo "{\"installed\": true, \"version\": \"$version\", \"status\": \"$status\"}"
    else
        echo "{\"installed\": false}"
    fi
}

check_mongodb() {
    if command_exists mongod; then
        local version=$(mongod --version 2>/dev/null | head -1 | awk '{print $3}')
        local status="unknown"
        if systemctl is-active mongod &>/dev/null; then
            status="running"
        elif pgrep -x mongod &>/dev/null; then
            status="running"
        else
            status="stopped"
        fi
        echo "{\"installed\": true, \"version\": \"$version\", \"status\": \"$status\"}"
    else
        echo "{\"installed\": false}"
    fi
}

check_redis() {
    if command_exists redis-server; then
        local version=$(redis-server --version 2>/dev/null | awk '{print $3}' | sed 's/v=//')
        local status="unknown"
        if systemctl is-active redis &>/dev/null || systemctl is-active redis-server &>/dev/null; then
            status="running"
        elif pgrep -x redis-server &>/dev/null; then
            status="running"
        else
            status="stopped"
        fi
        echo "{\"installed\": true, \"version\": \"$version\", \"status\": \"$status\"}"
    else
        echo "{\"installed\": false}"
    fi
}

check_sqlite() {
    if command_exists sqlite3; then
        local version=$(sqlite3 --version 2>/dev/null | awk '{print $1}')
        echo "{\"installed\": true, \"version\": \"$version\"}"
    else
        echo "{\"installed\": false}"
    fi
}

main() {
    log_info "Collecting database information..."
    
    cat << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$(hostname)",
    "databases": {
        "postgresql": $(check_postgres),
        "mysql": $(check_mysql),
        "mongodb": $(check_mongodb),
        "redis": $(check_redis),
        "sqlite": $(check_sqlite)
    }
}
EOF
    
    log_info "Database collection complete!"
}

main "$@"
