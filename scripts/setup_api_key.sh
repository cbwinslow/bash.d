#!/bin/bash
# Extract OpenRouter API key using multiple methods

# Method 1: Try to find actual .env file
ENV_FILE=""
if [[ -f "$HOME/.env" ]]; then
    ENV_FILE="$HOME/.env"
elif [[ -f ".env" ]]; then
    ENV_FILE=".env"
elif [[ -f "bash_functions.d/.env" ]]; then
    ENV_FILE="bash_functions.d/.env"
fi

if [[ -n "$ENV_FILE" ]]; then
    echo "📄 Found env file: $ENV_FILE"
    
    # Extract OPENROUTER_API_KEY using grep
    if grep -q "OPENROUTER_API_KEY" "$ENV_FILE"; then
        API_KEY=$(grep "OPENROUTER_API_KEY" "$ENV_FILE" | cut -d'=' -f2 | tr -d '" \n\r')
        if [[ "$API_KEY" != "your_openrouter_api_key_here" && -n "$API_KEY" ]]; then
            echo "✅ Found OpenRouter API key: ${API_KEY:0:20}..."
            export OPENROUTER_API_KEY="$API_KEY"
        else
            echo "❌ API key is placeholder, setting to default"
            export OPENROUTER_API_KEY=""
        fi
    else
        echo "❌ OPENROUTER_API_KEY not found in $ENV_FILE"
        export OPENROUTER_API_KEY=""
    fi
else
    echo "❌ No .env file found"
    export OPENROUTER_API_KEY=""
fi

# Use the extracted key
if [[ -n "$OPENROUTER_API_KEY" ]]; then
    echo "🔑 Adding API key to GitHub..."
    python scripts/add_github_secret.py
else
    echo "📝 Please enter your OpenRouter API key:"
    echo "(Get free key at: https://openrouter.ai/)"
    python scripts/add_github_secret.py
fi