#!/bin/bash
# Extract API keys safely from .env file

if [[ -f ".env" ]]; then
    # Read .env file line by line
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        
        # Remove quotes from value
        value=$(echo "$value" | tr -d '"\n\r')
        
        case "$key" in
            "OPENROUTER_API_KEY")
                echo "$value"
                exit 0
                ;;
        esac
    done < .env
fi

# Fallback: check environment
echo "${OPENROUTER_API_KEY:-}"