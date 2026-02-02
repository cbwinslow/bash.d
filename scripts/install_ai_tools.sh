#!/bin/bash
#
# bash.d: A modular framework for bash.
#
# Copyright (c) 2024, C. "BW" Winslow <cbwinslow@gmail.com>
#
# This script installs a suite of AI/LLM Python frameworks.
#

# ---
#
# ## `install_ai_tools`
#
# Installs LangChain, Langfuse, Langroid, LangSmith, and LangGraph.
#
# ### Usage
#
# ```bash
# ./scripts/install_ai_tools.sh
# ```
#
# ---

install_ai_tools() {
    if ! command -v uv &> /dev/null; then
        echo "Error: uv is not installed. Please install it to continue (e.g., curl -LsSf https://astral.sh/uv/install.sh | sh)."
        return 1
    fi

    local venv_path="./.venv"

    echo "Setting up Python virtual environment using uv..."
    if [ ! -d "$venv_path" ]; then
        uv venv "$venv_path"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create virtual environment using uv."
            return 1
        fi
        echo "Virtual environment created at $venv_path."
    else
        echo "Virtual environment already exists at $venv_path."
    fi

    echo "Activating virtual environment..."
    source "$venv_path/bin/activate"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to activate virtual environment."
        return 1
    fi
    echo "Virtual environment activated."

    echo "Upgrading pip, setuptools, and wheel..."
    if uv pip install -q --upgrade pip setuptools wheel; then
        echo "pip, setuptools, and wheel upgraded successfully."
    else
        echo "Warning: Failed to upgrade pip, setuptools, and wheel. Continuing with installation."
    fi

    echo "Installing AI/LLM frameworks using uv pip..."

    local packages=(
        "langchain"
        "langfuse"
        "langsmith"
        "langgraph"
    )

    for package in "${packages[@]}"; do
        echo "Installing $package..."
        if uv pip install -q "$package"; then
            echo "$package installed successfully."
        else
            echo "Error: Failed to install $package."
        fi
    done

    echo "Deactivating virtual environment..."
    deactivate
    echo "Virtual environment deactivated."

    echo "All AI/LLM frameworks have been installed."
}

install_ai_tools
