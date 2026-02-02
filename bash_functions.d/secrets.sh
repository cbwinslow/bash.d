#!/bin/bash
#
# bash.d: A modular framework for bash.
#
# Copyright (c) 2024, C. "BW" Winslow <cbwinslow@gmail.com>
#
# This script provides functions for interacting with Bitwarden.
#

# ---
#
# ## `get_secret`
#
# Retrieves a secret from Bitwarden. It can fetch various types of secret fields,
# such as passwords, and notes.
#
# ### Parameters
#
# - `$1`: The name of the secret in Bitwarden.
# - `$2` (optional): The field to retrieve. Defaults to "password".
#
# ### Usage
#
# ```bash
# get_secret "My API Key"
# get_secret "My Server" "notes"
# ```
#
# ---

get_secret() {
    local secret_name="$1"
    local field_type="${2:-password}"

    if ! command -v bw &> /dev/null; then
        echo "bw could not be found. Please install the Bitwarden CLI to continue."
        return 1
    fi

    if [ -z "$secret_name" ]; then
        echo "Error: No secret name provided."
        return 1
    fi

    # Check login status
    if ! bw status | grep -q '"status":"unlocked"'; then
        echo "Error: Bitwarden vault is locked. Please unlock it to continue."
        return 1
    fi

    local secret_value
    if [ "$field_type" == "password" ]; then
        secret_value=$(bw get password "$secret_name")
    else
        secret_value=$(bw get notes "$secret_name")
    fi


    if [ -z "$secret_value" ]; then
        echo "Error: Secret '$secret_name' not found or field '$field_type' is empty."
        return 1
    fi

    echo "$secret_value"
}

# ---
#
# ## `generate_env_file`
#
# Generates a .env file from a template by substituting placeholders with secrets
# from Bitwarden.
#
# The template file should use the format `VAR_NAME={{BW:SECRET_NAME}}` or
# `VAR_NAME={{BW:SECRET_NAME:FIELD_TYPE}}` for placeholders.
#
# ### Parameters
#
# - `$1`: The path to the template file (e.g., `.env.template`).
# - `$2`: The path to the output file (e.g., `.env`). Defaults to `.env`.
#
# ### Usage
#
# ```bash
# generate_env_file ".env.template"
# generate_env_file ".env.template" ".env.production"
# ```
#
# ---
generate_env_file() {
    local template_file="$1"
    local output_file="${2:-.env}"

    if [ ! -f "$template_file" ]; then
        echo "Error: Template file not found at '$template_file'."
        return 1
    fi

    echo "Generating '$output_file' from '$template_file'..."

    # Ensure the output file is empty before writing
    > "$output_file"

    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ \{\{BW:([^\}]+)\}\} ]]; then
            local placeholder="${BASH_REMATCH[1]}"
            local secret_name
            local field_type

            # Check if a field type is specified (e.g., SECRET_NAME:notes)
            if [[ "$placeholder" =~ (.+):(.+) ]]; then
                secret_name="${BASH_REMATCH[1]}"
                field_type="${BASH_REMATCH[2]}"
            else
                secret_name="$placeholder"
                field_type="password" # Default to password
            fi

            echo "Found secret: $secret_name (field: $field_type)"
            local secret_value
            secret_value=$(get_secret "$secret_name" "$field_type")

            if [ $? -ne 0 ]; then
                echo "Warning: Failed to retrieve secret for '$secret_name'. Leaving placeholder."
                echo "$line" >> "$output_file"
            else
                # Substitute the placeholder with the secret value
                local new_line="${line//\{\{BW:$placeholder\}\}/$secret_value}"
                echo "$new_line" >> "$output_file"
            fi
        else
            # Line does not contain a secret, write it as is
            echo "$line" >> "$output_file"
        fi
    done < "$template_file"

    echo "Successfully generated '$output_file'."
}
