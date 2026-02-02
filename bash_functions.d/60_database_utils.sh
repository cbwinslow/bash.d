#!/bin/bash
# ============================================================================
# Database Utilities
# ============================================================================
# Helper functions for database operations and management

# PostgreSQL quick connect
pgconnect() {
    if [ -z "$1" ]; then
        echo "Usage: pgconnect <database> [host] [user] [port]"
        return 1
    fi
    
    local db="$1"
    local host="${2:-localhost}"
    local user="${3:-postgres}"
    local port="${4:-5432}"
    
    psql -h "$host" -U "$user" -p "$port" -d "$db"
}

# PostgreSQL dump database
pgdump() {
    if [ -z "$1" ]; then
        echo "Usage: pgdump <database> [output_file]"
        return 1
    fi
    
    local db="$1"
    local output="${2:-${db}_$(date +%Y%m%d_%H%M%S).sql}"
    
    pg_dump "$db" > "$output"
    echo -e "${COLOR_GREEN}Database dumped to: $output${COLOR_RESET}"
}

# PostgreSQL restore database
pgrestore() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: pgrestore <database> <dump_file>"
        return 1
    fi
    
    local db="$1"
    local dump="$2"
    
    psql "$db" < "$dump"
    echo -e "${COLOR_GREEN}Database restored from: $dump${COLOR_RESET}"
}

# PostgreSQL list databases
pglist() {
    psql -l
}

# PostgreSQL execute query
pgquery() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: pgquery <database> <query>"
        return 1
    fi
    
    local db="$1"
    local query="$2"
    
    psql -d "$db" -c "$query"
}

# MySQL quick connect
myconnect() {
    if [ -z "$1" ]; then
        echo "Usage: myconnect <database> [host] [user]"
        return 1
    fi
    
    local db="$1"
    local host="${2:-localhost}"
    local user="${3:-root}"
    
    mysql -h "$host" -u "$user" -p "$db"
}

# MySQL dump database
mydump() {
    if [ -z "$1" ]; then
        echo "Usage: mydump <database> [output_file]"
        return 1
    fi
    
    local db="$1"
    local output="${2:-${db}_$(date +%Y%m%d_%H%M%S).sql}"
    
    mysqldump "$db" > "$output"
    echo -e "${COLOR_GREEN}Database dumped to: $output${COLOR_RESET}"
}

# MySQL restore database
myrestore() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: myrestore <database> <dump_file>"
        return 1
    fi
    
    local db="$1"
    local dump="$2"
    
    mysql "$db" < "$dump"
    echo -e "${COLOR_GREEN}Database restored from: $dump${COLOR_RESET}"
}

# MySQL list databases
mylist() {
    mysql -e "SHOW DATABASES;"
}

# MySQL execute query
myquery() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: myquery <database> <query>"
        return 1
    fi
    
    local db="$1"
    local query="$2"
    
    mysql -e "USE $db; $query"
}

# MongoDB connect
mongoconnect() {
    local db="${1:-test}"
    local host="${2:-localhost}"
    local port="${3:-27017}"
    
    mongo "$host:$port/$db"
}

# MongoDB dump database
mongodump_db() {
    if [ -z "$1" ]; then
        echo "Usage: mongodump_db <database> [output_dir]"
        return 1
    fi
    
    local db="$1"
    local output="${2:-dump_${db}_$(date +%Y%m%d_%H%M%S)}"
    
    mongodump --db "$db" --out "$output"
    echo -e "${COLOR_GREEN}Database dumped to: $output${COLOR_RESET}"
}

# MongoDB restore database
mongorestore_db() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: mongorestore_db <database> <dump_dir>"
        return 1
    fi
    
    local db="$1"
    local dump="$2"
    
    mongorestore --db "$db" "$dump/$db"
    echo -e "${COLOR_GREEN}Database restored from: $dump${COLOR_RESET}"
}

# Redis connect
redisconnect() {
    local host="${1:-localhost}"
    local port="${2:-6379}"
    
    redis-cli -h "$host" -p "$port"
}

# Redis get key
redisget() {
    if [ -z "$1" ]; then
        echo "Usage: redisget <key> [host] [port]"
        return 1
    fi
    
    local key="$1"
    local host="${2:-localhost}"
    local port="${3:-6379}"
    
    redis-cli -h "$host" -p "$port" GET "$key"
}

# Redis set key
redisset() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: redisset <key> <value> [host] [port]"
        return 1
    fi
    
    local key="$1"
    local value="$2"
    local host="${3:-localhost}"
    local port="${4:-6379}"
    
    redis-cli -h "$host" -p "$port" SET "$key" "$value"
}

# Redis list all keys
rediskeys() {
    local pattern="${1:-*}"
    local host="${2:-localhost}"
    local port="${3:-6379}"
    
    redis-cli -h "$host" -p "$port" KEYS "$pattern"
}

# SQLite connect to database
sqliteconnect() {
    if [ -z "$1" ]; then
        echo "Usage: sqliteconnect <database_file>"
        return 1
    fi
    
    sqlite3 "$1"
}

# SQLite dump database
sqlitedump() {
    if [ -z "$1" ]; then
        echo "Usage: sqlitedump <database_file> [output_file]"
        return 1
    fi
    
    local db="$1"
    local output="${2:-${db%.db}_$(date +%Y%m%d_%H%M%S).sql}"
    
    sqlite3 "$db" .dump > "$output"
    echo -e "${COLOR_GREEN}Database dumped to: $output${COLOR_RESET}"
}

# SQLite execute query
sqlitequery() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: sqlitequery <database_file> <query>"
        return 1
    fi
    
    local db="$1"
    local query="$2"
    
    sqlite3 "$db" "$query"
}

# Show table structure (PostgreSQL)
pgtable() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: pgtable <database> <table_name>"
        return 1
    fi
    
    local db="$1"
    local table="$2"
    
    psql -d "$db" -c "\d+ $table"
}

# Show table structure (MySQL)
mytable() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: mytable <database> <table_name>"
        return 1
    fi
    
    local db="$1"
    local table="$2"
    
    mysql -e "USE $db; DESCRIBE $table;"
}

# Database size (PostgreSQL)
pgsize() {
    if [ -z "$1" ]; then
        echo "Usage: pgsize <database>"
        return 1
    fi
    
    psql -d "$1" -c "SELECT pg_size_pretty(pg_database_size('$1'));"
}

# Database size (MySQL)
mysize() {
    if [ -z "$1" ]; then
        echo "Usage: mysize <database>"
        return 1
    fi
    
    mysql -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.TABLES WHERE table_schema = '$1' GROUP BY table_schema;"
}
